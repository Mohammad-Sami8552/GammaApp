// This module is not integrated for now in future will se to do this feature also
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadService {
  final String cloudName = "dejdnxjgs";
  final String uploadPreset = "gamma_app_preset";
  Future<String?> pickAndUploadVideo() async {
    //Pick Video
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if(video == null) return null;

    File videoFile = File(video.path);

    try {
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/dejdnxjgs/video/upload");

      var request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', videoFile.path));

      var response = await request.send();
      if(response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        String videoUrl = json['secure_url'];

        await _saveToFirestore(videoUrl);
        return "Success";
      } else {
        print("Upload Failed: ${response.statusCode}");
        return null;
      }
    

    } catch(e) {
      print("Error: $e");
      return null;
    }
  }

  Future<void> _saveToFirestore(String videoUrl) async {
    User? user = FirebaseAuth.instance.currentUser;
    if(user == null) return;

    await FirebaseFirestore.instance.collection('videos').add({
      'url': videoUrl,
      'username': user.email!.split('@')[0],
      'caption': 'Check out my new video!',
      'likes': 0,
      'timestamp': FieldValue.serverTimestamp()
    });

  }

}