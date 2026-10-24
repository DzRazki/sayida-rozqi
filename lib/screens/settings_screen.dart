import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'admin/admin_login_screen.dart';
import 'admin/recipe_management_screen.dart';
import 'user_auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool signingOut = false;

  Future<void> signOut() async {
    if (signingOut) return;
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('تسجيل الخروج'),
      content: const Text('هل تريدين تسجيل الخروج من الحساب على هذا الجهاز؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('خروج')),
      ],
    ));
    if (!mounted || confirmed != true || signingOut) return;
    setState(() => signingOut = true);
    try {
      await SupabaseService.client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تسجيل الخروج. حاولي مجددًا.')));
    } finally {
      if (mounted) setState(() => signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الإعدادات')),
    body: StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = SupabaseService.client.auth.currentUser;
        return ListView(padding: const EdgeInsets.all(16), children: [
          const CircleAvatar(radius: 38, backgroundColor: AppColors.gold, child: Text('🍲', style: TextStyle(fontSize: 32))),
          const SizedBox(height: 12),
          const Center(child: Text('السيدة رزقي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: user == null
              ? ListTile(
                  leading: const Icon(Icons.person_add_alt_1),
                  title: const Text('تسجيل الدخول / إنشاء حساب'),
                  subtitle: const Text('احفظي تفاعلاتك باسم حسابك'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () async {
                    await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const UserAuthScreen()));
                    if (mounted) setState(() {});
                  },
                )
              : ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: const Text('حسابي'),
                  subtitle: Text(user.email ?? 'حساب مسجّل'),
                  isThreeLine: false,
                ),
          ),
          if (user != null) Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: signingOut ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.logout),
              title: const Text('تسجيل الخروج'),
              enabled: !signingOut,
              onTap: signingOut ? null : signOut,
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('منطقة الإدارة'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupabaseService.isAdmin() ? const RecipeManagementScreen() : const AdminLoginScreen())),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(leading: Icon(Icons.info_outline), title: Text('حول التطبيق'), subtitle: Text('تطبيق وصفات جزائرية أصيلة')),
          ),
        ]);
      },
    ),
  );
}
