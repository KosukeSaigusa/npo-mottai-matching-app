import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../../../auth/auth.dart';
import '../../../auth/ui/auth_controller.dart';

@RoutePage()
class SignInSamplePage extends ConsumerWidget {
  const SignInSamplePage({super.key});

  /// [AutoRoute] で指定するパス文字列。
  static const path = '/signInSample';

  /// [SignInSamplePage] に遷移する際に `context.router.pushNamed` で指定する文字列。
  static const location = path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サインインページ'),
      ),
      body: Center(
        child: Column(
          children: [
            // Google
            SizedBox(
              height: 50,
              child: SignInButton(
                Buttons.google,
                text: 'Google でサインイン',
                onPressed: () async => ref
                    .read(authControllerProvider)
                    .signIn(SignInMethod.google),
              ),
            ),
            // Apple
            SizedBox(
              height: 50,
              child: SignInButton(
                Buttons.apple,
                text: 'Apple でサインイン',
                onPressed: () async =>
                    ref.read(authControllerProvider).signIn(SignInMethod.apple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}