import 'package:final_project/services/auth/auth_service.dart';
import 'package:final_project/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:final_project/services/group/group_service.dart';
import 'package:final_project/components/hub_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/components/my_textfield.dart';
import 'package:final_project/components/my_button.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Services
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService(); 

  // Controllers for the Hub creation dialog
  final TextEditingController _hubNameController = TextEditingController();
  final TextEditingController _joinHubNameController = TextEditingController();

  @override
  void dispose() {
    _hubNameController.dispose();
    _joinHubNameController.dispose();
    super.dispose();
  }

  void logout() {
    _authService.signOut();
  }

  // Implementation: Function to show a dialog for creating a new hub
  void _showCreateHubDialog() {
    // Reset state for new dialog instance
    _hubNameController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Hub"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hub Name Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: MyTextfield(
                    controller: _hubNameController,
                    hintText: "Enter Hub Name (e.g., CS 101)",
                    obscureText: false,
                    focusNode: null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () {
                _hubNameController.clear();
                Navigator.of(context).pop();
              },
              child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
            ),

            // Create Button
            MyButton(
              text: "Create",
              onTap: () {
                _createHub(_hubNameController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Implementation: Function to show a dialog for joining an existing hub
  void _showJoinHubDialog() {
    // Reset state for new dialog instance
    _joinHubNameController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Join Hub"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hub ID Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: MyTextfield(
                    controller: _joinHubNameController,
                    hintText: "Enter Hub ID to Join (e.g., ABC123)",
                    obscureText: false,
                    focusNode: null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () {
                _joinHubNameController.clear();
                Navigator.of(context).pop();
              },
              child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
            ),

            // Join Button
            MyButton(
              text: "Join",
              onTap: () {
                _joinHub(_joinHubNameController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to call the GroupService to create the hub
  void _createHub(String name) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hub name cannot be empty.")),
      );
      return;
    }

    try {
      String hubId = await _groupService.createNewHub(
        name: name.trim(),
      );

      _hubNameController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${name.trim()} Hub created successfully!\nHub ID: $hubId")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create hub: ${e.toString()}")),
      );
    }
  }

  // Function to call the GroupService to join the hub
  void _joinHub(String hubId) async {
    if (hubId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hub ID cannot be empty.")),
      );
      return;
    }

    try {
      await _groupService.joinHubById(hubId.trim().toUpperCase());

      _joinHubNameController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully joined hub ${hubId.trim().toUpperCase()}!")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to join hub: ${e.toString()}")),
      );
    }
  }


  Widget _buildBodyContent() {
    return _buildHubsList(); 
  }

  // List of all the user's private hubs/groups
    Widget _buildHubsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupService.getHubsStream(),
      builder: (context, snapshot) {
        // Handle error
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading hubs: ${snapshot.error}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        // Handle no data / loading
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<DocumentSnapshot> hubDocs = snapshot.data!.docs;

        // No hubs found
        if (hubDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hub,
                    size: 60,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                const SizedBox(height: 10),
                Text(
                  "You are not in any Hubs. Tap '+' to create one.",
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Return the list of Hubs
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: hubDocs.length,
          itemBuilder: (context, index) {
            final DocumentSnapshot doc = hubDocs[index];

            // Safely get data and make a copy so we don't mutate Firestore internals
            final raw = doc.data();
            final Map<String, dynamic> hubData =
                (raw is Map<String, dynamic>) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

            // Inject the Firestore document ID for navigation/identification
            hubData['id'] = doc.id;

            return HubTile(
              hubData: hubData,
              authService: _authService,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Hubs"),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      
      body: _buildBodyContent(),

      // Floating Action Button with menu for create/join
      floatingActionButton: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'create') {
            _showCreateHubDialog();
          } else if (value == 'join') {
            _showJoinHubDialog();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'create',
            child: Row(
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('Create Hub'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'join',
            child: Row(
              children: [
                Icon(Icons.group_add),
                SizedBox(width: 8),
                Text('Join Hub'),
              ],
            ),
          ),
        ],
        child: FloatingActionButton(
          onPressed: null, // Handled by PopupMenuButton
          backgroundColor: colorScheme.primary,
          child: Icon(Icons.more_vert, color: colorScheme.onPrimary),
        ),
      ),
    );
  }
}