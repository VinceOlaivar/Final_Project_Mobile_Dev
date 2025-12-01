import 'package:flutter/material.dart';
import 'package:final_project/services/auth/auth_service.dart';
//import 'package:final_project/services/chat/hub_messaging_service.dart';

class HubPage extends StatefulWidget {
  final String recieverEmail; // The Hub Name
  final String recieverID;    // The Hub's Firestore document ID
  final bool isGroupChat;     // Should always be true for Hubs
  final String groupType;     // 'Class' or 'Organization'
  final bool isModerator;     // Is the current user the creator/moderator?

  const HubPage({
    super.key,
    required this.recieverEmail,
    required this.recieverID,
    this.isGroupChat = true,
    required this.groupType,
    required this.isModerator,
  });

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  final TextEditingController _messageController = TextEditingController();
  //final HubMessagingService _hubService = HubMessagingService();
  final AuthService _authService = AuthService();

  // STUB: This is the placeholder method for sending a message
  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      // The actual logic to send a message to Firestore will go here later.
      print("STUB: Attempting to send message to Hub ${widget.recieverEmail}: ${_messageController.text}");
      _messageController.clear();
    }
  }

  // Placeholder for future actions (e.g., inviting members, editing hub details)
  void _showHubSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${widget.groupType} Hub Settings",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text("View/Manage Members"),
                onTap: () {
                  // Future: Navigate to member list page
                  Navigator.pop(context);
                },
              ),
              if (widget.isModerator)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Edit Hub Details"),
                  onTap: () {
                    // Future: Show dialog to edit name/cover
                    Navigator.pop(context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("Hub Info"),
                onTap: () {
                  // Future: Show basic info like creator and date
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.recieverEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              "Hub Type: ${widget.groupType} ${widget.isModerator ? '(Moderator)' : ''}",
              style: TextStyle(fontSize: 12, color: colorScheme.onPrimary.withOpacity(0.7)),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showHubSettings(context),
            tooltip: 'Hub Settings and Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Message Area (Placeholder for Message List)
          const Expanded(
            child: Center(
              child: Text(
                "Hub content area.\nMessaging features will be built here soon!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          // Message Input (Placeholder for Input Bar)
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Input area widget
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Textfield
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Send a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              obscureText: false,
            ),
          ),

          const SizedBox(width: 8),

          // Send Button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 5),
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}