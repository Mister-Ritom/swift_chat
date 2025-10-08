import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swift_chat/models/user_model.dart';
import 'package:swift_chat/pages/chat/chat_page.dart';
import 'package:swift_chat/pages/screns/discover_page.dart';
import 'package:swift_chat/pages/screns/home_page.dart';
import 'package:swift_chat/pages/screns/menu_page.dart';
import 'package:swift_chat/pages/screns/notifications_page.dart';
import 'package:swift_chat/providers/chat_receiver_provider.dart';

class DesktopHomePage extends ConsumerWidget {
  final List<Widget> iconList;
  final int selectedPage;
  const DesktopHomePage({
    super.key,
    required this.iconList,
    required this.selectedPage,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentReceiver = ref.watch(receiverProvider);
    final size = MediaQuery.of(context).size;
    final navWidth = 70.0;
    final pageWidth = size.width - navWidth - 8;
    final pages = [
      Row(
        children: [
          SizedBox(
            width: (pageWidth * 1.5 / 4),
            child: HomePage(isMobile: false),
          ),
          SizedBox(
            width: pageWidth * 2.5 / 4,
            child: getCurrentPage(currentReceiver),
          ),
        ],
      ),
      Row(
        children: [
          SizedBox(
            width: (pageWidth * 1.5 / 4),
            child: DiscoverPage(isMobile: false),
          ),
          SizedBox(
            width: pageWidth * 2.5 / 4,
            child: getCurrentPage(currentReceiver),
          ),
        ],
      ),
      NotificationsPage(),
      MenuPage(),
    ];

    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              SizedBox(
                width: navWidth,
                height: size.height,
                child: Column(children: iconList),
              ),
              VerticalDivider(width: 8),
              SizedBox(
                width: pageWidth,
                child: KeyedSubtree(
                  key: ValueKey(selectedPage),
                  child: pages[selectedPage],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getCurrentPage(UserModel? receiver) {
    if (receiver == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/icons/swift_chat.png", width: 300, height: 300),
        ],
      );
    } else {
      return ChatPage(receiver: receiver, isMobile: false);
    }
  }
}
