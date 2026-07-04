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

  static Future<void> handleItineraryShareLink(Uri uri) async {
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    final navigator = navigatorKey.currentState;
    final context = navigator?.context;
    if (navigator == null || context == null) return;

    try {
      final dio = sl<DioClient>().dio;
      final previewResponse = await dio.get('/itinerary/share-link/$token');
      final data = Map<String, dynamic>.from(previewResponse.data as Map);
      final itineraryId = (data['itineraryId'] ?? '').toString();
      final itineraryTitle = (data['itineraryTitle'] ?? 'lịch trình')
          .toString();
      final ownerName = (data['ownerName'] ?? 'Chủ lịch trình').toString();

      if (!context.mounted) return;
      if (itineraryId.isEmpty) {
        _showMessage(context, 'Link chia sẻ lịch trình không hợp lệ.');
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
      final userId = await AuthUtils.requireCurrentUserId();
      await dio.post(
        '/itinerary/share-link/respond',
        data: {
          'userId': userId,
          'token': token,
          'action': accepted ? 'accept' : 'reject',
        },
      );

      if (!context.mounted) return;
      _showMessage(
        context,
        accepted
            ? 'Đã tham gia lịch trình được chia sẻ.'
            : 'Đã từ chối lời mời tham gia lịch trình.',
      );

      if (accepted) {
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
    } catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          'Không thể mở lời mời chia sẻ: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
