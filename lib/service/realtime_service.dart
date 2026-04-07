import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class RealtimeService {
  static final supabase = Supabase.instance.client;
  static final player = AudioPlayer();

  static String? currentUser;
  static dynamic lastMessageId;

  static void start() {
    currentUser = supabase.auth.currentUser?.id;

    final channel = supabase.channel('global-messages');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            final newMessage = payload.newRecord;

            print("🌍 GLOBAL MESSAGE: $newMessage");

            final senderId = newMessage['sender_id'];

            /// ❌ skip sender
            if (senderId == currentUser) return;

            /// ❌ avoid duplicate
            if (newMessage['id'] == lastMessageId) return;
            lastMessageId = newMessage['id'];

            /// 🔥 GET SENDER NAME
            final userData = await supabase
                .from('users')
                .select('name')
                .eq('id', senderId)
                .maybeSingle();

            final senderName = userData?['name'] ?? "User";

            /// 🔥 HANDLE MESSAGE TYPE
            String displayMessage;

            if (newMessage['type'] == 'audio') {
              displayMessage = "🎤 Voice message";
            } else {
              displayMessage = newMessage['message'] ?? "New message";
            }

            /// 🔔 PLAY SOUND (only if app in foreground)
            if (isAppInForeground && !isChatPageOpen) {
              await player.play(AssetSource('notification.mp3'));
            }

            /// 🔥 SHOW OVERLAY (only if not in chat page)

            /// 🔥🔥🔥 SEND PUSH NOTIFICATION (FINAL FIX)
            final users = await supabase
                .from('users')
                .select('onesignal_id, id');
            final currentUserId = supabase.auth.currentUser?.id;
            for (var u in users) {
              /// ❌ skip sender
              if (u['id'] == currentUserId) continue;

              final playerId = u['onesignal_id'];

              print("🚀 Sending notification to: $playerId");

              if (playerId != null && playerId.toString().isNotEmpty) {}
            }
          },
        )
        .subscribe((status, error) {
          print("🔥 GLOBAL STATUS: $status");
        });
  }
}
