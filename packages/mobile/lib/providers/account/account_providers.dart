import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mottai_flutter_app/providers/auth/auth_providers.dart';
import 'package:mottai_flutter_app_models/models.dart';

/// ユーザーの account ドキュメントを購読する StreamProvider
final accountStreamProvider = StreamProvider<Account?>((ref) {
  final userId = ref.watch(userIdProvider).value;
  if (userId == null) {
    return Stream.value(null);
  }
  return AccountRepository.subscribeAccount(accountId: userId);
});

/// ユーザーの account ドキュメントを取得する FutureProvider
final accountFutureProvider = FutureProvider<Account?>((ref) async {
  final userId = ref.watch(userIdProvider).value;
  if (userId == null) {
    return Future.value(null);
  }
  final account = await AccountRepository.fetchAccount(accountId: userId);
  return account;
});

/// サインイン済みのユーザーの DocumentReference<Account> を取得する Provider
/// 未サインインの場合は例外をスローする。
final accountRefProvider = Provider<DocumentReference<Account>>((ref) {
  final userId = ref.watch(userIdProvider).value;
  if (userId == null) {
    throw const SignInRequiredException();
  }
  return AccountRepository.accountRef(accountId: userId);
});
