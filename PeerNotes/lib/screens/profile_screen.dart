import 'package:flutter/material.dart';
import '../models/note.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/empty_state.dart';
import '../services/user_service.dart';
import '../services/note_service.dart';

import 'forgot_password_screen.dart';
import 'edit_profile_screen.dart';
import 'support_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'note_detail_screen.dart';
import 'edit_note_screen.dart';
import '../services/auth_service.dart';
import '../theme/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _showLogoutDialog(BuildContext context) {
    final authService = AuthService();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();
    final NoteService noteService = NoteService();

    return StreamBuilder<Map<String, dynamic>>(
      stream: userService.getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error loading profile: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final String displayName = data['name'] ?? 'User';
        final String email = data['email'] ?? 'No email available';
        final String? profileImage = data['profileImage'];

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: const CustomAppBar(
            title: 'Profile',
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Profile Section
                _buildProfileHeader(context, displayName, email, profileImage),
                
                const SizedBox(height: 32),
                
                // Content Section
                _buildSectionHeader(context, 'Activity'),
                const SizedBox(height: 16),
                
                // My Uploads Section (Expandable)
                StreamBuilder<List<Note>>(
                  stream: noteService.getUserUploads(),
                  builder: (context, noteSnapshot) {
                    final List<Note> userUploads = noteSnapshot.data ?? [];
                    return _buildExpandableSection(
                      context,
                      title: 'My Uploads',
                      icon: Icons.cloud_upload_outlined,
                      count: userUploads.length,
                      items: userUploads,
                      isLoading: noteSnapshot.connectionState == ConnectionState.waiting,
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                // My Downloads Section (Expandable)
                StreamBuilder<List<Note>>(
                  stream: noteService.getDownloadedNotes(),
                  builder: (context, noteSnapshot) {
                    final List<Note> downloads = noteSnapshot.data ?? [];
                    return _buildExpandableSection(
                      context,
                      title: 'My Downloads',
                      icon: Icons.download_done_rounded,
                      count: downloads.length,
                      items: downloads,
                      isLoading: noteSnapshot.connectionState == ConnectionState.waiting,
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                // Saved Notes Section (Expandable)
                StreamBuilder<List<Note>>(
                  stream: noteService.getSavedNotes(),
                  builder: (context, noteSnapshot) {
                    final List<Note> saved = noteSnapshot.data ?? [];
                    return _buildExpandableSection(
                      context,
                      title: 'Saved Notes',
                      icon: Icons.bookmark_outline_rounded,
                      count: saved.length,
                      items: saved,
                      isLoading: noteSnapshot.connectionState == ConnectionState.waiting,
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Account Settings'),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  context,
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (v) {},
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () {},
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark Mode',
                  trailing: ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, _) => Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (v) => themeProvider.toggleTheme(),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onTap: () => themeProvider.toggleTheme(),
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Support & Info'),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SupportScreen()),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.info_rounded,
                  label: 'About App',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isDestructive: true,
                  onTap: () => _showLogoutDialog(context),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final color = isDestructive 
        ? Theme.of(context).colorScheme.error 
        : Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive 
                ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: isDestructive 
              ? Theme.of(context).colorScheme.error 
              : Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        trailing: trailing ?? Icon(
          Icons.chevron_right_rounded, 
          size: 20, 
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email, String? photoUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileAvatar(initialImageUrl: photoUrl),
          const SizedBox(height: 24),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.8,
                ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              email,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int count,
    required List<Note> items,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            if (isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: icon,
                  title: 'No ${title.toLowerCase()} yet',
                ),
              )
            else
              ...items.map((note) => _buildProfileNoteItem(context, note)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive 
        ? Theme.of(context).colorScheme.error 
        : Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive 
              ? Theme.of(context).colorScheme.error.withOpacity(0.05)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDestructive 
                ? Theme.of(context).colorScheme.error.withOpacity(0.2)
                : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded, 
              size: 20, 
              color: color.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNoteItem(BuildContext context, Note note) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnNote = currentUserId != null && currentUserId == note.uploaderId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(note: note),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            note.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          note.category,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnNote)
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditNoteScreen(note: note),
                    ),
                  );
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(right: 8),
                tooltip: 'Edit Note',
              ),
            _buildBadge(context, note),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, Note note) {
    final color = note.isFree ? Colors.green.shade600 : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        note.isFree ? 'FREE' : '\$${note.price.toStringAsFixed(2)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}
