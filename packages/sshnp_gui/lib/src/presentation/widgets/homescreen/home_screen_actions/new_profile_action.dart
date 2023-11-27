import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sshnp_gui/src/presentation/widgets/homescreen/home_screen_actions/home_screen_action_callbacks.dart';

class NewProfileAction extends ConsumerStatefulWidget {
  const NewProfileAction({Key? key}) : super(key: key);

  @override
  ConsumerState<NewProfileAction> createState() => _NewProfileActionState();
}

class _NewProfileActionState extends ConsumerState<NewProfileAction> {
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        // Change value to update to trigger the update functionality on the new connection form.
        HomeScreenActionCallbacks.newProfileAction(ref, context);
      },
      child: const Icon(Icons.add_circle_outline),
    );
  }
}
