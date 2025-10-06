import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swift_chat/models/message_model.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/utils/file_picker_helper.dart';
import 'package:swift_chat/utils/mapping.dart';
import 'package:swift_chat/utils/message_helper.dart';
import 'package:swift_chat/utils/presence_service.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:pocketbase/pocketbase.dart';

class ChatPage extends StatefulWidget {
  final UserModel receiver;
  const ChatPage({super.key, required this.receiver});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  List<RecordModel> messages = [];
  List<File> files = [];
  final _pb = PBClient.instance;
  late String chatId;
  late Function unsubscribe;

  bool _showAttachmentOptions = false;

  @override
  void initState() {
    super.initState();
    initChat();
  }

  void initChat() async {
    final senderId = _pb.authStore.record!.id;
    final receiverId = widget.receiver.id;
    chatId = getChatId(senderId, receiverId);

    try {
      await _pb.collection('chats').getOne(chatId);
    } catch (_) {
      await createChat(senderId, receiverId);
    }

    unsubscribe = await _pb
        .collection('messages')
        .subscribe(
          "*",
          (event) {
            setState(() {
              messages.add(event.record!);
            });
          },
          filter: 'chat="$chatId"',
          expand: 'sender',
        );

    final initialMessages = await _pb
        .collection('messages')
        .getFullList(
          filter: 'chat="$chatId"',
          sort: '-created',
          expand: 'sender',
        );

    setState(() {
      messages = initialMessages;
    });
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }

  void sendMessageHandler() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final senderId = _pb.authStore.record!.id;
    final receiverId = widget.receiver.id;
    await sendMessage(text, senderId, receiverId);
    _controller.clear();
  }

  void toggleAttachmentOptions() {
    setState(() => _showAttachmentOptions = !_showAttachmentOptions);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.receiver;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textFieldColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;

    final sortedMessages = [...messages]..sort(
      (a, b) =>
          b.getStringValue('created').compareTo(a.getStringValue('created')),
    );

    return Scaffold(
      body: Stack(
        children: [
          // ===== Messages & UI =====
          Column(
            children: [
              // AppBar
              Container(
                padding: const EdgeInsets.fromLTRB(8, 36, 8, 8),
                color: textFieldColor,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                    ),
                    const SizedBox(width: 8),
                    ProfilePicture(
                      name: user.username,
                      radius: 20,
                      fontsize: 24,
                      img: user.avatarUrl,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        userOnlineWidget(
                          userId: user.id,
                          onlineWidget: Text(
                            "Online",
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: Colors.lightGreen),
                          ),
                          offlineWidget: (String lastSeen) {
                            final date =
                                lastSeen.isEmpty
                                    ? user.lastSeen
                                    : DateTime.tryParse(lastSeen);
                            if (date != null) {
                              return SizedBox(
                                width: 160,
                                child: FittedBox(
                                  child: Text("Last seen ${timeAgo(date)}"),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const FaIcon(FontAwesomeIcons.ellipsisVertical),
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showAttachmentOptions = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = MessageModel.fromRecord(
                          sortedMessages[index],
                        );
                        final isMe = msg.sender.id == _pb.authStore.record!.id;
                        final isNewMessage = index == 0;

                        Widget messageBubble = Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  isMe
                                      ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.85)
                                      : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              msg.message,
                              style: TextStyle(
                                color:
                                    isMe
                                        ? Colors.white
                                        : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        );

                        if (isNewMessage) {
                          messageBubble = Animate(
                            key: ValueKey(msg.id),
                            effects: [
                              FadeEffect(duration: 150.ms),
                              SlideEffect(
                                begin: Offset(isMe ? 1 : -1, 0),
                                duration: 150.ms,
                                curve: Curves.easeOut,
                              ),
                            ],
                            child: messageBubble,
                          );
                        }
                        return messageBubble;
                      },
                    ),
                  ),
                ),
              ),

              // Input
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 12),
                      width: MediaQuery.of(context).size.width - 64,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 5,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: textFieldColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              hintText: 'Type a message',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(26),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: toggleAttachmentOptions,
                                  icon: const Icon(Icons.add, size: 24),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final image =
                                        await FilePickerHelper.captureImageFromCamera();
                                    if (image != null) {
                                      files.add(image);
                                    }
                                  },
                                  icon: const Icon(Icons.image, size: 24),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.arrowRight,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: sendMessageHandler,
                        splashRadius: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ===== Attachment Popup =====
          if (_showAttachmentOptions)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Animate(
                  effects: [
                    FadeEffect(duration: 100.ms),
                    SlideEffect(
                      duration: 100.ms,
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                      curve: Curves.easeOut,
                    ),
                  ],
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,

                      children: [
                        _AttachmentOption(
                          icon: FontAwesomeIcons.image,
                          label: "Photos",
                          color: Colors.pinkAccent,
                          onTap: () async {
                            final userFiles = await FilePickerHelper.pickImages(
                              allowMultiple: true,
                            );
                            files.addAll(userFiles);
                            toggleAttachmentOptions();
                          },
                        ),
                        _AttachmentOption(
                          icon: FontAwesomeIcons.video,
                          label: "Videos",
                          color: Colors.deepPurpleAccent,
                          onTap: () async {
                            final userFiles = await FilePickerHelper.pickVideos(
                              allowMultiple: true,
                            );
                            files.addAll(userFiles);
                            toggleAttachmentOptions();
                          },
                        ),
                        _AttachmentOption(
                          icon: FontAwesomeIcons.camera,
                          label: "Camera",
                          color: Colors.blueAccent,
                          onTap: () async {
                            final file =
                                await FilePickerHelper.captureImageFromCamera();
                            if (file != null) {
                              files.add(file);
                            }
                            toggleAttachmentOptions();
                          },
                        ),
                        _AttachmentOption(
                          icon: FontAwesomeIcons.file,
                          label: "Files",
                          color: Colors.orangeAccent,
                          onTap: () async {
                            final userFiles =
                                await FilePickerHelper.pickAnyFile(
                                  allowMultiple: true,
                                );
                            files.addAll(userFiles);
                            toggleAttachmentOptions();
                          },
                        ),
                        _AttachmentOption(
                          icon: FontAwesomeIcons.music,
                          label: "Music",
                          color: Colors.tealAccent.shade700,
                          onTap: () async {
                            final userFiles = await FilePickerHelper.pickAudio(
                              allowMultiple: true,
                            );
                            files.addAll(userFiles);
                            toggleAttachmentOptions();
                          },
                        ),
                        _AttachmentOption(
                          icon: FontAwesomeIcons.microphone,
                          label: "Record",
                          color: Colors.redAccent,
                          onTap: () async {
                            toggleAttachmentOptions();
                          },
                        ),
                        _AttachmentOption(
                          icon: FontAwesomeIcons.addressBook,
                          label: "Contacts",
                          color: Colors.greenAccent.shade700,
                          onTap: () async {
                            toggleAttachmentOptions();
                          },
                        ),
                        _AttachmentOption(
                          icon: FontAwesomeIcons.mapLocationDot,
                          label: "Location",
                          color: Colors.lightBlueAccent,
                          onTap: () async {
                            toggleAttachmentOptions();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.15),
            child: FaIcon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
