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
    final size = MediaQuery.of(context).size;
    final navWidth = 70.0;
    final pageWidth = size.width - navWidth - 8;

    Widget buildLeftPane() {
      switch (selectedPage) {
        case 0:
          return HomePage(isMobile: false);
        case 1:
          return DiscoverPage(isMobile: false);
        case 2:
          return NotificationsPage();
        case 3:
          return MenuPage();
        default:
          return HomePage(isMobile: false);
      }
    }

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
              const VerticalDivider(width: 8),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey(selectedPage),
                  child:
                      selectedPage <= 1
                          ? Row(
                            children: [
                              // Left half (Home or Discover)
                              SizedBox(
                                width: (pageWidth * 1.5 / 4),
                                child: buildLeftPane(),
                              ),

                              // Right half (Chat pane - reactive)
                              SizedBox(
                                width: pageWidth * 2.5 / 4,
                                child: Consumer(
                                  builder: (context, ref, _) {
                                    final receiver = ref.watch(
                                      receiverProvider,
                                    );
                                    return _getCurrentPage(receiver);
                                  },
                                ),
                              ),
                            ],
                          )
                          : buildLeftPane(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCurrentPage(UserModel? receiver) {
    if (receiver == null) {
      return const Center(
        child: Image(
          image: AssetImage("assets/icons/swift_chat.png"),
          width: 300,
          height: 300,
        ),
      );
    } else {
      // 👇 Force Flutter to treat this as a new widget whenever receiver.id changes
      return KeyedSubtree(
        key: ValueKey(receiver.id),
        child: ChatPage(receiver: receiver, isMobile: false),
      );
    }
  }
}
