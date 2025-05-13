import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_message.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 250),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: message.isUser ? Colors.deepPurple[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.imageData != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // תצוגת התמונה בגדול בלחיצה
                          showDialog(
                            context: context,
                            builder:
                                (context) => Dialog(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.memory(
                                        message.imageData!,
                                        fit: BoxFit.contain,
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('סגור'),
                                      ),
                                    ],
                                  ),
                                ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            message.imageData!,
                            width: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: Icon(
                            Icons.download,
                            size: 20,
                            color: Colors.deepPurple,
                          ),
                          tooltip: 'הורד תמונה',
                          onPressed: () async {
                            final result = await FilePicker.platform.saveFile(
                              dialogTitle: 'Save Image',
                              fileName: 'chat_image.png',
                            );
                            if (result != null) {
                              final file = File(result);
                              await file.writeAsBytes(message.imageData!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Image saved to $result'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                if (message.imageData != null) SizedBox(height: 8),
                Text(
                  message.text,
                  style: GoogleFonts.assistant(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 10, color: Colors.grey[600]),
                    SizedBox(width: 3),
                    Text(
                      '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.assistant(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
