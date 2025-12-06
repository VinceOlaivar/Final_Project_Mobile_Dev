import 'package:final_project/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatelessWidget {

  final String message;
  final bool isCurrentUser;
  final String? senderName;


  const ChatBubble({super.key,
    required this.message,
    required this.isCurrentUser,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {

    //light vs dark mode for correct bubble color
    bool isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return Container(
      margin: EdgeInsets.only(
        top: 5,
        bottom: 5,
        left: isCurrentUser ? 50 : 10,
        right: isCurrentUser ? 10 : 50,
      ),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser && senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7, // Max 70% of screen width
                minWidth: 50, // Minimum width
              ),
              decoration: BoxDecoration(
                color: isCurrentUser
                ? (isDarkMode ? Colors.blue.shade600 : Colors.blue.shade500)
                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade500),
                border: !isCurrentUser && !isDarkMode
                  ? Border.all(color: Colors.grey.shade600, width: 1)
                  : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isCurrentUser ? const Radius.circular(12) : const Radius.circular(4),
                  bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                message,
                style: TextStyle(
                  color: isCurrentUser
                  ? Colors.white
                  : (isDarkMode ? const Color.fromARGB(255, 154, 152, 180) : Colors.black),
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}