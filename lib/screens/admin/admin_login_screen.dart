import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
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
      appBar: AppBar(title: const Text('دخول الإدارة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: email, decoration: const InputDecoration(hintText: 'البريد الإلكتروني')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'كلمة المرور')),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : login, child: Text(loading ? 'جارٍ الدخول...' : 'تسجيل الدخول'))),
          if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error, style: const TextStyle(color: Colors.red))),
        ]),
      ),
    );
  }
}
