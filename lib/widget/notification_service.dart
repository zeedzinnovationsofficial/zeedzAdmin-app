import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class NotificationService {

  static final appId = dotenv.env['ONESIGNAL_APP_ID']!;
static final restApiKey = dotenv.env['ONESIGNAL_REST_API_KEY']!;

  static Future<void> sendMessageNotification({
  required String title,
  required String message,
  required String senderId,
}) 
async {  
   final response = await http.post(
   Uri.parse("https://api.onesignal.com/notifications"),
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Authorization": "Key $restApiKey",
    },
  body: jsonEncode({
    "app_id": appId,
    "filters": [
      {
        "field": "tag",
        "key": "user_id",
        "relation": "!=",
        "value": senderId
      }
    ],
    "headings": {"en": title},
    "contents": {"en": message},
  }),
);

print("STATUS = ${response.statusCode}");
print("BODY = ${response.body}");
    
  }
}