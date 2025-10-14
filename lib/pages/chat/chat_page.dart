import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:swift_chat/models/message_model.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/pages/chat/attachment_option.dart';
import 'package:swift_chat/pages/chat/message_bubble.dart';
import 'package:swift_chat/pages/chat/attachment_preview.dart';
import 'package:swift_chat/utils/file_picker_helper.dart';
import 'package:swift_chat/utils/mapping.dart';
import 'package:swift_chat/utils/message_helper.dart';
import 'package:swift_chat/utils/presence_service.dart';
import 'package:swift_chat/core/pb_client.dart';
import 'package:pocketbase/pocketbase.dart';

class ChatPage extends StatefulWidget {
  final UserModel receiver;
  final bool isMobile;
  const ChatPage({super.key, required this.receiver, this.isMobile = true});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  List<RecordModel> messages = [];
  List<PickedFileData> files = [];
  final _pb = PBClient.instance;

  late String chatId;
  late Function unsubscribe;
  bool _showAttachmentOptions = false;

  @override
  void initState() {
    super.initState();
    initChat();
  }

  Future<void> initChat() async {
    final senderId = _pb.authStore.record!.id;
    final receiverId = widget.receiver.id;

    final RecordModel chat = await MessageHelper.getChatCreate(
      senderId,
      receiverId,
    );
    chatId = chat.id;

    unsubscribe = await _pb
        .collection('messages')
        .subscribe(
          "*",
          (event) => setState(() {
            setState(() {
              messages.add(event.record!);
              messages.sort(
                (a, b) => b
                    .getStringValue('created')
                    .compareTo(a.getStringValue('created')),
              );
              if (messages.length > 50) {
                messages.removeRange(50, messages.length);
              }
            });
          }),
          filter: 'chat="$chatId"',
          expand: 'sender',
        );

    final initialMessages = await _pb
        .collection('messages')
        .getList(
          page: 1,
          perPage: 50,
          filter: 'chat="$chatId"',
          sort: '-created',
          expand: 'sender',
        );

    setState(() => messages.addAll(initialMessages.items));
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }

  Future<void> sendNotification() async {
    try {
      final pb = PBClient.instance;
      final senderId = pb.authStore.record!.id;
      final receiverId = widget.receiver.id;
      final rawText = _controller.text.trim();
      final text =
          rawText.length > 300 ? '${rawText.substring(0, 300)}…' : rawText;
      final filesCount = files.length;
      await pb
          .collection('notifications')
          .create(
            body: {
              'sender': senderId,
              'receiver': receiverId,
              'chat': chatId,
              'text': text,
              'files': filesCount,
            },
          );
    } catch (e) {
      log('Failed to send notification: $e');
    }
  }

  ValueNotifier<double> uploadProgress = ValueNotifier(0); // 0.0 to 1.0

  void sendMessageHandler() async {
    final text = _controller.text.trim();
    if (text.isEmpty && files.isEmpty) return;
    final request = await MessageHelper.buildMessageRequest(
      text,
      chatId,
      files,
    );

    try {
      final streamedResponse = await request.send();
      await _handleUploadResponse(streamedResponse);
      sendNotification();
    } catch (e) {
      log('Upload error: $e');
    }
  }

  Future<void> _handleUploadResponse(http.StreamedResponse response) async {
    final totalBytes = response.contentLength ?? 1;
    int bytesReceived = 0;

    response.stream.listen(
      (chunk) {
        bytesReceived += chunk.length;
        uploadProgress.value = bytesReceived / totalBytes;
        debugPrint(
          'Upload progress: ${(uploadProgress.value * 100).toStringAsFixed(1)}%',
        );
      },
      onDone: () async {
        if (response.statusCode == 200 || response.statusCode == 201) {
          log('Message sent successfully');
          _controller.clear();
          files.clear();
          uploadProgress.value = 0;
        } else {
          log('Upload failed: ${response.statusCode}');
        }
      },
      onError: (e, st) => log('Upload error', error: e, stackTrace: st),
      cancelOnError: true,
    );
  }

  void toggleAttachmentOptions() {
    setState(() => _showAttachmentOptions = !_showAttachmentOptions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildMessageList()),
              _buildInputBar(context),
            ],
          ),
          if (files.isNotEmpty)
            AttachmentPreview(
              files: files,
              onRemove: (index) => setState(() => files.removeAt(index)),
            ),
          if (_showAttachmentOptions) _buildAttachmentPopup(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final user = widget.receiver;
    final isMobile = widget.isMobile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(8, isMobile ? 36 : 8, 8, 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[200],
        borderRadius: BorderRadius.circular(16), // <-- rounded corners
      ),
      child: Row(
        children: [
          isMobile
              ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const FaIcon(FontAwesomeIcons.angleLeft, size: 32),
              )
              : SizedBox.shrink(),
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
                  style: TextStyle(color: Colors.lightGreen),
                ),
                offlineWidget: (lastSeen) {
                  final date =
                      lastSeen.isEmpty
                          ? user.lastSeen
                          : DateTime.tryParse(lastSeen);
                  return date != null
                      ? SizedBox(
                        width: 160,
                        child: FittedBox(
                          child: Text(
                            "Last seen ${timeAgo(date)}",
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ),
                      )
                      : const SizedBox.shrink();
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
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (context, index) {
        final msg = MessageModel.fromRecord(messages[index]);
        final isMe = msg.sender.id == _pb.authStore.record!.id;
        final isNewMessage = index == 0;

        Widget bubble = MessageBubble(msg: msg, isMe: isMe);
        if (isNewMessage) {
          bubble = Animate(
            key: ValueKey(msg.id),
            effects: [
              FadeEffect(duration: 150.ms),
              SlideEffect(
                begin: Offset(isMe ? 1 : -1, 0),
                duration: 150.ms,
                curve: Curves.easeOut,
              ),
            ],
            child: bubble,
          );
        }
        return bubble;
      },
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textFieldColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      child: Row(
        children: [
          Expanded(
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
                          if (image != null) setState(() => files.add(image));
                        },
                        icon: const Icon(Icons.image, size: 24),
                      ),
                      SizedBox(width: 4),
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
    );
  }

  Widget _buildAttachmentPopup(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
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
                  color: Colors.black.withAlpha(38),
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
                AttachmentOption(
                  icon: FontAwesomeIcons.image,
                  label: "Photos",
                  color: Colors.pinkAccent,
                  onTap: () async {
                    final picked = await FilePickerHelper.pickImages(
                      allowMultiple: true,
                    );
                    setState(() => files.addAll(picked));
                    toggleAttachmentOptions();
                  },
                ),
                AttachmentOption(
                  icon: FontAwesomeIcons.video,
                  label: "Videos",
                  color: Colors.deepPurpleAccent,
                  onTap: () async {
                    final picked = await FilePickerHelper.pickVideos(
                      allowMultiple: true,
                    );
                    setState(() => files.addAll(picked));
                    toggleAttachmentOptions();
                  },
                ),
                AttachmentOption(
                  icon: FontAwesomeIcons.camera,
                  label: "Camera",
                  color: Colors.blueAccent,
                  onTap: () async {
                    final file =
                        await FilePickerHelper.captureImageFromCamera();
                    if (file != null) setState(() => files.add(file));
                    toggleAttachmentOptions();
                  },
                ),
                AttachmentOption(
                  icon: FontAwesomeIcons.file,
                  label: "Files",
                  color: Colors.orangeAccent,
                  onTap: () async {
                    final picked = await FilePickerHelper.pickAnyFile(
                      allowMultiple: true,
                    );
                    setState(() => files.addAll(picked));
                    toggleAttachmentOptions();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
