import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/food/presentation/screens/food_menu_screen.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_summary_screen.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> handlePayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map) {
        await handleData(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      if (payload.startsWith('tracking:')) return;
    }
  }

  static Future<void> handleData(Map<String, dynamic> data) async {
    final action = data['action']?.toString() ?? data['type']?.toString();
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (action == 'open_food_order') {
      final placeId = data['place_id']?.toString() ?? '';
      if (placeId.isEmpty) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => FoodMenuScreen(
            placeId: placeId,
            restaurantName:
                data['restaurant_name']?.toString() ?? 'Quán ăn gần đây',
            itineraryDetailId: data['itinerary_detail_id']?.toString(),
          ),
        ),
      );
      return;
    }

    if (action == 'open_itinerary_day' || action == 'itinerary_checkin') {
      final itineraryId = data['itinerary_id']?.toString() ?? '';
      if (itineraryId.isEmpty) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<ItineraryCubit>()),
              BlocProvider(create: (_) => sl<TrackingCubit>()),
            ],
            child: ItinerarySummaryScreen(
              itineraryId: itineraryId,
              initialVisitDate: data['visit_date']?.toString(),
              autoOpenDetail: true,
            ),
          ),
        ),
      );
    }
  }

  /// Deep link chia sẻ lịch trình đang chờ xử lý khi người dùng
  /// bấm link mà chưa đăng nhập. Sau khi đăng nhập xong,
  /// [processPendingItineraryShareLink] sẽ xử lý tiếp link này.
  static Uri? _pendingItineraryShareUri;

  static Future<void> handleItineraryShareLink(Uri uri) async {
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    final navigator = navigatorKey.currentState;
    final context = navigator?.context;
    if (navigator == null || context == null) return;

    // Ràng buộc đăng nhập: chưa đăng nhập thì chưa hiện lời mời.
    // Giữ link lại, nhắc người dùng đăng nhập; đăng nhập xong
    // MainShell sẽ gọi processPendingItineraryShareLink để hiện lời mời.
    final currentUserId = await AuthUtils.getCurrentUserId();
    if (currentUserId == null || currentUserId.isEmpty) {
      _pendingItineraryShareUri = uri;
      if (context.mounted) {
        _showMessage(
          context,
          'Vui lòng đăng nhập để mở lời mời tham gia lịch trình. '
          'Lời mời sẽ hiển thị ngay sau khi bạn đăng nhập.',
        );
      }
      return;
    }

    try {
      final dio = sl<DioClient>().dio;
      final previewResponse = await dio.get(
        '/itinerary/share-link/$token',
        queryParameters: {'userId': currentUserId},
      );
      final data = Map<String, dynamic>.from(previewResponse.data as Map);
      final itineraryId = (data['itineraryId'] ?? '').toString();
      final itineraryTitle = (data['itineraryTitle'] ?? 'lịch trình')
          .toString();
      final ownerName = (data['ownerName'] ?? 'Chủ lịch trình').toString();
      final isOwner = data['isOwner'] == true;
      final alreadyMember = data['alreadyMember'] == true;

      if (!context.mounted) return;
      if (itineraryId.isEmpty) {
        _showMessage(context, 'Link chia sẻ lịch trình không hợp lệ.');
        return;
      }

      void openItinerarySummary() {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<ItineraryCubit>()),
                BlocProvider(create: (_) => sl<TrackingCubit>()),
              ],
              child: ItinerarySummaryScreen(itineraryId: itineraryId),
            ),
          ),
        );
      }

      // Load đúng trạng thái tham gia trước khi hiện dialog mời:
      // chủ lịch trình hoặc người đã là thành viên (dù tham gia bằng
      // deep link hay lời mời trực tiếp) thì không hiện lại lời mời.
      if (isOwner) {
        _showMessage(
          context,
          'Bạn là chủ lịch trình này nên không cần tham gia bằng link mời.',
        );
        openItinerarySummary();
        return;
      }
      if (alreadyMember) {
        _showMessage(context, 'Bạn đã tham gia lịch trình này rồi.');
        openItinerarySummary();
        return;
      }

      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Lời mời tham gia lịch trình'),
          content: Text(
            'Bạn đã được $ownerName mời tham gia lịch trình "$itineraryTitle". Bạn muốn chấp nhận tham gia hay từ chối?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Từ chối'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Chấp nhận'),
            ),
          ],
        ),
      );

      if (accepted == null || !context.mounted) return;
      final respondResponse = await dio.post(
        '/itinerary/share-link/respond',
        data: {
          'userId': currentUserId,
          'token': token,
          'action': accepted ? 'accept' : 'reject',
        },
      );

      if (!context.mounted) return;
      final respondData = respondResponse.data is Map
          ? Map<String, dynamic>.from(respondResponse.data as Map)
          : const <String, dynamic>{};
      final respondMessage = (respondData['message'] ?? '').toString();
      _showMessage(
        context,
        respondMessage.isNotEmpty
            ? respondMessage
            : accepted
            ? 'Đã tham gia lịch trình được chia sẻ.'
            : 'Đã từ chối lời mời tham gia lịch trình.',
      );

      if (accepted) {
        openItinerarySummary();
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          'Không thể mở lời mời chia sẻ: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  /// Xử lý lời mời chia sẻ đã bấm trước khi đăng nhập.
  /// Được gọi khi MainShell mount (mọi luồng đăng nhập thành công
  /// đều đi qua MainShell). Không có link chờ hoặc vẫn chưa đăng nhập
  /// thì bỏ qua.
  static Future<void> processPendingItineraryShareLink() async {
    final pending = _pendingItineraryShareUri;
    if (pending == null) return;

    final currentUserId = await AuthUtils.getCurrentUserId();
    if (currentUserId == null || currentUserId.isEmpty) return;

    _pendingItineraryShareUri = null;
    await handleItineraryShareLink(pending);
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
