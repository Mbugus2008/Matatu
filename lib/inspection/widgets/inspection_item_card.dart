import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/bus_inspection.dart';

class InspectionItemCard extends StatelessWidget {
  const InspectionItemCard({
    super.key,
    required this.item,
    required this.ratingOptions,
    required this.notesController,
    required this.onComplianceChanged,
    required this.onRatingChanged,
    required this.onNotesChanged,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final InspectionItemData item;
  final List<String> ratingOptions;
  final TextEditingController notesController;
  final ValueChanged<bool> onComplianceChanged;
  final ValueChanged<String> onRatingChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onAddPhoto;
  final ValueChanged<String> onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch.adaptive(
                  value: item.isCompliant,
                  onChanged: onComplianceChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: item.rating,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
              items:
                  ratingOptions
                      .map(
                        (String option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  onRatingChanged(value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              minLines: 2,
              maxLines: 4,
              onChanged: onNotesChanged,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _buildPhotoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              item.photoPaths.map((String path) {
                return InputChip(
                  label: Text(p.basename(path)),
                  onDeleted: () => onRemovePhoto(path),
                  avatar: const Icon(Icons.photo_camera, size: 18),
                );
              }).toList(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAddPhoto,
            icon: const Icon(Icons.attach_file),
            label: const Text('Attach Photo'),
          ),
        ),
      ],
    );
  }
}
