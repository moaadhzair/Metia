import 'dart:convert';
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

  List<Map<String, dynamic>> getExtensions() {
    if (!_isInitialized) {
      print('ExtensionManager not initialized');
      return [];
    }
    
    final String? extensionsJson = _prefs.getString(_extensionsKey);
    if (extensionsJson == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(extensionsJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error decoding extensions: $e');
      return [];
    }
  }

  Future<void> addExtension(Map<String, dynamic> extension) async {
    if (!_isInitialized) {
      print('ExtensionManager not initialized');
      return;
    }
    
    final extensions = getExtensions();
    final id = await _getNextId();
    extension['id'] = id;
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

  Future<void> setExtensions(List<Map<String, dynamic>> extensions) async {
    if (!_isInitialized) {
      print('ExtensionManager not initialized');
      return;
    }
    
    // Assign IDs to any extensions that don't have them
    for (var extension in extensions) {
      if (!extension.containsKey('id')) {
        extension['id'] = await _getNextId();
      }
    }
    
    await _saveExtensions(extensions);
  }

  Future<void> _saveExtensions(List<Map<String, dynamic>> extensions) async {
    try {
      final String encoded = jsonEncode(extensions);
      await _prefs.setString(_extensionsKey, encoded);
    } catch (e) {
      print('Error saving extensions: $e');
    }
  }

  bool isEmpty() {
    return getExtensions().isEmpty;
  }

  Map<String, dynamic>? getCurrentExtension() {
    if (!_isInitialized) {
      print('ExtensionManager not initialized');
      return null;
    }
    
    final String? currentExtensionJson = _prefs.getString(_currentExtensionKey);
    if (currentExtensionJson == null) return null;
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(currentExtensionJson);
      return decoded;
    } catch (e) {
      print('Error decoding current extension: $e');
      return null;
    }
  }

  bool isMainExtension(Map<String, dynamic> extension) {
    final currentExtension = getCurrentExtension();
    return currentExtension != null && currentExtension["id"] == extension["id"];
  }

  Future<void> setCurrentExtension(int id) async {
    if (!_isInitialized) {
      print('ExtensionManager not initialized');
      return;
    }
    
    final extensions = getExtensions();
    final extension = extensions.firstWhere(
      (ext) => ext["id"] == id,
      orElse: () => throw Exception('Extension not found'),
    );
    
    try {
      final String encoded = jsonEncode(extension);
      await _prefs.setString(_currentExtensionKey, encoded);
    } catch (e) {
      print('Error saving current extension: $e');
    }
  }
} 