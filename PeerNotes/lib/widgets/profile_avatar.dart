import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';

class ProfileAvatar extends StatefulWidget {
  final String? initialImageUrl;
  final VoidCallback? onImageChanged;

  const ProfileAvatar({Key? key, this.initialImageUrl, this.onImageChanged})
    : super(key: key);

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  XFile? _localImageFile; // Use XFile for web compatibility
  Uint8List? _webImageBytes; // For local preview on Web

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      // 1. Pick the image based on source
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      // 2. Immediately update UI to show the selected image and loading state
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _localImageFile = pickedFile;
        _webImageBytes = bytes;
        _isLoading = true;
      });

      print('DEBUG: Image picked, path: ${pickedFile.path}');

      // 3. Upload to Supabase
      final String? downloadUrl = await _userService.uploadProfileImage(
        _localImageFile!,
      );

      if (downloadUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile image updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (widget.onImageChanged != null) widget.onImageChanged!();
      }
    } catch (e) {
      print('DEBUG: Error picking/uploading image: $e');
      if (mounted) {
        // Remove the local preview if upload failed
        setState(() {
          _localImageFile = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Upload failed: ${e.toString().replaceAll('Exception:', '')}')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Profile Photo',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            _buildPickerOption(
              context,
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera); // Explicitly Camera
              },
            ),
            _buildPickerOption(
              context,
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery); // Explicitly Gallery
              },
            ),
            if (widget.initialImageUrl != null || _localImageFile != null)
              _buildPickerOption(
                context,
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                isDestructive: true,
                onTap: () async {
                  Navigator.pop(context);
                  setState(() {
                    _isLoading = true;
                    _localImageFile = null;
                  });
                  await _userService.updateUserData(profileImage: "");
                  setState(() {
                    _isLoading = false;
                  });
                  if (widget.onImageChanged != null) widget.onImageChanged!();
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.4)
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDestructive
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 54,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.4),
            // PRIORITY 1: Local picked image
            // PRIORITY 2: Network image from Firebase
            // PRIORITY 3: Null (shows icon)
            backgroundImage: _webImageBytes != null
                ? MemoryImage(_webImageBytes!)
                : (widget.initialImageUrl != null &&
                          widget.initialImageUrl!.isNotEmpty
                      ? NetworkImage(widget.initialImageUrl!)
                      : null),
            child: _isLoading
                ? const CircularProgressIndicator()
                : (_localImageFile == null &&
                      (widget.initialImageUrl == null ||
                          widget.initialImageUrl!.isEmpty))
                ? Icon(
                    Icons.person_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: GestureDetector(
            onTap: _isLoading ? null : () => _showImagePicker(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isLoading
                    ? Theme.of(context).colorScheme.outlineVariant
                    : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isLoading
                    ? Icons.hourglass_top_rounded
                    : Icons.camera_alt_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
