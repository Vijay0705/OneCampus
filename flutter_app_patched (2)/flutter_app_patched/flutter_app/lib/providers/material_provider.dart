import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/material_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class MaterialProvider extends ChangeNotifier {
  List<MaterialItem> _materials = [];
  bool _loading = false;
  bool _uploading = false;
  String? _errorMessage;
  String? _successMessage;
  String _selectedType = 'all';
  String _selectedSubject = 'All';
  String _selectedSemester = 'All';

  List<MaterialItem> get materials {
    var list = _materials;
    if (_selectedType != 'all') {
      list = list.where((m) => m.type == _selectedType).toList();
    }
    if (_selectedSubject != 'All') {
      list = list.where((m) => m.subject == _selectedSubject).toList();
    }
    if (_selectedSemester != 'All') {
      list = list.where((m) => m.semester == _selectedSemester).toList();
    }
    return list;
  }

  bool get loading => _loading;
  bool get uploading => _uploading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get selectedType => _selectedType;
  String get selectedSubject => _selectedSubject;
  String get selectedSemester => _selectedSemester;

  List<String> get subjects {
    final s = _materials.map((m) => m.subject).toSet().toList()..sort();
    return ['All', ...s];
  }

  List<String> get semesters {
    final s = _materials.map((m) => m.semester).toSet().toList()..sort();
    return ['All', ...s];
  }

  void setType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  void setSubject(String subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  void setSemester(String semester) {
    _selectedSemester = semester;
    notifyListeners();
  }

  Future<void> fetchMaterials() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await ApiService.get(AppConstants.materialsUrl);
      final list = res is List ? res : (res['data'] ?? res['materials'] ?? []);
      _materials = (list as List)
          .map((m) => MaterialItem.fromJson(m as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load materials. Check your connection.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadMaterial({
    required Uint8List fileBytes,
    required String fileName,
    required String title,
    required String subject,
    required String type,
    required String semester,
  }) async {
    _uploading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await ApiService.uploadFile(
        AppConstants.materialsUrl,
        fileBytes,
        fileName,
        {
          'title': title,
          'subject': subject,
          'type': type,
          'semester': semester,
        },
      );
      _successMessage = 'Material uploaded successfully!';
      await fetchMaterials();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Upload failed. Check your connection.';
      return false;
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}