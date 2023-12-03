import 'dart:async';

// Current implementation uses ServerSocket, which will be replaced with an
// internal Dart stream at a later time
import 'dart:io' show ServerSocket;

import 'package:at_utils/at_logger.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:meta/meta.dart';
import 'package:noports_core/sshnp_foundation.dart';

mixin SshnpDartSshSessionHandler on SshnpCore
    implements SshnpSshSessionHandler<SSHClient> {
  /// Set up timer to check to see if all connections are down
  @visibleForTesting
  String get terminateMessage =>
      'ssh session will terminate after ${params.idleTimeout} seconds'
      ' if it is not being used';

  @override
  Future<SSHClient> startInitialTunnelSession(
      {required String keyPairIdentifier}) async {
    // If we are starting an initial tunnel, it should be to sshrvd,
    // so it is safe to assume that sshrvdChannel is not null here
    logger.info(
        'Starting tunnel ssh session to ${sshrvdChannel.host} on port ${sshrvdChannel.sshrvdPort!} with forwardLocal of $localPort');

    AtSshKeyPair keyPair =
        await keyUtil.getKeyPair(identifier: keyPairIdentifier);

    SshClientHelper helper = SshClientHelper(logger);
    SSHClient tunnelSshClient = await helper.createSshClient(
      host: sshrvdChannel.host,
      port: sshrvdChannel.sshrvdPort!,
      username: tunnelUsername ?? getUserName(throwIfNull: true)!,
      keyPair: keyPair,
    );

    // Start local forwarding to the remote sshd
    logger.info('Starting port forwarding'
        ' from localhost:$localPort on local side'
        ' to localhost:${params.remoteSshdPort} on remote side');

    await helper.startForwarding(
      fLocalPort: localPort,
      fRemoteHost: 'localhost',
      fRemotePort: params.remoteSshdPort,
    );

    if (params.addForwardsToTunnel) {
      var optionsSplitBySpace = params.localSshOptions.join(' ').split(' ');
      logger.info('addForwardsToTunnel is true;'
          ' localSshOptions split by space is $optionsSplitBySpace');
      await helper.addForwards(optionsSplitBySpace);
    }

    logger.info(terminateMessage);

    Timer.periodic(Duration(seconds: params.idleTimeout), (timer) async {
      if (helper.counter == 0 || tunnelSshClient.isClosed) {
        timer.cancel();
        if (!tunnelSshClient.isClosed) tunnelSshClient.close();
        logger
            .shout('$sessionId | no active connections - ssh session complete');
      }
    });

    return tunnelSshClient;
  }

  @override
  Future<SSHClient> startUserSession(
      {required SSHClient tunnelSession}) async {
    throw UnimplementedError();
    // TODO v similar to startInitialTunnelSession
  }
}

class SshClientHelper {
  // TODO get rid of this
  final AtSignLogger logger;

  int counter = 0;

  @visibleForTesting
  late final SSHClient client;

  SshClientHelper(this.logger);

  Future<SSHClient> createSshClient({
    required String host,
    required int port,
    required String username,
    required AtSshKeyPair keyPair,
  }) async {
    try {
      late final SSHSocket socket;
      try {
        socket = await SSHSocket.connect(
          host,
          port,
        ).catchError((e) => throw e);
      } catch (e, s) {
        var error = SshnpError(
          'Failed to open socket to $host:$port : $e',
          error: e,
          stackTrace: s,
        );
        throw error;
      }

      try {
        client = SSHClient(
          socket,
          username: username,
          identities: [keyPair.keyPair],
          keepAliveInterval: Duration(seconds: 15),
        );
      } catch (e, s) {
        throw SshnpError(
          'Failed to create SSHClient for $username@$host:$port : $e',
          error: e,
          stackTrace: s,
        );
      }

      try {
        await client.authenticated.catchError((e) => throw e);
      } catch (e, s) {
        throw SshnpError(
          'Failed to authenticate as $username@$host:$port : $e',
          error: e,
          stackTrace: s,
        );
      }

      return client;
    } on SshnpError catch (_) {
      rethrow;
    } catch (e, s) {
      throw SshnpError(
        'SSH Client failure : $e',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> startForwarding(
      {required int fLocalPort,
      required String fRemoteHost,
      required int fRemotePort}) async {
    // TODO remove local dependency on ServerSockets
    /// Do the port forwarding for sshd
    final serverSocket = await ServerSocket.bind('localhost', fLocalPort);

    serverSocket.listen((socket) async {
      counter++;
      final forward = await client.forwardLocal(fRemoteHost, fRemotePort);
      unawaited(
        forward.stream.cast<List<int>>().pipe(socket).whenComplete(
          () async {
            counter--;
          },
        ),
      );
      unawaited(socket.pipe(forward.sink));
    }, onError: (Object error) {
      counter = 0;
    }, onDone: () {
      counter = 0;
    });
  }

  Future<void> addForwards(List<String> optionsSplitBySpace) async {
    // parse the localSshOptions, extract all of the local port forwarding
    // directives and act on all of them
    var lsoIter = optionsSplitBySpace.iterator;
    while (lsoIter.moveNext()) {
      if (lsoIter.current == '-L') {
        // we expect the args next
        bool hasArgs = lsoIter.moveNext();
        if (!hasArgs) {
          logger.warning('localSshOptions has -L with no args');
          continue;
        }
        String argString = lsoIter.current;
        // We expect args like $localPort:$remoteHost:$remotePort
        List<String> args = argString.split(':');
        if (args.length != 3) {
          logger.warning('localSshOptions has -L with bad args $argString');
          continue;
        }
        int? fLocalPort = int.tryParse(args[0]);
        String fRemoteHost = args[1];
        int? fRemotePort = int.tryParse(args[2]);
        if (fLocalPort == null || fRemoteHost.isEmpty || fRemotePort == null) {
          logger.warning('localSshOptions has -L with bad args $argString');
          continue;
        }

        // Start the forwarding
        logger.info('Starting port forwarding'
            ' from localhost:$fLocalPort on local side'
            ' to $fRemoteHost:$fRemotePort on remote side');

        await startForwarding(
          fLocalPort: fLocalPort,
          fRemoteHost: fRemoteHost,
          fRemotePort: fRemotePort,
        );
      }
    }
  }
}
