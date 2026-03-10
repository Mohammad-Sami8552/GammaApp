import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gamma_app/screens/call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserId;
  const ChatScreen({
    super.key,
    required this.receiverUserEmail,
    required this.receiverUserId
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatRoomId() {
    String currentUserId = _auth.currentUser!.uid;
    List<String> ids = [currentUserId, widget.receiverUserId];
    ids.sort();
    return ids.join("_");
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final String currentUserId = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email!;
      final Timestamp timestamp = Timestamp.now();

      Map<String, dynamic> newMessage = {
        'senderId': currentUserId,
        'senderEmail': currentUserEmail,
        'receiverId': widget.receiverUserId,
        'message': _messageController.text,
        'timestamp': timestamp,
      };

      // List<String> ids = [currentUserId, widget.receiverUserId];
      // ids.sort();
      String chatRoomId = getChatRoomId();

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage);

      _messageController.clear();
    }
  }


  
  Future<void> triggerCall({required bool isVideoCall}) async
  {
    String callID = getChatRoomId();
    String myUserId = _auth.currentUser!.uid;
    String myUserName = _auth.currentUser!.email!.split('@')[0];
    await FirebaseFirestore.instance
                           .collection('calls')
                           .doc(widget.receiverUserId)
                           .set({
                                  'caller_name': myUserName,
                                  'caller_id': myUserId,
                                  'status': 'ringing',
                                  'isVideoCall': isVideoCall,
                                  'room_id': callID
                           });
    if(context.mounted) {
      Navigator.push(
        context,
         MaterialPageRoute(
          builder: (context) => CallScreen(
            callID: callID, 
            userId: myUserId,
             userName: myUserName, 
             isVideoCall: isVideoCall,
             callDocId: widget.receiverUserId))
         );
    }
  }

    @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverUserEmail),
        actions: [
          IconButton(onPressed: () {
            triggerCall(isVideoCall: false);
          }, 
          icon: const Icon(Icons.phone)
          ),

          IconButton(onPressed: () {
            triggerCall(isVideoCall: true);
          }, icon: Icon(Icons.videocam))
        ],
        backgroundColor: Color(0xFF5FAFD3)
,

        foregroundColor: Colors.black
      
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF87CEEB), // sky blue
    Color(0xFFB0E0E6), // powder blue
    Color(0xFFFFF9C4), // soft sunlight
  ],
)

        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: _firestore
                    .collection('chat_rooms')
                    .doc(getChatRoomId())
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading messages'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView(
                    reverse: true,
                    children: snapshot.data!.docs.map((document) {
                      var data = document.data();
                      bool isMe = data['senderId'] == _auth.currentUser!.uid;
                      var alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
                      var color = isMe ? Color(0xFFDCF8C6) : Colors.white;
                      // var textColor = isMe ? Colors.white : Colors.black;
                      return Container(
                        alignment: alignment,
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data['message'],
                            // style: TextStyle(color: textColor),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Enter message..',
                        hintStyle: Theme.of(context).textTheme.labelMedium,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onSubmitted: (value) {
                        sendMessage();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send, size: 30),
                    color: Theme.of(context).colorScheme.primary,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}