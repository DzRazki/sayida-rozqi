import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UserAuthScreen extends StatefulWidget {
  const UserAuthScreen({super.key});
  @override
  State<UserAuthScreen> createState() => _UserAuthScreenState();
}

class _UserAuthScreenState extends State<UserAuthScreen> {
  static const _googleWebClientId =
      '727229417562-vo4rkvh6vj6n83mkq1q5mr4mojlhdjjr.apps.googleusercontent.com';

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
    if (user == null || !mounted) {
      return;
    }
    SharedPreferences? prefs;
    bool seen = false;
    final key = 'youtube-channel-invite:${user.id}';
    try {
      prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(key) ?? false;
    } catch (_) {
      // An optional invitation must not prevent sign-in.
    }
    if (!mounted || Supabase.instance.client.auth.currentUser?.id != user.id) {
      return;
    }
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
      if (!mounted || Supabase.instance.client.auth.currentUser?.id != user.id) {
        return;
      }
      try {
        await prefs?.setBool(key, true);
      } catch (_) {}
      if (!mounted) {
        return;
      }
      if (openChannel == true) {
        try {
          final launched = await launchUrl(
            Uri.parse('https://www.youtube.com/@chef4razki'),
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            throw StateError('Channel could not be opened');
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تعذر فتح YouTube. يمكنك زيارة القناة لاحقًا من تبويب القناة.'),
            ));
          }
        }
      }
    }
    if (mounted && Supabase.instance.client.auth.currentUser?.id == user.id) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> signInWithGoogle() async {
    if (busy) {
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    var stage = 'google-account';
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: _googleWebClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }
      stage = 'google-token';
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        if (mounted) {
          setState(() => message = 'لم ترجع Google رمز هوية. التشخيص: google-token / missing-id-token');
        }
        return;
      }
      stage = 'supabase-token';
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      stage = 'finish-sign-in';
      await finishSignIn();
    } on PlatformException catch (error) {
      final apiCode = RegExp(r'ApiException:\s*(\d+)').firstMatch(error.message ?? '')?.group(1);
      const safeCodes = {'sign_in_failed', 'network_error', 'sign_in_canceled', 'sign_in_required'};
      final code = safeCodes.contains(error.code) ? error.code : 'platform-error';
      final diagnostic = apiCode == null ? code : '$code / api-$apiCode';
      if (mounted) {
        setState(() => message = 'تعذر إكمال دخول Google. التشخيص: $stage / $diagnostic');
      }
    } on AuthException catch (error) {
      final status = error.statusCode;
      final safeStatus = status != null && RegExp(r'^\d{3}$').hasMatch(status) ? status : 'unknown';
      if (mounted) {
        setState(() => message = 'تعذر إكمال المصادقة. التشخيص: $stage / auth-status-$safeStatus');
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = 'تعذر إكمال الدخول. التشخيص: $stage / unexpected-error');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (auth.currentUser != null) {
        await finishSignIn();
        return;
      }
      final result = register
          ? await auth.signUp(email: email.text.trim(), password: password.text)
          : await auth.signInWithPassword(email: email.text.trim(), password: password.text);
      if (!mounted) {
        return;
      }
      if (result.session != null) {
        await finishSignIn();
      } else {
        setState(() {
          message = 'راجعي بريدك لتأكيد الحساب، ثم عودي لتسجيل الدخول. إذا لم تصلك رسالة، تحققي من البريد غير المرغوب فيه.';
          register = false;
        });
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => message = 'تعذر إكمال الطلب: ${error.message}');
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = 'تعذر الاتصال. تحققي من الإنترنت وحاولي مجددًا.');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
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
            if (value == null || value.isEmpty) {
              return 'أدخلي كلمة المرور';
            }
            if (register && value.length < 8) {
              return 'استخدمي 8 أحرف على الأقل';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        if (message != null) ...[Text(message!), const SizedBox(height: 12)],
        if (busy) const LinearProgressIndicator(),
        FilledButton(onPressed: busy ? null : submit, child: Text(register ? 'إنشاء حساب' : 'دخول')),
        const SizedBox(height: 12),
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('أو', style: Theme.of(context).textTheme.bodySmall),
          ),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : signInWithGoogle,
          icon: const Icon(Icons.login),
          label: const Text('المتابعة باستخدام Google'),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: busy ? null : () => setState(() { register = !register; message = null; }), child: Text(register ? 'لديّ حساب بالفعل' : 'إنشاء حساب جديد')),
      ])),
    ),
  );
}
