import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> sendLeaveNotification({
  required String title,
  required String message,
}) async {

  const appId = "ae86ab43-3a9b-4c7a-92c2-831be9a91ad9";
  const restApiKey = "os_v2_app_v2dkwqz2tnghvewcqmn6tki23ecfo5bh4esu475z7xzfiwpp5e5mnxupuelpjtwhmsrz4vwmcfolrrror7kvya5exixzpq3ap6bufei";

  final response = await http.post(
    Uri.parse("https://onesignal.com/api/v1/notifications"),
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Authorization": "Basic $restApiKey",
    },
    body: jsonEncode({
      "app_id": appId,

      // 👇 send to multiple roles
      "filters": [
        {"field": "tag", "key": "role", "relation": "=", "value": "hr"},
        {"operator": "OR"},
        {"field": "tag", "key": "role", "relation": "=", "value": "admin"},
        {"operator": "OR"},
        {"field": "tag", "key": "role", "relation": "=", "value": "superadmin"},
      ],

      "headings": {"en": title},
      "contents": {"en": message},
    }),
  );

  print("STATUS CODE = ${response.statusCode}");
  print("RESPONSE = ${response.body}");
}
