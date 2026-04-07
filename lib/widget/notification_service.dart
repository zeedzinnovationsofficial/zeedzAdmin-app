import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static Future<void> sendNotification({
    required String playerId,
    required String title,
    required String body,
  }) async {
    await Supabase.instance.client.functions.invoke(
      'send-notification',
      body: {'playerId': playerId, 'title': title, 'body': body},
    );
  }
}
