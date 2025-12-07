import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:final_project/services/assignment_service.dart';
import 'package:final_project/components/my_button.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final int? maxLines;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class AssignmentSubmissionDialog extends StatefulWidget {
  final String assignmentId;
  final String channelId;
  final String hubId;
  final String assignmentTitle;

  const AssignmentSubmissionDialog({
    super.key,
    required this.assignmentId,
    required this.channelId,
    required this.hubId,
    required this.assignmentTitle,
  });

  @override
  State<AssignmentSubmissionDialog> createState() => _AssignmentSubmissionDialogState();
}

class _AssignmentSubmissionDialogState extends State<AssignmentSubmissionDialog> {
  final AssignmentService _assignmentService = AssignmentService();
  final TextEditingController _textController = TextEditingController();
  Uint8List? _selectedFileBytes;
  String? _fileName;
  bool _isSubmitting = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);

    if (result != null) {
      setState(() {
        _selectedFileBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (_textController.text.trim().isEmpty && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide text or select a file')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _assignmentService.submitAssignment(
        assignmentId: widget.assignmentId,
        channelId: widget.channelId,
        hubId: widget.hubId,
        submissionText: _textController.text.trim().isNotEmpty ? _textController.text.trim() : null,
        fileBytes: _selectedFileBytes,
        fileName: _fileName,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting assignment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Submit Assignment: ${widget.assignmentTitle}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyTextField(
              controller: _textController,
              hintText: 'Enter your submission text (optional)',
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _fileName ?? 'No file selected',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach File'),
                ),
              ],
            ),
            if (_selectedFileBytes != null) ...[
              const SizedBox(height: 8),
              Text(
                'File: $_fileName',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        MyButton(
          text: _isSubmitting ? 'Submitting...' : 'Submit',
          onTap: _isSubmitting ? null : _submitAssignment,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
