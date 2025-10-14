# 🚀 Swift Chat

**A blazingly fast, cross-platform real-time chat app built with Flutter and PocketBase.**

Swift Chat is designed for speed, privacy, and simplicity — delivering a Discord-like group chat experience across Android, iOS, macOS, Windows, and Web. Built using modern Flutter architecture with PocketBase as a realtime backend.

---

## 🧠 Tech Stack

| Layer                     | Technologies                                                                                      |
| ------------------------- | ------------------------------------------------------------------------------------------------- |
| **Frontend**              | Flutter, Riverpod, Google Fonts, Flutter Animate                                                  |
| **Backend**               | PocketBase (Realtime Database, Auth, File Storage)                                                |
| **Storage**               | Hive, Isar                                                                                        |
| **Notifications**         | Firebase Messaging, Flutter Local Notifications                                                   |
| **Media & File Handling** | Image Picker, File Picker, Video Player, Photo View, OpenFileX                                    |
| **Utilities**             | Cached Network Image, Connectivity Plus, Permission Handler, Crypto, Saver Gallery, Path Provider |
| **Design & Icons**        | Cupertino Icons, Font Awesome Flutter                                                             |

---

## ⚡ Features

- 💬 **Realtime Chat** – Built on PocketBase’s websocket subscriptions
- 🔒 **Private & Secure** – Locally encrypted data (Crypto + Hive)
- 🖼️ **Rich Media Sharing** – Send images, videos, and files easily
- 📶 **Offline-first Support** – Messages auto-sync when reconnected
- 🔔 **Push Notifications** – Delivered via Firebase Cloud Messaging
- 🧩 **Cross-Platform Ready** – Works on Android, iOS, macOS, Windows & Web
- 🎨 **Smooth UI & Animations** – Built with Flutter Animate + Riverpod
- 🧑‍💻 **Self-Hosted Freedom** – Control your backend with PocketBase

---

## 🧭 Why I Built It

> I wanted to create a chat experience as smooth as Discord — but **lightweight, private, and self-hosted**.  
> Firebase was great but limited on the free tier, so I switched to **PocketBase**, giving me full backend control with real-time updates, authentication, and file storage — all in one small binary.

---

## 🧰 Development Notes

- Built using **Flutter Riverpod** for reactive state management.
- Local caching handled by **Hive** and **Isar** for fast, persistent storage.
- Integrated **Firebase Messaging** + **Flutter Local Notifications** for background and foreground push alerts.
- Offline message queue and auto-retry ensure reliability on poor networks.
- Media is efficiently cached with **CachedNetworkImage** and **FlutterCacheManager**.

---

## 🧩 Architecture Overview

Swift Chat
│
├── lib/
│ ├── main.dart
│ ├── models/
│ ├── services/ # PocketBase, Auth, Notifications, etc.
│ ├── screens/ # Chat, Login, Media Viewer, Settings
│ ├── widgets/
│ └── utils/
│
├── assets/
│ ├── icons/
│ └── configs/config.json
│
└── pubspec.yaml

---

## 🪄 Screenshots

Here’s a glimpse of **Swift Chat** in action 👇

<p align="center">
  <img src="https://github.com/Mister-Ritom/swift_chat/raw/main/File%201.HEIC" width="32%" />
  <img src="https://github.com/Mister-Ritom/swift_chat/raw/main/File%202.HEIC" width="32%" />
  <img src="https://github.com/Mister-Ritom/swift_chat/raw/main/File%203.HEIC" width="32%" />
  <img src="https://github.com/Mister-Ritom/swift_chat/raw/main/File%204.HEIC" width="32%" />
  <img src="https://github.com/Mister-Ritom/swift_chat/raw/main/File%205.HEIC" width="32%" />
  <img src="https://github.com/Mister-Ritom/swift_chat/raw/main/File%206.png" width="32%" />
  <img src="https://github.com/Mister-Ritom/swift_chat/raw/main/File%207.png" width="32%" />
</p>

---

## 🧑‍💻 Author

**Ritom Ghosh**  
📧 [ritomghosh856@gmail.com](mailto:ritomghosh856@gmail.com)  
🌐 [me.ritom.site](https://me.ritom.site)  
🐙 [@mister-ritom](https://github.com/mister-ritom)

---

## 🏷️ License

This project is currently private. An open-source release is planned soon.

---

### 🏁 Built with Passion ❤️ using Flutter & PocketBase
