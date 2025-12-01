import "package:final_project/components/hub_tile.dart"; 
import "package:final_project/services/auth/auth_service.dart";
import "package:final_project/components/my_drawer.dart";
import "package:flutter/material.dart";
import 'package:cloud_firestore/cloud_firestore.dart'; // Keep for Timestamp if needed, but primarily for type
import 'package:flutter/foundation.dart';
import 'package:final_project/services/group/group_service.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  final AuthService authService = AuthService();
  final GroupService groupService = GroupService(); 
  
  // MOCK: Role state is still mocked, but we keep the logic structure.
  String _userRole = 'General'; 

  @override
  void initState() {
    super.initState();
    _fetchUserRole(); 
    // Removed _hubsFuture initialization as we are using a Stream now
  }
  
  // MOCK: Function to refresh the hub list is no longer needed with StreamBuilder
  // void _refreshHubs() { ... } 


  // Fetch the current user's role from Firestore in real-time (MOCKED for UI focus)
  void _fetchUserRole() async {
    final userId = authService.getCurrentUser()?.uid;
    if (userId != null) {
      try {
        // --- START MOCKING ROLE FETCH (Replace with actual Firestore fetch later) ---
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
            _userRole = (userId.hashCode % 2 == 0) ? 'Teacher' : 'Student Org';
        });
        // --- END MOCKING ROLE FETCH ---

      } catch (e) {
        if (kDebugMode) {
          print("Error fetching user role: $e");
        }
      }
    }
  }
  
  // MOCK: Removed _fetchMockHubs() 


  // Universal function to create a new group (Class or Org) 
  void _createNewGroup(BuildContext context, String groupType) {
    String requiredRole = groupType == 'Class' ? 'Teacher' : 'Student Org';
    
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        bool isLoading = false; // State for loading indicator inside dialog

        return StatefulBuilder( // Use StatefulBuilder to manage loading state inside the dialog
          builder: (context, setStateInDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Create New $groupType Hub", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _userRole == requiredRole 
                    ? "Your current role is $_userRole."
                    : _userRole == 'General'
                      ? "Creating a $groupType will upgrade your role to '$requiredRole'."
                      : "Only a $requiredRole can create a $groupType. You are currently $_userRole.",
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: "Enter $groupType Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    enabled: (_userRole == 'General' || _userRole == requiredRole) && !isLoading,
                  ),
                  if (isLoading) const Padding(
                    padding: EdgeInsets.only(top: 15.0),
                    child: LinearProgressIndicator(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                if (_userRole == 'General' || _userRole == requiredRole)
                  TextButton(
                    onPressed: isLoading ? null : () async {
                      if (nameController.text.isNotEmpty) {
                        setStateInDialog(() { isLoading = true; }); // Start loading
                        
                        try {
                          await groupService.createNewHub(
                            name: nameController.text.trim(),
                            type: groupType,
                          );
                          
                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            // NO NEED TO CALL _refreshHubs()! The StreamBuilder handles the refresh.
                            
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Hub '${nameController.text.trim()}' created successfully!"),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                          
                        } catch (e) {
                          if (kDebugMode) {
                            print("Hub creation failed: $e");
                          }
                          if (context.mounted) {
                            setStateInDialog(() { isLoading = false; }); // Stop loading
                            Navigator.pop(context); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error creating hub: ${e.toString()}"),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Text(
                      isLoading ? "Creating..." : "Create Hub", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).colorScheme.primary
                      )
                    ),
                  ),
              ],
            );
          }
        );
      },
    );
  }

  // Helper function to determine the number of columns based on screen width
  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) {
      // Small screens (Mobile)
      return 3;
    } else {
      // Larger screens (Tablet/Desktop)
      return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = authService.getCurrentUser();
    final displayName = currentUser?.email?.split('@').first ?? 'User';

    // Floating Action Button
    final fab = FloatingActionButton.extended(
      onPressed: () => _showGroupCreationOptions(context),
      label: const Text("Create Hub"),
      icon: const Icon(Icons.add_circle_outline),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      tooltip: 'Create a new Class or Organization Hub',
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome Back, $displayName", 
              style: TextStyle(
                fontSize: 14, 
                color: colorScheme.tertiary,
                fontWeight: FontWeight.w500
              )
            ),
            const Text(
              "My School Hubs", 
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.w900
              )
            ),
          ],
        ),
        toolbarHeight: 80, 
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("MOCK: Search feature coming soon!"))
              );
            },
            tooltip: 'Search Hubs',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const MyDrawer(),
      body: _buildJoinedHubsGrid(), 
      floatingActionButton: fab, 
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  // Dialog to choose which type of group to create
  void _showGroupCreationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 15),
              ),
              Text(
                'Create New Hub',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w800, 
                  color: Theme.of(context).colorScheme.onSurface
                )
              ),
              const SizedBox(height: 5),
              Text(
                'Your Role: $_userRole',
                style: TextStyle(
                  fontSize: 14, 
                  color: Theme.of(context).colorScheme.tertiary
                )
              ),
              const Divider(height: 30),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: const Icon(Icons.class_, color: Colors.blueAccent),
                ),
                title: const Text('New Class Hub', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('For academic subjects and courses'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _createNewGroup(context, 'Class');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: const Icon(Icons.people, color: Colors.green),
                ),
                title: const Text('New Organization Hub', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('For clubs, teams, and student groups'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _createNewGroup(context, 'Organization');
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Widget to consolidate and display both Classes and Organizations in a single Grid
  Widget _buildJoinedHubsGrid() {
    // Use StreamBuilder to listen for real-time updates from the database
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: groupService.getHubsStream(), 
      
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Display a user-friendly error message
          if (kDebugMode) {
            print("Firestore Stream Error: ${snapshot.error}");
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Text(
                "Error loading hubs. Check your Firestore rules or network connection.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          );
        }

        // Show a loading indicator while the data is fetching
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Map<String, dynamic>> allHubs = snapshot.data ?? [];

        if (allHubs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.widgets_outlined, size: 60, color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5)),
                  const SizedBox(height: 15),
                  Text(
                    "You haven't joined any School Hubs yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap 'Create Hub' below to get started or 'Join Hub' from the menu.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Display Grid View
        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80), 
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context), 
              crossAxisSpacing: 12.0, 
              mainAxisSpacing: 12.0, 
              childAspectRatio: 1.0, 
            ),
            itemCount: allHubs.length,
            itemBuilder: (context, index) {
              final hubData = allHubs[index];
              return HubTile(
                hubData: hubData, 
                authService: authService,
              );
            },
          ),
        );
      },
    );
  }
}