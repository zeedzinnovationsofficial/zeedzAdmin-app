import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {

  static const String appId = "ae86ab43-3a9b-4c7a-92c2-831be9a91ad9";
  static const String restApiKey = "os_v2_app_v2dkwqz2tnghvewcqmn6tki23ec5tm5umouuilmwnbjzxhnl7xb42rvz7zqlavb7ke63gtvfy45qiwfk36nrsldmj7hnsaxknbrnjuy";

  static Future<void> sendMessageNotification({
  required String title,
  required String message,
  required String senderId,
}) async {
  

   final response = await http.post(
  Uri.parse("https://onesignal.com/api/v1/notifications"),
  headers: {
    "Content-Type": "application/json; charset=utf-8",
    "Authorization": "Basic $restApiKey",
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