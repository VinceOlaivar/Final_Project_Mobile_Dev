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
    // Determine hub properties
    final bool isClass = hubData["groupType"] == 'Classes';
    final IconData icon = isClass ? Icons.menu_book_rounded : Icons.groups_2_rounded;
    // Define distinct primary and light colors for Class (Blue) and Organization (Green)
    final Color primaryColor = isClass ? const Color(0xFF1E88E5) : const Color(0xFF43A047); 
    final String type = isClass ? 'Class' : 'Organization';
    final bool isModerator = authService.getCurrentUser()?.uid == hubData["creatorId"];
    final colorScheme = Theme.of(context).colorScheme;

    // --- FIXES: Robustly get data to handle name/email discrepancies ---
    // 1. Robustly get the Hub Name (checking for 'name' OR 'groupName')
    final String hubName = hubData["name"] ?? hubData["groupName"] ?? "Untitled Hub"; 
    // 2. Robustly get the Creator (checking for 'creatorName' OR 'creatorEmail')
    final String creator = hubData["creatorName"] ?? hubData["creatorEmail"] ?? 'No Creator Info';
    // 3. Get the ID (which is set to 'id' in home_page.dart)
    final String hubId = hubData["id"] ?? "No-ID";
    // -------------------------------------------------------------------

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isClass ? primaryColor : colorScheme.outline.withOpacity(0.3),
          width: isClass ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isClass ? primaryColor.withOpacity(0.25) : colorScheme.shadow.withOpacity(0.08),
            spreadRadius: isClass ? 3 : 1,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent, // Allows InkWell/Ripple effect
        child: InkWell(
          onTap: () {
            // Navigate to the Hub Page
            if (kDebugMode) {
              print("Navigating to Hub: $hubName (ID: $hubId)");
            }
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => HubPage( 
                recieverEmail: hubName, // Hub name
                recieverID: hubId,      // Hub ID (Firestore document ID)
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
                          size: 56, 
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                    
                    // Top-right Badge for Type
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), 
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9, 
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
                  padding: const EdgeInsets.all(10.0), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hubName, // Use the resolved name
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_pin, size: 12, color: colorScheme.tertiary), 
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              creator, // Use the resolved creator name/email
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
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
                            const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 14), 
                            const SizedBox(width: 4),
                            Text(
                              'Moderator',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange.shade600,
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