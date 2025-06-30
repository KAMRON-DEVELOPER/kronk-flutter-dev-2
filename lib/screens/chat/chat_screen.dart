import 'package:flutter/material.dart';
import 'package:kronk/models/user_model.dart';

class ChatScreen extends StatelessWidget {
  final UserSearchModel participant;

  const ChatScreen({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('data'), centerTitle: true),
      body: Center(child: Text(participant.name)),
    );
  }
}
