import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'admin/admin_login_screen.dart';
import 'admin/recipe_management_screen.dart';
import 'user_auth_screen.dart';
import 'account_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool signingOut = false;
  static const privacyUrl = 'https://doukara983-a11y.github.io/sayida-rozqi/privacy.html';
  static const deletionUrl = 'https://doukara983-a11y.github.io/sayida-rozqi/delete-account.html';
  static const supportEmail = 'midou4tv@gmail.com';

  Future<void> openLink(String address) async {
    try {
      if (await launchUrl(Uri.parse(address), mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(address.startsWith('mailto:') ? 'تعذر فتح تطبيق البريد. يمكنك نسخ بريد الدعم.' : 'تعذر فتح الرابط. يمكنك نسخه وفتحه في المتصفح.'),
      action: SnackBarAction(label: 'نسخ', onPressed: () async {
        try { await Clipboard.setData(ClipboardData(text: address.startsWith('mailto:') ? supportEmail : address)); } catch (_) {}
      }),
    ));
  }

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

  Widget tile({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 18, offset: const Offset(0, 6))],
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .18), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.darkBrown)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
      subtitle: subtitle == null ? null : Text(subtitle, style: const TextStyle(color: AppColors.brown)),
      trailing: trailing ?? const Icon(Icons.chevron_left, color: AppColors.gold),
      onTap: onTap,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: const Text('الإعدادات')),
    body: StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = SupabaseService.client.auth.currentUser;
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .07), blurRadius: 22, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 84, height: 84,
                    decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .18), shape: BoxShape.circle),
                    child: const Center(child: Text('🍲', style: TextStyle(fontSize: 36))),
                  ),
                  const SizedBox(height: 14),
                  const Text('السيدة رزقي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
                  const SizedBox(height: 6),
                  const Text('تطبيق وصفات جزائرية أصيلة', style: TextStyle(color: AppColors.brown)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (user == null) tile(
              icon: Icons.person_add_alt_1,
              title: 'تسجيل الدخول / إنشاء حساب',
              subtitle: 'احفظي تفاعلاتك باسم حسابك',
              onTap: () async {
                await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const UserAuthScreen()));
                if (mounted) setState(() {});
              },
            ) else tile(
              icon: Icons.account_circle_outlined,
              title: 'حسابي',
              subtitle: user.email ?? 'حساب مسجّل',
              onTap: signingOut ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())),
            ),
            if (user != null) tile(
              icon: Icons.logout,
              title: 'تسجيل الخروج',
              subtitle: 'تسجيل الخروج من هذا الجهاز',
              trailing: signingOut ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)) : const Icon(Icons.chevron_left, color: AppColors.gold),
              onTap: signingOut ? null : signOut,
            ),
            tile(
              icon: Icons.privacy_tip_outlined, title: 'سياسة الخصوصية',
              subtitle: 'البيانات والخدمات الخارجية وحقوقك',
              onTap: () => openLink(privacyUrl),
            ),
            tile(
              icon: Icons.manage_accounts_outlined, title: 'طلب حذف الحساب والبيانات',
              subtitle: 'طريقة الحذف من التطبيق أو عبر الدعم',
              onTap: () => openLink(deletionUrl),
            ),
            tile(
              icon: Icons.support_agent, title: 'الدعم والتواصل',
              subtitle: supportEmail, onTap: () => openLink('mailto:$supportEmail'),
            ),
            tile(
              icon: Icons.admin_panel_settings,
              title: 'منطقة الإدارة',
              subtitle: 'إدارة الوصفات والإحصائيات',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupabaseService.isAdmin() ? const RecipeManagementScreen() : const AdminLoginScreen())),
            ),
            tile(
              icon: Icons.info_outline, title: 'حول التطبيق',
              subtitle: 'تطبيق وصفات جزائرية أصيلة — المطوّر: NY SIG CITY',
              trailing: const SizedBox.shrink(),
            ),
          ],
        );
      },
    ),
  );
}
