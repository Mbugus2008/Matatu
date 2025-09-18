// import 'package:flutter/material.dart';
// import 'package:t_matatu/controllers/Members.dart';

// class VehicleSearch extends StatelessWidget {
//   const VehicleSearch({super.key});
  
//   get memberController => null;

//   @override
//   Widget build(BuildContext context) {
//     return Autocomplete<Suggestion>(
//       initialValue: TextEditingValue.empty,
//       optionsBuilder: (textEditingValue) async {
//         if (textEditingValue.text.isEmpty) return const Iterable<Suggestion>.empty();
//         return memberController.getVehicleSuggestions(textEditingValue.text);
//       },
//       displayStringForOption: (option) => option.displayText,
//       onSelected: (selection) => _handleVehicleSelection(selection),
//       fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
//         return TextField(
//           controller: controller,
//           focusNode: focusNode,
//           decoration: InputDecoration(
//             hintText: 'Enter vehicle number or member name',
//             prefixIcon: const Icon(Icons.search),
//             suffixIcon: IconButton(
//               icon: const Icon(Icons.clear, color: Colors.red),
//               onPressed: () => controller.clear(),
//             ),
//           ),
//           onChanged: (value) {
//             memberController.filterVehicles(value);
//           },
//         );
//       },
//     );
//   }
// }