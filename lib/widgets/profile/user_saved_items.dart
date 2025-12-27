import 'package:app_demo/UI/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/login/auth_service.dart';
import '../../backend_data/service/saved_items_service.dart';
import '../../backend_data/service/firestore_service.dart';
import '../../backend_data/database/lesson_data.dart';
import '../SundaySchool_app/lesson_preview.dart';
import '../SundaySchool_app/further_reading/further_reading_dialog.dart';

class SavedItemsPage extends StatefulWidget {
  const SavedItemsPage({super.key});

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SavedItemsService _service = SavedItemsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = context.read<AuthService>();

    // If not logged in or no church, show a message
    if (user == null || user.isAnonymous || !authService.hasChurch) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved Items'),
          centerTitle: true,
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bookmark, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Sign in to save your favorites',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bookmarks, lessons, and readings will sync across your devices.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final churchId = authService.churchId;
    final userId = user.uid;

    if (churchId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved Items'),
          centerTitle: true,
          backgroundColor: AppColors.primary,
        ),
        body: const Center(
          child: Text('No church selected'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Items'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.bookmark), text: 'Bookmarks'),
            Tab(icon: Icon(Icons.school), text: 'Lessons'),
            Tab(icon: Icon(Icons.library_books), text: 'Readings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BookmarksTab(
            churchId: churchId,
            userId: userId,
            service: _service,
          ),
          _SavedLessonsTab(
            churchId: churchId,
            userId: userId,
            service: _service,
          ),
          _FurtherReadingsTab(
            churchId: churchId,
            userId: userId,
            service: _service,
          ),
        ],
      ),
    );
  }
}

// ──────────────── BOOKMARKS TAB ──────────────────
class _BookmarksTab extends StatelessWidget {
  final String churchId;
  final String userId;
  final SavedItemsService service;

  const _BookmarksTab({
    required this.churchId,
    required this.userId,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.watchBookmarks(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _EmptyState(
            icon: Icons.bookmark_border,
            title: 'No Bookmarks Yet',
            message: 'Save your favorite scriptures to read them anytime.',
          );
        }

        final bookmarks = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            final id = bookmark['id'] as String;
            final title = bookmark['title'] as String? ?? 'Unknown';
            final note = bookmark['note'] as String?;
            final text = bookmark['text'] as String?;

            return _BookmarkCard(
              title: title,
              text: text,
              note: note,
              onDelete: () => service.removeBookmark(userId, id),
              onEditNote: (newNote) =>
                  service.updateBookmarkNote(userId, id, newNote),
            );
          },
        );
      },
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final String title;
  final String? text;
  final String? note;
  final VoidCallback onDelete;
  final Function(String) onEditNote;
  final VoidCallback? onTap;


  const _BookmarkCard({
    required this.title,
    required this.text,
    required this.note,
    required this.onDelete,
    required this.onEditNote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            ExpansionTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Prevents extra vertical space
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (text != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    text!.length > 60 
                        ? "${text!.substring(0, 60)}..." 
                        : text!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: AppColors.grey700, size: 20),
              onPressed: onDelete,
              tooltip: 'Delete bookmark',
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            initiallyExpanded: false, // ← Starts minimized (collapsed)
            expandedAlignment: Alignment.topLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full content shown when expanded
              if (text != null) ...[
                const SizedBox(height: 8),
                Text(
                  text!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
              if (note != null && note!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Note",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 244, 174, 82),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note!,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
              // Optional: Add edit note button or field here if you want
              if (note != null || text != null)
                const SizedBox(height: 12),
            ],
          ),
        ],
      ),
    ));
  }
}
/*class _BookmarkCard extends StatelessWidget {
  final String title;
  final String? text;
  final String? note;
  final VoidCallback onDelete;
  final Function(String) onEditNote;

  const _BookmarkCard({
    required this.title,
    required this.text,
    required this.note,
    required this.onDelete,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete bookmark',
                ),
              ],
            ),
            if (text != null) ...[
              const SizedBox(height: 8),
              Text(
                text!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (note != null && note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Note: $note',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}*/

// ──────────────── SAVED LESSONS TAB ──────────────────
class _SavedLessonsTab extends StatelessWidget {
  final String churchId;
  final String userId;
  final SavedItemsService service;

  const _SavedLessonsTab({
    required this.churchId,
    required this.userId,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.watchSavedLessons(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _EmptyState(
            icon: Icons.school,
            title: 'No Saved Lessons',
            message: 'Save lessons to review them later.',
          );
        }

        final lessons = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            final id = lesson['id'] as String;
            final lessonId = lesson['lessonId'] as String? ?? id;
            final title = lesson['title'] as String? ?? 'Untitled';
            final lessonType = lesson['lessonType'] as String? ?? '';
            final preview = lesson['preview'] as String?;
            final note = lesson['note'] as String?;

            return _LessonCard(
              title: title,
              type: lessonType,
              preview: preview,
              note: note,
              onDelete: () => service.removeSavedLesson(userId, id),
              onEditNote: (newNote) =>
                  service.updateSavedLessonNote(userId, id, newNote),
              onTap: () async {
                DateTime? date;
                try {
                  final parts = lessonId.split('-').map((s) => int.parse(s)).toList();
                  if (parts.length == 3) {
                    date = DateTime(parts[0], parts[1], parts[2]);
                  }
                } catch (_) {
                  date = null;
                }

                if (date == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid saved lesson id')));
                  return;
                }

                final auth = context.read<AuthService>();
                final fs = FirestoreService(churchId: auth.churchId);
                final lessonDay = await fs.loadLesson(date!);
                if (lessonDay == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson not found')));
                  return;
                }

                final isTeen = (lessonType == 'teen');
                final section = isTeen ? lessonDay.teenNotes : lessonDay.adultNotes;
                if (section == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved lesson content not available')));
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BeautifulLessonPage(
                      data: section,
                      title: title,
                      lessonDate: date!,
                      isTeen: isTeen,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LessonCard extends StatelessWidget {
  final String title;
  final String type;
  final String? preview;
  final String? note;
  final VoidCallback onDelete;
  final Function(String) onEditNote;
  final VoidCallback? onTap;

  const _LessonCard({
    required this.title,
    required this.type,
    required this.preview,
    required this.note,
    required this.onDelete,
    required this.onEditNote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (preview != null && preview!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        preview!.length > 120 ? "${preview!.substring(0, 120)}..." : preview!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (note != null && note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                        child: Text('Note: $note', style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.grey),
                    onPressed: onTap,
                    tooltip: 'Open lesson',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.grey700, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete lesson',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*class _LessonCard extends StatelessWidget {
  final String title;
  final String type;
  final String? preview;
  final String? note;
  final VoidCallback onDelete;
  final Function(String) onEditNote;

  const _LessonCard({
    required this.title,
    required this.type,
    required this.preview,
    required this.note,
    required this.onDelete,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (type.isNotEmpty)
                        Text(
                          'Type: ${type.capitalize()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete lesson',
                ),
              ],
            ),
            if (preview != null && preview!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                preview!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (note != null && note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Note: $note',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}*/

// ──────────────── FURTHER READINGS TAB ──────────────────
class _FurtherReadingsTab extends StatelessWidget {
  final String churchId;
  final String userId;
  final SavedItemsService service;

  const _FurtherReadingsTab({
    required this.churchId,
    required this.userId,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.watchFurtherReadings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _EmptyState(
            icon: Icons.library_books,
            title: 'No Further Readings',
            message: 'Save reading materials to explore them later.',
          );
        }

        final readings = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: readings.length,
          itemBuilder: (context, index) {
            final reading = readings[index];
            final id = reading['id'] as String;
            final title = reading['title'] as String? ?? 'Untitled';
            final readingText = reading['reading'] as String?;
            final note = reading['note'] as String?;

            return _ReadingCard(
              title: title,
              readingText: readingText,
              note: note,
              onDelete: () => service.removeFurtherReading(userId, id),
              onEditNote: (newNote) =>
                  service.updateFurtherReadingNote(userId, id, newNote),
              onTap: () {
                // prefer link if it looks like a scripture reference, otherwise title
                final todayReading = (readingText != null && readingText.isNotEmpty) ? readingText : title;
                showFurtherReadingDialog(context: context, todayReading: todayReading);
              },
            );
          },
        );
      },
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final String title;
  final String? readingText;
  final String? note;
  final VoidCallback onDelete;
  final Function(String) onEditNote;
  final VoidCallback? onTap;

  const _ReadingCard({
    required this.title,
    required this.readingText,
    required this.note,
    required this.onDelete,
    required this.onEditNote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color:  AppColors.grey700, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete reading',
                  ),
                ],
              ),
              /*if (readingText != null && readingText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    if (onTap != null) {
                      onTap!();
                      return;
                    }
      
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening: $readingText')),
                    );
                  },
                  child: Text(
                    readingText!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],*/
              if (note != null && note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Note: $note',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────── EMPTY STATE ──────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
