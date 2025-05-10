import 'dart:convert';
import 'package:metia/api/extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExtensionManager {
  static const String _extensionsKey = 'installed_extensions';
  static const String _currentExtensionKey = 'current_extension';
  static const String _lastIdKey = 'last_extension_id';
  static final ExtensionManager _instance = ExtensionManager._internal();
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  factory ExtensionManager() {
    return _instance;
  }

  ExtensionManager._internal();

  Future<void> init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  Future<int> _getNextId() async {
    final lastId = _prefs.getInt(_lastIdKey) ?? 0;
    final nextId = lastId + 1;
    await _prefs.setInt(_lastIdKey, nextId);
    return nextId;
  }

  List<Extension> getExtensions() {
    if (!_isInitialized) {
      print('ExtensionManager not initialized');
      return [];
    }

    final String? extensionsJson = _prefs.getString(_extensionsKey);
    if (extensionsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(extensionsJson);
      List<Extension> extensions = [];
      for (var extension in decoded) {
        extensions.add(
          Extension(
            episodeListApi: extension["episodeListApi"],
            title: extension["title"],
            iconUrl: extension["iconUrl"],
            dub: extension["dub"],
            sub: extension["sub"],
            language: extension["language"],
            id: extension["id"],
          ),
        );
      }
      return extensions;
    } catch (e) {
      print('Error decoding extensions: $e');
      return [];
    }
  }

  Future<void> addExtension(Extension extension) async {
    if (!_isInitialized) {
      print('ExtensionManager not initialized');
      return;
    }

    final extensions = getExtensions();
    final id = await _getNextId();
    extension.id = id;
    extensions.add(extension);
    await _saveExtensions(extensions);
  }

  Future<void> removeExtension(int index) async {
    if (!_isInitialized) {
      print('ExtensionManager not initialized');
      return;
    }

    final extensions = getExtensions();
    if (index >= 0 && index < extensions.length) {
      extensions.removeAt(index);
      await _saveExtensions(extensions);
    }
  }

  Future<void> setExtensions(List<Extension> extensions) async {
    if (!_isInitialized) {
      print('ExtensionManager not initialized');
      return;
    }

    // Assign IDs to any extensions that don't have them
    for (var extension in extensions) {
      if (!extension.hasId()) {
        extension.id = await _getNextId();
      }
    }

    await _saveExtensions(extensions);
  }

  Future<void> _saveExtensions(List<Extension> extensions) async {
    try {
      final String encoded = jsonEncode(
      extensions.map((extension) => extension.toMap()).toList()
      );
      await _prefs.setString(_extensionsKey, encoded);
    } catch (e) {
      print('Error saving extensions: $e');
    }
  }

  bool isEmpty() {
    return getExtensions().isEmpty;
  }

  Extension? getCurrentExtension() {
    if (!_isInitialized) {
      print('ExtensionManager not initialized');
      return null;
    }

    final String? currentExtensionJson = _prefs.getString(_currentExtensionKey);
    if (currentExtensionJson == null) return null;

    try {
      final Map<String, dynamic> decoded = jsonDecode(currentExtensionJson);
      return Extension(
        episodeListApi: decoded["episodeListApi"],
        title: decoded["title"],
        iconUrl: decoded["iconUrl"],
        dub: decoded["dub"],
        sub: decoded["sub"],
        language: decoded["language"],
        id: decoded["id"],
      );
    } catch (e) {
      print('Error decoding current extension: $e');
      return null;
    }
  }

  bool isMainExtension(Extension extension) {
    final currentExtension = getCurrentExtension();
    return currentExtension != null && currentExtension.id == extension.id;
  }

  Future<void> setCurrentExtension(int id) async {
    if (!_isInitialized) {
      print('ExtensionManager not initialized');
      return;
    }

    final extensions = getExtensions();
    final extension = extensions.firstWhere(
      (ext) => ext.id == id,
      orElse: () => throw Exception('Extension not found'),
    );

    try {
      final String encoded = jsonEncode(extension.toMap());
      await _prefs.setString(_currentExtensionKey, encoded);
    } catch (e) {
      print('Error saving current extension: $e');
    }
  }
}
