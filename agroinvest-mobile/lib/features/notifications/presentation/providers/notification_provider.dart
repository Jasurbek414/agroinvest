import 'package:flutter/material.dart';
import '../../data/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final _repository = NotificationRepository();

  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;
  String? _error;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  String? get error => _error;

  void reset() {
    _notifications = [];
    _unreadCount = 0;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      notifyListeners();
    } catch (_) {
      // silent - the badge simply won't update if this fails
    }
  }

  Future<void> fetchNotifications() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _repository.getNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1 && _notifications[index]['isRead'] != true) {
        _notifications[index] = {..._notifications[index], 'isRead': true};
        _unreadCount = (_unreadCount - 1).clamp(0, 1 << 30);
        notifyListeners();
      }
    } catch (_) {
      // non-critical
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      _notifications = _notifications.map((n) => {...n, 'isRead': true}).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {
      // non-critical
    }
  }
}
