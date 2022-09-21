import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:sshnoports/api_util.dart';

/// Sets up your device's atSign for you. Just enter your email address and the binary will cycle through atSigns for you to choose from. Once you choose an atSign, it will prompt you for an OTP (one-time-password). Upon giving the correct OTP, it will activate your atSign and generate an .atKeys file inside the `~/.atsign/keys/` directory.
/// This binary should realistically be only ran once to initialize and register the device's atSign.
/// If you go to your emails' atSigns dashboard (at `my.atsign.com/dashboard`), you can reset/delete the atSign and the atSign's keys will no longer work on the device. You can re-activate your atSign by onboarding via one of our apps or [at_onboarding_cli](https://github.com/atsign-foundation/at_libraries/tree/trunk/at_onboarding_cli)
/// Run this file via `dart run bin/register_tool.dart -e <email@email.com>`

const String defaultRootUrl = 'root.atsign.org:64';
const String keysDirectory = '~/.atsign/keys/';

void main(List<String> args) {
  final ArgParser parser = _initParser();

  late ArgResults results;
  try {
    results = parser.parse(args);
  } catch (exception) {
    _printUsage(parser);
    exit(1);
  }

  final String email = results['email'];
  final String rootUrl = results['rooturl'];

  if (!_isValidEmail(email)) {
    print(
        '\'$email\' is an invalid email. Try something like \'info@atsign.com\'');
    return;
  }

  if (!_isValidRootUrl(rootUrl)) {
    print(
        '\'$rootUrl\' is an invalid root url. Try something like \'root.atsign.org:64\'');
    return;
  }

  final ApiUtil apiUtil = ApiUtil();

  startRepl(apiUtil, email, rootUrl);
}

/// ====================================================
/// REPL
/// ====================================================

Future<void> startRepl(ApiUtil apiUtil, String email, String rootUrl) async {
  // 1. i am the client
  // 2. i am the device
  print('\u001b[37mWelcome to the sshnp setup tool!');
  print(
      'Which one are you? (\'\u001b[31mc\u001b[37m\'=client or \'\u001b[31md\u001b[37m\'=device)');
  String choice = getChoice();
  if (!['c', 'd'].contains(choice)) {
    print('Invalid choice. (c/d)\n');
    startRepl(apiUtil, email, rootUrl);
    exit(1);
  }

  if (choice == 'c') {
    print('\u001b[32mYou entered the client setup tool.\u001b[37m');
    do {
      _printClientUsage();
      choice = getChoice();
    } while (!['1'].contains(choice));

    if (choice == '1') {
      await _onboardNewAtSign(apiUtil, email, rootUrl);
    }

  } else if (choice == 'd') {
    print('You entered the device setup tool.');
    do {
      _printDeviceUsage();
      choice = getChoice();
    } while (!['1', '2'].contains(choice));

    if(choice == '1') {
      await _onboardNewAtSign(apiUtil, email, rootUrl);
    } else if(choice == '2') {
      print('\u001b[31mUnder construction...');
    }
  }
}

Future<void> _onboardNewAtSign(
  ApiUtil apiUtil,
  String email,
  String rootUrl,
) async {
  String choice;
  int numAtSigns = 5; // how many atSigns to show at at ttime

  List<String> atSigns;
  choice = 'r';
  do {
    print('Choose an atSign from the list below:');
    atSigns = await apiUtil.getFreeAtSigns(numAtSigns);
    _printAtSigns(atSigns);
    print('r to refresh');
    choice = getChoice();
  } while (choice == 'r' ||
      ((int.parse(choice) > numAtSigns) || int.parse(choice) <= 0));
  String atSign = atSigns[int.parse(choice) - 1];
  print('\u001b[32mYou chose @$atSign');
  bool sentSuccessfully = await apiUtil.registerAtSign(atSign, email);
  if (!sentSuccessfully) {
    print('\u001b[31mSomething went wrong. Please try again.');
    exit(1);
  }
  print('\u001b[31mEnter the OTP sent to your email ($email):');
  String otp = getChoice(prompt: false)
      .trim()
      .replaceAll('/\u001b[.*?m/g', '')
      .replaceAll('\n', '')
      .toUpperCase(); // remove new line and color codes. also uppercase.
  String? cram = await apiUtil.registerAtSignValidate(atSign, email, otp);
  if (cram == null) {
    print('\u001b[37mSomething went wrong. Please try again.');
    exit(1);
  }

  List<String> s = rootUrl.split(":");
  AtOnboardingPreference pref = AtOnboardingPreference()
    ..rootDomain = s[0]
    ..rootPort = int.parse(s[1])
    ..cramSecret = cram
    ..downloadPath = Directory.fromUri(Uri.directory(
            '${Platform.environment['HOME']}/.atsign/keys/',
            windows: Platform.isWindows))
        .path;

  AtOnboardingService service = AtOnboardingServiceImpl(atSign, pref);
  bool onboarded = await service.onboard();
  if (onboarded) {
    print('\u001b[32mYou have successfully onboarded your atSign @$atSign');
  } else {
    print('\u001b[31mOnboard unsuccessful. Please try again.');
  }
  service.close();
}

/// Returns the user input string read from terminal. If data is returned without a line terminator. Returns null if no bytes preceded the end of input.
String getChoice({prompt = true}) {
  if (prompt) print('\u001b[31mEnter choice:');
  String input = (stdin.readLineSync() ?? '').toLowerCase();
  print('\u001b[37m');
  return input;
}

void _printClientUsage() {
  print('Choose an option:');
  print('1. Register a new atSign to this client');
}

void _printDeviceUsage() {
  print('Choose an option:');
  print('1. Register a new atSign on this device');
  print('2. Create the systemd service (startup sshnpd on boot)');
}

void _printAtSigns(List<String> atSigns) {
  for (int i = 0; i < atSigns.length; i++) {
    print('[${i + 1}]: @${atSigns[i]}');
  }
}

/// ====================================================
/// Helper functions to make main() easier to read
/// ====================================================

void _printUsage(ArgParser parser) {
  String b;
  b = '\n';
  b += 'Usage: ./register_device -e <email>';
  b += '\n';
  b += parser.usage + '\n';
  print(b);
}

ArgParser _initParser() {
  final ArgParser parser = ArgParser();

  parser.addOption(
    'email',
    abbr: 'e',
    mandatory: true,
    help: 'Email that your atSign will be registered to',
  );

  parser.addOption(
    'rooturl',
    abbr: 'r',
    mandatory: false,
    help: 'Root URL with host and port',
    defaultsTo: defaultRootUrl,
  );

  return parser;
}

bool _isValidEmail(String? email) {
  return email != null && email.isNotEmpty && email.contains('@');
}

bool _isValidRootUrl(String? rootUrl) {
  return rootUrl != null && rootUrl.isNotEmpty && rootUrl.contains(':');
}