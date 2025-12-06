import 'package:flutter/material.dart';
import 'package:final_project/services/chat/hub_messaging_service.dart';
import 'package:final_project/components/chat_bubble.dart';
import 'package:final_project/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HubPage extends StatefulWidget {
  final String recieverEmail; // The Hub Name
  final String recieverID;    // The Hub's Firestore document ID
  final bool isGroupChat;     // Should always be true for Hubs
  final String groupType;     // 'Class' or 'Organization'
  final bool isModerator;     // If current user is moderator

  const HubPage({
    super.key,
    required this.recieverEmail,
    required this.recieverID,
    required this.isGroupChat,
    required this.groupType,
    required this.isModerator,
  });

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  final HubMessagingService _hubMessagingService = HubMessagingService();
  final TextEditingController _messageController = TextEditingController();
  String? _selectedChannelId;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty && _selectedChannelId != null) {
      await _hubMessagingService.sendChannelMessage(
        _selectedChannelId!,
        _messageController.text,
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recieverEmail),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            // Left Column: Channels
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Channels Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Channels',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          if (widget.isModerator)
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _showCreateChannelDialog(),
                            ),
                        ],
                      ),
                    ),
                    // Channels List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _hubMessagingService.getChannelsStream(widget.recieverID),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final channels = snapshot.data!.docs;
                          if (channels.isEmpty) {
                            return Center(
                              child: Text(
                                'No channels yet',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: channels.length,
                            itemBuilder: (context, index) {
                              final channel = channels[index].data() as Map<String, dynamic>;
                              final channelId = channel['id'] as String;
                              final channelName = channel['name'] as String;
                              final isSelected = _selectedChannelId == channelId;

                              return ListTile(
                                title: Text(
                                  '# $channelName',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedChannelId = channelId;
                                  });
                                },
                                selected: isSelected,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center Column: Chat
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Chat Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        _selectedChannelId != null ? '# ${_getChannelName(_selectedChannelId!)}' : 'Select a channel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    // Messages
                    Expanded(
                      child: _selectedChannelId != null
                          ? StreamBuilder<QuerySnapshot>(
                              stream: _hubMessagingService.getChannelMessages(_selectedChannelId!),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                }
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final messages = snapshot.data!.docs;
                                return ListView.builder(
                                  reverse: true,
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final messageData = messages[messages.length - 1 - index].data() as Map<String, dynamic>;
                                    final message = Message.fromMap(messageData);
                                    final isCurrentUser = message.senderID == _hubMessagingService.getCurrentUser()?.uid;

                                    return ChatBubble(
                                      message: message.message,
                                      isCurrentUser: isCurrentUser,
                                      senderName: message.senderName,
                                    );
                                  },
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                'Select a channel to start chatting',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ),
                    ),
                    // Message Input
                    if (_selectedChannelId != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                onSubmitted: (_) => sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: sendMessage,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Right Column: Members
            Expanded(
              flex: 2,
              child: Container(
                child: Column(
                  children: [
                    // Members Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    // Members List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _hubMessagingService.getHubMembers(widget.recieverID),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final members = snapshot.data!.docs;
                          if (members.isEmpty) {
                            return Center(
                              child: Text(
                                'No members',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              final member = members[index].data() as Map<String, dynamic>;
                              final name = member['name'] as String? ?? 'Unknown';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getChannelName(String channelId) {
    // This is a simple implementation. In a real app, you might want to cache channel names.
    // For now, we'll just return the channel ID without the hub prefix.
    return channelId.split('_').sublist(1).join('_').replaceAll('_', ' ');
  }

  void _showCreateChannelDialog() {
    final TextEditingController channelNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Channel'),
          content: TextField(
            controller: channelNameController,
            decoration: const InputDecoration(hintText: 'Channel name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (channelNameController.text.isNotEmpty) {
                  try {
                    await _hubMessagingService.createChannel(
                      widget.recieverID,
                      channelNameController.text,
                      'text',
                    );
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating channel: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
