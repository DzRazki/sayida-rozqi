import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: ListView(padding: const EdgeInsets.all(16), children: const [
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile(leading: Icon(Icons.restaurant_menu), title: Text('وصفات جديدة'), subtitle: Text('تابعي أحدث الوصفات الجزائرية المضافة إلى التطبيق.'))),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile(leading: Icon(Icons.favorite), title: Text('وصفات مميزة'), subtitle: Text('اكتشفي الوصفات المميزة والمجربة من السيدة رزقي.'))),
      ]),
    );
  }
}
