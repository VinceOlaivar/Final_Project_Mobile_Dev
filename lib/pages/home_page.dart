import "package:final_project/components/user_tile.dart";
import "package:final_project/pages/chat_page.dart";
import "package:final_project/services/auth/auth_service.dart";
import "package:final_project/components/my_drawer.dart";
import "package:flutter/material.dart";
import 'package:final_project/services/chat/chat_service.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  //chat & auth service

  final ChatService chatService = ChatService();
  final AuthService authService = AuthService();


  void logout() {
    // Implement logout functionality here
    final auth = AuthService();
    auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Home Page"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey[800],
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: _buildUserList(),
    );
  }

  // build a list of users except current user logged in user

  Widget _buildUserList(){
    return StreamBuilder(
      stream: chatService.getUsersStream(),
      builder: (context, snapshot){
        //error
        if (snapshot.hasError) {
         return const Text("Error occurred");
        }

        //loading

        if (snapshot.connectionState == ConnectionState.waiting){
          return const CircularProgressIndicator();
        }

        //return list view
        return ListView(
          children: snapshot.data!.map<Widget>((userData) => _buildUserListItem(userData,context)).toList()
        );
      },
    );
  }
//build individual list title for user
  Widget _buildUserListItem(Map<String, dynamic> userdata, BuildContext context){
    //display all user except current user
    if(userdata["email"] != authService.getCurrentUser()!.email){
       return UserTile(
      text: userdata["email"],
      onTap: () {

        //tapped on a user -> go to chat page
        Navigator.push(context, MaterialPageRoute(
          builder:(context)=> ChatPage(
            recieverEmail: userdata["email"],
            recieverID: userdata["uid"],
          ),
          ),
        );
      }
    );
    }else{
      return Container();
    }
  }
}