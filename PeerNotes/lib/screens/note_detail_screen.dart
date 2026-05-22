import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io';
import '../models/note.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/detail_header.dart';
import '../widgets/info_row.dart';
import '../widgets/file_preview.dart';
import '../widgets/star_rating_input.dart';
import '../widgets/pdf_preview_card.dart';
import '../widgets/review_card.dart';
import '../services/note_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../services/purchase_service.dart';
import 'mock_payment_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final NoteService _noteService = NoteService();
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 0;
  bool _isBookmarked = false;
  bool _isSavingBookmark = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  // Credit system fields
  // Purchase system fields
  final PurchaseService _purchaseService = PurchaseService();
  bool _isUnlocked = false;
  bool _isCheckingUnlock = true;

  @override
  void initState() {
    super.initState();
    _checkIfBookmarked();
    _checkUnlockStatus();
  }

  Future<void> _checkUnlockStatus() async {
    // Scenario 1: Free (price <= 0) and not premium -> Direct download
    // Scenario 2: Free (price <= 0) but premium -> Invalid state, treated as Free to prevent bug
    if (widget.note.isFree || widget.note.uploaderId == _noteService.uid) {
      setState(() {
        _isUnlocked = true;
        _isCheckingUnlock = false;
      });
      return;
    }

    final unlocked = await _purchaseService.isNoteUnlocked(widget.note.id);
    if (mounted) {
      setState(() {
        _isUnlocked = unlocked;
        _isCheckingUnlock = false;
      });
    }
  }

  Future<void> _checkIfBookmarked() async {
    final saved = await _noteService.isNoteSaved(widget.note.id);
    if (mounted) {
      setState(() {
        _isBookmarked = saved;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isSavingBookmark) return;

    setState(() => _isSavingBookmark = true);
    try {
      final targetState = !_isBookmarked;
      await _noteService.setBookmark(widget.note.id, targetState);
      setState(() => _isBookmarked = targetState);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBookmarked
                  ? 'Note saved to bookmarks'
                  : 'Note removed from bookmarks',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingBookmark = false);
    }
  }

  Future<void> _submitReview() async {
    final comment = _reviewController.text.trim();

    if (_selectedRating == 0 && comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating or a comment')),
      );
      return;
    }

    try {
      await _noteService.addReview(
        widget.note.id,
        _selectedRating.toDouble(),
        comment,
      );

      if (mounted) {
        _reviewController.clear();
        setState(() => _selectedRating = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review submitted!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 10),
              const Text('Delete Review'),
            ],
          ),
          content: const Text('Are you sure you want to delete your review?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'DELETE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _noteService.deleteReview(reviewId, widget.note.id);
      if (mounted) {
        setState(() {}); // Rebuild stream to fetch updated reviews
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete review: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 10),
              const Text('Delete Note'),
            ],
          ),
          content: Text('Are you sure you want to delete "${note.title}"? This will permanently remove it from the marketplace and cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'DELETE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _noteService.deleteNote(note.id, note.fileUrl);
      
      if (mounted) {
        // Pop loading indicator
        Navigator.of(context).pop();
        // Pop NoteDetailScreen and return true to indicate deletion
        Navigator.of(context).pop(true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Pop loading indicator
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete note: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _downloadNote(Note note) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final supabase = Supabase.instance.client;

      // 1. Extract the internal path from the public URL
      // Format: https://.../public/note_attachments/path/to/file.ext
      String pathInBucket;
      if (note.fileUrl.contains('note_attachments/')) {
        pathInBucket = note.fileUrl.split('note_attachments/').last;
      } else {
        // Fallback if URL structure is different
        pathInBucket = note.fileUrl.split('/').last;
      }

      // 2. Download bytes from Supabase
      // Using download() instead of public URL for better reliability
      final Uint8List fileBytes = await supabase.storage
          .from('note_attachments')
          .download(pathInBucket);

      if (mounted) setState(() => _downloadProgress = 0.5);

      // 3. Ask user where to save the file (Native Windows/Mobile Dialog)
      // On Web, bytes are required here to trigger the download.
      final String? savePath = await FilePicker.saveFile(
        dialogTitle: 'Select where to save your note:',
        fileName: note.fileName ?? (note.title + (note.isPdf ? '.pdf' : '')),
        bytes: fileBytes,
      );

      if (savePath != null || kIsWeb) {
        // 4. Save the file locally (Only needed for non-web platforms if bytes were not handled)
        if (!kIsWeb && savePath != null) {
          final File file = File(savePath);
          await file.writeAsBytes(fileBytes);
        }

        if (mounted) {
          setState(() => _downloadProgress = 1.0);

          // Record the download in history
          await _noteService.recordDownload(note.id);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(savePath != null
                  ? 'Note saved to: $savePath'
                  : 'Note downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // User cancelled the save dialog
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Download cancelled')));
        }
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Bucket not found')) {
        errorMessage =
            'Database Error: The storage bucket "note_attachments" does not exist in your Supabase project. Please create it in the Supabase console.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _handleUnlock(Note note) async {
    if (note.isPremium) {
      // Step 1: Deduct credits first
      setState(() => _isCheckingUnlock = true);
      try {
        await _purchaseService.deductCredits(note.creditsCost);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${note.creditsCost} credits deducted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isCheckingUnlock = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return; // Block download if credits cannot be deducted
      }
      if (mounted) setState(() => _isCheckingUnlock = false);
    }

    // Step 2: Navigate to Mock Payment Screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MockPaymentScreen(note: note)),
    );

    if (result == true) {
      _checkUnlockStatus();
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwnNote = widget.note.uploaderId == _noteService.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: 'Note Details',
        showBackButton: true,
        actions: [
          if (isOwnNote)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: () => _deleteNote(widget.note),
              tooltip: 'Delete Note',
            ),
        ],
      ),
      body: StreamBuilder<Note>(
        stream: _noteService.getNoteStream(widget.note.id),
        initialData: widget.note,
        builder: (context, noteSnapshot) {
          final note = noteSnapshot.data ?? widget.note;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Section (Highlight Area)
                          DetailHeader(
                            note: note.copyWith(isBookmarked: _isBookmarked),
                            onBookmarkToggle: _toggleBookmark,
                          ),

                          const SizedBox(height: 24),

                          // Info Section (Uploader & Date)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InfoRow(
                                    icon: Icons.person_outline_rounded,
                                    label: 'UPLOADER',
                                    value: note.uploaderName,
                                  ),
                                ),
                                Container(
                                  height: 32,
                                  width: 1.5,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant.withOpacity(0.5),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: InfoRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'DATE',
                                    value:
                                        '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Description Section
                          _buildSectionCard(
                            context,
                            title: 'Description',
                            child: Text(
                              note.description.isNotEmpty
                                  ? note.description
                                  : 'No description available',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    height: 1.6,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Reviews Section
                          _buildSectionCard(
                            context,
                            title: 'Ratings & Reviews',
                            child: Column(
                              children: [
                                StarRatingInput(
                                  onRatingChanged: (rating) {
                                    _selectedRating = rating;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _reviewController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Write your review...',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitReview,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'SUBMIT REVIEW',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const Divider(),
                                const SizedBox(height: 16),
                                StreamBuilder<List<Review>>(
                                  stream: _noteService.getNoteReviews(note.id),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    final reviews = snapshot.data ?? [];
                                    if (reviews.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        child: Text(
                                          'No reviews yet',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                          ),
                                        ),
                                      );
                                    }
                                    return Column(
                                      children: reviews
                                          .map(
                                            (review) => ReviewCard(
                                              userName: review.userName,
                                              date:
                                                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                              comment: review.comment,
                                              rating: review.rating,
                                              userId: review.userId,
                                              avatarUrl: review.avatarUrl,
                                              onDelete: () => _deleteReview(review.id),
                                            ),
                                          )
                                          .toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Premium Lock Overlay
              if (!_isUnlocked && !_isCheckingUnlock)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_rounded,
                                size: 48,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Premium Content',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This note is locked. Unlock it for ${widget.note.isPremium ? '${widget.note.creditsCost} credits + ₹${widget.note.price}' : '₹${widget.note.price}'} to view the full details and download.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Action Button (Sticky at bottom)
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isDownloading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            color: Theme.of(context).colorScheme.primary,
                            minHeight: 6,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isCheckingUnlock
                            ? 'CHECKING STATUS...'
                            : _isUnlocked
                            ? (_isDownloading
                                  ? 'DOWNLOADING...'
                                  : 'DOWNLOAD NOTE')
                            : 'UNLOCK FOR ${note.isPremium ? '${note.creditsCost} CR + ₹${note.price}' : '₹${note.price}'}',
                        icon: _isCheckingUnlock
                            ? null
                            : _isUnlocked
                            ? (_isDownloading ? null : Icons.download_rounded)
                            : Icons.lock_open_rounded,
                        color: (!_isUnlocked && !_isCheckingUnlock)
                            ? Colors.amber.shade900
                            : null,
                        onPressed: _isCheckingUnlock || _isDownloading
                            ? null
                            : _isUnlocked
                            ? () => _downloadNote(note)
                            : () => _handleUnlock(note),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
