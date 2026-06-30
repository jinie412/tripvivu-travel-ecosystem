import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
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
}
