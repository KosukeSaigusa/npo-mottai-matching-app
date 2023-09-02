import 'package:auto_route/auto_route.dart';
import 'package:firebase_common/firebase_common.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/auth.dart';
import '../../../auth/ui/auth_controller.dart';
import '../../../push_notification/firebase_messaging.dart';
import '../../../root/ui/root.dart';

@RoutePage()
class EmailAndPasswordSignInPage extends ConsumerStatefulWidget {
  const EmailAndPasswordSignInPage({super.key});

  /// [AutoRoute] で指定するパス文字列。
  static const path = '/emailAndPasswordSignIn';

  /// [EmailAndPasswordSignInPage] に遷移する際に `context.router.pushNamed` で指定する文字列。
  static const location = path;

  @override
  ConsumerState<EmailAndPasswordSignInPage> createState() =>
      EmailAndPasswordSignInPageState();
}

class EmailAndPasswordSignInPageState
    extends ConsumerState<EmailAndPasswordSignInPage> {
  late final TextEditingController _emailTextEditingController;
  late final TextEditingController _passwordTextEditingController;

  @override
  void initState() {
    _emailTextEditingController = TextEditingController();
    _passwordTextEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('サインイン')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailTextEditingController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'メールアドレス',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const Gap(16),
            TextField(
              controller: _passwordTextEditingController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'パスワード',
              ),
              obscureText: true,
            ),
            const Gap(16),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await ref
                      .read(authControllerProvider)
                      .signInWithEmailAndPassword(
                        email: _emailTextEditingController.text,
                        password: _passwordTextEditingController.text,
                      );
                  navigator.pop();

                  /// [FcmTokenRepository] のインスタンス。
                  final _fcmTokenRepository = FcmTokenRepository();
                  final _token = await ref.read(getFcmTokenProvider).call();
                  final _userId = ref.read(userIdProvider);

                  final _deviceInfo = await getDeviceInfo();

                  if (_token == null || _userId == null) {
                    return;
                  }

                  await _fcmTokenRepository.setUserFcmToken(
                    userId: _userId,
                    token: _token,
                    deviceInfo: _deviceInfo,
                  );
                },
                child: const Text('サインイン'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
