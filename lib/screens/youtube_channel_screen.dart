import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YouTubeChannelScreen extends StatefulWidget {
  const YouTubeChannelScreen({super.key});

  @override
  State<YouTubeChannelScreen> createState() => _YouTubeChannelScreenState();
}

class _YouTubeChannelScreenState extends State<YouTubeChannelScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://youtube.com/@chef4razki?si=3Q1Y_iVOn1NqGPUO'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('قناة السيدة رزقي')), body: WebViewWidget(controller: controller));
  }
}
