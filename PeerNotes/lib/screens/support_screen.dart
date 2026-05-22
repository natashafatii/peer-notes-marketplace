import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'Help & Support',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How can we help you?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search our FAQs or contact our support team directly.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            
            // FAQ Section
            _buildSectionHeader(context, 'Frequently Asked Questions'),
            const SizedBox(height: 16),
            _buildFAQTile(
              context,
              question: 'How do I upload a note?',
              answer: 'Go to the Upload screen, fill in the details, select your file, and tap Upload. Your note will be available instantly.',
            ),
            _buildFAQTile(
              context,
              question: 'Are my payments secure?',
              answer: 'Yes, we use industry-standard encryption and premium payment gateways to ensure your transactions are 100% safe.',
            ),
            _buildFAQTile(
              context,
              question: 'Can I get a refund?',
              answer: 'If a note is corrupted or doesn\'t match the description, you can request a refund within 24 hours of purchase.',
            ),
            
            const SizedBox(height: 32),
            
            // Contact Section
            _buildSectionHeader(context, 'Contact Us'),
            const SizedBox(height: 16),
            _buildContactCard(
              context,
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@peernotes.com',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening email client...')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Live Chat',
              subtitle: 'Available 24/7',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Starting live chat...')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              icon: Icons.help_outline_rounded,
              title: 'Feedback',
              subtitle: 'Help us improve',
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening feedback form...')),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildFAQTile(BuildContext context, {required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}
