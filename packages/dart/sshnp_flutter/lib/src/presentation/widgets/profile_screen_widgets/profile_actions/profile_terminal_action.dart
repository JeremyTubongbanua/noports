import 'dart:developer';

import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noports_core/sshnp.dart';
import 'package:sshnp_flutter/src/controllers/navigation_controller.dart';
import 'package:sshnp_flutter/src/controllers/navigation_rail_controller.dart';
import 'package:sshnp_flutter/src/controllers/terminal_session_controller.dart';
import 'package:sshnp_flutter/src/presentation/widgets/profile_screen_widgets/profile_actions/profile_action_button.dart';
import 'package:sshnp_flutter/src/repository/private_key_manager_repository.dart';
import 'package:sshnp_flutter/src/utility/sizes.dart';

import '../../../../repository/profile_private_key_manager_repository.dart';
import '../../utility/custom_snack_bar.dart';

class ProfileTerminalAction extends ConsumerStatefulWidget {
  final SshnpParams params;
  const ProfileTerminalAction(this.params, {Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileTerminalAction> createState() => _ProfileTerminalActionState();
}

class _ProfileTerminalActionState extends ConsumerState<ProfileTerminalAction> {
  Future<void> showProgress(String status) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          gapH16,
          Text(status),
        ],
      )),
    );
  }

  Future<void> onPressed() async {
    if (mounted) {
      showProgress('Starting Shell Session...');
    }

    /// Issue a new session id
    final sessionId = ref.watch(terminalSessionController.notifier).createSession();

    /// Create the session controller for the new session id
    final sessionController = ref.watch(terminalSessionFamilyController(sessionId).notifier);
    // TODO: add try
    try {
      // TODO ensure that this keyPair gets uploaded to the app first
      // final privateKeyManager = ref.watch(privateKeyManagerFamilyController(privateKeyNickname));

      // final params = privateKeyManager.when(data: (value) {
      //   log('content: ${value.content}, passPhrase: ${value.passPhrase}');

      //   return SshnpParams.merge(
      //     widget.params,
      //     SshnpPartialParams(identityFile: value.content, identityPassphrase: value.passPhrase),
      //   );
      // }, error: (error, stackTrace) {
      //   log(error.toString());
      // }, loading: () {
      //   log('loading');
      // });

      AtClient atClient = AtClientManager.getInstance().atClient;
      // TODO: Delete the below line
      // DartSshKeyUtil keyUtil = DartSshKeyUtil();
      // widget.params was originally used
      // AtSshKeyPair keyPair = await keyUtil.getKeyPair(
      //   identifier: widget.params.identityFile ?? 'id_${atClient.getCurrentAtSign()!.replaceAll('@', '')}',
      // );
      // TODO: Get values from biometric storage (PrivateKeyManagerController)

      final profilePrivateKey =
          await ProfilePrivateKeyManagerRepository.readProfilePrivateKeyManager(widget.params.profileName ?? '');
      final privateKeyManager =
          await PrivateKeyManagerRepository.readPrivateKeyManager(profilePrivateKey.privateKeyNickname);
      // log('private key is: ${privateKeyManager!.privateKeyFileName}');
      // log('private key manager passphrase is: ${privateKeyManager.passPhrase}');
      // AtSshKeyPair keyPair = AtSshKeyPair.fromPem(
      //   privateKeyManager.content,
      //   identifier: privateKeyManager.privateKeyFileName,
      //   passphrase: privateKeyManager.passPhrase,
      //   // passphrase: privateKeyManager.passPhrase,
      // );
      final keyPair = privateKeyManager.toAtSshKeyPair();

      final sshnp = Sshnp.dartPure(
        // params: sshnpParams,
        params: SshnpParams.merge(
          widget.params,
          SshnpPartialParams(
            verbose: kDebugMode,
            idleTimeout: 30,
          ),
        ),
        atClient: atClient,
        identityKeyPair: keyPair,
      );

      final result = await sshnp.run();
      if (result is SshnpError) {
        throw result;
      }

      if (result is SshnpCommand) {
        if (sshnp.canRunShell) {
          if (mounted) {
            context.pop();
            showProgress('running shell session...');
          }
          log('running shell session...');

          SshnpRemoteProcess shell = await sshnp.runShell();
          if (mounted) {
            context.pop();
            showProgress('starting terminal session...');
          }
          log('starting terminal session');
          sessionController.startSession(
            shell,
            terminalTitle: '${widget.params.sshnpdAtSign}-${widget.params.device}',
          );
        }

        sessionController.issueDisplayName(widget.params.profileName!);

        ref.read(navigationRailController.notifier).setRoute(AppRoute.terminal);
        if (mounted) {
          context.pushReplacementNamed(AppRoute.terminal.name);
        }
      }
      //TODO: Add catch
    } catch (e) {
      sessionController.dispose();
      if (mounted) {
        log('error: ${e.toString()}');
        context.pop();
        CustomSnackBar.error(content: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //TODO: Add a terminal icon that calls on pressed. Reuse old code
    return ProfileActionButton(onPressed: onPressed, icon: const Icon(Icons.terminal));
    // final profilePrivateKeys = ref.watch(profilePrivateKeyManagerListController);
    // return profilePrivateKeys.when(
    //     data: (data) {
    //       return PopupMenuButton(
    //         icon: const Icon(Icons.terminal),
    //         tooltip: 'select a private key to ssh with',
    //         itemBuilder: (itemBuilderContext) => data
    //             .map((e) => PopupMenuItem(
    //                   onTap: (() async => await ref.read(profilePrivateKeyManagerListController.notifier).remove(e)),
    //                   child: Row(
    //                     children: [
    //                       const Icon(Icons.vpn_key),
    //                       gapW12,
    //                       Text(e),
    //                     ],
    //                   ),
    //                 ))
    //             .toList(),
    //       );
    //     },
    //     error: (error, stack) => Center(child: Text(error.toString())),
    //     loading: () => const Center(child: CircularProgressIndicator()));
  }
}