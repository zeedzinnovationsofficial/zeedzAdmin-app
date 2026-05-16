import 'dart:async';

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/User/home/widget/message_info_page.dart';
import 'package:zeedz_attendance/main.dart';
import 'package:zeedz_attendance/widget/notification_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Future<void> markAllAsRead() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user!.id);
  }

  final supabase = Supabase.instance.client;
  late String receiverId;
  final ScrollController scrollController = ScrollController();
  final player = AudioPlayer();
  Map<String, String> userMap = {};
  String? lastMessageId;
  int seconds = 0;
  bool isRecordingUI = false;
  int recordDuration = 0;
  Timer? timer;
  String? recordedFilePath;
  String get currentUser => supabase.auth.currentUser!.id;
  List<double> waveData = [];
  bool canSend = false;
  String? userRole;
  final TextEditingController messageController = TextEditingController();
  late RealtimeChannel channel;

  void startTimer() {
    recordDuration = 0;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => recordDuration++);
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    markAllAsRead();
    isChatPageOpen = true;
    markMessagesAsRead();
    initRecorder();
    loadCurrentUserRole();
    
    ensureUserExists();
    loadUsers();

    messageController.addListener(() {
      setState(() {});
    });
    channel = supabase.channel('messages_channel');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            print("🔥 CALLBACK TRIGGERED");

            final newMessage = payload.newRecord;

            print("DATA: $newMessage");

            /// ❌ skip sender
            if (newMessage['sender_id'] != currentUser) {
              await supabase
                  .from('messages')
                  .update({'status': 'delivered'})
                  .eq('id', newMessage['id']);
            }
          },
        )
        .subscribe((status, error) {
          print("Realtime status: $status");
        });
  }

  @override
  void dispose() {
    channel.unsubscribe();
    recorder.closeRecorder();
    isChatPageOpen = false;
    messageController.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> loadCurrentUserRole() async {
    final res = await supabase
        .from('users')
        .select('role')
        .eq('id', currentUser)
        .single();

    setState(() {
      userRole = res['role'];
    });
  }

  Future<void> ensureUserExists() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    await supabase.from('users').upsert({
      'id': user.id, //  MUST match sender_id
      'name': user.userMetadata?['name'] ?? "User",
      'phone': user.phone ?? "0000000000",
      'role': user.userMetadata?['role'] ?? "employee",
    });
  }

  Future<void> loadUsers() async {
    final res = await supabase.from('users').select();

    for (var user in res) {
      userMap[user['id']] = user['name'];
    }

    setState(() {});
  }

 
  
  ///  SEND MESSAGE (NO receiver_id)
 Future<void> sendMessage(String text) async {
  if (text.trim().isEmpty) return;

  final currentUser = supabase.auth.currentUser!.id;

  // 🔥 get current user role
  final roleRes = await supabase
      .from('users')
      .select('role,name')
      .eq('id', currentUser)
      .single();

  final role = roleRes['role'];
  print("Current role: $role"); 
  final senderName = roleRes['name'] ?? "User";

  // ✅ allow only admin / hr / superadmin
  if (role != 'admin' && role != 'hr' && role != 'superadmin') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Only Admin / HR / Superadmin can send messages"),
      ),
    );
    return;
  }

  await supabase.from('messages').insert({
    'sender_id': currentUser,
    'message': text,
    'status': 'sent',
    'seen_by': [],
  });

  messageController.clear();

  final users = await supabase.from('users').select('onesignal_id, id');

  for (var u in users) {
    if (u['id'] == currentUser) continue;

    final playerId = u['onesignal_id'];

    if (playerId != null && playerId.toString().isNotEmpty) {
      await NotificationService.sendNotification(
        playerId: playerId,
        title: senderName,
        body: text,
      );
    }
  }
} Future<void> uploadVoice(String path) async {
    try {
      final file = File(path);
      final fileName = "voice_${DateTime.now().millisecondsSinceEpoch}.m4a";

      /// 🔥 UPLOAD AUDIO
      await supabase.storage.from('chat-audio').upload(fileName, file);

      final url = supabase.storage.from('chat-audio').getPublicUrl(fileName);

      final currentUser = supabase.auth.currentUser!.id;

      /// 🔥 GET SENDER NAME
      final user = await supabase
          .from('users')
          .select('name')
          .eq('id', currentUser)
          .maybeSingle();

      final senderName = user?['name'] ?? "User";

      /// 🔥 INSERT MESSAGE
      await supabase.from('messages').insert({
        'sender_id': currentUser,

        'message': url,
        'type': 'audio',
        'duration': seconds, // ✅ ADD THIS
        'status': 'sent',
        'seen_by': [],
      });

      /// 🔥 GET RECEIVER ONESIGNAL ID
      final users = await supabase.from('users').select('onesignal_id, id');

      for (var u in users) {
        if (u['id'] == currentUser) continue;

        final playerId = u['onesignal_id'];

        if (playerId != null && playerId.toString().isNotEmpty) {
          await NotificationService.sendNotification(
            playerId: playerId,
            title: senderName,
            body: "🎤 Voice message",
          );
        }
      }

      print("✅ Voice sent + Notification sent");
    } catch (e) {
      print("❌ Upload error: $e");
    }
  }

  /// SETTINGS
  void openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return FutureBuilder(
          future: Future.wait([
            supabase.from('users').select(),
            supabase.from('chat_permissions').select(),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data![0] as List;
            final permissions = snapshot.data![1] as List;

            Map<String, bool> selectedUsers = {};

            /// LOAD EXISTING PERMISSION
            for (var user in users) {
              if (user['id'] == currentUser) continue;

              final perm = permissions.cast<Map<String, dynamic>>().firstWhere(
                (p) => p['user_id'] == user['id'],
                orElse: () => {},
              );

              selectedUsers[user['id']] = perm.isNotEmpty
                  ? perm['can_send'] == true
                  : false;
            }

            return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              Navigator.pop(context); //  POP BUTTON
                            },
                          ),
                          SizedBox(width: 70),
                          Center(
                            child: const Text(
                              "Message Permissions",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(),

                      ///  USER LIST (NO CHECKBOX)
                      Expanded(
                        child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];

                            if (user['id'] == currentUser) {
                              return const SizedBox();
                            }

                            bool isAllowed = selectedUsers[user['id']] ?? false;

                            return ListTile(
                              title: Text(user['name'] ?? ''),
                              subtitle: Text(user['role'] ?? ''),
                              trailing: Icon(
                                isAllowed ? Icons.check_circle : Icons.cancel,
                                color: isAllowed ? Colors.green : Colors.red,
                              ),

                              ///  CLICK TO CHANGE PERMISSION
                              onTap: () async {
                                final action = await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(user['name']),
                                    content: const Text(
                                      "Change message permission",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, "cancel"),
                                        child: const Text("Cancel Permission"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, "allow"),
                                        child: const Text("Allow"),
                                      ),
                                    ],
                                  ),
                                );

                                if (action == null) return;

                                bool newValue = action == "allow";

                                ///  UPDATE UI
                                setModalState(() {
                                  selectedUsers[user['id']] = newValue;
                                });

                                /// UPDATE DATABASE INSTANTLY
                                await supabase.from('chat_permissions').upsert(
                                  {'user_id': user['id'], 'can_send': newValue},
                                  onConflict: 'user_id', //  VERY IMPORTANT
                                );
                              },
                            );
                          },
                        ),
                      ),

                      ///  DONE BUTTON (FAST CLOSE)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context); //  instant close

                           

                            ///  SMALL SNACKBAR (FAST)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Permissions Updated ✅"),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Text("Done"),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Page"),
        backgroundColor: AppColors.white,
        actions: [
          if (userRole == 'admin' ||
              userRole == 'superadmin' ||
              userRole == 'hr')
            PopupMenuButton(
              onSelected: (value) {
                if (value == 'settings') openSettings();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'settings', child: Text("Settings")),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (isRecording)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fiber_manual_record, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    "Recording... ${seconds}s",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          ///  MESSAGE LIST (ALL USERS)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  for (var msg in snapshot.data!) {
                    if (msg['sender_id'] != currentUser) {
                      final seenBy = List.from(msg['seen_by'] ?? []);

                      if (!seenBy.contains(currentUser)) {
                        markAsSeen(msg['id']); // 🔥 realtime seen update
                      }
                    }
                  }
                }
                final messages = snapshot.data!;
                // final unreadMessages = snapshot.data!.where((msg) {
                //   final seenBy = List.from(msg['seen_by'] ?? []);
                //   return msg['sender_id'] != currentUser &&
                //       !seenBy.contains(currentUser);
                // }).toList();
                // WidgetsBinding.instance.addPostFrameCallback((_) {
                //   scrollToBottom();
                // });
                return ListView.builder(
                  controller: scrollController,
                  reverse: true, // latest at bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];

                    bool isMe = msg['sender_id'] == currentUser;
                    if (!isMe && msg['status'] != 'seen') {
                      markAsSeen(msg['id']);
                    }
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          if (msg['sender_id'] != currentUser) return;

                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: "Options",
                            barrierColor: Colors.black.withOpacity(0.4),
                            transitionDuration: const Duration(
                              milliseconds: 250,
                            ),

                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                                  return Center(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Container(
                                        width: 250,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            /// 🔹 INFO
                                            ListTile(
                                              leading: const Icon(Icons.info),
                                              title: const Text("Info"),
                                              onTap: () {
                                                Navigator.pop(context);

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        MessageInfoPage(
                                                          message: msg,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),

                                            /// 🔴 DELETE
                                            ListTile(
                                              leading: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              title: const Text("Delete"),
                                              onTap: () {
                                                Navigator.pop(context);
                                                showDeleteDialog(msg);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },

                            /// 🔥 ANIMATION
                            transitionBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return ScaleTransition(
                                    scale: CurvedAnimation(
                                      parent: animation,
                                      curve: Curves
                                          .easeOutBack, // 🔥 nice pop effect
                                    ),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                          );
                        },
                        child: IntrinsicWidth(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.5,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color.fromARGB(255, 123, 255, 127)
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// NAME
                                Text(
                                  isMe
                                      ? "You"
                                      : (userMap[msg['sender_id']] ??
                                            "Unknown"),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isMe ? Colors.black : Colors.black54,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                /// MESSAGE
                                msg['type'] == 'audio'
                                    ? audioBubble(
                                        msg['message'],
                                        msg['duration'] ?? 0,
                                      )
                                    : Flexible(
                                        child: Text(
                                          msg['message'] ?? '',
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.black
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: 4),

                                ///  TIME
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      /// 🕒 TIME
                                      Text(
                                        DateFormat('hh:mm a').format(
                                          DateTime.parse(
                                            msg['created_at'],
                                          ).toLocal(),
                                        ),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.black
                                              : Colors.black54,
                                        ),
                                      ),

                                      /// ✅ TICKS (ONLY FOR SENDER)
                                      if (isMe) ...[
                                        const SizedBox(width: 4),

                                        Icon(
                                          msg['status'] == 'sent'
                                              ? Icons
                                                    .check // ✓
                                              : Icons.done_all, // ✓✓
                                          size: 16,
                                          color: msg['status'] == 'seen'
                                              ? Colors
                                                    .blue // 🔵 seen
                                              : Colors.grey, // normal
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// INPUT
          Opacity(
            opacity:1,
            child: isRecordingUI
                ? buildVoiceUI() // WhatsApp UI
                : buildNormalInput(), // your current UI
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget buildNormalInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 190, 190, 190),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      keyboardType: TextInputType.multiline,
                      minLines: 1, // start with 1 line
                      maxLines: 5, // grow up to 5 lines (like WhatsApp)
                      textInputAction:
                          TextInputAction.newline, // allow next line
                      decoration: InputDecoration(
                        hintText: (userRole == 'admin' || userRole == 'hr' || userRole == 'superadmin')
                         ? "Type a message"
                         : "Only admin can send",
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  /// MIC BUTTON
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              if (messageController.text.trim().isNotEmpty) {
  await sendMessage(messageController.text);
} else {
                /// 🎤 VOICE LOGIC
                if (!isRecorderReady) {
                  await initRecorder();
                }

                if (isRecording) {
                  await stopRecording();
                } else {
                  await startRecording();
                }
              }
            },

            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                messageController.text.trim().isNotEmpty
                    ? Icons.send
                    : isRecording
                    ? Icons.stop
                    : Icons.mic,
                key: ValueKey(
                  messageController.text.isNotEmpty.toString() +
                      isRecording.toString(),
                ),
                color: Colors.green,
              ),
            ),
          ),

          /// SEND TEXT
          // IconButton(
          //   icon:  Icon(
          //     messageController.text.isNotEmpty?
          //     Icons.send: isRecording ? Icons.stop : Icons.mic, color: Colors.green),

          //   onPressed:
          //    messageController.text.isNotEmpty?
          //   canSend ? sendMessage : null,
          // ),
        ],
      ),
    );
  }

  bool isRecorderReady = false;

  Future<void> initRecorder() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      print("Mic permission denied ");
      return;
    }
    print("Permission status: $status");
    print("Recorder ready: $isRecorderReady");
    await recorder.openRecorder();
    isRecorderReady = true;

    print("Recorder READY ");

    setState(() {});
  }

  FlutterSoundRecorder recorder = FlutterSoundRecorder();
  bool isRecording = false;
  String? path;

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();

    if (!status.isGranted) {
      print("No mic permission ");
      return;
    }

    if (!isRecorderReady) {
      print("Recorder not ready ");
      return;
    }

    final dir = await getTemporaryDirectory();
    path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

    await recorder.startRecorder(
      toFile: path, // NO codec
    );
    waveData.clear(); // reset old waveform

    recorder.onProgress?.listen((event) {
      final level = event.decibels ?? 0.0;

      double normalized = (level + 50) / 50; // adjust sensitivity
      normalized = normalized.clamp(0.0, 1.0);

      setState(() {
        waveData.add(normalized);

        if (waveData.length > 30) {
          waveData.removeAt(0);
        }
      });
    });

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => seconds++);
    });

    setState(() {
      isRecording = true;
      isRecordingUI = true;
    });
  }

  Future<void> stopRecording() async {
    final result = await recorder.stopRecorder();

    print("STOP RESULT: $result");

    timer?.cancel();

    setState(() {
      isRecording = false;
      seconds = 0;
    });

    if (result != null) {
      recordedFilePath = result;
      print(" File saved: $recordedFilePath");
    }
  }

  Future<void> sendVoice() async {
    print("Send clicked");
    final roleRes = await supabase
    .from('users')
    .select('role')
    .eq('id', currentUser)
    .single();

final role = roleRes['role'];

bool allowed =
    role == 'admin' ||
    role == 'hr' ||
    role == 'superadmin';

    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Admin restricted messaging")),
      );
      return;
    }

    /// AUTO STOP recording FIRST
    if (isRecording) {
      print("Stopping before sending...");
      await stopRecording();
    }

    print("Path after stop: $recordedFilePath");

    if (recordedFilePath == null) {
      print(" No file found");
      return;
    }
    await uploadVoice(recordedFilePath!);

    setState(() {
      isRecording = false;
      isRecordingUI = false;
      recordedFilePath = null;
      seconds = 0;
    });

    print(" Voice sent");
  }

  void deleteVoice() async {
    ///  STOP recorder if running
    if (isRecording) {
      await recorder.stopRecorder();
    }

    ///  STOP timer
    timer?.cancel();

    setState(() {
      isRecording = false;
      isRecordingUI = false;
      recordedFilePath = null;
      seconds = 0;
    });
  }

  Widget audioBubble(String url, int duration) {
    bool isPlaying = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
              ),
              onPressed: () async {
                if (isPlaying) {
                  await player.stop();
                } else {
                  await player.play(UrlSource(url));
                }
                setState(() => isPlaying = !isPlaying);
              },
            ),

            Row(
              children: List.generate(
                15,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 3,
                  height: (index % 5 + 5).toDouble(),
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(width: 6),

            /// 🎯 DURATION TEXT
            Text(
              formatDuration(duration),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  String formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  Widget buildVoiceUI() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: const Color.fromARGB(0, 0, 0, 0),
      child: Row(
        children: [
          ///  DELETE
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            onPressed: deleteVoice,
          ),

          ///  PLAY
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.black),
            onPressed: () async {
              if (recordedFilePath != null) {
                await player.play(DeviceFileSource(recordedFilePath!));
              }
            },
          ),

          /// WAVE
          Expanded(
            child: Row(
              children: List.generate(
                20,
                (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: (i % 5 + 5).toDouble(),
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),

          ///  TIMER
          Text(
            formatTime(seconds),
            style: const TextStyle(color: Colors.black),
          ),

          const SizedBox(width: 10),

          ///  SEND
          CircleAvatar(
            backgroundColor: Colors.green,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendVoice,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteMessage(String id, String? audioUrl) async {
    try {
      await supabase.from('messages').delete().eq('id', id);

      if (audioUrl != null && audioUrl.contains('chat-audio')) {
        final fileName = audioUrl.split('/').last;
        await supabase.storage.from('chat-audio').remove([fileName]);
      }

      print(" Message deleted");
    } catch (e) {
      print(" Delete error: $e");
    }
  }

  void showDeleteDialog(Map msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Message"),
        content: const Text("Do you want to delete this message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              await deleteMessage(
                msg['id'],
                msg['type'] == 'audio' ? msg['message'] : null,
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> markAsSeen(String messageId) async {
    final userId = currentUser;

    final res = await supabase
        .from('messages')
        .select('seen_by')
        .eq('id', messageId)
        .single();

    List seenList = res['seen_by'] ?? [];

    if (!seenList.contains(userId)) {
      seenList.add(userId);

      await supabase
          .from('messages')
          .update({'seen_by': seenList, 'status': 'seen'})
          .eq('id', messageId);
    }
  }

  Future<void> markMessagesAsRead() async {
    final userId = supabase.auth.currentUser!.id;

    final messages = await supabase
        .from('messages')
        .select('id, sender_id, seen_by');

    for (var msg in messages) {
      ///  skip my own messages
      if (msg['sender_id'] == userId) continue;

      List seen = List.from(msg['seen_by'] ?? []);

      if (!seen.contains(userId)) {
        seen.add(userId);

        await supabase
            .from('messages')
            .update({'seen_by': seen, 'status': 'seen'})
            .eq('id', msg['id']);
      }
    }
  }
}
