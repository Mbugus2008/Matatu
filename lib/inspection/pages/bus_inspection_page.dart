import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../controllers/bus_inspection_controller.dart';
import '../models/bus_inspection.dart';
import '../widgets/inspection_item_card.dart';

class BusInspectionPage extends StatelessWidget {
  BusInspectionPage({super.key});

  final BusInspectionController controller = Get.put<BusInspectionController>(
    BusInspectionController(),
  );

  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Inspection')),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: Obx(
            () => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildGeneralSection(context),
                  const SizedBox(height: 16),
                  ...controller.items.entries.map((
                    MapEntry<String, InspectionItemData> entry,
                  ) {
                    return InspectionItemCard(
                      key: ValueKey<String>(entry.key),
                      item: entry.value,
                      ratingOptions: controller.ratingOptions,
                      notesController: controller.notesControllers[entry.key]!,
                      onComplianceChanged:
                          (bool value) =>
                              controller.toggleCompliance(entry.key, value),
                      onRatingChanged:
                          (String value) =>
                              controller.setRating(entry.key, value),
                      onNotesChanged:
                          (String value) =>
                              controller.setNotes(entry.key, value),
                      onAddPhoto: () => _handleAddPhoto(context, entry.key),
                      onRemovePhoto:
                          (String path) =>
                              controller.removePhoto(entry.key, path),
                    );
                  }),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          controller: controller.busIdentifierController,
          decoration: const InputDecoration(
            labelText: 'Bus Identifier',
            hintText: 'Enter bus registration',
            border: OutlineInputBorder(),
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bus identifier is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.inspectorNameController,
          decoration: const InputDecoration(
            labelText: 'Inspector Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          return InkWell(
            onTap: () async {
              FocusScope.of(context).unfocus();
              final DateTime initialDate = controller.inspectionDate.value;
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(initialDate.year - 5),
                lastDate: DateTime(initialDate.year + 5),
              );
              if (picked != null) {
                controller.setInspectionDate(picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Inspection Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(_dateFormat.format(controller.inspectionDate.value)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Obx(
          () => ElevatedButton.icon(
            onPressed:
                controller.isSaving.value
                    ? null
                    : () async {
                      await controller.saveLocally();
                    },
            icon:
                controller.isSaving.value
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save_alt),
            label: Text(controller.isSaving.value ? 'Saving…' : 'Save Locally'),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => ElevatedButton.icon(
            onPressed:
                controller.isSubmitting.value
                    ? null
                    : () async {
                      await controller.submitInspection();
                    },
            icon:
                controller.isSubmitting.value
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.cloud_upload),
            label: Text(
              controller.isSubmitting.value ? 'Submitting…' : 'Submit',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAddPhoto(BuildContext context, String key) async {
    final ImageSource? source = await _showPhotoSourcePicker(context);
    if (source == null) {
      return;
    }
    await controller.addPhoto(key, source: source);
  }

  Future<ImageSource?> _showPhotoSourcePicker(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }
}
