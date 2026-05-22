import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_app_bar.dart';
import '../services/credit_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _previewTextController = TextEditingController();

  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedCategory = 'Programming';
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // Credit & Limit fields
  final CreditService _creditService = CreditService();
  bool _isPremium = false;
  int _remainingUploads = 5;
  bool _canUpload = true;

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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkUploadLimit();
  }

  Future<void> _checkUploadLimit() async {
    final status = await _creditService.getUploadStatus();
    setState(() {
      _canUpload = status['canUpload'];
      _remainingUploads = status['remaining'];
    });
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
      withData: true, // Ensure bytes are loaded for cross-platform support
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.single;
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      _showSnackBar('Please select a file to upload.', isError: true);
      return;
    }

    final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (price <= 0 && _isPremium) {
      _showSnackBar(
        'Invalid Configuration: A free note cannot be marked as Premium. Please set a price greater than 0, or uncheck the Premium option.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.05;
      _uploadStatus = 'Checking upload limit...';
    });

    // --- 0. Check Daily Upload Limit ---
    try {
      print('DEBUG: Checking upload status...');
      final status = await _creditService.getUploadStatus();
      print('DEBUG: Status received: $status');

      if (status['canUpload'] == false) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          _showSnackBar(
            'Daily upload limit reached (5 notes/day). Try again tomorrow!',
            isError: true,
          );
        }
        return;
      }
    } catch (e) {
      print('DEBUG: Error checking status: $e');
      // If check fails, we'll allow it for now but log the error
    }

    setState(() {
      _uploadProgress = 0.1;
      _uploadStatus = 'Initializing upload...';
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _showSnackBar('You must be logged in to upload.', isError: true);
        return;
      }

      print('DEBUG: Uploading for user: ${user.id}');

      // --- 1. Build file path ---
      final fileExt = _selectedFile!.name.split('.').last.toLowerCase();
      final filePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      print('DEBUG: Target path: $filePath');
      setState(() {
        _uploadProgress = 0.2;
        _uploadStatus = 'Uploading file...';
      });

      // --- 2. Get file bytes ---
      Uint8List fileBytes;
      if (_selectedFile!.bytes != null) {
        fileBytes = _selectedFile!.bytes!;
      } else if (_selectedFile!.path != null) {
        fileBytes = await File(_selectedFile!.path!).readAsBytes();
      } else {
        throw Exception('Could not read the selected file.');
      }

      // --- 3. Upload to Supabase Storage ---
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

      setState(() {
        _uploadProgress = 0.7;
        _uploadStatus = 'Saving note details...';
      });

      // --- 4. Get public URL ---
      final fileUrl = _supabase.storage
          .from('note_attachments')
          .getPublicUrl(filePath);

      // --- 5. Save metadata to 'notes' table ---
      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final String authorName =
          (user.userMetadata?['display_name'] as String?)?.trim().isNotEmpty ==
              true
          ? user.userMetadata!['display_name'] as String
          : (user.email?.split('@').first ?? 'Anonymous');

      print('DEBUG: Inserting metadata into notes table...');
      await _supabase.from('notes').insert({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'category': _selectedCategory,
        'file_url': fileUrl,
        'file_name': _selectedFile!.name,
        'file_type': _getContentType(fileExt),
        'uploader_id': user.id,
        'uploader_name': authorName,
        'is_pdf': fileExt == 'pdf',
        'created_at': DateTime.now().toIso8601String(),
        'download_count': 0,
        'rating': 0.0,
        'review_count': 0,
        'preview_url': null,
        'preview_text': null,
        'is_premium': _isPremium,
        'credits_cost': _isPremium ? 15 : 0,
      });

      print('DEBUG: Metadata saved successfully!');

      // Sync the user's daily upload count with the actual database ground truth
      await _creditService.recordUpload();

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Done!';
      });

      if (mounted) {
        _showSnackBar('Note uploaded successfully!', isError: false);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      }
    } on StorageException catch (e) {
      if (mounted) _showSnackBar('Storage error: ${e.message}', isError: true);
    } on PostgrestException catch (e) {
      if (mounted) _showSnackBar('Database error: ${e.message}', isError: true);
    } catch (e) {
      if (mounted) _showSnackBar('Upload failed: $e', isError: true);
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
      appBar: const CustomAppBar(title: 'Upload Note', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share Your Knowledge',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in the details below to list your note on the marketplace.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _canUpload
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _canUpload
                          ? Icons.info_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: 16,
                      color: _canUpload ? Colors.blue : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_remainingUploads/5 uploads remaining today',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _canUpload
                            ? Colors.blue.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
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
                        if (value == null || value.isEmpty)
                          return 'Enter price';
                        if (double.tryParse(value) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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

              // File Picker
              InkWell(
                onTap: _isLoading ? null : _pickFile,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: _selectedFile == null
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedFile == null
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3)
                          : Colors.green.withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile == null
                            ? Icons.cloud_upload_outlined
                            : _getFileIcon(_selectedFile!.name),
                        size: 52,
                        color: _selectedFile == null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.green.shade600,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFile == null
                            ? 'Tap to Select File'
                            : _selectedFile!.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _selectedFile == null
                              ? Theme.of(context).colorScheme.primary
                              : Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedFile == null
                            ? 'PDF, DOC, PPT, XLS, TXT, JPG, PNG'
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

              // Upload Progress
              if (_isLoading) ...[
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 8,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
                text: 'UPLOAD NOTE',
                onPressed: _isLoading ? null : _handleUpload,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
