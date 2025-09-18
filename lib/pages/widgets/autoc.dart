import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/decorations/input.dart';
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/pages/edit_phone.dart';

import '../../models/member.dart';

class CustomAutocomplete extends StatelessWidget {
  TextEditingController textEditingController = TextEditingController();
  Crew_type? crew_type;
  String? caption;
  Icon? leadingicon = Icon(Icons.text_fields);
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _autocompleteKey = GlobalKey();

  CustomAutocomplete(
      {Key? key,
      required this.textEditingController,
      this.crew_type,
      this.caption,
      this.leadingicon})
      : super(key: key);

  void clear() {
    textEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<Member>(
      direction: VerticalDirection.down,
      controller: textEditingController,
      suggestionsCallback: (search) {
        List<Member>? returnResult = [];
        if (search.length >= 2) {
          returnResult =
              Get.find<MemberController>().Crews.where((Member option) {
            return option
                    .toString()
                    .toLowerCase()
                    .contains(search.toLowerCase()) &&
                option.Crew_Type == crew_type;
          }).toList();
        }
        return Future.value(returnResult);
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          decoration: input.inputdecoration(caption, leadingicon),
        );
      },
      itemBuilder: (context, city) {
        return Card(
          child: ListTile(
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Get.to(EditPhonePage(member: city));
              },
            ),
            dense: true,
          title: Text(city.Name.toString()),
          subtitle: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.black),
           
              children: [
                TextSpan(text: '${city.No.toString()} - '),
                TextSpan(
  text: city.Phone_No == null || city.Phone_No!.isEmpty 
      ? 'N/A' 
      : city.Phone_No!,
  style: TextStyle(
    color: city.Phone_No == null || city.Phone_No!.isEmpty 
        ? Colors.red 
        : null
  ),
),
                TextSpan(text: ' - ${city.ID_No.toString()}'),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
       
        ),
      );
      },

      onSelected: (selection) {
        textEditingController.text = selection.No.toString();
        switch (crew_type) {
          case Crew_type.Driver:
            Get.find<MemberController>().currentdriver.value = selection;
            break;
          case Crew_type.Conductor:
            Get.find<MemberController>().currentcunductor.value = selection;
            break;
          case null:
          // TODO: Handle this case.
        }
      },
      debounceDuration: const Duration(seconds: 0), // debounceDuration,
      hideOnSelect: true, // settings.hideOnSelect.value,
      hideOnUnfocus: true, // settings.hideOnUnfocus.value,
      hideWithKeyboard: true, // settings.hideOnUnfocus.value,
      retainOnLoading: true,
      hideOnEmpty: true,
      // settings.retainOnLoading.value,
    );
  }
}
