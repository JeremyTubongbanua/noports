import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noports_core/sshnp.dart';
import 'package:sshnp_gui/src/controllers/navigation_rail_controller.dart';
import 'package:sshnp_gui/src/controllers/config_controller.dart';
import 'package:sshnp_gui/src/presentation/widgets/profile_form/custom_text_form_field.dart';
import 'package:sshnp_gui/src/controllers/navigation_controller.dart';
import 'package:sshnp_gui/src/utility/sizes.dart';
import 'package:sshnp_gui/src/utility/form_validator.dart';

class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key});

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  late CurrentConfigState currentProfile;
  SshnpPartialParams newConfig = SshnpPartialParams.empty();
  @override
  void initState() {
    super.initState();
  }

  void onSubmit(SshnpParams oldConfig, SshnpPartialParams newConfig) async {
    if (_formkey.currentState!.validate()) {
      _formkey.currentState!.save();
      final controller = ref.read(configFamilyController(
              newConfig.profileName ?? oldConfig.profileName!)
          .notifier);
      bool rename = newConfig.profileName != null &&
          newConfig.profileName!.isNotEmpty &&
          oldConfig.profileName != null &&
          oldConfig.profileName!.isNotEmpty &&
          newConfig.profileName != oldConfig.profileName;
      SshnpParams config = SshnpParams.merge(oldConfig, newConfig);

      if (rename) {
        // delete old config file and write the new one
        await controller.putConfig(config,
            oldProfileName: oldConfig.profileName!, context: context);
      } else {
        // create new config file
        await controller.putConfig(config, context: context);
      }
      if (mounted) {
        ref.read(navigationRailController.notifier).setRoute(AppRoute.home);
        context.pushReplacementNamed(AppRoute.home.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    currentProfile = ref.watch(currentConfigController);

    final asyncOldConfig =
        ref.watch(configFamilyController(currentProfile.profileName));
    return asyncOldConfig.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (oldConfig) {
          return SingleChildScrollView(
            child: Form(
              key: _formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextFormField(
                        initialValue: oldConfig.profileName,
                        labelText: strings.profileName,
                        onChanged: (value) {
                          newConfig = SshnpPartialParams.merge(
                            newConfig,
                            SshnpPartialParams(profileName: value),
                          );
                        },
                        validator: FormValidator.validateProfileNameField,
                      ),
                      gapW8,
                      CustomTextFormField(
                        initialValue: oldConfig.device,
                        labelText: strings.device,
                        onChanged: (value) =>
                            newConfig = SshnpPartialParams.merge(
                          newConfig,
                          SshnpPartialParams(device: value),
                        ),
                      ),
                    ],
                  ),
                  gapH10,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextFormField(
                        initialValue: oldConfig.sshnpdAtSign,
                        labelText: strings.sshnpdAtSign,
                        onChanged: (value) =>
                            newConfig = SshnpPartialParams.merge(
                          newConfig,
                          SshnpPartialParams(sshnpdAtSign: value),
                        ),
                        validator: FormValidator.validateAtsignField,
                      ),
                      gapW8,
                      CustomTextFormField(
                        initialValue: oldConfig.host,
                        labelText: strings.host,
                        onChanged: (value) =>
                            newConfig = SshnpPartialParams.merge(
                          newConfig,
                          SshnpPartialParams(host: value),
                        ),
                        validator: FormValidator.validateRequiredField,
                      ),
                    ],
                  ),
                  gapH10,
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TODO replace this with a drop down of available keyPairs (and buttons to upload / generate a new one, and button to delete)
                      // CustomTextFormField(
                      //   initialValue: oldConfig.sendSshPublicKey,
                      //   labelText: strings.sendSshPublicKey,
                      //   onChanged: (value) =>
                      //       newConfig = SshnpPartialParams.merge(
                      //     newConfig,
                      //     SshnpPartialParams(sendSshPublicKey: value),
                      //   ),
                      // ),
                      gapW8,
                      // TODO replace this switch with a dropdown with options for SupportedSSHAlgorithm.values
                      // SizedBox(
                      //   width: CustomTextFormField.defaultWidth,
                      //   height: CustomTextFormField.defaultHeight,
                      //   child: Row(
                      //     children: [
                      //       Text(strings.rsa),
                      //       gapW8,
                      //       Switch(
                      //         value: newConfig.rsa ?? oldConfig.rsa,
                      //         onChanged: (newValue) {
                      //           setState(() {
                      //             newConfig = SshnpPartialParams.merge(
                      //               newConfig,
                      //               SshnpPartialParams(rsa: newValue),
                      //             );
                      //           });
                      //         },
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                  gapH10,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextFormField(
                          initialValue: oldConfig.remoteUsername ?? '',
                          labelText: strings.remoteUserName,
                          onChanged: (value) {
                            newConfig = SshnpPartialParams.merge(
                              newConfig,
                              SshnpPartialParams(remoteUsername: value),
                            );
                          }),
                      gapW8,
                      CustomTextFormField(
                        initialValue: oldConfig.port.toString(),
                        labelText: strings.port,
                        onChanged: (value) =>
                            newConfig = SshnpPartialParams.merge(
                          newConfig,
                          SshnpPartialParams(port: int.tryParse(value)),
                        ),
                        validator: FormValidator.validateRequiredField,
                      ),
                    ],
                  ),
                  gapH10,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextFormField(
                        initialValue: oldConfig.localPort.toString(),
                        labelText: strings.localPort,
                        onChanged: (value) =>
                            newConfig = SshnpPartialParams.merge(
                          newConfig,
                          SshnpPartialParams(localPort: int.tryParse(value)),
                        ),
                      ),
                      gapW8,
                      CustomTextFormField(
                        initialValue: oldConfig.localSshdPort.toString(),
                        labelText: strings.localSshdPort,
                        onChanged: (value) =>
                            newConfig = SshnpPartialParams.merge(
                          newConfig,
                          SshnpPartialParams(
                              localSshdPort: int.tryParse(value)),
                        ),
                      ),
                    ],
                  ),
                  gapH10,
                  CustomTextFormField(
                    initialValue: oldConfig.localSshOptions.join(','),
                    hintText: strings.localSshOptionsHint,
                    labelText: strings.localSshOptions,
                    //Double the width of the text field (+8 for the gapW8)
                    width: CustomTextFormField.defaultWidth * 2 + 8,
                    onChanged: (value) => newConfig = SshnpPartialParams.merge(
                      newConfig,
                      SshnpPartialParams(localSshOptions: value.split(',')),
                    ),
                  ),
                  gapH10,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextFormField(
                        initialValue: oldConfig.atKeysFilePath,
                        labelText: strings.atKeysFilePath,
                        onChanged: (value) =>
                            newConfig = SshnpPartialParams.merge(
                          newConfig,
                          SshnpPartialParams(atKeysFilePath: value),
                        ),
                      ),
                      gapW8,
                      CustomTextFormField(
                        initialValue: oldConfig.rootDomain,
                        labelText: strings.rootDomain,
                        onChanged: (value) =>
                            newConfig = SshnpPartialParams.merge(
                          newConfig,
                          SshnpPartialParams(rootDomain: value),
                        ),
                      ),
                    ],
                  ),
                  gapH10,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: CustomTextFormField.defaultWidth,
                        height: CustomTextFormField.defaultHeight,
                        child: Row(
                          children: [
                            Text(strings.verbose),
                            gapW8,
                            Switch(
                              value: newConfig.verbose ?? oldConfig.verbose,
                              onChanged: (newValue) {
                                setState(() {
                                  newConfig = SshnpPartialParams.merge(
                                    newConfig,
                                    SshnpPartialParams(verbose: newValue),
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () => onSubmit(oldConfig, newConfig),
                        child: Text(strings.submit),
                      ),
                      gapW8,
                      TextButton(
                        onPressed: () {
                          ref
                              .read(navigationRailController.notifier)
                              .setRoute(AppRoute.home);
                          context.pushReplacementNamed(AppRoute.home.name);
                        },
                        child: Text(strings.cancel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }
}