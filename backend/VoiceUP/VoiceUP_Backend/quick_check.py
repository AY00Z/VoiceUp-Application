"""Quick script to check messages and transcriptions - Simple version"""
from app import app
from models import db, Message, Transcription, User

def quick_check():
    with app.app_context():
        print("\n" + "="*60)
        print("QUICK CHECK - Messages & Transcriptions")
        print("="*60)
        
        # Counts
        total_messages = Message.query.count()
        audio_messages = Message.query.filter_by(type='AUDIO').count()
        total_transcriptions = Transcription.query.count()
        
        print(f"\n📊 Totals:")
        print(f"   Messages: {total_messages}")
        print(f"   Audio Messages: {audio_messages}")
        print(f"   Transcriptions: {total_transcriptions}")
        
        # Recent messages with transcriptions
        print(f"\n📨 Recent Messages with Transcriptions:")
        print("-" * 60)
        
        messages = Message.query.filter_by(type='AUDIO').order_by(Message.createdAt.desc()).limit(10).all()
        
        if not messages:
            print("   No audio messages found")
        else:
            for msg in messages:
                sender = User.query.get(msg.senderId)
                sender_name = sender.name if sender else "Unknown"
                
                if msg.transcription:
                    trans = msg.transcription
                    text_preview = trans.text[:50] + "..." if len(trans.text) > 50 else trans.text
                    conf = f"{trans.confidence:.1%}" if trans.confidence else "N/A"
                    print(f"\n   [{sender_name}] {text_preview}")
                    print(f"      Confidence: {conf} | Created: {msg.createdAt.strftime('%Y-%m-%d %H:%M')}")
                else:
                    print(f"\n   [{sender_name}] Audio message (no transcription)")
                    print(f"      Created: {msg.createdAt.strftime('%Y-%m-%d %H:%M')}")
        
        print("\n" + "="*60)

if __name__ == '__main__':
    quick_check()

