import 'package:flutter/material.dart';
import '../../data/project_repository.dart';

class ProjectsProvider extends ChangeNotifier {
  final _repository = ProjectRepository();

  List<dynamic> _projects = [];
  Map<String, dynamic>? _selectedProject;
  List<String> _regions = [];
  bool _loading = false;
  String? _error;

  List<dynamic> get projects => _projects;
  Map<String, dynamic>? get selectedProject => _selectedProject;
  List<String> get regions => _regions;
  bool get loading => _loading;
  String? get error => _error;

  /// Clears state on logout - see InvestmentProvider.reset for why this matters.
  void reset() {
    _projects = [];
    _selectedProject = null;
    _regions = [];
    _error = null;
    notifyListeners();
  }

  Future<void> fetchRegions() async {
    try {
      final list = await _repository.getRegions();
      if (list.isNotEmpty) {
        _regions = list;
        notifyListeners();
      }
    } catch (_) {
      // silent
    }
  }

  Future<void> fetchProjects({String? status, String? assetType, String? animalType}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _projects = await _repository.getProjects(status: status, assetType: assetType, animalType: animalType);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProjectById(String id) async {
    _loading = true;
    _error = null;
    _selectedProject = null;
    notifyListeners();
    try {
      _selectedProject = await _repository.getProjectById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
