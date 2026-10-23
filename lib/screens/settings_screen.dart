import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'admin/admin_login_screen.dart';
import 'admin/recipe_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 38, backgroundColor: AppColors.gold, child: Text('🍲', style: TextStyle(fontSize: 32))),
          const SizedBox(height: 12),
          const Center(child: Text('السيدة رزقي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile(leading: const Icon(Icons.admin_panel_settings), title: const Text('منطقة الإدارة'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupabaseService.isAdmin() ? const RecipeManagementScreen() : const AdminLoginScreen())))),
          const Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile(leading: Icon(Icons.info_outline), title: Text('حول التطبيق'), subtitle: Text('تطبيق وصفات جزائرية أصيلة'))),
          Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ListTile(leading: const Icon(Icons.logout), title: const Text('تسجيل الخروج'), onTap: () => SupabaseService.signOut())),
        ],
      ),
    );
  }
}
