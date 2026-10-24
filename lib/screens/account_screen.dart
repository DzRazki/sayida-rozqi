import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_auth_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}
class _AccountScreenState extends State<AccountScreen> {
  bool busy = false;
  Future<void> logout() async {
    if (busy) return;
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('تسجيل الخروج'), content: const Text('تسجيل الخروج من هذا الجهاز؟'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('خروج'))]));
    if (!mounted || ok != true) return;
    setState(() => busy = true);
    try { await Supabase.instance.client.auth.signOut(scope: SignOutScope.local); } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تسجيل الخروج. حاولي مجددًا.')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('حسابي')),
    body: StreamBuilder<AuthState>(stream: Supabase.instance.client.auth.onAuthStateChange, builder: (context, snapshot) {
      final user = Supabase.instance.client.auth.currentUser;
      return ListView(padding: const EdgeInsets.all(24), children: [
        const Icon(Icons.account_circle_outlined, size: 72), const SizedBox(height: 20),
        if (user == null) ...[
          const Text('سجّلي الدخول أو أنشئي حسابًا لحفظ تفاعلاتك.'), const SizedBox(height: 16),
          FilledButton(onPressed: () async {
            await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const UserAuthScreen()));
            if (mounted) setState(() {});
          }, child: const Text('تسجيل الدخول / إنشاء حساب')),
          const Text('تصفّح الوصفات متاح دون تسجيل.'),
        ] else ...[
          const Text('حسابي', style: TextStyle(fontSize: 22)),
          Text(user.email ?? 'حساب مسجّل'), const SizedBox(height: 20),
          if (busy) const LinearProgressIndicator(),
          OutlinedButton.icon(onPressed: busy ? null : logout, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
        ],
      ]);
    }),
  );
}
