import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/recipe.dart';

class YoutubeScreen extends StatefulWidget {
  final Recipe recipe;
  const YoutubeScreen({super.key, required this.recipe});

  @override
  State<YoutubeScreen> createState() => _YoutubeScreenState();
}

class _YoutubeScreenState extends State<YoutubeScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    final url = widget.recipe.youtubeUrl;
    final videoId = Uri.tryParse(url)?.queryParameters['v'] ?? '';
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.youtube.com/embed/$videoId'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(widget.recipe.name)), body: WebViewWidget(controller: controller));
  }
}
