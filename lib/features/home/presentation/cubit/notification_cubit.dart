import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/features/home/domain/usecases/notification_usecases.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final GetNotificationsUseCase _getNotifications;

  NotificationCubit({required GetNotificationsUseCase getNotifications})
      : _getNotifications = getNotifications,
        super(const NotificationInitial());

  Future<void> loadNotifications() async {
    emit(const NotificationLoading());
    try {
      final notifications = await _getNotifications();
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }
}
