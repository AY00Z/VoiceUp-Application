import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'chat_page.dart';
import '../main.dart' show LoginPage;
import '../config/api_config.dart';
import '../services/api_service.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  // Current user ID - will be set from contacts (find "Moi-même")
  String? currentUserId;

  final ApiService _apiService = ApiConfig.createApiService();
  List<Conversation> _conversations = [];
  Map<String, User> _usersMap = {};
  Map<String, Message?> _lastMessages = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to check backend health, but don't block if it fails
      // (health endpoint might not exist, but other endpoints might work)
      bool backendAvailable = false;
      try {
        backendAvailable = await _apiService.checkHealth();
      } catch (e) {
        print('Backend health check failed (this is OK if /api/health doesn\'t exist): $e');
        // Don't block - continue and try to load data anyway
        backendAvailable = true; // Assume available, will fail later if not
      }

      List<User> contacts = [];
      List<Conversation> conversations = [];
      String? errorMsg;

    // Load contacts - try first
    try {
      contacts = await _apiService.contacts.getContacts();
    } catch (e) {
      print('Error loading contacts: $e');
      final errorStr = e.toString();
      if (errorStr.contains('Failed to fetch') || errorStr.contains('ClientException')) {
        errorMsg = 'Network error: Cannot reach backend. Check if server is running and CORS is enabled.';
      } else {
        errorMsg = 'Failed to load contacts: $e';
      }
    }

    // Load conversations - try separately so contacts can still load
    try {
      conversations = await _apiService.conversations.getConversations();
    } catch (e) {
      print('Error loading conversations: $e');
      final errorStr = e.toString();
      String convError;
      if (errorStr.contains('Failed to fetch') || errorStr.contains('ClientException')) {
        convError = 'Network error: Cannot reach backend. Check if server is running and CORS is enabled.';
      } else if (errorStr.contains('404') || errorStr.contains('404')) {
        convError = '⚠️ Backend endpoint /api/conversations not found.\n\n'
            'Your backend needs to implement:\n'
            'GET /api/conversations\n\n'
            'Expected response format:\n'
            '[\n'
            '  {\n'
            '    "id": "conv-1",\n'
            '    "title": "Contact Name",\n'
            '    "participantIds": ["me", "user-1"],\n'
            '    "createdAt": "2026-01-02T..."\n'
            '  }\n'
            ']\n\n'
            'Also ensure CORS is enabled for OPTIONS requests.';
      } else {
        convError = 'Failed to load conversations: $e';
      }
      
      if (errorMsg != null) {
        errorMsg = '$errorMsg\n\n$convError';
      } else {
        errorMsg = convError;
      }
    }

    // Build users map for quick lookup
    final usersMap = <String, User>{};
    for (var contact in contacts) {
      usersMap[contact.id] = contact;
    }

    // Find "Moi-même" from contacts to get the actual current user ID
    String? actualCurrentUserId;
    for (var contact in contacts) {
      if (contact.name == 'Moi-même' || contact.displayName == 'Moi-même') {
        actualCurrentUserId = contact.id;
        // Update ApiConfig so other pages can use it
        ApiConfig.userId = actualCurrentUserId;
        _apiService.updateUserId(actualCurrentUserId);
        break;
      }
    }
    // Fallback to 'me' if not found (for backward compatibility)
    if (actualCurrentUserId == null) {
      actualCurrentUserId = 'me';
    }

      // Load last messages for each conversation (non-blocking, can be slow)
      final lastMessages = <String, Message?>{};
      // Initialize all to null first so UI can render immediately
      for (var conversation in conversations) {
        lastMessages[conversation.id] = null;
      }
      
      // Update UI first with conversations (without last messages)
      print('Loading data: ${contacts.length} contacts, ${conversations.length} conversations, currentUserId: $actualCurrentUserId');
      setState(() {
        _conversations = conversations;
        _usersMap = usersMap;
        _lastMessages = lastMessages;
        currentUserId = actualCurrentUserId;
        _isLoading = false;
        // Only show error if both failed, or if we have no data at all
        if (errorMsg != null && contacts.isEmpty && conversations.isEmpty) {
          _errorMessage = errorMsg;
        } else if (errorMsg != null && (contacts.isEmpty || conversations.isEmpty)) {
          // Show warning but still display what we have
          _errorMessage = 'Warning: $errorMsg';
        }
      });
      
      // Then load last messages in background and update UI
      for (var conversation in conversations) {
        try {
          final messages = await _apiService.messages.getMessages(
            conversation.id,
            limit: 1,
            offset: 0,
          );
          if (mounted) {
            setState(() {
              _lastMessages[conversation.id] = messages.isNotEmpty ? messages.first : null;
            });
          }
        } catch (e) {
          print('Error loading last message for conversation ${conversation.id}: $e');
          // Don't update state on error, just leave it as null
        }
      }
    } catch (e) {
      // Catch any unexpected errors
      print('Unexpected error in _loadData: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unexpected error: $e';
      });
    }
  }

  User? _getOtherParticipant(Conversation conversation) {
    if (currentUserId == null) {
      print('Warning: currentUserId is null, cannot find other participant');
      // Try to return the first participant that's not in the usersMap as "me"
      // This is a fallback if currentUserId isn't set yet
      for (var id in conversation.participantIds) {
        if (_usersMap.containsKey(id)) {
          return _usersMap[id];
        }
      }
      return null;
    }
    
    final otherId = conversation.participantIds
        .firstWhere((id) => id != currentUserId, orElse: () => '');
    
    if (otherId.isEmpty) {
      print('Warning: No other participant found in conversation ${conversation.id}');
      return null;
    }
    
    final user = _usersMap[otherId];
    if (user == null) {
      print('Warning: User $otherId not found in usersMap for conversation ${conversation.id}');
    }
    return user;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1976D2),
        title: const Text(
          'Conversations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Add search functionality
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          // Navigate back to login page and clear navigation stack
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
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
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Conversations list
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[700],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _conversations.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 100),
                            child: Text(
                              'No conversations yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 20),
                            itemCount: _conversations.length,
                            itemBuilder: (context, index) {
                              final conversation = _conversations[index];
                              final user = _getOtherParticipant(conversation);
                              
                              if (user == null) {
                                return const SizedBox.shrink();
                              }
                              
                              final lastMessage = _lastMessages[conversation.id];

                              return _ConversationListItem(
                                conversation: conversation,
                                user: user,
                                lastMessage: lastMessage,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                        conversation: conversation,
                                        otherUser: user,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
        ],
      ),
    );
  }
}

class _ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final User user;
  final Message? lastMessage;
  final VoidCallback onTap;

  const _ConversationListItem({
    required this.conversation,
    required this.user,
    this.lastMessage,
    required this.onTap,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    final difference = today.difference(messageDate);

    // Format hour:minute
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    if (difference.inDays == 0) {
      // Today - show only time
      return timeStr;
    } else if (difference.inDays == 1) {
      // Yesterday - show "Yesterday HH:MM"
      return 'Yesterday $timeStr';
    } else if (difference.inDays < 7) {
      // This week - show day name and time
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = days[time.weekday - 1];
      return '$dayName $timeStr';
    } else {
      // Older - show date and time
      final day = time.day.toString().padLeft(2, '0');
      final month = time.month.toString().padLeft(2, '0');
      return '$day/$month $timeStr';
    }
  }
  
  String _formatDate(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    final difference = today.difference(messageDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[time.weekday - 1];
    } else {
      final day = time.day.toString().padLeft(2, '0');
      final month = time.month.toString().padLeft(2, '0');
      final year = time.year.toString();
      return '$day/$month/$year';
    }
  }

  String _getAvatarInitial(String name) {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade50,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
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
                  _getAvatarInitial(user.displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  if (lastMessage?.contentPreview != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      lastMessage!.contentPreview!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Date and Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Date
                if (lastMessage?.createdAt != null)
                  Text(
                    _formatDate(lastMessage!.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                // Time
                Text(
                  lastMessage?.createdAt != null
                      ? '${lastMessage!.createdAt.hour.toString().padLeft(2, '0')}:${lastMessage!.createdAt.minute.toString().padLeft(2, '0')}'
                      : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
