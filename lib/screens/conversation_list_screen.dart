import 'package:flutter/material.dart';
import 'package:trash_dash_demo/models/conversation.dart';
import 'package:trash_dash_demo/services/chat_service.dart';
import 'package:trash_dash_demo/services/local_storage_service.dart';
import 'package:trash_dash_demo/screens/chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List<Conversation> _conversations = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadConversations();
  }

  void _loadUserData() {
    final currentUser = LocalStorageService.getCurrentUser();
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
    }
  }

  void _loadConversations() {
    if (_currentUserId == null) return;

    setState(() {
      _conversations = ChatService.getUserConversations(_currentUserId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'When you message someone about an item, your conversations will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _loadConversations();
              },
              child: ListView.separated(
                itemCount: _conversations.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return _buildConversationTile(conversation);
                },
              ),
            ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final otherName = _currentUserId != null
        ? conversation.getOtherParticipantName(_currentUserId!)
        : 'Unknown';

    final unreadCount = _currentUserId != null
        ? ChatService.getUnreadCountForConversation(
            conversation.id, _currentUserId!)
        : 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.green.shade100,
        child: Text(
          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherName,
              style: TextStyle(
                fontWeight:
                    unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            _formatDate(conversation.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              color: unreadCount > 0
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
              fontWeight:
                  unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            conversation.itemName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  conversation.lastMessageContent ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: unreadCount > 0
                        ? Colors.black87
                        : Colors.grey.shade600,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversation: conversation),
          ),
        );
        // Reload conversations when returning to update read status
        _loadConversations();
      },
      onLongPress: () {
        _showDeleteDialog(conversation);
      },
    );
  }

  void _showDeleteDialog(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ChatService.deleteConversation(conversation.id);
              _loadConversations();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversation deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      int hour = dateTime.hour;
      final period = hour >= 12 ? 'PM' : 'AM';
      // Convert 24-hour to 12-hour format
      if (hour == 0) {
        hour = 12; // Midnight is 12 AM
      } else if (hour > 12) {
        hour = hour - 12;
      }
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year % 100}';
    }
  }
}
