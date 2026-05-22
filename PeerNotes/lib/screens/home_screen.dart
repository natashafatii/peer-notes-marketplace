import 'package:flutter/material.dart';
import 'upload_screen.dart';
import 'profile_screen.dart';
import '../widgets/category_chip.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar.dart';
import '../models/note.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state.dart';
import '../services/note_service.dart';

import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const HomeScreen({super.key, this.onProfileTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NoteService _noteService = NoteService();
  final List<String> _categories = [
    'All',
    'Programming',
    'Design',
    'Business',
    'Academics',
    'Math',
    'Science',
  ];
  String _selectedCategory = 'All';

  final List<String> _filters = ['All', 'Free', 'Paid'];
  String _selectedFilter = 'All';

  final TextEditingController _searchController = TextEditingController();

  String _selectedSort = 'Most Recent';
  final List<String> _sortOptions = [
    'Most Recent',
    'Highest Rated',
    'Most Popular',
    'Price: Low to High',
    'Price: High to Low',
    'A to Z',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: 'Peer Notes',
        subtitle: 'Marketplace',
        isHomeScreen: true,
        onProfileTap:
            widget.onProfileTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
      ),
      body: StreamBuilder<List<Note>>(
        stream: _noteService.getAllNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allNotes = snapshot.data ?? [];
          final query = _searchController.text.toLowerCase();

          final filteredNotes = allNotes.where((note) {
            final matchesSearch =
                query.isEmpty ||
                note.title.toLowerCase().contains(query) ||
                note.category.toLowerCase().contains(query);

            final matchesCategory =
                _selectedCategory == 'All' ||
                note.category == _selectedCategory;

            final matchesFilter =
                _selectedFilter == 'All' ||
                (_selectedFilter == 'Free' && note.isFree) ||
                (_selectedFilter == 'Paid' && !note.isFree);

            return matchesSearch && matchesCategory && matchesFilter;
          }).toList();

          // Sort the filtered notes list based on the chosen option
          switch (_selectedSort) {
            case 'Highest Rated':
              filteredNotes.sort((a, b) => b.rating.compareTo(a.rating));
              break;
            case 'Most Recent':
              filteredNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              break;
            case 'Most Popular':
              filteredNotes.sort(
                (a, b) => b.downloadCount.compareTo(a.downloadCount),
              );
              break;
            case 'Price: Low to High':
              filteredNotes.sort((a, b) => a.price.compareTo(b.price));
              break;
            case 'Price: High to Low':
              filteredNotes.sort((a, b) => b.price.compareTo(a.price));
              break;
            case 'A to Z':
              filteredNotes.sort(
                (a, b) =>
                    a.title.toLowerCase().compareTo(b.title.toLowerCase()),
              );
              break;
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomSearchBar(
                        controller: _searchController,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 42,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return CategoryChip(
                              label: category,
                              isSelected: _selectedCategory == category,
                              onTap: () {
                                setState(() => _selectedCategory = category);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: _filters.map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedFilter = filter),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.surface
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      filter,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Notes',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          _buildSortDropdown(context),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              if (filteredNotes.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.notes_rounded,
                    title: 'No notes uploaded yet',
                    subtitle:
                        'Be the first to share your knowledge with the community!',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return NoteCard(note: filteredNotes[index]);
                    }, childCount: filteredNotes.length),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Upload Note',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        initialValue: _selectedSort,
        onSelected: (String newValue) {
          setState(() {
            _selectedSort = newValue;
          });
        },
        itemBuilder: (BuildContext context) {
          return _sortOptions.map((String option) {
            IconData icon;
            switch (option) {
              case 'Highest Rated':
                icon = Icons.star_rounded;
                break;
              case 'Most Recent':
                icon = Icons.access_time_rounded;
                break;
              case 'Most Popular':
                icon = Icons.trending_up_rounded;
                break;
              case 'Price: Low to High':
                icon = Icons.arrow_downward_rounded;
                break;
              case 'Price: High to Low':
                icon = Icons.arrow_upward_rounded;
                break;
              case 'A to Z':
                icon = Icons.sort_by_alpha_rounded;
                break;
              default:
                icon = Icons.sort_rounded;
            }
            final isSelected = option == _selectedSort;

            return PopupMenuItem<String>(
              value: option,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    option,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _selectedSort,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
