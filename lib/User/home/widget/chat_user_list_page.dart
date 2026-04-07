import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';

class ChatUserListPage extends StatefulWidget {
  const ChatUserListPage({super.key});

  @override
  State<ChatUserListPage> createState() => _ChatUserListPageState();
}

class _ChatUserListPageState extends State<ChatUserListPage> {
  final supabase = Supabase.instance.client;

  List users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final currentUser = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('chat_permissions')
        .select('receiver_id')
        .eq('sender_id', currentUser)
        .eq('can_send', true);

    List ids = res.map((e) => e['receiver_id']).toList();

    if (ids.isEmpty) return;

    final userData = await supabase
        .from('users')
        .select()
        .inFilter('id', ids);

    setState(() {
      users = userData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: users.isEmpty
          ? const Center(child: Text("No chats available"))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user['name'] ?? ''),
                  subtitle: Text(user['role'] ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                        
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}