import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mottai_flutter_app_models/models.dart';

import '../../providers/attending_room/attending_room.dart';
import '../../providers/auth/auth.dart';
import '../../providers/message/message.dart';
import '../../providers/public_user/public_user_providers.dart';
import '../../services/scaffold_messenger_service.dart';
import '../../theme/theme.dart';
import '../../utils/date_time.dart';
import '../../utils/utils.dart';
import '../../widgets/common/image.dart';
import '../../widgets/loading/loading.dart';
import '../room/room_page.dart';

class RoomsPage extends StatefulHookConsumerWidget {
  const RoomsPage({Key? key}) : super(key: key);

  static const path = '/rooms';
  static const name = 'RoomsPage';
  static const location = path;

  @override
  ConsumerState<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends ConsumerState<RoomsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ref.watch(attendingRoomsStreamProvider).when<Widget>(
            loading: () => const PrimarySpinkitCircle(),
            error: (error, __) {
              return Center(
                child: SizedBox(
                  width: 280,
                  child: Text(
                    error.toString(),
                    style: grey12,
                  ),
                ),
              );
            },
            data: (attendingRooms) => attendingRooms.isEmpty
                ? Center(
                    child: Text(
                      'まだメッセージしている相手がいません。',
                      style: grey12,
                    ),
                  )
                : ListView.builder(
                    itemBuilder: (context, index) =>
                        AttendingRoomWidget(attendingRoom: attendingRooms[index]),
                    itemCount: attendingRooms.length,
                  ),
          ),
      floatingActionButton: _showFloatingActionButton ? _fab : null,
    );
  }

  // TODO: 開発中のみ。後で消す。
  bool get _showFloatingActionButton {
    try {
      return (ref.watch(attendingRoomsStreamProvider).value ?? <AttendingRoom>[]).isEmpty;
    } on SignInRequiredException {
      return false;
    } on Exception {
      return false;
    }
  }

  Widget get _fab => FloatingActionButton(
        child: const FaIcon(FontAwesomeIcons.solidComment),
        onPressed: () async {
          final userId = ref.watch(userIdProvider).value;
          if (userId == null) {
            return;
          }
          final roomId = uuid;
          const hostId = String.fromEnvironment('HOST_1_ID');
          await ref
              .read(messageRepositoryProvider)
              .roomRef(roomId: roomId)
              .set(Room(roomId: roomId, hostId: hostId, workerId: userId));
          await ref
              .read(messageRepositoryProvider)
              .attendingRoomRef(userId: userId, roomId: roomId)
              .set(AttendingRoom(
                roomId: roomId,
                partnerId: hostId,
              ));
          ref.read(scaffoldMessengerServiceProvider).showSnackBar('【テスト用】ホスト 1 とのルームを作成しました。');
        },
      );
}

/// AttendingRoom ページのひとつひとつのウィジェット
class AttendingRoomWidget extends HookConsumerWidget {
  const AttendingRoomWidget({Key? key, required this.attendingRoom}) : super(key: key);
  final AttendingRoom attendingRoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider).value;
    return userId != null
        ? InkWell(
            onTap: () async {
              // 非同期的に lastReadAt を更新する
              unawaited(ref
                  .read(messageRepositoryProvider)
                  .readStatusRef(roomId: attendingRoom.roomId, readStatusId: userId)
                  .set(const ReadStatus(), SetOptions(merge: true)));
              await Navigator.pushNamed<void>(
                context,
                RoomPage.location(roomId: attendingRoom.roomId),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ref.watch(publicUserStreamProvider(attendingRoom.partnerId)).when<Widget>(
                        loading: () => const CircleImagePlaceholder(diameter: 48),
                        error: (error, stackTrace) => const CircleImagePlaceholder(diameter: 48),
                        data: (publicUser) => publicUser == null
                            ? const CircleImagePlaceholder(diameter: 48)
                            : CircleImageWidget(diameter: 48, imageURL: publicUser.imageURL),
                      ),
                  const Gap(8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ref.watch(publicUserStreamProvider(attendingRoom.partnerId)).when<Widget>(
                              loading: () => const SizedBox(),
                              error: (error, stackTrace) => const SizedBox(),
                              data: (publicUser) => publicUser == null
                                  ? const Text('-', style: bold12)
                                  : Text(publicUser.displayName, style: bold12),
                            ),
                        ref.watch(messagesStreamProvider(attendingRoom.roomId)).when<Widget>(
                              loading: () => const SizedBox(),
                              error: (error, stackTrace) {
                                debugPrint('=============================');
                                debugPrint('⛔️ $error');
                                debugPrint(stackTrace.toString());
                                debugPrint('=============================');
                                return const SizedBox();
                              },
                              data: (messages) => Text(
                                messages.isEmpty ? 'ルームが作成されました。' : messages.first.body,
                                style: grey12,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ref.watch(messagesStreamProvider(attendingRoom.roomId)).when<Widget>(
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                            data: (messages) => Text(
                              messages.isEmpty
                                  ? ''
                                  : humanReadableDateTimeString(messages.first.createdAt),
                              style: grey10,
                            ),
                          ),
                      const Gap(4),
                      ref.watch(unreadCountStreamProvider(attendingRoom.roomId)).when<Widget>(
                            loading: () => const SizedBox(width: 20, height: 20),
                            error: (_, __) => const SizedBox(width: 20, height: 20),
                            data: (count) => count > 0
                                ? Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    child: Center(
                                      child: Text(
                                        count > 9 ? '9+' : count.toString(),
                                        style: whiteBold10,
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 20, height: 20),
                          ),
                    ],
                  ),
                ],
              ),
            ),
          )
        : const SizedBox();
  }
}