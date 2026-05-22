import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_app_bar.dart';
import '../models/note.dart';

class EditNoteScreen extends StatefulWidget {
  final Note note;
  const EditNoteScreen({super.key, required this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  final SupabaseClient _supabase = Supabase.instance.client;

  late String _selectedCategory;
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  late bool _isPremium;

  final List<String> _categories = [
    'Programming',
    'Design',
    'Business',
    'Academics',
    'Math',
    'Science',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _descriptionController = TextEditingController(text: widget.note.description);
    _priceController = TextEditingController(text: widget.note.price.toString());
    _selectedCategory = _categories.contains(widget.note.category)
        ? widget.note.category
        : 'Other';
    _isPremium = widget.note.isPremium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'jpg',
        'jpeg',
        'png',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
        'txt',
      ],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.single;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.1;
      _uploadStatus = 'Initializing update...';
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _showSnackBar('You must be logged in to edit this note.', isError: true);
        return;
      }

      String finalFileUrl = widget.note.fileUrl;
      String finalFileName = widget.note.fileName ?? '';
      String finalFileType = widget.note.fileType ?? '';
      bool finalIsPdf = widget.note.isPdf;

      // If a new file was chosen, upload it and clean up the old one
      if (_selectedFile != null) {
        setState(() {
          _uploadProgress = 0.3;
          _uploadStatus = 'Uploading new file...';
        });

        final fileExt = _selectedFile!.name.split('.').last.toLowerCase();
        final filePath = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        Uint8List fileBytes;
        if (_selectedFile!.bytes != null) {
          fileBytes = _selectedFile!.bytes!;
        } else if (_selectedFile!.path != null) {
          fileBytes = await File(_selectedFile!.path!).readAsBytes();
        } else {
          throw Exception('Could not read the selected file.');
        }

        // Upload new file to storage
        await _supabase.storage
            .from('note_attachments')
            .uploadBinary(
              filePath,
              fileBytes,
              fileOptions: FileOptions(
                contentType: _getContentType(fileExt),
                upsert: false,
              ),
            );

        finalFileUrl = _supabase.storage
            .from('note_attachments')
            .getPublicUrl(filePath);
        finalFileName = _selectedFile!.name;
        finalFileType = _getContentType(fileExt);
        finalIsPdf = fileExt == 'pdf';

        setState(() {
          _uploadProgress = 0.7;
          _uploadStatus = 'Cleaning up old file...';
        });

        // Delete old storage file
        try {
          String oldPathInBucket;
          if (widget.note.fileUrl.contains('note_attachments/')) {
            oldPathInBucket = Uri.decodeComponent(widget.note.fileUrl.split('note_attachments/').last);
          } else {
            oldPathInBucket = Uri.decodeComponent(widget.note.fileUrl.split('/').last);
          }

          if (oldPathInBucket.contains('?')) {
            oldPathInBucket = oldPathInBucket.split('?').first;
          }

          await _supabase.storage.from('note_attachments').remove([oldPathInBucket]);
        } catch (e) {
          debugPrint('Error deleting old note file: $e');
        }
      }

      setState(() {
        _uploadProgress = 0.8;
        _uploadStatus = 'Updating note details...';
      });

      // Update in notes table
      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      await _supabase.from('notes').update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'category': _selectedCategory,
        'file_url': finalFileUrl,
        'file_name': finalFileName,
        'file_type': finalFileType,
        'is_pdf': finalIsPdf,
        'is_premium': _isPremium,
        'credits_cost': _isPremium ? 15 : 0,
      }).eq('id', widget.note.id).eq('uploader_id', user.id);

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Done!';
      });

      if (mounted) {
        _showSnackBar('Note updated successfully!', isError: false);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } on StorageException catch (e) {
      if (mounted) _showSnackBar('Storage error: ${e.message}', isError: true);
    } on PostgrestException catch (e) {
      if (mounted) _showSnackBar('Database error: ${e.message}', isError: true);
    } catch (e) {
      if (mounted) _showSnackBar('Update failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getContentType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  IconData _getFileIcon(String? name) {
    if (name == null) return Icons.cloud_upload_outlined;
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const CustomAppBar(title: 'Edit Note', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Note Details',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update your note information and file attachment in the marketplace.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              CustomTextField(
                controller: _titleController,
                hintText: 'Note Title',
                prefixIcon: Icons.title_rounded,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Description',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),

              // Price & Category Row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      hintText: 'Price (0 for free)',
                      prefixIcon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          items: _categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _selectedCategory = newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // File Selection
              InkWell(
                onTap: _isLoading ? null : _pickFile,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: _selectedFile == null
                        ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2)
                        : Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedFile == null
                          ? Theme.of(context).colorScheme.outlineVariant
                          : Colors.green.withOpacity(0.5),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile == null
                            ? Icons.insert_drive_file_outlined
                            : _getFileIcon(_selectedFile!.name),
                        size: 52,
                        color: _selectedFile == null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.green.shade600,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFile == null
                            ? (widget.note.fileName ?? 'Original File Attached')
                            : _selectedFile!.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _selectedFile == null
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedFile == null
                            ? 'Tap to replace file attachment'
                            : '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB  ·  Tap to change',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Premium Toggle
              SwitchListTile(
                title: const Text(
                  'Mark as Premium',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text(
                  'Premium notes cost 15 credits to unlock.',
                  style: TextStyle(fontSize: 13),
                ),
                secondary: Icon(
                  _isPremium ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: _isPremium ? Colors.amber.shade900 : Colors.grey,
                ),
                value: _isPremium,
                onChanged: (val) => setState(() => _isPremium = val),
                activeColor: Colors.amber.shade900,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),

              // Progress Indicator
              if (_isLoading) ...[
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 8,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _uploadStatus,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 48),

              CustomButton(
                text: 'SAVE CHANGES',
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
