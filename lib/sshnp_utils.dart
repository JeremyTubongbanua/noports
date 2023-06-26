import 'dart:io';

/// Get the home directory or null if unknown.
String? getHomeDirectory({bool throwIfNull = false}) {
  String? homeDir;
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
      homeDir = Platform.environment['HOME'];
    case 'windows':
      homeDir = Platform.environment['USERPROFILE'];
    case 'android':
      // Probably want internal storage.
      homeDir = '/storage/sdcard0';
    case 'ios':
      // iOS doesn't really have a home directory.
    case 'fuchsia':
      // I have no idea.
    default:
      homeDir = null;
  }
  if (throwIfNull && homeDir == null) {
    throw ('\nUnable to determine your home directory: please set environment variable\n\n');
  }
  return homeDir;
}

/// Get the local username or null if unknown
String? getUserName({bool throwIfNull = false}) {
  Map<String, String> envVars = Platform.environment;
  if (Platform.isLinux || Platform.isMacOS) {
    return envVars['USER'];
  } else if (Platform.isWindows) {
    return envVars['USERPROFILE'];
  }
  if (throwIfNull) {
    throw ('\nUnable to determine your username: please set environment variable\n\n');
  }
  return null;
}

Future<bool> fileExists(String file) async {
  bool f = await File(file).exists();
  return f;
}

bool checkNonAscii(String test) {
  var extra = test.replaceAll(RegExp(r'[a-zA-Z0-9_]*'), '');
  if ((extra != '') || (test.length > 15)) {
    return true;
  } else {
    return false;
  }
}

String getDefaultAtKeysFilePath(String homeDirectory, String atSign) {
return '$homeDirectory/.atsign/keys/${atSign}_key.atKeys'
    .replaceAll('/', Platform.pathSeparator);
}

String getDefaultSshDirectory(String homeDirectory) {
return '$homeDirectory/.ssh/'
    .replaceAll('/', Platform.pathSeparator);
}