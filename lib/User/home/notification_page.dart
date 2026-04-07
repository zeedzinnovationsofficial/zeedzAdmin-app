import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    markAllAsRead();
  }

  Future<void> markAllAsRead() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user!.id);
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: FutureBuilder(
        future: supabase
            .from('notifications')
            .select()
            .eq('user_id', user!.id)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = List<Map<String, dynamic>>.from(
            snapshot.data as List,
          );

          if (notifications.isEmpty) {
            return const Center(child: Text("No Notifications"));
          }

          print("Logged user ID: ${user.id}");

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.01,
            ),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];

              return Container(
                margin: EdgeInsets.symmetric(vertical: size.height * 0.008),
                padding: EdgeInsets.all(size.width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    n['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: size.height * 0.005),
                    child: Text(n['message']),
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
