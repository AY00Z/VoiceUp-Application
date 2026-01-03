"""Script to check database contents - Focus on Messages and Transcriptions"""
from app import app
from models import db, User, Conversation, Message, Transcription
import json

def check_database():
    with app.app_context():
        print("=" * 70)
        print("DATABASE CHECK - MESSAGES & TRANSCRIPTIONS")
        print("=" * 70)
        
        # Check total counts
        total_messages = Message.query.count()
        total_transcriptions = Transcription.query.count()
        total_conversations = Conversation.query.count()
        total_users = User.query.count()
        
        print(f"\n📊 SUMMARY:")
        print(f"  Users: {total_users}")
        print(f"  Conversations: {total_conversations}")
        print(f"  Messages: {total_messages}")
        print(f"  Transcriptions: {total_transcriptions}")
        print("-" * 70)
        
        # Check Messages in detail WITH transcriptions
        print(f"\n📨 MESSAGES WITH TRANSCRIPTIONS ({total_messages} total):")
        print("-" * 70)
        
        messages = Message.query.order_by(Message.createdAt.desc()).all()
        
        if messages:
            for i, msg in enumerate(messages, 1):
                print(f"\n[{i}] Message ID: {msg.id[:8]}...")
                print(f"   Conversation: {msg.conversationId[:8]}...")
                
                # Get sender name
                sender = User.query.get(msg.senderId)
                sender_name = sender.name if sender else f"Unknown ({msg.senderId[:8]}...)"
                print(f"   Sender: {sender_name}")
                
                print(f"   Type: {msg.type}")
                print(f"   Encrypted: {msg.isEncrypted}")
                
                # Show content preview (for TEXT messages)
                if msg.type == 'TEXT' and msg.contentPreview:
                    preview = msg.contentPreview[:60] + "..." if len(msg.contentPreview) > 60 else msg.contentPreview
                    print(f"   Preview: {preview}")
                
                # Show audio info
                if msg.type == 'AUDIO':
                    if msg.encryptedBlobUrl:
                        print(f"   Audio URL: {msg.encryptedBlobUrl[:50]}...")
                    if msg.iv:
                        print(f"   IV: {msg.iv[:30]}...")
                
                # Show transcription if available
                if msg.transcription:
                    trans = msg.transcription
                    text_preview = trans.text[:80] + "..." if len(trans.text) > 80 else trans.text
                    print(f"   🗣️  TRANSCRIPTION:")
                    print(f"      Text: {text_preview}")
                    print(f"      Confidence: {trans.confidence:.2%}" if trans.confidence else "      Confidence: N/A")
                elif msg.type == 'AUDIO':
                    print(f"   ⚠️  No transcription available")
                
                print(f"   Created: {msg.createdAt}")
        else:
            print("  No messages found in database")
        
        # Check Transcriptions in detail
        print(f"\n🗣️  TRANSCRIPTIONS DETAIL ({total_transcriptions} total):")
        print("-" * 70)
        
        transcriptions = Transcription.query.all()
        
        if transcriptions:
            for i, trans in enumerate(transcriptions, 1):
                print(f"\n[{i}] Transcription ID: {trans.id}")
                print(f"   Message ID: {trans.messageId}")
                
                # Get associated message
                message = Message.query.get(trans.messageId)
                if message:
                    print(f"   Message Type: {message.type}")
                    sender = User.query.get(message.senderId)
                    if sender:
                        print(f"   From: {sender.name}")
                
                # Show transcription text (truncated if long)
                text_preview = trans.text[:80] + "..." if len(trans.text) > 80 else trans.text
                print(f"   Text: {text_preview}")
                
                print(f"   Confidence: {trans.confidence}")
                print(f"   Created: {trans.createdAt}")
        else:
            print("  No transcriptions found in database")
        
        # Check messages WITHOUT transcriptions
        print(f"\n⚠️  MESSAGES WITHOUT TRANSCRIPTIONS:")
        print("-" * 70)
        
        messages_without_trans = []
        for msg in messages:
            if msg.type == 'AUDIO' and not msg.transcription:
                messages_without_trans.append(msg)
        
        if messages_without_trans:
            for i, msg in enumerate(messages_without_trans, 1):
                sender = User.query.get(msg.senderId)
                sender_name = sender.name if sender else "Unknown"
                print(f"[{i}] Message {msg.id} from {sender_name} - Created: {msg.createdAt}")
        else:
            print("  All audio messages have transcriptions!")
        
        # Check orphaned transcriptions (transcriptions without messages)
        print(f"\n🔍 ORPHANED TRANSCRIPTIONS (no linked message):")
        print("-" * 70)
        
        orphaned = []
        for trans in transcriptions:
            message = Message.query.get(trans.messageId)
            if not message:
                orphaned.append(trans)
        
        if orphaned:
            for i, trans in enumerate(orphaned, 1):
                print(f"[{i}] Transcription {trans.id} references non-existent message {trans.messageId}")
        else:
            print("  No orphaned transcriptions found")
        
        # Statistics
        print(f"\n📈 STATISTICS:")
        print("-" * 70)
        
        if messages:
            text_count = sum(1 for msg in messages if msg.type == 'TEXT')
            audio_count = sum(1 for msg in messages if msg.type == 'AUDIO')
            encrypted_count = sum(1 for msg in messages if msg.isEncrypted)
            
            print(f"  Text Messages: {text_count}")
            print(f"  Audio Messages: {audio_count}")
            print(f"  Encrypted Messages: {encrypted_count} ({encrypted_count/total_messages*100:.1f}%)")
        
        if transcriptions:
            # Calculate average confidence
            avg_confidence = sum(t.confidence for t in transcriptions if t.confidence) / len(transcriptions)
            print(f"  Average Transcription Confidence: {avg_confidence:.2%}")
            
            # Count transcriptions with high confidence (>90%)
            high_conf = sum(1 for t in transcriptions if t.confidence and t.confidence > 0.9)
            print(f"  High Confidence Transcripts (>90%): {high_conf}")
        
        # Check for each conversation
        print(f"\n💬 PER CONVERSATION ANALYSIS:")
        print("-" * 70)
        
        conversations = Conversation.query.all()
        for conv in conversations:
            conv_messages = Message.query.filter_by(conversationId=conv.id).all()
            conv_transcriptions = [m for m in conv_messages if m.transcription]
            
            if conv_messages:
                participants = [u.name for u in conv.users]
                print(f"\nConversation: {conv.title}")
                print(f"  Participants: {', '.join(participants)}")
                print(f"  Total Messages: {len(conv_messages)}")
                print(f"  Audio Messages: {sum(1 for m in conv_messages if m.type == 'AUDIO')}")
                print(f"  With Transcription: {len(conv_transcriptions)}")
        
        print("\n" + "=" * 70)
        print("DATABASE CHECK COMPLETED")
        print("=" * 70)

def check_specific_transcription(transcription_id):
    """Check a specific transcription by ID"""
    with app.app_context():
        trans = Transcription.query.get(transcription_id)
        
        if not trans:
            print(f"❌ Transcription with ID {transcription_id} not found")
            return
        
        print(f"\n🔍 DETAILS FOR TRANSCRIPTION {transcription_id}:")
        print("-" * 60)
        print(f"ID: {trans.id}")
        print(f"Message ID: {trans.messageId}")
        print(f"Text: {trans.text}")
        print(f"Confidence: {trans.confidence}")
        print(f"Created: {trans.createdAt}")
        
        # Get associated message
        message = Message.query.get(trans.messageId)
        if message:
            print(f"\n📨 Associated Message:")
            print(f"  Type: {message.type}")
            print(f"  Sender ID: {message.senderId}")
            print(f"  Created: {message.createdAt}")
            
            # Get sender name
            sender = User.query.get(message.senderId)
            if sender:
                print(f"  Sender Name: {sender.name}")
        else:
            print(f"\n⚠️  Warning: Message {trans.messageId} not found (orphaned transcription)")

def export_transcriptions_to_file(filename="transcriptions_export.json"):
    """Export all transcriptions to a JSON file"""
    with app.app_context():
        transcriptions = Transcription.query.all()
        
        data = []
        for trans in transcriptions:
            message = Message.query.get(trans.messageId)
            sender_name = None
            if message:
                sender = User.query.get(message.senderId)
                sender_name = sender.name if sender else None
            
            data.append({
                "transcription_id": str(trans.id),
                "message_id": str(trans.messageId),
                "text": trans.text,
                "confidence": trans.confidence,
                "created_at": trans.createdAt.isoformat() if trans.createdAt else None,
                "sender": sender_name,
                "message_type": message.type if message else None
            })
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ Exported {len(data)} transcriptions to {filename}")

if __name__ == '__main__':
    print("Choose an option:")
    print("1. Full database check")
    print("2. Check specific transcription")
    print("3. Export transcriptions to JSON")
    
    choice = input("\nEnter choice (1-3): ").strip()
    
    if choice == '1':
        check_database()
    elif choice == '2':
        trans_id = input("Enter transcription ID: ").strip()
        check_specific_transcription(trans_id)
    elif choice == '3':
        filename = input("Enter filename (default: transcriptions_export.json): ").strip()
        if not filename:
            filename = "transcriptions_export.json"
        export_transcriptions_to_file(filename)
    else:
        print("Invalid choice. Running full database check...")
        check_database()