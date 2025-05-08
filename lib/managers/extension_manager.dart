import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExtensionManager {
  static const String _extensionsKey = 'installed_extensions';
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
} 