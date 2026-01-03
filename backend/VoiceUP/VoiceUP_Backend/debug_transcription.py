"""Debug script to check why transcriptions are not being saved"""
from app import app
from models import db, Message, Transcription
import json

def debug_transcription_issue():
    with app.app_context():
        print("\n" + "="*70)
        print("DEBUG: Transcription Issue Analysis")
        print("="*70)
        
        # Check recent audio messages
        audio_messages = Message.query.filter_by(type='AUDIO').order_by(Message.createdAt.desc()).limit(5).all()
        
        print(f"\n📨 Recent Audio Messages (last 5):")
        print("-" * 70)
        
        for msg in audio_messages:
            print(f"\nMessage ID: {msg.id}")
            print(f"  Created: {msg.createdAt}")
            print(f"  Has transcription: {msg.transcription is not None}")
            
            if msg.transcription:
                print(f"  Transcription text: {msg.transcription.text[:50]}...")
                print(f"  Confidence: {msg.transcription.confidence}")
            else:
                print(f"  ⚠️  NO TRANSCRIPTION")
                print(f"  This message was likely sent before STT_API integration")
                print(f"  or STT_API failed silently")
        
        # Check if there are any transcriptions at all
        total_transcriptions = Transcription.query.count()
        print(f"\n📊 Total transcriptions in DB: {total_transcriptions}")
        
        if total_transcriptions == 0:
            print("\n🔍 DIAGNOSIS:")
            print("  - No transcriptions found in database")
            print("  - Possible causes:")
            print("    1. STT_API is not running or not accessible")
            print("    2. STT_API is failing silently (check frontend logs)")
            print("    3. Messages were sent before STT_API integration")
            print("    4. Transcription data is not being sent from frontend")
            print("\n💡 SOLUTION:")
            print("  1. Make sure STT_API is running on port 5001:")
            print("     cd STT_API/VoiceUP/api/VoiceUP/STT_API")
            print("     python app.py")
            print("  2. Send a NEW voice message and check:")
            print("     - Frontend console for STT_API errors")
            print("     - Backend console for transcription logs")
            print("  3. Check if transcription is being sent:")
            print("     - Look for '[DEBUG] Transcription data received' in backend logs")
        
        print("\n" + "="*70)

if __name__ == '__main__':
    debug_transcription_issue()

