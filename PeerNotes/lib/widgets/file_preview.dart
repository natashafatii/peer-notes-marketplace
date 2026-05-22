import 'package:flutter/material.dart';

class FilePreview extends StatelessWidget {
  final bool isPdf;
  final String? imageUrl;
  final String? fileName;

  const FilePreview({
    Key? key,
    required this.isPdf,
    this.imageUrl,
    this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: isPdf
            ? _buildPdfPlaceholder(context)
            : _buildImagePreview(context),
      ),
    );
  }

  Widget _buildPdfPlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.picture_as_pdf_rounded,
          size: 64,
          color: Colors.red.shade400,
        ),
        const SizedBox(height: 12),
        Text(
          fileName ?? 'Document.pdf',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        Text(
          'Preview not available',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(context),
      );
    }
    return _buildImagePlaceholder(context);
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Image Preview',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
