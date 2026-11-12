part of 'bookmarks_body.dart';

class _BookmarkMetaDialog extends StatefulWidget {
  const _BookmarkMetaDialog({required this.folder, required this.note});

  final String folder;
  final String note;

  @override
  State<_BookmarkMetaDialog> createState() => _BookmarkMetaDialogState();
}

class _BookmarkMetaDialogState extends State<_BookmarkMetaDialog> {
  late final TextEditingController _folder;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _folder = TextEditingController(text: widget.folder);
    _note = TextEditingController(text: widget.note);
  }

  @override
  void dispose() {
    _folder.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.bookmarkEdit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _folder,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: loc.bookmarkFolder,
                hintText: loc.bookmarkFolderHint,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: loc.bookmarkNote,
                hintText: loc.bookmarkNoteHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            (folder: _folder.text, note: _note.text),
          ),
          child: Text(loc.bookmarkMetaSave),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.entry});

  final BookmarkMetaEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.folder.isNotEmpty)
          Text(
            entry.folder,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        if (entry.note.isNotEmpty)
          Text(
            entry.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
      ],
    );
  }
}
