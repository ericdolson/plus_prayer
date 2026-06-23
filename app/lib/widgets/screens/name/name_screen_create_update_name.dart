import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:plusprayer/hooks/use_names.dart';
import 'package:plusprayer/hooks/use_screen_size.dart';
import 'package:plusprayer/presentation/text.dart';
import 'package:plusprayer/widgets/framework/surface_card.dart';

import '../../../models/name.dart';
import '../../../utils/collection_uitls.dart';

void showCreateUpdateName({required BuildContext context, Name? name, void Function()? onDelete}) {
  showModalBottomSheet(
    enableDrag: false,
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return _CreateUpdateName(name: name, onDelete: onDelete);
    },
  );
}

class _CreateUpdateName extends HookWidget {
  final Name? name;
  final void Function()? onDelete;

  const _CreateUpdateName({super.key, this.name, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final activateToRoll = useState(name?.selected ?? true);
    final aliasController = useTextEditingController(text: name?.alias);
    final aliasValue = useValueListenable(aliasController);
    final focusNode = useRef(FocusNode());
    final formKey = useRef(GlobalKey<FormState>());
    final intentionController = useTextEditingController(text: name?.intention);
    final intentionValue = useValueListenable(intentionController);
    final nameController = useTextEditingController(text: name?.name);
    final names = useNames();
    final textValue = useValueListenable(nameController);

    final isValid = useMemoized(() {
      return textValue.text.isNotEmpty;
    }, [textValue]);

    final String? avatarChar = useMemoized(() {
      if (aliasValue.text.isNotEmpty) {
        return aliasValue.text[0].toUpperCase();
      } else if (textValue.text.isNotEmpty) {
        return textValue.text[0].toUpperCase();
      }

      return null;
    }, [textValue, aliasValue]);

    final onSave = useCallback(() async {
      if (name != null) {
        // Update the name
        name!.name = textValue.text;
        name!.alias = aliasValue.text;
        name!.intention = intentionValue.text;
        name!.selected = activateToRoll.value;

        await name!.updateWith(trimAndNullifyEmptyStrings({
          'name': textValue.text,
          'alias': aliasValue.text,
          'intention': intentionValue.text,
          'selected': activateToRoll.value,
        }));
      } else {
        // Save the name
        await Name(
          name: textValue.text,
          alias: aliasValue.text,
          intention: intentionValue.text,
          // avatar: avatarChar,
          selected: activateToRoll.value,
          sortIndex: names.isEmpty ? 1 : names.last.sortIndex + 1,
        ).saveAsNewToDB();
      }

      context.pop();
    }, [formKey, textValue, aliasValue, activateToRoll, intentionValue, names, name]);

    final handleTapOutside = useCallback(() {
      FocusScope.of(context).unfocus();
    }, [1]);

    // Focus on the first input field with a slight delay
    // useEffect(() {
    //   Future.delayed(300.ms, () {
    //     print('focusing');
    //     FocusScope.of(context).requestFocus(focusNode.value);
    //   });
    // }, [1]);

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Padding(
              padding: EdgeInsets.only(left: 16, top: 20),
              child: AnimatedOpacity(
                  opacity: isValid ? 1 : 0,
                  duration: 200.ms,
                  child: TextButton(
                      onPressed: isValid ? onSave : null,
                      child: Text('Save', style: TextStyle(fontWeight: FontWeight.w600))))),
          leadingWidth: 100,
          actions: [
            Padding(
                padding: EdgeInsets.only(right: 16, top: 12),
                child: Opacity(
                    opacity: .5,
                    child: IconButton(
                      icon: Icon(Icons.close_rounded),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )))
          ],
          // backgroundColor: Colors.red,
          // scrolledUnderElevation: 0,
          // toolbarHeight: 50,
          // title: const FancyText(
          //   'Add Name',
          //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          // ),
        ),
        body: GestureDetector(
            onTap: handleTapOutside,
            child: SingleChildScrollView(
              // physics: AlwaysScrollableScrollPhysics(),
              // padding: EdgeInsets.symmetric(horizontal: 24),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              child: Form(
                  key: formKey.value,
                  child: Column(
                    // mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // HorizonalStepper(width: MediaQuery.of(context).size.width,
                      //     curStep: 0,
                      //     color: Color(0xff50AC02),
                      //     titles: ['Name', 'Alias', 'Avatar']),
                      Center(
                          child: Stack(children: [
                        CircleAvatar(
                            radius: 44,
                            backgroundColor:
                                Theme.of(context).colorScheme.onSurface.withValues(alpha:.2),
                            child: avatarChar == null
                                ? Icon(Icons.image_outlined, size: 40)
                                : Text(avatarChar,
                                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w500))),
                        Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.primary,
                                    border: Border.all(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        width: 2)),
                                child: Icon(Icons.camera_alt_rounded,
                                    size: 16, color: Colors.white.withValues(alpha:.7))))
                      ])),

                      SizedBox(height: 20),
                      _InputWrapper(
                          showLabel: textValue.text.isNotEmpty,
                          label: '*Full name',
                          helpText: ['Will be printed on the daily prayer roll.'],
                          child: TextFormField(
                            focusNode: focusNode.value,
                            controller: nameController,
                            autofocus: false,
                            textCapitalization: TextCapitalization.words,
                            // textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              // labelText: 'Name',
                              // labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                              hintText: '*Full name',
                              hintStyle: fancyTextStyle.copyWith(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.3)),
                            ),
                            style: fancyTextStyle.copyWith(
                              fontSize: 18,
                            ),
                            // The validator receives the text that the user has entered.
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                          )),
                      // Container(
                      //     child: Text('* Printed on the daily prayer roll', textAlign: TextAlign.left)),
                      const SizedBox(height: 20),
                      _InputWrapper(
                          showLabel: aliasValue.text.isNotEmpty,
                          label: 'Nickname',
                          helpText: [
                            'Just for you to see, if you want. "Mom", "Angel", "Tater Tot", ...',
                          ],
                          child: TextFormField(
                            controller: aliasController,
                            autofocus: false,
                            textCapitalization: TextCapitalization.words,
                            // textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              // labelText: 'Name',
                              // labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                              hintText: 'Nickname',
                              hintStyle: fancyTextStyle.copyWith(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.3)),
                            ),
                            style: fancyTextStyle.copyWith(fontSize: 18),
                            // The validator receives the text that the user has entered.
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                          )),
                      const SizedBox(height: 20),
                      _InputWrapper(
                          showLabel: intentionValue.text.isNotEmpty,
                          label: 'Intention',
                          helpText: [
                            'A reason for praying or something to think of when you pray for this name.',
                          ],
                          child: TextFormField(
                            maxLines: 3,
                            controller: intentionController,
                            autofocus: false,
                            textCapitalization: TextCapitalization.sentences,
                            // textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              // labelText: 'Name',
                              // labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                              hintText: 'Intention',
                              hintStyle: fancyTextStyle.copyWith(
                                  fontSize: 18,
                                  // fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.3)),
                            ),
                            textAlign: TextAlign.left,
                            style: fancyTextStyle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              fontStyle: FontStyle.italic,
                            ),
                            // The validator receives the text that the user has entered.
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                          )),
                      const SizedBox(height: 24),

                      if (name == null)
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Switch(
                              // applyTheme: true,
                              value: activateToRoll.value,
                              onChanged: (value) {
                                activateToRoll.value = value;
                              }),
                          SizedBox(width: 8),
                          Text('Place on prayer list',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.7))),
                          SizedBox(width: 6),
                          IconButton(
                              icon: Icon(Icons.info_outline_rounded,
                                  size: 24,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Prayer Roll'),
                                        content: Text(
                                            'This name will be included in the daily prayer roll. You can pray for this person and their intention.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text('OK'))
                                        ],
                                      );
                                    });
                              })
                        ]),

                      if (name != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Delete name'),
                                    content: Text(
                                        'Are you sure you want to delete this name? This cannot be undone.'),
                                    actions: [
                                      FilledButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text('Cancel')),
                                      TextButton(
                                          onPressed: () {
                                            context.pop();
                                            context.pop();
                                            onDelete?.call();
                                          },
                                          child: Text('Delete',
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.error)))
                                    ],
                                  );
                                });
                          },
                          icon: Icon(Icons.delete_rounded,
                              color: Theme.of(context).colorScheme.error),
                          label: Text('Delete name'),
                        )

                      // Container(child: Text('Optional')),
                      // Container(
                      //     child: Text(
                      //         '"Mom", "Papa", ... This is how you will see this person in your own list',
                      //         textAlign: TextAlign.left)),
                    ],
                  )),
            )));
  }
}

class _InputWrapper extends HookWidget {
  final bool showLabel;
  final String label;
  final List<String> helpText;
  final Widget child;

  const _InputWrapper(
      {super.key,
      this.showLabel = false,
      required this.label,
      required this.helpText,
      required this.child});

  @override
  Widget build(BuildContext context) {
    final screenSize = useScreenSize();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(children: [
          // Input field
          Container(
              padding: EdgeInsets.only(top: 10),
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SurfaceCard.tinted(child: child))),

          // Label text
          Padding(
              padding: EdgeInsets.only(left: 40, right: 24),
              child: AnimatedScale(
                  alignment: Alignment.centerLeft,
                  scale: showLabel ? 1 : 0,
                  duration: 200.ms,
                  child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(24)),
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)))))),
        ]),

        // Divider
        // Container(
        //   height: 3,
        //   color: Theme.of(context).colorScheme.surfaceTint,
        // ),

        // Help text
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Container(
                // width: screenSize.width,
                padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                // color: Theme.of(context).colorScheme.surfaceTint.withValues(alpha:.5),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  // AnimatedContainer(
                  //     duration: 200.ms,
                  //     height: showLabel ? 22 : 0,
                  //     child: Text(label,
                  //         style: TextStyle(
                  //             fontSize: 12,
                  //             fontWeight: FontWeight.w700,
                  //             color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)))),
                  ...helpText.map((ht) => Text(ht,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.6))))
                ]))),

        // Divider
        // Container(
        //   height: 1,
        //   color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.1),
        // ),
      ],
    );
  }
}
