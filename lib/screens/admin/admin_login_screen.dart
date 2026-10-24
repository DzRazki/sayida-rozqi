import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../theme.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String error = '';

  Future<void> login() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      await SupabaseService.signIn(email.text.trim(), password.text);
      if (!SupabaseService.isAdmin()) {
        await SupabaseService.signOut();
        throw Exception('هذا الحساب غير مخوّل بإدارة الوصفات');
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('دخول الإدارة')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .18), shape: BoxShape.circle),
                  child: const Icon(Icons.admin_panel_settings, size: 38, color: AppColors.darkBrown),
                ),
                const SizedBox(height: 16),
                const Text('لوحة إدارة الوصفات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
                const SizedBox(height: 6),
                const Text('سجّلي الدخول للمتابعة', style: TextStyle(color: AppColors.brown)),
                const SizedBox(height: 20),
                TextField(controller: email, decoration: const InputDecoration(hintText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined))),
                const SizedBox(height: 14),
                TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'كلمة المرور', prefixIcon: Icon(Icons.lock_outline))),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: loading ? null : login,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.darkBrown, foregroundColor: AppColors.gold, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    icon: const Icon(Icons.login),
                    label: Text(loading ? 'جارٍ الدخول...' : 'تسجيل الدخول'),
                  ),
                ),
                if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
