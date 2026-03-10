import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamma_app/screens/chat_screen.dart';
import 'package:gamma_app/screens/chatbot_screen.dart';
// import 'package:gamma_app/screens/video_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  createState() => _HomeScreen();
}


class _HomeScreen extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
 @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),)..repeat();
  }

  @override 
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

Future<void> deleteMyAccount(BuildContext context) async {
  User? user = FirebaseAuth.instance.currentUser;
  
  if(user != null) {
    try {
      String uid = user.uid;
      // Deleting the current user account from storage
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      // Deleting the history calls of the user
      await FirebaseFirestore.instance.collection("calls").doc(uid).delete();
      // Deleting his chat
      await FirebaseFirestore.instance.collection("chat_rooms").doc(uid).delete();
      // Deleting the user from authentication feature
      await user.delete();
      // Logging his out 
      await FirebaseAuth.instance.signOut();
  } on FirebaseAuthException catch (e) {
     if (e.code == 'requires-recent-login') {
      print("User needs to re-authenticate (log out and log back in) before deleting account.");
     }
  } catch(e) {
    print("Error deleting account: $e");
  }
}
}
  @override
 Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Center(child: Text('GAMMA',
      style: Theme.of(context).textTheme.titleLarge,)) ,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            deleteMyAccount(context);
          },
        )
      ],
    ),
    floatingActionButton: 
        FloatingActionButton(
          onPressed: () {
          Navigator.push(
            context,
           MaterialPageRoute(
            builder: (context) => const MetaAIScreen()
            )
           );
        }, 
        // backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        child:  AnimatedBuilder(
          animation: _controller,
           builder: (context, child) {
           return Transform.rotate(angle: 2 * 3.1515926 * _controller.value,
            child: ShaderMask(shaderCallback: ( bounds) {
              return const SweepGradient(
                colors: [
                    Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)
                ],
        
              ).createShader(bounds);
            }, 
            child: child,
            ),
            );
           },
            child: const Icon(
              size: 30,
              Icons.circle_outlined,
              color: Colors.white,
              semanticLabel: "Ai",
        
              )
        )
        ),


     
    body: StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').snapshots(), 
      builder: (context, snapshot) {
        if(snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if(snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.requireData;

        return ListView.builder(
          itemCount: data.size,
          itemBuilder: (context, index) {
            var userData = data.docs[index];
            if(userData['uid'] == FirebaseAuth.instance.currentUser?.uid) {
              return Container();
            }

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(userData['email']),
              onTap: () {
                Navigator.push(
                  context,
                   MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      receiverUserEmail: userData['email'],
                       receiverUserId: userData['uid']),
                    ) 
                  );
              }
            );

          }
        );
      }
      ),
    );
 }
}