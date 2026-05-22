import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../widgets/profile_avatar.dart';
import '../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Set initial email
    _emailController.text = user.email ?? '';

    // Try to get data from profiles table
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['full_name'] ?? '';
        });
      } else if (mounted) {
        // Fallback to auth metadata
        _nameController.text = user.userMetadata?['full_name'] ?? 
                             user.userMetadata?['display_name'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // 1. Update Auth Metadata (for session/security)
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {
              'full_name': _nameController.text.trim(),
              'display_name': _nameController.text.trim()
            }),
          );

          // Update mock user data
          await _userService.updateUserData(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const CustomAppBar(title: 'Edit Profile', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: _userService.getUserStream(),
                  builder: (context, snapshot) {
                    final profileImage = snapshot.data?['profileImage'];
                    return ProfileAvatar(
                      initialImageUrl: profileImage,
                      onImageChanged: () {
                        // ProfileAvatar handles its own upload and update
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _nameController,
                hintText: 'Full Name',
                prefixIcon: Icons.person_outline_rounded,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email Address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email usually handled separately
              ),
              const SizedBox(height: 12),
              Text(
                'Email cannot be changed from this screen for security reasons.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'SAVE CHANGES',
                isLoading: _isLoading,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
