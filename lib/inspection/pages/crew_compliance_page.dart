import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/crew_compliance_controller.dart';
import '../models/crew_compliance_entry.dart';
import '../widgets/document_upload_tile.dart';

class CrewCompliancePage extends GetView<CrewComplianceController> {
  const CrewCompliancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crew Compliance'),
      ),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Required Documents',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...controller.documentKeys.map(
                  (String key) => Obx(
                    () => DocumentUploadTile(
                      title: CrewComplianceDocumentKeys.label(key),
                      subtitle: controller.documents[key]?.name,
                      onUpload: () => controller.pickDocument(key),
                      onRemove: controller.documents.containsKey(key)
                          ? () => controller.removeDocument(key)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Crew Assessment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: controller.grooming.value,
                    items: controller.groomingOptions
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) =>
                        controller.grooming.value = value,
                    validator: (String? value) =>
                        value == null ? 'Select grooming status' : null,
                    decoration: const InputDecoration(
                      labelText: 'Grooming',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: controller.behaviour.value,
                    items: controller.behaviourOptions
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) =>
                        controller.behaviour.value = value,
                    validator: (String? value) =>
                        value == null ? 'Select behaviour rating' : null,
                    decoration: const InputDecoration(
                      labelText: 'Behaviour',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Obx(
                        () => ElevatedButton.icon(
                          onPressed: controller.isSaving.value
                              ? null
                              : controller.saveEntry,
                          icon: controller.isSaving.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_alt),
                          label: const Text('Save & Sync'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Obx(
                      () => OutlinedButton.icon(
                        onPressed: controller.isSyncing.value
                            ? null
                            : controller.syncPendingEntries,
                        icon: controller.isSyncing.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync),
                        label: const Text('Sync Pending'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Entries are saved locally first. They will automatically sync when connectivity is restored.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
