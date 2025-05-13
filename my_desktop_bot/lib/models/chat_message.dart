import 'dart:typed_data';
import 'dart:convert';
import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 1)
class ChatMessage {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final bool isUser;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final Uint8List? imageData;

  @HiveField(4)
  final String? id;

  @HiveField(5)
  final String? conversationId;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageData,
    this.id,
    this.conversationId,
  });
}
