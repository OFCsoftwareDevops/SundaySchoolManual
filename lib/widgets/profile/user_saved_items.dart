
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../UI/app_bar.dart';
import '../../UI/app_colors.dart';
import '../../auth/login/auth_service.dart';
import '../../backend_data/service/firestore/saved_items_service.dart';
import '../../backend_data/service/firestore/firestore_service.dart';
import '../../l10n/app_localizations.dart';
import '../SundaySchool_app/lesson_preview.dart';
import '../SundaySchool_app/further_reading/further_reading_dialog.dart';
import '../helpers/snackbar.dart';

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
    final theme = Theme.of(context);

    /*/ If not logged in or no church, show a message
    if (user == null || user.isAnonymous || !authService.hasChurch) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          centerTitle: true,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)?.savedItemsTitle ?? "Saved Items",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: style.monthFontSize.sp,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: style.monthFontSize.sp,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.sp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.sp),
                Text(
                  AppLocalizations.of(context)?.signInToSaveFavorites ?? 'Sign in to save your favorites',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.sp),
                Text(
                  AppLocalizations.of(context)?.bookmarksSyncMessage ?? 'Bookmarks, lessons, and readings will sync across your devices.',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }*/
    final userId = user!.uid;

    /*if (churchId == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          centerTitle: true,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)?.savedItemsTitle ?? "Saved Items",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: style.monthFontSize.sp,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: style.monthFontSize.sp,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)?.noChurchSelected ?? 'No church selected'),
        ),
      );
    }*/

    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalizations.of(context)?.savedItemsTitle ?? "Saved Items",
        showBack: true,
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: theme.colorScheme.onSecondaryContainer, // selected background
          ),
          indicatorColor: theme.colorScheme.onSecondaryContainer,
          labelColor: theme.colorScheme.secondaryContainer,
          unselectedLabelColor: theme.colorScheme.onSecondaryContainer,
          labelStyle: TextStyle(
            fontSize: 13.sp,        // Clear, readable tab labels
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 13.sp,
          ),
          indicatorSize: TabBarIndicatorSize.tab, // Optional: makes indicator match full tab width
          indicatorWeight: 2.0,                    // Slightly thicker for emphasis
          tabs: [
            Tab(
              icon: Icon(Icons.bookmark, size: 18.sp),
              text: AppLocalizations.of(context)?.bookmarks ?? 'Bookmarks',
            ),
            Tab(
              icon: Icon(Icons.school, size: 18.sp),
              text: AppLocalizations.of(context)?.lessons ?? 'Lessons',
            ),
            Tab(
              icon: Icon(Icons.library_books, size: 18.sp),
              text: AppLocalizations.of(context)?.readings ?? 'Readings',
            ),
          ],
        ),
      ),
      /*/backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown, // Scales down text if it would overflow
          child: Text(
            AppLocalizations.of(context)?.savedItemsTitle ?? "Saved Items",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: style.monthFontSize.sp, // Matches your other screen's style
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: style.monthFontSize.sp, // Consistent sizing
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontSize: 13.sp,        // Clear, readable tab labels
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 13.sp,
          ),
          indicatorSize: TabBarIndicatorSize.tab, // Optional: makes indicator match full tab width
          indicatorWeight: 2.0,                    // Slightly thicker for emphasis
          tabs: [
            Tab(
              icon: Icon(Icons.bookmark, size: 18.sp),
              text: AppLocalizations.of(context)?.bookmarks ?? 'Bookmarks',
            ),
            Tab(
              icon: Icon(Icons.school, size: 18.sp),
              text: AppLocalizations.of(context)?.lessons ?? 'Lessons',
            ),
            Tab(
              icon: Icon(Icons.library_books, size: 18.sp),
              text: AppLocalizations.of(context)?.readings ?? 'Readings',
            ),
          ],
        ),
      ),*/
      body: TabBarView(
        controller: _tabController,
        children: [
          _BookmarksTab(
            userId: userId,
            service: _service,
          ),
          _SavedLessonsTab(
            userId: userId,
            service: _service,
          ),
          _FurtherReadingsTab(
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
  final String userId;
  final SavedItemsService service;

  const _BookmarksTab({
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
            title: AppLocalizations.of(context)?.noBookmarksYetMessage ?? 'No Bookmarks Yet',
            message: AppLocalizations.of(context)?.saveFavoriteScriptures ?? 'Save your favorite scriptures to read them anytime.',
          );
        }

        final bookmarks = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(8.sp),
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
      borderRadius: BorderRadius.circular(12.sp),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.sp, horizontal: 8.sp),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
        child: Stack(
          children: [
            ExpansionTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Prevents extra vertical space
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (text != null) ...[
                  SizedBox(height: 4.sp),
                  Text(
                    text!.length > 60 
                        ? "${text!.substring(0, 60)}..." 
                        : text!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.3.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: AppColors.grey700, size: 20.sp),
              onPressed: onDelete,
              tooltip: AppLocalizations.of(context)?.deleteBookmark ?? 'Delete bookmark',
            ),
            tilePadding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
            childrenPadding: EdgeInsets.fromLTRB(16.sp, 0, 16.sp, 12.sp),
            initiallyExpanded: false, // ← Starts minimized (collapsed)
            expandedAlignment: Alignment.topLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full content shown when expanded
              if (text != null) ...[
                SizedBox(height: 8.sp),
                Text(
                  text!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.4.sp,
                  ),
                ),
              ],
              if (note != null && note!.isNotEmpty) ...[
                SizedBox(height: 16.sp),
                Container(
                  padding: EdgeInsets.all(12.sp),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.yourNote ?? "Your Note",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 244, 174, 82),
                        ),
                      ),
                      SizedBox(height: 4.sp),
                      Text(
                        note!,
                        style: TextStyle(fontSize: 13.sp, height: 1.4.sp),
                      ),
                    ],
                  ),
                ),
              ],
              // Optional: Add edit note button or field here if you want
              if (note != null || text != null)
                SizedBox(height: 12.sp),
            ],
          ),
        ],
      ),
    ));
  }
}

// ──────────────── SAVED LESSONS TAB ──────────────────
class _SavedLessonsTab extends StatelessWidget {
  final String userId;
  final SavedItemsService service;

  const _SavedLessonsTab({
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
            title: AppLocalizations.of(context)?.noSavedLessons ?? 'No Saved Lessons',
            message: AppLocalizations.of(context)?.saveLessonsToReview ?? 'Save lessons to review them later.',
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
                  showTopToast(
                    context,
                    AppLocalizations.of(context)?.invalidSavedLessonId ?? 'Invalid saved lesson id',
                  );
                  return;
                }

                final auth = context.read<AuthService>();
                final fs = FirestoreService(churchId: auth.churchId);
                final lessonDay = await fs.loadLesson(context, date);
                if (lessonDay == null) {
                  showTopToast(
                    context,
                    AppLocalizations.of(context)?.lessonNotFound ?? 'Lesson not found',
                  );
                  return;
                }

                final isTeen = (lessonType == 'teen');
                final section = isTeen ? lessonDay.teenNotes : lessonDay.adultNotes;
                if (section == null) {
                  showTopToast(
                    context,
                    AppLocalizations.of(context)?.savedLessonContentNotAvailable ?? 'Saved lesson content not available',
                  );
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
      borderRadius: BorderRadius.circular(12.sp),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.sp, horizontal: 8.sp),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (preview != null && preview!.isNotEmpty) ...[
                      SizedBox(height: 8.sp),
                      Text(
                        preview!.length > 120 ? "${preview!.substring(0, 120)}..." : preview!,
                        style: TextStyle(fontSize: 13.sp, /*color: Colors.grey[700],*/ height: 1.4.sp),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (note != null && note!.isNotEmpty) ...[
                      SizedBox(height: 8.sp),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6.sp)),
                        child: Text('${AppLocalizations.of(context)?.noteLabel ?? 'Note'}: $note', style: TextStyle(fontSize: 13.sp)),
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
                    tooltip: AppLocalizations.of(context)?.openLesson ?? 'Open lesson',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: AppColors.grey700, size: 20.sp),
                    onPressed: onDelete,
                    tooltip: AppLocalizations.of(context)?.deleteLesson ?? 'Delete lesson',
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

// ──────────────── FURTHER READINGS TAB ──────────────────
class _FurtherReadingsTab extends StatelessWidget {
  final String userId;
  final SavedItemsService service;

  const _FurtherReadingsTab({
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
            title: AppLocalizations.of(context)?.noFurtherReadings ?? 'No Further Readings',
            message: AppLocalizations.of(context)?.saveReadingMaterials ?? 'Save reading materials to explore them later.',
          );
        }

        final readings = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(8.sp),
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
              onTap: () async {
                // prefer link if it looks like a scripture reference, otherwise title
                final todayReading = (readingText != null && readingText.isNotEmpty) 
                  ? readingText 
                  : title;
                  
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
      borderRadius: BorderRadius.circular(12.sp),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.sp, horizontal: 8.sp),
        child: Padding(
          padding: EdgeInsets.all(12.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20.sp),
                    onPressed: onDelete,
                    tooltip: AppLocalizations.of(context)?.deleteReading ?? 'Delete reading',
                  ),
                ],
              ),
              if (note != null && note!.isNotEmpty) ...[
                SizedBox(height: 8.sp),
                Container(
                  padding: EdgeInsets.all(8.sp),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.sp),
                  ),
                  child: Text(
                    '${AppLocalizations.of(context)?.noteLabel ?? 'Note'}: $note',
                    style: TextStyle(fontSize: 13.sp),
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
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64.sp/*, color: Colors.grey[400]*/),
            SizedBox(height: 16.sp),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.sp),
            Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
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
