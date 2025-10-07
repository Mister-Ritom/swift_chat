import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:swift_chat/models/message_model.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/utils/attachment_preview.dart';
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

  Future<void> initChat() async {
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
          (event) => setState(() => messages.add(event.record!)),
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

    setState(() => messages.addAll(initialMessages));
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }

  String getFileName(String path) {
    final parts = path.split(RegExp(r'[\\/]+')); // handles both / and \
    return parts.isNotEmpty ? parts.last : '';
  }

  ValueNotifier<double> uploadProgress = ValueNotifier(0); // 0.0 to 1.0

  void sendMessageHandler() async {
    final text = _controller.text.trim();
    if (text.isEmpty && files.isEmpty) return;

    final senderId = _pb.authStore.record!.id;

    // Build multipart request manually for streaming
    final url = Uri.parse('${_pb.baseURL}/api/collections/messages/records');
    final request =
        http.MultipartRequest('POST', url)
          ..fields['message'] = text
          ..fields['chat'] = chatId
          ..fields['sender'] = senderId
          ..headers['Authorization'] = 'Bearer ${_pb.authStore.token}';

    // Add files as streams
    for (final file in files) {
      final length = await file.length();
      final stream = http.ByteStream(file.openRead());
      final multipartFile = http.MultipartFile(
        'documents',
        stream,
        length,
        filename: getFileName(file.path),
      );
      request.files.add(multipartFile);
      log('Added file: ${file.path}, size: $length bytes');
    }

    // Send request with streamed response
    final streamedResponse = await request.send();

    // Track progress
    final totalBytes = streamedResponse.contentLength ?? 1;
    int bytesReceived = 0;

    streamedResponse.stream.listen(
      (chunk) {
        bytesReceived += chunk.length;
        uploadProgress.value = bytesReceived / totalBytes;
        debugPrint(
          'Upload progress: ${(uploadProgress.value * 100).toStringAsFixed(1)}%',
        );
      },
      onDone: () async {
        if (streamedResponse.statusCode == 200 ||
            streamedResponse.statusCode == 201) {
          log('Message sent successfully');
          _controller.clear();
          files.clear();
          uploadProgress.value = 0;
        } else {
          log('Upload failed: ${streamedResponse.statusCode}');
        }
      },
      onError: (e) {
        log('Upload error: $e');
      },
      cancelOnError: true,
    );
  }

  void toggleAttachmentOptions() {
    setState(() => _showAttachmentOptions = !_showAttachmentOptions);
  }

  @override
  Widget build(BuildContext context) {
    final sortedMessages = [...messages]..sort(
      (a, b) =>
          b.getStringValue('created').compareTo(a.getStringValue('created')),
    );

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildMessageList(sortedMessages)),
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

  // ===================== WIDGETS =====================
  Widget _buildAppBar(BuildContext context) {
    final user = widget.receiver;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 36, 8, 8),
      color: isDark ? Colors.grey[850] : Colors.grey[200],
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const FaIcon(FontAwesomeIcons.angleLeft, size: 32),
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
                          child: Text("Last seen ${timeAgo(date)}"),
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

  Widget _buildMessageList(List<RecordModel> sortedMessages) {
    return ListView.builder(
      reverse: true,
      itemCount: sortedMessages.length,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (context, index) {
        final msg = MessageModel.fromRecord(sortedMessages[index]);
        final isMe = msg.sender.id == _pb.authStore.record!.id;
        final isNewMessage = index == 0;

        Widget bubble = _MessageBubble(msg: msg, isMe: isMe);
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
                _AttachmentOption(
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
                _AttachmentOption(
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
                _AttachmentOption(
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
                _AttachmentOption(
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

class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    const maxFilesToShow = 4;
    final totalFiles = msg.documentLinks.length;
    final filesToShow = msg.documentLinks.take(maxFilesToShow).toList();
    final remainingFiles = totalFiles - maxFilesToShow;

    List<Widget> fileWidgets = [];

    for (int i = 0; i < filesToShow.length; i++) {
      final url = filesToShow[i];

      Widget thumb = buildFileThumbnail(url, 120, true);

      // If last visible file and there are more, overlay blur + text
      if (i == maxFilesToShow - 1 && remainingFiles > 0) {
        thumb = Stack(
          children: [
            SizedBox(width: 120, height: 120, child: thumb),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 120,
                  height: 120,
                  color: Colors.black.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  child: Text(
                    '+$remainingFiles more',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showAllFiles(context),
                ),
              ),
            ),
          ],
        );
      }

      fileWidgets.add(thumb);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          gradient:
              isMe
                  ? LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 1),
                      Theme.of(context).primaryColor.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : LinearGradient(
                    colors: [
                      Theme.of(context).cardColor,
                      Theme.of(context).cardColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.message.isNotEmpty)
              Text(
                msg.message,
                style: TextStyle(
                  color:
                      isMe
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            if (fileWidgets.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: fileWidgets),
            ],
          ],
        ),
      ),
    );
  }

  /// Show bottom modal with thumbnails of all files
  void _showAllFiles(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5), // outside tap dim
      builder:
          (_) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder:
                  (_, controller) => GestureDetector(
                    onTap: () {}, // block tap inside sheet
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        controller: controller,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: msg.documentLinks.length,
                        itemBuilder: (_, index) {
                          return buildFileThumbnail(
                            msg.documentLinks[index],
                            120,
                            true,
                          );
                        },
                      ),
                    ),
                  ),
            ),
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
            backgroundColor: color.withValues(alpha: 0.15),
            child: FaIcon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
