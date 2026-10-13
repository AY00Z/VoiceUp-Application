# VoiceUP

VoiceUP is a mobile chat application built with **Flutter**. Send text and voice messages, and get automatic **transcriptions** of your audio.

## Features

- Text and voice messages
- Speech-to-text transcription of voice messages
- Keyword search in transcriptions and text messages
- AES-256 encryption of message content and audio files

## Architecture

| Part | Tech | Port |
|------|------|------|
| Mobile app | Flutter | - |
| Backend API | Flask + PostgreSQL | 5000 |
| STT API | Python (speech-to-text) | 5001 |

## How It Works

**Voice message flow:**

1. Record audio (`.wav`)
2. Transcribe with the STT API (before encryption)
3. Encrypt audio with AES-256
4. Upload the encrypted file (`.enc`)
5. Send the message with its transcription

**Text messages** are encrypted on the client and stored encrypted in the database.

## Getting Started

```bash
# 1. STT API
cd STT_API/VoiceUP/api/VoiceUP/STT_API
pip install -r requirements.txt
python app.py

# 2. Backend
cd backend/VoiceUP/VoiceUP_Backend
python app.py

# 3. Flutter app
cd frontend
flutter run
```

## Main API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/conversations/:id/messages` | Send a message |
| GET | `/api/conversations/:id/messages` | Get messages |
| POST | `/api/uploads` | Upload an encrypted audio file |
| GET | `/api/search?conversationId=<id>&q=<keyword>` | Search messages |
| POST | `http://127.0.0.1:5001/transcribe` | Transcribe audio (STT API) |

## Notes

- If the STT API is down, voice messages are still sent, just without a transcription.
- This is a prototype: the encryption key is shared between users, and `contentPreview` and metadata are stored in plain text. A proper key exchange is needed for production.
