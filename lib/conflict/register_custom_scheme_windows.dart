// register_custom_scheme_windows.dart
import 'dart:io';
import 'package:win32_registry/win32_registry.dart';

void registerCustomScheme(String scheme) {
  final String appPath = Platform.resolvedExecutable;

  final String protocolRegKey = 'Software\\Classes\\$scheme';
  final RegistryValue protocolRegValue = const RegistryValue(
    'URL Protocol',
    RegistryValueType.string,
    '',
  );
  final String protocolCmdRegKey = 'shell\\open\\command';
  final RegistryValue protocolCmdRegValue = RegistryValue(
    '',
    RegistryValueType.string,
    '"$appPath" "%1"',
  );

  final regKey = Registry.currentUser.createKey(protocolRegKey);
  regKey.createValue(protocolRegValue);
  regKey.createKey(protocolCmdRegKey).createValue(protocolCmdRegValue);
}
