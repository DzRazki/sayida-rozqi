import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
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
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: const Text('حسابي')),
    body: StreamBuilder<AuthState>(stream: Supabase.instance.client.auth.onAuthStateChange, builder: (context, snapshot) {
      final user = Supabase.instance.client.auth.currentUser;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .07), blurRadius: 22, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .18), shape: BoxShape.circle),
                  child: const Icon(Icons.account_circle_outlined, size: 46, color: AppColors.darkBrown),
                ),
                const SizedBox(height: 16),
                if (user == null) ...[
                  const Text('مرحبًا بك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
                  const SizedBox(height: 8),
                  const Text('سجّلي الدخول أو أنشئي حسابًا لحفظ تفاعلاتك.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.brown)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const UserAuthScreen()));
                        if (mounted) setState(() {});
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.darkBrown, foregroundColor: AppColors.gold, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                      icon: const Icon(Icons.login),
                      label: const Text('تسجيل الدخول / إنشاء حساب'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('تصفّح الوصفات متاح دون تسجيل.', style: TextStyle(color: AppColors.brown)),
                ] else ...[
                  const Text('حسابي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
                  const SizedBox(height: 8),
                  Text(user.email ?? 'حساب مسجّل', style: const TextStyle(color: AppColors.brown)),
                  const SizedBox(height: 20),
                  if (busy) const LinearProgressIndicator(color: AppColors.gold),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : logout,
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.darkBrown, side: const BorderSide(color: AppColors.gold), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                      icon: const Icon(Icons.logout),
                      label: const Text('تسجيل الخروج'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }),
  );
}
