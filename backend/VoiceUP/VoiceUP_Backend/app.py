import os
import uuid
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from dotenv import load_dotenv
from werkzeug.utils import secure_filename
from models import db, User, Conversation, Message, Transcription

load_dotenv()

app = Flask(__name__)
CORS(app)

app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['UPLOAD_FOLDER'] = os.getenv('UPLOAD_FOLDER', 'uploads')

if not os.path.exists(app.config['UPLOAD_FOLDER']):
    os.makedirs(app.config['UPLOAD_FOLDER'])

db.init_app(app)

with app.app_context():
    db.create_all()

# --- ENDPOINTS EXISTANTS (CONTACTS / CONVS) ---

@app.route('/api/contacts', methods=['GET'])
def get_contacts():
    """GET /api/contacts - List all users/contacts"""
    users = User.query.all()
    return jsonify([{
        "id": u.id, 
        "name": u.name, 
        "avatarUrl": u.avatarUrl,
        "createdAt": u.createdAt.isoformat() if u.createdAt else None
    } for u in users])

# --- CONVERSATIONS ENDPOINTS ---

@app.route('/api/conversations', methods=['GET'])
def get_conversations():
    """GET /api/conversations - List all conversations, optionally filtered by userId"""
    user_id = request.args.get('userId')
    
    if user_id:
        # Get conversations for a specific user
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404
        conversations = user.conversations
    else:
        # Get all conversations
        conversations = Conversation.query.all()
    
    result = []
    for conv in conversations:
        # Get participant IDs
        participant_ids = [user.id for user in conv.users]
        
        # If no title, generate one from participant names (excluding current user if provided)
        title = conv.title
        if not title and participant_ids:
            # Get names of other participants
            other_users = [u for u in conv.users if user_id is None or u.id != user_id]
            if other_users:
                title = ", ".join([u.name for u in other_users])
            else:
                title = "Conversation"
        
        result.append({
            "id": conv.id,
            "title": title or "Conversation",
            "participantIds": participant_ids,
            "createdAt": conv.createdAt.isoformat() if conv.createdAt else None
        })
    
    return jsonify(result), 200

@app.route('/api/conversations', methods=['POST'])
def create_conversation():
    """POST /api/conversations - Create a new conversation"""
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    participant_ids = data.get('participantIds', [])
    if not participant_ids or len(participant_ids) < 2:
        return jsonify({"error": "At least 2 participants required"}), 400
    
    # Verify all users exist
    users = []
    for user_id in participant_ids:
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": f"User {user_id} not found"}), 404
        users.append(user)
    
    # Create conversation
    new_conv = Conversation(
        title=data.get('title'),
        createdAt=datetime.utcnow()
    )
    db.session.add(new_conv)
    db.session.flush()  # Get the ID
    
    # Add participants
    for user in users:
        new_conv.users.append(user)
    
    db.session.commit()
    
    # Return the created conversation
    participant_ids_list = [user.id for user in new_conv.users]
    return jsonify({
        "id": new_conv.id,
        "title": new_conv.title or "Conversation",
        "participantIds": participant_ids_list,
        "createdAt": new_conv.createdAt.isoformat() if new_conv.createdAt else None
    }), 201

# --- NOUVEAU : ENVOI DE MESSAGE ---

@app.route('/api/conversations/<conv_id>/messages', methods=['POST'])
def send_message(conv_id):
    # On vérifie si c'est un message texte (JSON) ou audio (Multipart ou JSON avec URL)
    if request.is_json:
        data = request.get_json()
        msg_type = data.get('type', 'TEXT').upper()
        # Get senderId from body or X-User-Id header
        sender_id = data.get('senderId') or request.headers.get('X-User-Id')
        
        if msg_type == 'AUDIO':
            # Audio message with encryptedPayloadUrl (already uploaded)
            encrypted_blob_url = data.get('encryptedPayloadUrl')
            if not encrypted_blob_url:
                return jsonify({"error": "encryptedPayloadUrl is required for AUDIO messages"}), 400
            
            new_msg = Message(
                conversationId=conv_id,
                senderId=sender_id,
                type='AUDIO',
                encryptedBlobUrl=encrypted_blob_url,
                iv=data.get('iv', ''),
                contentPreview=data.get('contentPreview', 'Voice message')
            )
            db.session.add(new_msg)
            db.session.flush()
            
            # Handle transcription if provided
            transcription_data = data.get('transcription')
            print(f"[DEBUG] Transcription data received: {transcription_data}")
            if transcription_data and isinstance(transcription_data, dict):
                transcription_text = transcription_data.get('text')
                print(f"[DEBUG] Transcription text: {transcription_text}")
                if transcription_text:
                    new_trans = Transcription(
                        messageId=new_msg.id,
                        text=transcription_text,
                        confidence=transcription_data.get('confidence', 1.0)
                    )
                    db.session.add(new_trans)
                    print(f"[DEBUG] Transcription added to database for message {new_msg.id}")
                else:
                    print(f"[DEBUG] Warning: Transcription text is empty")
            else:
                print(f"[DEBUG] Warning: No transcription data provided or invalid format")
            
            db.session.commit()
            print(f"[DEBUG] Message {new_msg.id} committed to database")
            return jsonify({
                "id": new_msg.id,
                "conversationId": new_msg.conversationId,
                "senderId": new_msg.senderId,
                "type": new_msg.type,
                "encryptedBlobUrl": new_msg.encryptedBlobUrl,
                "iv": new_msg.iv,
                "isEncrypted": new_msg.isEncrypted,
                "contentPreview": new_msg.contentPreview,
                "createdAt": new_msg.createdAt.isoformat() if new_msg.createdAt else None,
                "isRead": False
            }), 201
        else:
            # Text message
            new_msg = Message(
                conversationId=conv_id,
                senderId=sender_id,
                type='TEXT',
                encryptedPayload=data.get('encryptedPayload'),
                iv=data.get('iv'),
                contentPreview=data.get('plaintextPreview') # Optionnel
            )
            db.session.add(new_msg)
            db.session.commit()
            return jsonify({
                "id": new_msg.id,
                "conversationId": new_msg.conversationId,
                "senderId": new_msg.senderId,
                "type": new_msg.type,
                "encryptedPayload": new_msg.encryptedPayload,
                "encryptedBlobUrl": new_msg.encryptedBlobUrl or '',
                "iv": new_msg.iv,
                "isEncrypted": new_msg.isEncrypted,
                "contentPreview": new_msg.contentPreview,
                "createdAt": new_msg.createdAt.isoformat() if new_msg.createdAt else None,
                "isRead": False
            }), 201

    else:
        # Cas du message AUDIO (envoi de fichier)
        file = request.files.get('file')
        # Get senderId from form or X-User-Id header
        sender_id = request.form.get('senderId') or request.headers.get('X-User-Id')
        iv = request.form.get('iv')
        transcription_text = request.form.get('transcription')

        if not file:
            return jsonify({"error": "Fichier manquant"}), 400

        # Sécurisation du nom de fichier (on utilise un UUID pour éviter les conflits)
        filename = f"{uuid.uuid4()}.enc"
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)

        new_msg = Message(
            conversationId=conv_id,
            senderId=sender_id,
            type='AUDIO',
            encryptedBlobUrl=f"/api/uploads/{filename}",
            iv=iv
        )
        db.session.add(new_msg)
        db.session.flush() # Pour récupérer l'ID du message avant le commit final

        # Si une transcription est fournie par le client
        if transcription_text:
            new_trans = Transcription(
                messageId=new_msg.id,
                text=transcription_text,
                confidence=request.form.get('confidence', 1.0)
            )
            db.session.add(new_trans)

        db.session.commit()
        return jsonify({"id": new_msg.id, "status": "uploaded"}), 201

# --- RÉCUPÉRATION DES MESSAGES ---

@app.route('/api/conversations/<conv_id>/messages', methods=['GET'])
def get_messages(conv_id):
    messages = Message.query.filter_by(conversationId=conv_id).order_by(Message.createdAt.asc()).all()
    result = []
    for m in messages:
        msg_dict = {
            "id": m.id,
            "conversationId": m.conversationId,
            "senderId": m.senderId,
            "type": m.type,
            "encryptedPayload": m.encryptedPayload,
            "encryptedBlobUrl": m.encryptedBlobUrl,
            "iv": m.iv or '',  # Ensure IV is never None, use empty string instead
            "isEncrypted": m.isEncrypted,
            "contentPreview": m.contentPreview,
            "createdAt": m.createdAt.isoformat() if m.createdAt else None,
            "isRead": False,  # TODO: Add read status tracking
        }
        # Add transcription if available
        if m.transcription:
            msg_dict["transcription"] = {
                "text": m.transcription.text,
                "confidence": m.transcription.confidence
            }
        else:
            msg_dict["transcription"] = None
        result.append(msg_dict)
    return jsonify(result)

# --- UPLOAD FILES ---

@app.route('/api/uploads', methods=['POST'])
def upload_file():
    """POST /api/uploads - Upload a file (multipart/form-data)"""
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "Empty filename"}), 400
    
    # Generate a secure filename using UUID
    file_ext = os.path.splitext(file.filename)[1] if '.' in file.filename else ''
    filename = f"{uuid.uuid4()}{file_ext}"
    file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    file.save(file_path)
    
    # Return the URL to access the file
    file_url = f"/api/uploads/{filename}"
    return jsonify({"url": file_url}), 201

# --- ACCÈS AUX FICHIERS AUDIO ---

@app.route('/api/uploads/<filename>')
def downloaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/api/messages/<message_id>/transcription', methods=['GET'])
def get_message_transcription(message_id):
    trans = Transcription.query.filter_by(messageId=message_id).first()
    if not trans:
        return jsonify({"error": "Transcription non trouvée"}), 404
    
    return jsonify({
        "id": trans.id,
        "messageId": trans.messageId,
        "text": trans.text,
        "confidence": trans.confidence,
        "createdAt": trans.createdAt.isoformat()
    }), 200

@app.route('/api/messages/<message_id>', methods=['GET'])
def get_message_details(message_id):
    m = Message.query.get_or_404(message_id)
    return jsonify({
        "id": m.id,
        "conversationId": m.conversationId,
        "senderId": m.senderId,
        "type": m.type,
        "isEncrypted": m.isEncrypted,
        "encryptedBlobUrl": m.encryptedBlobUrl,
        "iv": m.iv or '',  # Ensure IV is never None, use empty string instead
        "contentPreview": m.contentPreview,
        "createdAt": m.createdAt.isoformat() if m.createdAt else None,
        "isRead": False  # TODO: Add read status tracking
    }), 200

@app.route('/api/search', methods=['GET'])
def search_messages():
    """
    GET /api/search?conversationId=<id>&q=<keyword>
    Search for messages by keyword in transcriptions and text content previews
    """
    conversation_id = request.args.get('conversationId')
    query = request.args.get('q', '').strip()
    
    if not query:
        return jsonify({"error": "Query parameter 'q' is required"}), 400
    
    if not conversation_id:
        return jsonify({"error": "Query parameter 'conversationId' is required"}), 400
    
    # Verify conversation exists
    conversation = Conversation.query.get(conversation_id)
    if not conversation:
        return jsonify({"error": "Conversation not found"}), 404
    
    results = []
    
    # Search in transcriptions (for audio messages)
    transcriptions = db.session.query(Transcription).join(Message).filter(
        Message.conversationId == conversation_id,
        Transcription.text.ilike(f'%{query}%')
    ).all()
    
    for trans in transcriptions:
        message = Message.query.get(trans.messageId)
        if message:
            # Extract excerpt around the keyword
            text_lower = trans.text.lower()
            query_lower = query.lower()
            idx = text_lower.find(query_lower)
            if idx != -1:
                start = max(0, idx - 30)
                end = min(len(trans.text), idx + len(query) + 30)
                excerpt = trans.text[start:end]
                if start > 0:
                    excerpt = '...' + excerpt
                if end < len(trans.text):
                    excerpt = excerpt + '...'
            else:
                excerpt = trans.text[:100] + ('...' if len(trans.text) > 100 else '')
            
            results.append({
                "messageId": message.id,
                "excerpt": excerpt,
                "type": message.type,
                "createdAt": message.createdAt.isoformat() if message.createdAt else None
            })
    
    # Search in text message content previews
    text_messages = Message.query.filter(
        Message.conversationId == conversation_id,
        Message.type == 'TEXT',
        Message.contentPreview.ilike(f'%{query}%')
    ).all()
    
    for msg in text_messages:
        # Check if already in results (from transcription search)
        if not any(r['messageId'] == msg.id for r in results):
            preview_lower = msg.contentPreview.lower()
            query_lower = query.lower()
            idx = preview_lower.find(query_lower)
            if idx != -1:
                start = max(0, idx - 30)
                end = min(len(msg.contentPreview), idx + len(query) + 30)
                excerpt = msg.contentPreview[start:end]
                if start > 0:
                    excerpt = '...' + excerpt
                if end < len(msg.contentPreview):
                    excerpt = excerpt + '...'
            else:
                excerpt = msg.contentPreview[:100] + ('...' if len(msg.contentPreview) > 100 else '')
            
            results.append({
                "messageId": msg.id,
                "excerpt": excerpt,
                "type": msg.type,
                "createdAt": msg.createdAt.isoformat() if msg.createdAt else None
            })
    
    # Sort by creation date (newest first)
    results.sort(key=lambda x: x['createdAt'] or '', reverse=True)
    
    return jsonify(results), 200

if __name__ == '__main__':
    app.run(debug=True, port=5000)