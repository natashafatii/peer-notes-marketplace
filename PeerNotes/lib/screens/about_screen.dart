import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'About App',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // App Icon/Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            // App Name
            Text(
              'Peer Notes Marketplace',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            
            const SizedBox(height: 48),
            
            // Description Card
            _buildInfoCard(
              context,
              title: 'What is Peer Notes?',
              description: 'Peer Notes Marketplace is a premium community-driven platform designed for students and professionals to share, sell, and discover high-quality study materials and academic notes.',
              icon: Icons.info_outline_rounded,
            ),
            
            const SizedBox(height: 16),
            
            // Purpose Card
            _buildInfoCard(
              context,
              title: 'Our Purpose',
              description: 'We believe in making education more accessible by connecting knowledge-seekers with knowledge-sharers. Our goal is to empower creators and help learners achieve their academic potential through peer-to-peer collaboration.',
              icon: Icons.auto_awesome_rounded,
            ),
            
            const SizedBox(height: 16),
            
            // Developer Section
            _buildInfoCard(
              context,
              title: 'The Team',
              description: 'Developed with ❤️ by the Peer Notes Team. We are dedicated to building the best experience for our community of learners.',
              icon: Icons.people_outline_rounded,
            ),
            
            const SizedBox(height: 60),
            
            // Footer
            Text(
              '© 2026 Peer Notes Inc.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required String description, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
