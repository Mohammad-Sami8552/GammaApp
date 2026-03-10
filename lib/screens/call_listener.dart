import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gamma_app/screens/call_screen.dart'; 

class GlobalCallListener extends StatefulWidget {
  final Widget child;
  const GlobalCallListener({super.key, required this.child});

  @override
  State<GlobalCallListener> createState() => _GlobalCallListenerState();
}

class _GlobalCallListenerState extends State<GlobalCallListener> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRinging = false; 

  @override
  void initState() {
    super.initState();
    _listenForCalls();
  }

  void _listenForCalls() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) return;

      FirebaseFirestore.instance
          .collection('calls')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
      
        if (snapshot.exists && snapshot.data()?['status'] == 'ringing') {
          
          if (_isRinging) return;

          String callerId = snapshot.data()?['caller_id'];
          if (callerId == user.uid) return;
          
          bool isVideoCall = snapshot.data()?['isVideoCall'] ?? false;
          String callerName = snapshot.data()?['caller_name'] ?? "Unknown";
          String roomId = snapshot.data()?['room_id'];

          _startRinging(callerName, roomId, isVideoCall, user.uid);
        }
      });
    });
  }


  void _startRinging(String callerName, String roomId, bool isVideo, String myUserId) {
    setState(() {
      _isRinging = true;
    });

    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));

    showDialog(
      context: context,
      barrierDismissible: false, // User MUST click Answer or Decline
      builder: (context) => AlertDialog(
        title: Text(isVideo ? "Incoming Video Call" : "Incoming Voice Call"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 60, color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text("$callerName is calling...", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // DECLINE
          TextButton(
            onPressed: () {
              _stopRinging();
              Navigator.pop(context);
              FirebaseFirestore.instance
                  .collection('calls')
                  .doc(myUserId)
                  .update({'status': 'ended'});
            },
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              _stopRinging();
              Navigator.pop(context);
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    callID: roomId,
                    userId: myUserId,
                    userName: 'User', 
                    callDocId: myUserId, 
                    isVideoCall: isVideo,
                  ),
                ),
              );
            },
            child: const Text("Answer", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    ).then((_) {
      _stopRinging();
    });
  }

  void _stopRinging() {
    _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _isRinging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}