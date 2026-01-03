import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
// Conditional imports for web vs mobile
// For web, import dart:html directly (we check kIsWeb before using it)
import 'dart:html' as html if (dart.library.html) 'dart:html';
import 'dart:io' if (dart.library.io) 'dart:io' show File;
import '../models/user.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/encryption_service.dart';

// Import path_provider only when not on web
import 'package:path_provider/path_provider.dart' if (dart.library.html) '../path_provider_stub.dart';

// Import file helper - uses stub on web
import '../file_helper.dart' if (dart.library.html) '../file_helper_stub.dart';

class ChatPage extends StatefulWidget {
  final Conversation conversation;
  final User otherUser;

  const ChatPage({
    super.key,
    required this.conversation,
    required this.otherUser,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isRecordingVoice = false;
  bool _isLoadingMessages = false;
  
  // Get current user ID from ApiConfig (set by FriendsListPage after finding "Moi-même")
  String get currentUserId => ApiConfig.userId ?? 'me';
  
  // API services
  final ApiService _apiService = ApiConfig.createApiService();
  final EncryptionService _encryptionService = EncryptionService();
  
  // Audio recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  
  // Voice playback state
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingMessageId;
  double _playbackPosition = 0.0; // 0.0 to 1.0
  bool _isPlaying = false;
  Duration? _audioDuration;
  String? _currentBlobUrl; // For cleanup on web
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<int> _searchResults = []; // Indices des messages dans _messages
  int _currentSearchIndex = -1;
  bool _isSearchMode = false;
  bool _isSearching = false; // Loading state for search
  Timer? _searchDebounceTimer; // Pour éviter trop de requêtes
  final Map<int, GlobalKey> _messageKeys = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final messages = await _apiService.messages.getMessages(
        widget.conversation.id,
        limit: 50,
        offset: 0,
      );

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _isLoadingMessages = false;
      });
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: $e')),
        );
      }
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    // Stop any playing audio
    _stopPlayback();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
  
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _currentSearchIndex = -1;
        _isSearchMode = false;
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _isSearchMode = true;
    });
    
    try {
      // Appeler l'endpoint /api/search qui cherche dans les transcriptions ET les messages texte
      final searchResults = await _apiService.search.search(
        conversationId: widget.conversation.id,
        query: query.trim(),
      );
      
      // Mapper les résultats de l'API aux indices des messages dans _messages
      final results = <int>[];
      for (final searchResult in searchResults) {
        final messageIndex = _messages.indexWhere(
          (m) => m.id == searchResult.messageId,
        );
        if (messageIndex != -1) {
          results.add(messageIndex);
        }
      }
      
      setState(() {
        _searchResults = results;
        _currentSearchIndex = results.isNotEmpty ? 0 : -1;
        _isSearching = false;
      });
      
      if (results.isNotEmpty) {
        _scrollToSearchResult(0);
      } else {
        // Afficher un message si aucun résultat
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun résultat trouvé'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _currentSearchIndex = -1;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la recherche: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _navigateToNextResult() {
    if (_searchResults.isEmpty) return;
    
    setState(() {
      _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
    });
    
    _scrollToSearchResult(_currentSearchIndex);
  }
  
  void _navigateToPreviousResult() {
    if (_searchResults.isEmpty) return;
    
    setState(() {
      _currentSearchIndex = (_currentSearchIndex - 1 + _searchResults.length) % _searchResults.length;
    });
    
    _scrollToSearchResult(_currentSearchIndex);
  }
  
  void _scrollToSearchResult(int resultIndex) {
    if (resultIndex < 0 || resultIndex >= _searchResults.length) return;
    
    final messageIndex = _searchResults[resultIndex];
    final key = _messageKeys[messageIndex];
    
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.3, // Scroll to show message at 30% from top
      );
    } else {
      // Fallback: scroll to approximate position
      final itemHeight = 100.0; // Approximate height per message
      final targetOffset = messageIndex * itemHeight;
      
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _closeSearch() {
    setState(() {
      _isSearchMode = false;
      _searchResults = [];
      _currentSearchIndex = -1;
      _searchController.clear();
    });
  }

  void _toggleVoicePlayback(String messageId) {
    if (_playingMessageId == messageId && _isPlaying) {
      // Pause current playback
      _pausePlayback();
    } else {
      // Stop any other playing message and start this one
      if (_playingMessageId != null) {
        _stopPlayback();
      }
      _startPlayback(messageId);
    }
  }

  void _startPlayback(String messageId) async {
    // Find the message
    final message = _messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => _messages.first,
    );
    
    if (message.type != MessageType.audio) return;
    
    setState(() {
      _playingMessageId = messageId;
      _isPlaying = true;
      _playbackPosition = 0.0;
    });
    
    try {
      // Get the audio file URL
      String audioUrl = message.encryptedBlobUrl;
      
      if (audioUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio file not found')),
          );
          _stopPlayback();
        }
        return;
      }
      
      // Make URL absolute if it's relative
      if (audioUrl.startsWith('/')) {
        audioUrl = '${ApiConfig.baseUrl}$audioUrl';
      }
      
      // Check if IV is available before attempting to fetch
      String iv = message.iv;
      if (iv.isEmpty || iv.trim().isEmpty) {
        // Check if this is a temporary message (ID is a timestamp)
        final isTempMessage = RegExp(r'^\d+$').hasMatch(messageId);
        
        if (isTempMessage) {
          // This is a temporary message that hasn't been replaced yet
          // Wait a bit and try to find the actual message
          print('IV is missing in temporary message, waiting for server response...');
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Try to find the message in the list (might have been replaced)
          final updatedMessage = _messages.firstWhere(
            (m) => m.id == messageId || 
                   (m.type == MessageType.audio && 
                    m.encryptedBlobUrl == message.encryptedBlobUrl &&
                    m.iv.isNotEmpty),
            orElse: () => message,
          );
          
          if (updatedMessage.iv.isNotEmpty && updatedMessage.id != messageId) {
            // Message was replaced, use the new one
            print('Found updated message with IV: ${updatedMessage.id}');
            iv = updatedMessage.iv;
            // Update the message reference
            setState(() {
              final index = _messages.indexWhere((m) => m.id == messageId);
              if (index != -1) {
                _messages[index] = updatedMessage;
              }
            });
          } else {
            throw Exception('IV is missing for temporary audio message. Please wait a moment and try again.');
          }
        } else {
          // Try to fetch the message details from backend to get the IV
          print('IV is missing in local message, fetching from backend...');
          try {
            final updatedMessage = await _apiService.messages.getMessage(messageId);
            if (updatedMessage.iv.isNotEmpty) {
              iv = updatedMessage.iv;
              // Update local message with IV
              setState(() {
                final index = _messages.indexWhere((m) => m.id == messageId);
                if (index != -1) {
                  _messages[index] = Message(
                    id: message.id,
                    conversationId: message.conversationId,
                    senderId: message.senderId,
                    type: message.type,
                    encryptedBlobUrl: message.encryptedBlobUrl,
                    iv: iv,
                    isEncrypted: message.isEncrypted,
                    contentPreview: message.contentPreview,
                    createdAt: message.createdAt,
                    isRead: message.isRead,
                  );
                }
              });
              print('IV retrieved from backend: $iv');
            } else {
              throw Exception('IV is missing for this audio message. The message may have been created before encryption was implemented.');
            }
          } catch (e) {
            print('Failed to fetch message from backend: $e');
            throw Exception('IV is missing for audio message. Cannot decrypt. Please try refreshing the conversation.');
          }
        }
      }
      
      // Fetch and decrypt the audio file
      print('Fetching encrypted audio from: $audioUrl');
      print('Message IV: $iv');
      final response = await http.get(Uri.parse(audioUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch audio: ${response.statusCode}');
      }
      
      // Decrypt the audio
      final encryptedBytes = response.bodyBytes;
      print('Decrypting audio: ${encryptedBytes.length} bytes, IV: ${message.iv}');
      
      Uint8List decryptedBytes;
      try {
        decryptedBytes = _encryptionService.decryptBinary(
          encryptedBytes,
          iv,
        );
        print('Decrypted audio: ${decryptedBytes.length} bytes');
      } catch (e) {
        print('Decryption failed: $e');
        throw Exception('Failed to decrypt audio: $e');
      }
      
      // Create a blob URL from decrypted audio (for web) or save to temp file (for mobile)
      String playableUrl;
      if (kIsWeb) {
        // Clean up previous blob URL if exists
        if (_currentBlobUrl != null) {
          html.Url.revokeObjectUrl(_currentBlobUrl!);
        }
        // On web, create a blob URL
        // Try different MIME types - the audio format depends on what was recorded
        String mimeType = 'audio/wav'; // Default
        // The record package on web typically records as WAV, but let's try to detect
        if (decryptedBytes.length > 4) {
          // Check for WAV header (RIFF)
          if (decryptedBytes[0] == 0x52 && decryptedBytes[1] == 0x49 && 
              decryptedBytes[2] == 0x46 && decryptedBytes[3] == 0x46) {
            mimeType = 'audio/wav';
          } else if (decryptedBytes[0] == 0xFF && decryptedBytes[1] == 0xFB) {
            mimeType = 'audio/mpeg';
          } else {
            mimeType = 'audio/webm'; // WebM is common for web recordings
          }
        }
        print('Creating blob with MIME type: $mimeType');
        final blob = html.Blob([decryptedBytes], mimeType);
        playableUrl = html.Url.createObjectUrl(blob);
        _currentBlobUrl = playableUrl;
        print('Created blob URL for playback: $playableUrl');
      } else {
        // On mobile/desktop, save to temp file and play from there
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/audio_${messageId}.wav');
        await tempFile.writeAsBytes(decryptedBytes);
        playableUrl = tempFile.path;
      }
      
      // Play the decrypted audio
      print('Playing decrypted audio from: $playableUrl');
      if (kIsWeb) {
        if (!playableUrl.startsWith('blob:')) {
          throw Exception('Invalid blob URL: $playableUrl. Expected blob: URL.');
        }
        await _audioPlayer.play(UrlSource(playableUrl));
      } else {
        await _audioPlayer.play(DeviceFileSource(playableUrl));
      }
      
      // Get audio duration
      final duration = await _audioPlayer.getDuration();
      if (duration != null) {
        setState(() {
          _audioDuration = duration;
        });
      }
      
      // Listen to position changes
      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted && _playingMessageId == messageId) {
          final duration = _audioDuration ?? const Duration(seconds: 1);
          setState(() {
            _playbackPosition = position.inMilliseconds / duration.inMilliseconds;
            if (_playbackPosition > 1.0) _playbackPosition = 1.0;
          });
        }
      });
      
      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted && _playingMessageId == messageId) {
          _stopPlayback();
        }
      });
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
        _stopPlayback();
      }
    }
  }

  void _pausePlayback() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  void _stopPlayback() async {
    await _audioPlayer.stop();
    // Clean up blob URL on web
    if (kIsWeb && _currentBlobUrl != null) {
      html.Url.revokeObjectUrl(_currentBlobUrl!);
      _currentBlobUrl = null;
    }
    setState(() {
      _playingMessageId = null;
      _isPlaying = false;
      _playbackPosition = 0.0;
      _audioDuration = null;
    });
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final plaintext = _messageController.text.trim();
    _messageController.clear();

    // Encrypt the message
    final encryptionResult = _encryptionService.encryptText(plaintext);
    final encryptedPayload = encryptionResult['encryptedPayload']!;
    final iv = encryptionResult['iv']!;

    // Optimistically add message to UI
    final tempMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: widget.conversation.id,
      senderId: currentUserId,
      type: MessageType.text,
      encryptedBlobUrl: '',
      iv: iv,
      isEncrypted: true,
      contentPreview: plaintext,
      createdAt: DateTime.now(),
      isRead: false,
    );

    setState(() {
      _messages.add(tempMessage);
    });

    try {
      // Send encrypted message to backend
      final message = await _apiService.messages.sendTextMessage(
        conversationId: widget.conversation.id,
        encryptedPayload: encryptedPayload,
        iv: iv,
        plaintextPreview: plaintext,
        meta: {'length': plaintext.length},
      );

      // Replace temp message with actual message from server
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = message;
        }
      });
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
        
        // Remove failed message from UI
        setState(() {
          _messages.removeWhere((m) => m.id == tempMessage.id);
        });
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      // Handle web platform separately - no file system needed
      if (kIsWeb) {
        // Check and request permission
        bool hasPermission = await _audioRecorder.hasPermission();
        
        // On web, try to start recording even if hasPermission returns false
        // The browser will prompt for permission automatically
        if (hasPermission) {
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.wav,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: '', // Empty path on web
          );
        } else {
          // Try to start anyway - browser will prompt
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.wav,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: '', // Empty path on web
          );
        }
        
        setState(() {
          _isRecordingVoice = true;
          _recordingDuration = Duration.zero;
        });
        
        // Update recording duration
        _updateRecordingDuration();
        return;
      }
      
      // Non-web platform: use file system
      // Check and request permission
      bool hasPermission = await _audioRecorder.hasPermission();
      
      if (hasPermission) {
        // Get directory for saving audio (mobile/desktop)
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recordingPath = '${directory.path}/$fileName';
        
        // Start recording
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordingPath!,
        );
        
        setState(() {
          _isRecordingVoice = true;
          _recordingDuration = Duration.zero;
        });
        
        // Update recording duration
        _updateRecordingDuration();
      } else {
        // Show error if permission denied
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required. Please grant permission in your device settings.')),
          );
        }
      }
    } catch (e) {
      print('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
      // Reset recording state on error
      setState(() {
        _isRecordingVoice = false;
      });
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecordingVoice) return;
    
    try {
      // Stop the recording
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecordingVoice = false;
      });
      
      // Handle the recording path
      if (path != null && path.isNotEmpty) {
        _recordingPath = path;
        _sendVoiceMessage();
      } else if (kIsWeb) {
        // On web, path might be empty, but we still have the recording
        _recordingPath = path ?? '';
        if (_recordingPath!.isNotEmpty) {
          _sendVoiceMessage();
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
      setState(() {
        _isRecordingVoice = false;
      });
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecordingVoice) return;
    
    try {
      await _audioRecorder.stop();
      
      // Delete the recording file (only on non-web platforms)
      if (!kIsWeb && _recordingPath != null) {
        await deleteFileIfExists(_recordingPath!);
      }
      
      setState(() {
        _isRecordingVoice = false;
        _recordingPath = null;
        _recordingDuration = Duration.zero;
      });
    } catch (e) {
      print('Error canceling recording: $e');
      setState(() {
        _isRecordingVoice = false;
        _recordingPath = null;
        _recordingDuration = Duration.zero;
      });
    }
  }

  void _updateRecordingDuration() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecordingVoice && mounted) {
        setState(() {
          _recordingDuration = _recordingDuration + const Duration(seconds: 1);
        });
        _updateRecordingDuration();
      }
    });
  }

  Future<void> _sendVoiceMessage() async {
    if (_recordingPath == null || _recordingPath!.isEmpty) return;

    final recordingPath = _recordingPath!;
    _recordingPath = null;
    _recordingDuration = Duration.zero;

    // Optimistically add message to UI
    final tempMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: widget.conversation.id,
      senderId: currentUserId,
      type: MessageType.audio,
      encryptedBlobUrl: recordingPath,
      iv: '',
      isEncrypted: true,
      contentPreview: 'Voice message',
      createdAt: DateTime.now(),
      isRead: false,
    );

    setState(() {
      _messages.add(tempMessage);
    });

    try {
      // PHASE 1: Read audio file
      print('[DEBUG] Starting voice message send process...');
      print('[DEBUG] Recording path: $recordingPath');
      
      // The readFileAsBytes helper now handles web blob URLs properly
      print('[DEBUG] Reading audio file...');
      final audioBytes = await readFileAsBytes(recordingPath);
      print('[DEBUG] Audio file read: ${audioBytes.length} bytes');

      // PHASE 2: Transcribe audio using STT_API (before encryption)
      String? transcriptionText;
      double? transcriptionConfidence;
      
      print('[DEBUG] Starting STT transcription...');
      try {
        print('[DEBUG] Calling STT_API for transcription...');
        print('[DEBUG] STT_API URL: http://127.0.0.1:5001/transcribe');
        print('[DEBUG] Audio bytes to send: ${audioBytes.length}');
        
        final sttResult = await _apiService.stt.transcribeAudio(
          audioBytes: audioBytes,
          fileName: 'voice.wav',
        );
        
        print('[DEBUG] STT_API response received');
        transcriptionText = sttResult['text'] as String?;
        transcriptionConfidence = sttResult['confidence'] as double?;
        
        print('[DEBUG] STT transcription: $transcriptionText (confidence: $transcriptionConfidence)');
        
        // Update temp message preview with transcription
        if (transcriptionText != null && transcriptionText.isNotEmpty) {
          print('[DEBUG] Updating message preview with transcription');
          setState(() {
            final index = _messages.indexWhere((m) => m.id == tempMessage.id);
            if (index != -1) {
              _messages[index] = Message(
                id: tempMessage.id,
                conversationId: tempMessage.conversationId,
                senderId: tempMessage.senderId,
                type: tempMessage.type,
                encryptedBlobUrl: tempMessage.encryptedBlobUrl,
                iv: tempMessage.iv,
                isEncrypted: tempMessage.isEncrypted,
                contentPreview: transcriptionText,
                createdAt: tempMessage.createdAt,
                isRead: tempMessage.isRead,
              );
            }
          });
        } else {
          print('[DEBUG] Warning: Transcription text is empty or null');
        }
      } catch (sttError) {
        print('[DEBUG] STT_API error (continuing without transcription): $sttError');
        print('[DEBUG] Error type: ${sttError.runtimeType}');
        print('[DEBUG] Error details: $sttError');
        // Continue without transcription if STT fails
      }
      
      print('[DEBUG] Transcription phase completed. Text: $transcriptionText, Confidence: $transcriptionConfidence');

      // PHASE 3: Encrypt audio bytes
      final encryptionResult = _encryptionService.encryptBinary(audioBytes);
      final encryptedBytes = encryptionResult['encryptedData'] as Uint8List;
      final iv = encryptionResult['iv'] as String;

      // Update temp message with IV so it can be played before server response
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = Message(
            id: tempMessage.id,
            conversationId: tempMessage.conversationId,
            senderId: tempMessage.senderId,
            type: tempMessage.type,
            encryptedBlobUrl: tempMessage.encryptedBlobUrl,
            iv: iv, // Update with actual IV
            isEncrypted: tempMessage.isEncrypted,
            contentPreview: tempMessage.contentPreview,
            createdAt: tempMessage.createdAt,
            isRead: tempMessage.isRead,
          );
        }
      });

      // PHASE 4: Upload encrypted blob
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.enc';
      final blobUrl = await _apiService.uploads.uploadAudioBlob(
        encryptedAudioBytes: encryptedBytes,
        fileName: fileName,
      );
      
      // Update temp message with the uploaded blob URL
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = Message(
            id: tempMessage.id,
            conversationId: tempMessage.conversationId,
            senderId: tempMessage.senderId,
            type: tempMessage.type,
            encryptedBlobUrl: blobUrl, // Update with actual blob URL
            iv: iv,
            isEncrypted: tempMessage.isEncrypted,
            contentPreview: tempMessage.contentPreview,
            createdAt: tempMessage.createdAt,
            isRead: tempMessage.isRead,
          );
        }
      });

      // PHASE 5: Send message with encrypted blob URL and transcription
      print('[DEBUG] Sending message to backend...');
      print('[DEBUG] Transcription to send - Text: $transcriptionText, Confidence: $transcriptionConfidence');
      
      final message = await _apiService.messages.sendAudioMessage(
        conversationId: widget.conversation.id,
        encryptedPayloadUrl: blobUrl,
        iv: iv,
        transcriptionText: transcriptionText,
        transcriptionConfidence: transcriptionConfidence,
      );
      
      print('[DEBUG] Message sent successfully. Message ID: ${message.id}');

      // Replace temp message with actual message from server
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = message;
        }
      });

      // Clean up local file after successful upload
      if (!kIsWeb) {
        try {
          await deleteFileIfExists(recordingPath);
        } catch (e) {
          print('Error deleting temp file: $e');
        }
      }
    } catch (e) {
      print('Error sending voice message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice message: $e')),
        );
        
        // Remove failed message from UI
        setState(() {
          _messages.removeWhere((m) => m.id == tempMessage.id);
        });
      }
    }
  }

  String _formatRecordingDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getAvatarInitial(String name) {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1976D2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getAvatarInitial(widget.otherUser.displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.otherUser.name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_isSearchMode) ...[
            // Search navigation buttons
            if (_searchResults.isNotEmpty) ...[
              Text(
                '${_currentSearchIndex + 1}/${_searchResults.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_upward, color: Colors.white),
                onPressed: _navigateToPreviousResult,
                tooltip: 'Précédent',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, color: Colors.white),
                onPressed: _navigateToNextResult,
                tooltip: 'Suivant',
              ),
            ],
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _closeSearch,
              tooltip: 'Fermer la recherche',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearchMode = true;
                });
              },
              tooltip: 'Rechercher',
            ),
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.white),
              onPressed: () {
                // TODO: Add call functionality
              },
            ),
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white),
              onPressed: () {
                // TODO: Add video call functionality
              },
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // Blue background shape
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Search bar
          if (_isSearchMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans les messages texte et vocaux...',
                    prefixIcon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                              ),
                            ),
                          )
                        : const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchDebounceTimer?.cancel();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    // Debounce: annuler le timer précédent et en créer un nouveau
                    _searchDebounceTimer?.cancel();
                    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
                      _performSearch(value);
                    });
                  },
                  onSubmitted: (_) {
                    _searchDebounceTimer?.cancel();
                    _performSearch(_searchController.text);
                    if (_searchResults.isNotEmpty) {
                      _scrollToSearchResult(0);
                    }
                  },
                ),
              ),
            ),
          // Messages list
          Column(
            children: [
              if (_isSearchMode) const SizedBox(height: 60), // Space for search bar
              Expanded(
                child: _isLoadingMessages
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                    // Create a key for each message if it doesn't exist
                    if (!_messageKeys.containsKey(index)) {
                      _messageKeys[index] = GlobalKey();
                    }
                    
                    final message = _messages[index];
                    final isSent = message.senderId == currentUserId;
                    final isHighlighted = _isSearchMode && 
                                         _searchResults.contains(index) && 
                                         _currentSearchIndex >= 0 &&
                                         _searchResults[_currentSearchIndex] == index;
                    
                    return Container(
                      key: _messageKeys[index],
                      child: _MessageBubble(
                        message: message,
                        isSent: isSent,
                        isPlaying: _playingMessageId == message.id && _isPlaying,
                        playbackPosition: _playingMessageId == message.id ? _playbackPosition : 0.0,
                        onPlayPause: () => _toggleVoicePlayback(message.id),
                        audioDuration: _audioDuration,
                        isHighlighted: isHighlighted,
                        searchQuery: _isSearchMode && _searchController.text.isNotEmpty
                            ? _searchController.text
                            : null,
                      ),
                    );
                  },
                        ),
                      ),
              ),
              // Input area
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _isRecordingVoice
                    ? _buildRecordingBar()
                    : _buildInputBar(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Recording bar shown while recording
  Widget _buildRecordingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          // Animated recording indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Recording duration
          Text(
            _formatRecordingDuration(_recordingDuration),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const Spacer(),
          // Cancel button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _cancelRecording,
            tooltip: 'Cancel',
          ),
          const SizedBox(width: 8),
          // Send/Stop button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _stopRecordingAndSend,
              tooltip: 'Send',
            ),
          ),
        ],
      ),
    );
  }

  // Normal input bar
  Widget _buildInputBar() {
    return Row(
      children: [
        // Voice message button
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.mic,
              color: Color(0xFF1976D2),
            ),
            onPressed: _startRecording,
          ),
        ),
        const SizedBox(width: 8),
        // Text input
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
              onSubmitted: (_) => _sendTextMessage(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Send button
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _sendTextMessage,
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSent;
  final bool isPlaying;
  final double playbackPosition;
  final VoidCallback? onPlayPause;
  final Duration? audioDuration;
  final bool isHighlighted;
  final String? searchQuery;

  const _MessageBubble({
    required this.message,
    required this.isSent,
    this.isPlaying = false,
    this.playbackPosition = 0.0,
    this.onPlayPause,
    this.audioDuration,
    this.isHighlighted = false,
    this.searchQuery,
  });
  
  // Helper method to highlight search text
  List<TextSpan> _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }
    
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    
    while (true) {
      final index = textLower.indexOf(queryLower, start);
      if (index == -1) {
        // Add remaining text
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: const TextStyle(),
          ));
        }
        break;
      }
      
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: const TextStyle(),
        ));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
    }
    
    return spans;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatAudioDuration(double position) {
    if (audioDuration == null) {
      return '0:00';
    }
    final totalSeconds = audioDuration!.inSeconds;
    final currentSeconds = (position * totalSeconds).toInt();
    final minutes = currentSeconds ~/ 60;
    final seconds = currentSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSent
                    ? const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSent ? null : Colors.grey.shade200,
                border: isHighlighted
                    ? Border.all(color: Colors.yellow, width: 3)
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSent ? 16 : 4),
                  bottomRight: Radius.circular(isSent ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.audio)
                    InkWell(
                      onTap: onPlayPause,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Voice message icon indicator
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSent
                                    ? Colors.white.withOpacity(0.25)
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.mic,
                                color: isSent ? Colors.white : const Color(0xFF1976D2),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Play/Pause button
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSent
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSent
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.grey[400]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: isSent ? Colors.white : const Color(0xFF1976D2),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Progress bar
                            Container(
                              width: 120,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSent
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.grey[400],
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Stack(
                                children: [
                                  // Progress indicator
                                  FractionallySizedBox(
                                    widthFactor: playbackPosition,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSent
                                            ? Colors.white
                                            : const Color(0xFF1976D2),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Duration
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSent
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatAudioDuration(playbackPosition),
                                style: TextStyle(
                                  color: isSent ? Colors.white : Colors.grey[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final text = message.contentPreview ?? message.encryptedBlobUrl;
                        final query = searchQuery ?? '';
                        
                        if (query.isNotEmpty && text.toLowerCase().contains(query.toLowerCase())) {
                          return RichText(
                            text: TextSpan(
                              children: _buildHighlightedText(text, query),
                              style: TextStyle(
                                color: isSent ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          );
                        } else {
                          return Text(
                            text,
                            style: TextStyle(
                              color: isSent ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          );
                        }
                      },
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: isSent ? Colors.white70 : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      if (isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          color: message.isRead
                              ? Colors.blue.shade300
                              : Colors.white70,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSent) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}