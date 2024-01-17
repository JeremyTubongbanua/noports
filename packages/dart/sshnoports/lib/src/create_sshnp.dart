import 'dart:io';

import 'package:noports_core/sshnp_foundation.dart';
import 'package:at_client/at_client.dart';
import 'package:sshnoports/src/extended_arg_parser.dart';

typedef AtClientGenerator = Future<AtClient> Function(SshnpParams params);

Future<Sshnp> createSshnp(
  SshnpParams params, {
  AtClient? atClient,
  AtClientGenerator? atClientGenerator,
  SupportedSshClient sshClient = DefaultExtendedArgs.sshClient,
  bool legacyDaemon = DefaultExtendedArgs.legacyDaemon,
}) async {
  atClient ??= await atClientGenerator?.call(params);

  if (atClient == null) {
    throw ArgumentError(
        'atClient must be provided or atClientGenerator must be provided');
  }

  if (legacyDaemon) {
    // ignore: deprecated_member_use
    return Sshnp.unsigned(
      atClient: atClient,
      params: params,
    );
  }

  switch (sshClient) {
    case SupportedSshClient.openssh:
      return Sshnp.openssh(
        atClient: atClient,
        params: params,
      );
    case SupportedSshClient.dart:
      String identityFile = params.identityFile ??
          (throw ArgumentError(
            'Identity file is mandatory when using the dart client.',
          ));
      String pemText = await File(identityFile).readAsString();
      AtSshKeyPair identityKeyPair = AtSshKeyPair.fromPem(
        pemText,
        identifier: params.identityFile!,
        passphrase: params.identityPassphrase,
      );
      return Sshnp.dartPure(
        atClient: atClient,
        params: params,
        identityKeyPair: identityKeyPair,
      );
  }
}