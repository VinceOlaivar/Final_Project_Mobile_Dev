import 'package:flutter/material.dart';
import 'package:final_project/services/chat/hub_messaging_service.dart';
import 'package:final_project/services/group/group_service.dart';
import 'package:final_project/services/assignment_service.dart';
import 'package:final_project/components/chat_bubble.dart';
import 'package:final_project/components/assignment_submission_dialog.dart';
import 'package:final_project/models/message.dart';
import 'package:final_project/models/submission.dart';
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

  // Import GroupService for hub management
  final GroupService _groupService = GroupService();

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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if screen width is less than 800px (typical tablet/mobile breakpoint)
        bool isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          // Mobile layout: Use tabs for channels, chat, and members
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: Text(widget.recieverEmail),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 0,
                actions: widget.isModerator ? [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showHubSettingsDialog(),
                  ),
                ] : null,
                bottom: TabBar(
                  indicatorColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                  tabs: const [
                    Tab(icon: Icon(Icons.forum), text: 'Channels'),
                    Tab(icon: Icon(Icons.chat), text: 'Chat'),
                    Tab(icon: Icon(Icons.people), text: 'Members'),
                  ],
                ),
              ),
              body: Container(
                color: Theme.of(context).colorScheme.surface,
                child: TabBarView(
                  children: [
                    // Channels Tab
                    _buildChannelsView(),
                    // Chat Tab
                    _buildChatView(),
                    // Members Tab
                    _buildMembersView(),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Desktop layout: Original 3-column layout
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.recieverEmail),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              actions: widget.isModerator ? [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showHubSettingsDialog(),
                ),
              ] : null,
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
                      child: _buildChannelsView(),
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
                      child: _buildChatView(),
                    ),
                  ),

                  // Right Column: Members
                  Expanded(
                    flex: 2,
                    child: Container(
                      child: _buildMembersView(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  // Extracted widget builders for reusability
  Widget _buildChannelsView() {
    return Column(
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
                  final channelType = channel['type'] as String? ?? 'text';
                  final isSelected = _selectedChannelId == channelId;

                  return ListTile(
                    leading: Icon(
                      channelType == 'assignment' ? Icons.assignment : Icons.chat,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      channelType == 'assignment' ? '📝 $channelName' : '# $channelName',
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: channelType == 'assignment' && channel['dueDate'] != null
                        ? Text(
                            'Due: ${(channel['dueDate'] as Timestamp).toDate().toString().split(' ')[0]}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
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
    );
  }

  Widget _buildChatView() {
    if (_selectedChannelId == null) {
      return Center(
        child: Text(
          'Select a channel to start chatting',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    // Check if this is an assignment channel
    return FutureBuilder<DocumentSnapshot>(
      future: _hubMessagingService.getChannelById(_selectedChannelId!),
      builder: (context, channelSnapshot) {
        if (channelSnapshot.hasError) {
          return Center(child: Text('Error: ${channelSnapshot.error}'));
        }
        if (!channelSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final channelData = channelSnapshot.data!.data() as Map<String, dynamic>;
        final channelType = channelData['type'] as String? ?? 'text';

        if (channelType == 'assignment') {
          return _buildAssignmentView(channelData);
        } else {
          return _buildTextChatView();
        }
      },
    );
  }

  Widget _buildTextChatView() {
    return Column(
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
            '# ${_getChannelName(_selectedChannelId!)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        // Messages
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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
          ),
        ),
        // Message Input
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
    );
  }

  Widget _buildAssignmentView(Map<String, dynamic> channelData) {
    final assignmentTitle = channelData['assignmentTitle'] as String?;
    final assignmentDescription = channelData['assignmentDescription'] as String?;
    final dueDate = channelData['dueDate'] as Timestamp?;

    return Column(
      children: [
        // Assignment Header
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      assignmentTitle ?? 'Assignment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              if (dueDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Due: ${dueDate.toDate().toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Assignment Description
        if (assignmentDescription != null && assignmentDescription.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              assignmentDescription,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        // Assignment Content - Different for moderators vs students
        Expanded(
          child: widget.isModerator
              ? _buildModeratorAssignmentView(channelData)
              : _buildStudentAssignmentView(channelData),
        ),
      ],
    );
  }

  Widget _buildStudentAssignmentView(Map<String, dynamic> channelData) {
    return FutureBuilder<Submission?>(
      future: AssignmentService().getUserSubmission(_selectedChannelId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasSubmitted = snapshot.data != null;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasSubmitted) ...[
                const Icon(Icons.check_circle, size: 48, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Assignment Submitted',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submitted on: ${snapshot.data!.submittedAt.toDate().toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (snapshot.data!.grade != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Grade: ${snapshot.data!.grade}/100',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ] else ...[
                const Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Not Submitted Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showSubmissionDialog(channelData),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Submit Assignment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeratorAssignmentView(Map<String, dynamic> channelData) {
    return Column(
      children: [
        // Submissions Header
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
                'Submissions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showGradingDialog(channelData),
                icon: const Icon(Icons.grade),
                tooltip: 'Grade Submissions',
              ),
            ],
          ),
        ),
        // Submissions List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: AssignmentService().getSubmissionsStream(_selectedChannelId!),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final submissions = snapshot.data!.docs;
              if (submissions.isEmpty) {
                return Center(
                  child: Text(
                    'No submissions yet',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                );
              }

              return ListView.builder(
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final submissionData = submissions[index].data() as Map<String, dynamic>;
                  final submission = Submission.fromMap(submissionData);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: submission.grade != null ? Colors.green : Theme.of(context).colorScheme.primary,
                      child: Text(
                        submission.studentName[0].toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                    title: Text(
                      submission.studentName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submitted: ${submission.submittedAt.toDate().toString().split(' ')[0]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (submission.grade != null)
                          Text(
                            'Grade: ${submission.grade}/100',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    trailing: submission.grade != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.pending, color: Colors.orange),
                    onTap: () => _showSubmissionDetailsDialog(submission),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMembersView() {
    return Column(
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
    );
  }

  String _getChannelName(String channelId) {
    // This is a simple implementation. In a real app, you might want to cache channel names.
    // For now, we'll just return the channel ID without the hub prefix.
    return channelId.split('_').sublist(1).join('_').replaceAll('_', ' ');
  }

  void _showCreateChannelDialog() {
    final TextEditingController channelNameController = TextEditingController();
    final TextEditingController assignmentTitleController = TextEditingController();
    final TextEditingController assignmentDescriptionController = TextEditingController();
    String selectedChannelType = 'text';
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Channel'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Channel Name
                    TextField(
                      controller: channelNameController,
                      decoration: const InputDecoration(hintText: 'Channel name'),
                    ),
                    const SizedBox(height: 16),

                    // Channel Type Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedChannelType,
                      decoration: const InputDecoration(
                        labelText: 'Channel Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'text', child: Text('Text Channel')),
                        DropdownMenuItem(value: 'assignment', child: Text('Assignment Channel')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedChannelType = value!;
                        });
                      },
                    ),

                    // Assignment-specific fields
                    if (selectedChannelType == 'assignment') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: assignmentTitleController,
                        decoration: const InputDecoration(
                          hintText: 'Assignment title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: assignmentDescriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Assignment description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // Due Date Picker
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDueDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            selectedDueDate != null
                                ? selectedDueDate!.toLocal().toString().split(' ')[0]
                                : 'Select due date',
                            style: TextStyle(
                              color: selectedDueDate != null
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),

                const SizedBox(width: 8),

                TextButton(
                  onPressed: () async {
                    if (channelNameController.text.isNotEmpty) {
                      try {
                        await _hubMessagingService.createChannel(
                          widget.recieverID,
                          channelNameController.text,
                          selectedChannelType,
                          assignmentTitle: selectedChannelType == 'assignment' ? assignmentTitleController.text : null,
                          assignmentDescription: selectedChannelType == 'assignment' ? assignmentDescriptionController.text : null,
                          dueDate: selectedChannelType == 'assignment' ? selectedDueDate : null,
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${selectedChannelType == 'assignment' ? 'Assignment' : 'Channel'} created successfully')),
                        );
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
      },
    );
  }

  void _showHubSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hub Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hub ID Display
              Text(
                'Hub ID: ${widget.recieverID}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Hub Name
              Text(
                'Hub Name: ${widget.recieverEmail}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Moderator Note
              Text(
                'As the hub creator, you have moderator privileges including the ability to delete this hub.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            // Copy Hub ID Button
            TextButton.icon(
              onPressed: () {
                // TODO: Implement copy to clipboard functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hub ID copied: ${widget.recieverID}')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy ID'),
            ),

            // Close Button
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Close'),
            ),

            // Delete Hub Button
            TextButton(
              onPressed: () => _showDeleteHubConfirmation(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Delete Hub'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteHubConfirmation() {
    Navigator.of(context).pop(); // Close settings dialog

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Hub'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to delete "${widget.recieverEmail}"?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone. All channels and messages will be permanently deleted.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),

            const SizedBox(width: 8),

            TextButton(
              onPressed: () async {
                try {
                  await _groupService.deleteHub(widget.recieverID);
                  Navigator.of(context).pop(); // Close confirmation dialog
                  Navigator.of(context).pop(); // Go back to home page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hub deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting hub: $e')),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSubmissionDialog(Map<String, dynamic> channelData) {
    final assignmentTitle = channelData['assignmentTitle'] as String? ?? 'Assignment';

    showDialog(
      context: context,
      builder: (context) => AssignmentSubmissionDialog(
        assignmentId: _selectedChannelId!,
        channelId: _selectedChannelId!,
        hubId: widget.recieverID,
        assignmentTitle: assignmentTitle,
      ),
    );
  }

  void _showGradingDialog(Map<String, dynamic> channelData) {
    // TODO: Implement grading interface
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grading interface coming soon!')),
    );
  }

  void _showSubmissionDetailsDialog(Submission submission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Submission by ${submission.studentName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (submission.submissionText != null && submission.submissionText!.isNotEmpty) ...[
                Text(
                  'Text Submission:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(submission.submissionText!),
                const SizedBox(height: 16),
              ],
              if (submission.fileUrl != null) ...[
                Text(
                  'File:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(submission.fileName ?? 'Attached file'),
                // TODO: Add download button or view file
              ],
              const SizedBox(height: 16),
              Text('Submitted: ${submission.submittedAt.toDate().toString()}'),
              if (submission.grade != null) ...[
                const SizedBox(height: 8),
                Text('Grade: ${submission.grade}/100'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (widget.isModerator && submission.grade == null) ...[
            TextButton(
              onPressed: () => _showGradeDialog(submission),
              child: const Text('Grade'),
            ),
          ],
        ],
      ),
    );
  }

  void _showGradeDialog(Submission submission) {
    final TextEditingController gradeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grade Submission'),
        content: TextField(
          controller: gradeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter grade (0-100)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final grade = int.tryParse(gradeController.text);
              if (grade != null && grade >= 0 && grade <= 100) {
                try {
                  await AssignmentService().gradeSubmission(
                    submissionId: submission.id,
                    grade: grade,
                  );
                  Navigator.of(context).pop(); // Close grade dialog
                  Navigator.of(context).pop(); // Close details dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Submission graded successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error grading submission: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid grade (0-100)')),
                );
              }
            },
            child: const Text('Submit Grade'),
          ),
        ],
      ),
    );
  }
}
