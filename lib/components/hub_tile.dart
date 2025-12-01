import 'package:final_project/pages/hub_page.dart';
import 'package:final_project/services/auth/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HubTile extends StatelessWidget {
  final Map<String, dynamic> hubData;
  final AuthService authService;

  const HubTile({
    super.key,
    required this.hubData,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClass = hubData["groupType"] == 'Classes';
    final IconData icon = isClass ? Icons.menu_book_rounded : Icons.groups_2_rounded;
    // Define distinct primary and light colors for Class (Blue) and Organization (Green)
    final Color primaryColor = isClass ? const Color(0xFF1E88E5) : const Color(0xFF43A047); 
    final String type = isClass ? 'Class' : 'Organization';
    final bool isModerator = authService.getCurrentUser()?.uid == hubData["creatorId"];
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5), 
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent, // Allows InkWell/Ripple effect
        child: InkWell(
          onTap: () {
            // Navigate to the Hub Page (MOCKED navigation)
            if (kDebugMode) {
              print("Navigating to Hub: ${hubData["name"]}");
            }
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => HubPage( 
                recieverEmail: hubData["name"],
                recieverID: hubData["groupId"],
                isGroupChat: true,
                groupType: type,
                isModerator: isModerator, 
              )
            ));
          },
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Photo/Icon Area (Stack for gradient and badge overlay)
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Background Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor.withOpacity(0.85), primaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          size: 56, // Slightly reduced icon size for smaller tile
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                    
                    // Top-right Badge for Type
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), // Smaller padding
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9, // Smaller font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Text Info Area
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10.0), // Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hubData["name"] ?? "Untitled Hub",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15, // Reduced font size
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_pin, size: 12, color: colorScheme.tertiary), // Smaller icon
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hubData["creatorName"] ?? 'No Creator',
                              style: TextStyle(
                                fontSize: 11, // Reduced font size
                                color: colorScheme.tertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Moderator Badge at the bottom
                      if (isModerator)
                        Row(
                          children: [
                            const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 14), // Smaller icon
                            const SizedBox(width: 4),
                            Text(
                              'Moderator',
                              style: TextStyle(
                                fontSize: 11, // Reduced font size
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}