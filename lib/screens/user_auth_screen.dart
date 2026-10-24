import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() { busy = true; message = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (auth.currentUser != null) {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      final result = register
          ? await auth.signUp(email: email.text.trim(), password: password.text)
          : await auth.signInWithPassword(email: email.text.trim(), password: password.text);
      if (!mounted) return;
      if (result.session != null) {
        Navigator.of(context).pop(true);
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
