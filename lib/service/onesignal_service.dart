import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<void> sendLeaveNotification({
  required String title,
  required String message,
})
 async {
 final appId = dotenv.env['ONESIGNAL_APP_ID']!;
  final restApiKey = dotenv.env['ONESIGNAL_REST_API_KEY']!;

  final response = await http.post(
   Uri.parse("https://api.onesignal.com/notifications"),
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Authorization": "Key $restApiKey",
    },
    body: jsonEncode({
      "app_id": appId,      
      "filters": [
        {"field": "tag", "key": "role", "relation": "!=", "value": "intern"},
        {"operator": "AND"}, 
        {"field": "tag", "key": "role", "relation": "!=", "value": "employee"}
      ],
      "headings": {"en": title},
      "contents": {"en": message},
    }),
  );

  print("STATUS CODE = ${response.statusCode}");
  print("RESPONSE = ${response.body}");
}
