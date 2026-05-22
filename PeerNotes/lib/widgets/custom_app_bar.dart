import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';
import '../services/user_service.dart';
import '../services/credit_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool isHomeScreen;
  final VoidCallback? onProfileTap;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.actions,
    this.isHomeScreen = false,
    this.onProfileTap,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered Title Area
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: onPrimaryColor,
                      letterSpacing: -0.6,
                      fontSize: 22,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: onPrimaryColor.withOpacity(0.8),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),

              // Back Button on the Left
              if (showBackButton)
                Positioned(
                  left: 0,
                  child: _buildBackButton(context, onPrimaryColor),
                ),

              // Actions on the Right
              Positioned(
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (actions != null)
                      ...actions!
                    else if (isHomeScreen)
                      _buildProfileAvatar(context, onPrimaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: color,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, Color color) {
    final UserService userService = UserService();
    final CreditService creditService = CreditService();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Credit Balance
        StreamBuilder<Map<String, dynamic>>(
          stream: creditService.getCreditProfile(),
          builder: (context, snapshot) {
            final credits = snapshot.data?['credits'] ?? 0;
            return Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on_rounded, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    credits.toString(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Profile Avatar
        GestureDetector(
          onTap:
              onProfileTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
          child: StreamBuilder<Map<String, dynamic>>(
            stream: userService.getUserStream(),
            builder: (context, snapshot) {
              final String? photoUrl = snapshot.data?['profileImage'];

              return Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                ),
                child: Hero(
                  tag: 'profile_avatar',
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withOpacity(0.2),
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Icon(Icons.person_rounded, color: color, size: 24)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
