import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sshnp_gui/src/presentation/widgets/navigation/app_navigation_mobile_dialog.dart';
import 'package:sshnp_gui/src/utility/constants.dart';

import '../../../utility/sizes.dart';
import 'home_screen_actions/home_screen_action_callbacks.dart';
import 'home_screen_core.dart';

class HomeScreenMobile extends ConsumerWidget {
  const HomeScreenMobile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                showDialog(context: context, builder: ((context) => const AppNavigationMobileDialog()));
              },
              icon: const Icon(Icons.menu)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.currentConnections,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              Text(
                strings.currentConnectionsDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        body: const Padding(
          padding: EdgeInsets.only(top: Sizes.p21, left: Sizes.p10, right: Sizes.p10),
          child: HomeScreenCore(),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: UniqueKey(),
              onPressed: () {
                HomeScreenActionCallbacks.newProfileAction(ref, context);
              },
              child: const Icon(Icons.add_circle_outline),
            ),
            gapW8,
            FloatingActionButton(
              backgroundColor: Colors.white,
              heroTag: UniqueKey(),
              onPressed: () {
                HomeScreenActionCallbacks.import(ref, context);
              },
              child: const Icon(
                Icons.file_upload_outlined,
                color: kPrimaryColor,
              ),
            ),
          ],
        ));
  }
}
