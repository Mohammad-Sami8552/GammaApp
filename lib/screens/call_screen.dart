import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

class CallScreen extends StatefulWidget {
  final String callID;
  final String userId;
  final String userName;
  final bool isVideoCall;
  final String callDocId;

  const CallScreen({
    super.key,
    required this.callID,
    required this.userId,
    required this.userName,
    required this.isVideoCall,
    required this.callDocId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Widget? _localView;
  Widget? _remoteView;
  bool _isMicOn = true;
  bool _isFrontCamera = true;
  String myUserId = "";
  String myUserName = "";
  bool _isEngineActive = false;
  StreamSubscription<DocumentSnapshot>? _callStatusStream;

  // --- DRAGGABLE VARIABLES ---
  double _localViewTop = 50;
  double _localViewRight = 20;
  // ---------------------------

  @override
  void initState() {
    super.initState();
    myUserId = kIsWeb ? "web_test_user" : widget.userId;
    myUserName = kIsWeb ? "Web Master" : widget.userName;
    startCall();
    listenForCallEnd();
  }

  void listenForCallEnd() {
    _callStatusStream = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callDocId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['status'] == 'ended') {
        if (mounted) Navigator.pop(context);
      }
    });
  }

  Future<String> fetchToken(String userId) async {
    try {
      String baseUrl = "https://zegotokenserver.vercel.app/api"; 
      final response = await http.get(Uri.parse("$baseUrl?userId=$userId"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }

  @override
  void dispose() {
    _callStatusStream?.cancel();
    if (_isEngineActive) {
      ZegoExpressEngine.instance.logoutRoom();
      ZegoExpressEngine.destroyEngine();
    }
    super.dispose();
  }

  Future<void> startCall() async {
    try {
      if (!kIsWeb) {
        await [Permission.camera, Permission.microphone].request();
      }

      String? appSign = kIsWeb 
          ? null 
          : dotenv.env["APP_SIGN"]; 

      await ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
        int.parse(dotenv.env["ZEGO_CRED"]!),
        ZegoScenario.Default,
        appSign: appSign,
      ));
      
      _isEngineActive = true;
      ZegoExpressEngine.instance.enableCamera(widget.isVideoCall);

      ZegoExpressEngine.onRoomStreamUpdate = (roomID, updateType, streamList, extendedData) {
        if (updateType == ZegoUpdateType.Add) {
          startPlayingStream(streamList[0].streamID);
        }
      };
      if(widget.isVideoCall)
      {
      await startPreview();
      }

      String token = "";
      if (kIsWeb) {
         token = await fetchToken(myUserId);
         if (token.isEmpty) return;
      }

      ZegoUser user = ZegoUser(myUserId, myUserName);
      ZegoRoomConfig config = ZegoRoomConfig.defaultConfig();
      config.isUserStatusNotify = true;
      if (kIsWeb) config.token = token;

      ZegoRoomLoginResult result = await ZegoExpressEngine.instance.loginRoom(widget.callID, user, config: config);

      if (!mounted) return; 

      if (result.errorCode == 0) {
        await ZegoExpressEngine.instance.startPublishingStream(myUserId);
      } 

    } catch (e) {
      return;
    }
  }

  Future<void> startPreview() async {
    Widget? view = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPreview(canvas: canvas);
    });
    setState(() { _localView = view; });
  }

  Future<void> startPlayingStream(String streamID) async {
    Widget? view = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    });
    setState(() { _remoteView = view; });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for boundary checks
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Remote View (Full Screen)
          Positioned.fill(
            child: widget.isVideoCall? ( _remoteView ?? Container(
              color: Colors.black,
              child: const Center(
                child: Text("Waiting for partner...", style: TextStyle(color: Colors.white, fontSize: 18)))
              )): Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),),
                const SizedBox(height: 10),
                const Text("Voice Call", style: TextStyle(color: Colors.grey, fontSize: 16))
              ],
            )
          ),

          // 2. Draggable Local View
          if(widget.isVideoCall) 
          Positioned(
            top: _localViewTop,
            right: _localViewRight,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  // Update position based on drag (delta)
                  // Note: We subtract delta.dx because we are positioning from the RIGHT
                  _localViewTop += details.delta.dy;
                  _localViewRight -= details.delta.dx;

                  // Simple Boundary Checks (Keep it on screen)
                  if (_localViewTop < 0) _localViewTop = 0;
                  if (_localViewTop > size.height - 150) _localViewTop = size.height - 150;
                  if (_localViewRight < 0) _localViewRight = 0;
                  if (_localViewRight > size.width - 100) _localViewRight = size.width - 100;
                });
              },
              child: SizedBox(
                width: 100, 
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      border: Border.all(color: Colors.white, width: 1), // White border to see it better
                    ),
                    child: _localView ?? const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
          ),


          // 3. Control Buttons (Bottom)
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() { _isMicOn = !_isMicOn; });
                    ZegoExpressEngine.instance.muteMicrophone(!_isMicOn);
                  },
                  icon: Icon(_isMicOn ? Icons.mic : Icons.mic_off),
                  style: IconButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(12)),
                ),
                IconButton(
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('calls')
                        .doc(widget.callDocId)
                        .update({'status': 'ended'});
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.call_end, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(16)),
                ),
                if(widget.isVideoCall)
                IconButton(
                  onPressed: () {
                    ZegoExpressEngine.instance.useFrontCamera(!_isFrontCamera);
                    setState(() { _isFrontCamera = !_isFrontCamera; });
                  },
                  icon: const Icon(Icons.switch_camera),
                  style: IconButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}