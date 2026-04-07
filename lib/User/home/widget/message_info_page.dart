import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageInfoPage extends StatefulWidget {
  final Map message;

  const MessageInfoPage({super.key, required this.message});

  @override
  State<MessageInfoPage> createState() => _MessageInfoPageState();
}

class _MessageInfoPageState extends State<MessageInfoPage> {
  final supabase = Supabase.instance.client;

  List users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final res = await supabase.from('users').select();
    setState(() => users = res);
  }

  String formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final seenBy = List.from(widget.message['seen_by'] ?? []);

    /// 👇 Delivered users = all except sender
    final deliveredUsers = users
        .where((u) => u['id'] != widget.message['sender_id'])
        .toList();

    final seenUsers = users.where((u) => seenBy.contains(u['id'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.message['type'] == 'audio'
              ? "🎤 Voice Message Info"
              : "Message Info",
        ),
      ),
      body: users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                /// 🔹 MESSAGE PREVIEW
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Message:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),

                      widget.message['type'] == 'audio'
                          ? Text(
                              "🎤 Voice Message (${formatDuration(widget.message['duration'] ?? 0)})",
                            )
                          : Text(widget.message['message'] ?? ''),
                    ],
                  ),
                ),

                /// 🔵 SEEN SECTION
                if (seenUsers.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "Seen",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  ...seenUsers.map((user) {
                    return ListTile(
                      leading: CircleAvatar(child: Text(user['name'][0])),
                      title: Text(user['name']),
                      trailing: const Icon(Icons.done_all, color: Colors.blue),
                    );
                  }).toList(),
                ],

                /// ⚫ DELIVERED SECTION
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    "Delivered",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),

                ...deliveredUsers.map((user) {
                  final isSeen = seenBy.contains(user['id']);

                  return ListTile(
                    leading: CircleAvatar(child: Text(user['name'][0])),
                    title: Text(user['name']),
                    trailing: Icon(
                      Icons.done_all,
                      color: isSeen ? Colors.blue : Colors.grey,
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}
