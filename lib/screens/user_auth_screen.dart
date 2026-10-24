import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UserAuthScreen extends StatefulWidget {
  const UserAuthScreen({super.key});
  @override
  State<UserAuthScreen> createState() => _UserAuthScreenState();
}

class _UserAuthScreenState extends State<UserAuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool register = false;
  bool busy = false;
  String? message;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> finishSignIn() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || !mounted) return;
    SharedPreferences? prefs;
    bool seen = false;
    final key = 'youtube-channel-invite:${user.id}';
    try {
      prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(key) ?? false;
    } catch (_) {
      // An optional invitation must not prevent sign-in.
    }
    if (!mounted || Supabase.instance.client.auth.currentUser?.id != user.id) return;
    if (!seen) {
      final openChannel = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 40),
            title: const Text('تابعي وصفات السيدة رزقي على YouTube'),
            content: const Text('افتحي القناة واضغطي زر الاشتراك في YouTube إذا رغبتِ. المتابعة اختيارية ولا تؤثر على استخدام التطبيق.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('لاحقًا')),
              FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('فتح القناة للاشتراك')),
            ],
          ),
        ),
      );
      if (!mounted || Supabase.instance.client.auth.currentUser?.id != user.id) return;
      try {
        await prefs?.setBool(key, true);
      } catch (_) {}
      if (!mounted) return;
      if (openChannel == true) {
        try {
          final launched = await launchUrl(
            Uri.parse('https://www.youtube.com/@chef4razki'),
            mode: LaunchMode.externalApplication,
          );
          if (!launched) throw StateError('Channel could not be opened');
        } catch (_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تعذر فتح YouTube. يمكنك زيارة القناة لاحقًا من تبويب القناة.'),
          ));
        }
      }
    }
    if (mounted && Supabase.instance.client.auth.currentUser?.id == user.id) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() { busy = true; message = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (auth.currentUser != null) {
        await finishSignIn();
        return;
      }
      final result = register
          ? await auth.signUp(email: email.text.trim(), password: password.text)
          : await auth.signInWithPassword(email: email.text.trim(), password: password.text);
      if (!mounted) return;
      if (result.session != null) {
        await finishSignIn();
      } else {
        setState(() {
          message = 'راجعي بريدك لتأكيد الحساب، ثم عودي لتسجيل الدخول. إذا لم تصلك رسالة، تحققي من البريد غير المرغوب فيه.';
          register = false;
        });
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => message = 'تعذر إكمال الطلب: ${error.message}');
    } catch (_) {
      if (mounted) setState(() => message = 'تعذر الاتصال. تحققي من الإنترنت وحاولي مجددًا.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(register ? 'إنشاء حساب' : 'تسجيل الدخول')),
      body: Form(key: form, child: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('سجّلي الدخول لحفظ تفاعلاتك باسم حسابك. يمكنك الرجوع لتصفح الوصفات دون تسجيل.'),
        const SizedBox(height: 20),
        TextFormField(
          controller: email, enabled: !busy,
          textDirection: TextDirection.ltr,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
          validator: (value) {
            final text = value?.trim() ?? '';
            return text.isEmpty || !text.contains('@') ? 'أدخلي بريدًا إلكترونيًا صالحًا' : null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: password, enabled: !busy, obscureText: true,
          textDirection: TextDirection.ltr,
          autocorrect: false, enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'كلمة المرور'),
          validator: (value) {
            if (value == null || value.isEmpty) return 'أدخلي كلمة المرور';
            if (register && value.length < 8) return 'استخدمي 8 أحرف على الأقل';
            return null;
          },
        ),
        const SizedBox(height: 20),
        if (message != null) ...[Text(message!), const SizedBox(height: 12)],
        if (busy) const LinearProgressIndicator(),
        FilledButton(onPressed: busy ? null : submit, child: Text(register ? 'إنشاء حساب' : 'دخول')),
        TextButton(onPressed: busy ? null : () => setState(() { register = !register; message = null; }), child: Text(register ? 'لديّ حساب بالفعل' : 'إنشاء حساب جديد')),
      ])),
    ),
  );
}
