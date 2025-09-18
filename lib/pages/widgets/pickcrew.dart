import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/providers/colors.dart';

import '../../models/Utils/veh_mem.dart';
import '../../models/member.dart';

class PickUser extends StatelessWidget {
  PickUser({super.key, required this.caption, this.crew_type});

  String caption = "";
  Crew_type? crew_type;
  Widget getLeadingWidget(SuggestionType? suggestionType) {
    // Add your conditions here
    switch (suggestionType) {
      case SuggestionType.vehicle:
        return const Icon(Icons.bus_alert_rounded, color: AppColors.buses);
      case SuggestionType.Member:
        return const Icon(Icons.verified_user, color: AppColors.member);
      case SuggestionType.Crew:
        return const Icon(Icons.support_agent, color: AppColors.crew);
      case null:
        return const Icon(Icons.signal_cellular_null);
    }
  }

  String displayStringForOption(Member option) => option.No.toString();
  @override
  Widget build(BuildContext context) {
    return Autocomplete<Member>(
      optionsMaxHeight: 50,
      displayStringForOption: displayStringForOption,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<Member>.empty();
        }
        return Get.find<MemberController>().Crews.value.where((Member option) {
          return option
              .toString()
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (Member selection) {
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
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        //controller = headerController.textEditingController.value;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.supervised_user_circle,
                color: Colors.blue,
              ),
              contentPadding: EdgeInsets.only(left: 50),
              label: Text(caption),
              floatingLabelAlignment: FloatingLabelAlignment.center),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Material(
          elevation: 4,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.toList()[index];
              return Card(
                elevation: 20,
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(
                      top: 0, left: 5, bottom: 0, right: 130),
                  //title: Icon(Icons.supervised_user_circle),
                  titleAlignment: ListTileTitleAlignment.top,
                  leading: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((option.Vehicle != "") && (option.Vehicle != null))
                        Text(
                            '${option.No.toString()} (${option.Vehicle.toString()})')
                      else
                        Text(option.No.toString()),
                      Text(
                        option.Name.toString(),
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),

                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Add space between icon and text
                      Text(
                          option.Phone_No == null
                              ? " No phone"
                              : option.Phone_No.toString(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12)),
                      Text(
                          option.ID_No == null
                              ? " No ID No"
                              : option.ID_No.toString(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  onTap: () {
                    onSelected(option);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
