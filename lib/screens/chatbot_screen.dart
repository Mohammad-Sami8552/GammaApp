import 'dart:convert';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

class MetaAIScreen extends StatefulWidget {
  const MetaAIScreen({super.key});
  @override
  State<MetaAIScreen> createState() => _MetaAIScreenState();
}

class _MetaAIScreenState extends State<MetaAIScreen> {
  final ChatUser _currentUser = ChatUser(id: '1', firstName: 'User');
  final ChatUser _metaAI = ChatUser(
    id: '2',
    firstName: 'Meta AI',
    profileImage:
        "https://upload.wikimedia.org/wikipedia/commons/a/ab/Meta-Logo.png",
  );

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final String _apiKey = dotenv.env['GROQ_API_KEY']!;

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    setState(() {
      _messages.insert(0, chatMessage);
      _isTyping = true;
    });

    try {
      List<Map<String, String>> history = _messages.reversed.map((m) {
        return {
          "role": m.user.id == '1' ? "user" : "assistant",
          "content": m.text,
        };
      }).toList();

      //Defining the request
      var url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

      var body = jsonEncode({
        "model": "openai/gpt-oss-20b",
        "messages": history,
        'temperature': 0.7,
      });

      //Send Request
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        // 1. Decode the data
        var data = jsonDecode(response.body);

        // 2. DEBUG PRINT: See exactly what the API sent back
        print("API Response: ${response.body}");

        // 3. Safe Parsing using '?' and '??'
        // This says: "Try to get content. If anything is missing/null, return a default string."
        String aiResponse =
            data['choices']?[0]?['message']?['content'] ??
            "I'm not sure how to answer that.";

        // 4. Create the message
        ChatMessage aiMessage = ChatMessage(
          user: _metaAI,
          createdAt: DateTime.now(),
          text: aiResponse,
        );

        setState(() {
          _messages.insert(0, aiMessage);
        });
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error sending message: $e");
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.circle_outlined, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text("Meta AI", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Color(0xFF5FAFD3),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
          ),
        ),
        child: DashChat(
          currentUser: _currentUser,
          onSend: _sendMessage,
          typingUsers: _isTyping ? [_metaAI] : [],
          messages: _messages,
          scrollToBottomOptions: ScrollToBottomOptions(disabled: false),
          messageOptions: MessageOptions(
            marginDifferentAuthor: EdgeInsets.only(top: 30),
            maxWidth: screenWidth * 0.8,
            showOtherUsersAvatar: false,
            containerColor: Colors.white,
            currentUserContainerColor: const Color(0xFFDCF8C6),
            textColor: Colors.black,
            messageTextBuilder: (message, [previousMessage, nextMessage]) {
              return MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.black),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          inputOptions: InputOptions(
            sendButtonBuilder: (onSend) {
             return  IconButton(
                    onPressed: onSend,
                    icon: const Icon(Icons.send, size: 30),
                    color: Color.fromARGB(255, 100, 13, 240)
                  );
            },
            inputDecoration: InputDecoration(
              hintText: "Ask Meta AI anything...",
              hintStyle: Theme.of(context).textTheme.labelMedium,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              filled: true,
              fillColor: Color(0xFFF2F2F2),
              contentPadding: EdgeInsets.all(12),
            ),
            sendOnEnter: true,
            alwaysShowSend: true,
          ),
        ),
      ),
    );
  }
}
