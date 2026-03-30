import 'package:flutter/foundation.dart';
import '../models/material_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AnnouncementProvider extends ChangeNotifier {
  List<Announcement> _announcements = [];
  bool _loading = false;
  bool _posting = false;
  String? _errorMessage;
  String? _successMessage;

  List<Announcement> get announcements => _announcements;
  bool get loading => _loading;
  bool get posting => _posting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // ── Fetch ─────────────────────────────────────────────────────────
  Future<void> fetchAnnouncements() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await ApiService.get(AppConstants.announcementsUrl);
      final list = res is List ? res : (res['data'] ?? res['announcements'] ?? []);
      _announcements = (list as List)
          .map((a) => Announcement.fromJson(a as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load announcements';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Create (staff/admin only) ─────────────────────────────────────
  Future<bool> createAnnouncement({
    required String title,
    required String description,
    required String priority,
    required String department,
  }) async {
    _posting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await ApiService.post(AppConstants.announcementsUrl, {
        'title': title,
        'description': description,
        'priority': priority,
        'department': department,
      });
      _successMessage = 'Announcement posted!';
      await fetchAnnouncements();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _posting = false;
      notifyListeners();
    }
  }

  // ── Update (staff/admin only) ─────────────────────────────────────
  Future<bool> updateAnnouncement(
    String id, {
    required String title,
    required String description,
    required String priority,
    required String department,
  }) async {
    _posting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await ApiService.put('${AppConstants.announcementsUrl}/$id', {
        'title': title,
        'description': description,
        'priority': priority,
        'department': department,
      });
      _successMessage = 'Announcement updated!';
      await fetchAnnouncements();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _posting = false;
      notifyListeners();
    }
  }

  // ── Delete (staff/admin only) ─────────────────────────────────────
  Future<bool> deleteAnnouncement(String id) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await ApiService.delete('${AppConstants.announcementsUrl}/$id');
      _announcements.removeWhere((a) => a.id == id);
      _successMessage = 'Announcement deleted';
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}