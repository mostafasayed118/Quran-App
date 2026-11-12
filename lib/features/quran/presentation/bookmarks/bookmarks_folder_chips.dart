part of 'bookmarks_body.dart';

class _FolderChips extends StatelessWidget {
  const _FolderChips({required this.folders});

  final List<String> folders;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          for (final folder in folders)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: GestureDetector(
                onLongPress: () => _folderActions(context, folder),
                child: ActionChip(
                  avatar: const Icon(Icons.folder_outlined, size: 16),
                  label: Text(folder),
                  onPressed: () => context.push(bookmarksFolderPath(folder)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Long-press a folder chip: rename it everywhere or drop the label.
  Future<void> _folderActions(BuildContext context, String folder) async {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<BookmarkMetaCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final action = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(folder),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('rename'),
            child: Text(loc.bookmarkFolderRename),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('delete'),
            child: Text(loc.bookmarkFolderDelete),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (action == 'rename') {
      final name = await showDialog<String>(
        context: context,
        builder: (_) => _FolderNameDialog(initial: folder),
      );
      if (name == null || name.trim().isEmpty) return;
      final saved = await cubit.renameFolder(folder, name);
      if (!saved) {
        AppToast.showOn(messenger, loc.genericError, tone: ToastTone.error);
      }
    } else if (action == 'delete') {
      final confirmed = await confirmDeleteDialog(
        context,
        title: loc.bookmarkFolderDelete,
        body: loc.bookmarkFolderDeleteBody,
      );
      if (!confirmed) return;
      final saved = await cubit.deleteFolder(folder);
      if (!saved) {
        AppToast.showOn(messenger, loc.genericError, tone: ToastTone.error);
      }
    }
  }
}

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({required this.initial});

  final String initial;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final value = _name.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.bookmarkFolderRename),
      content: TextField(
        controller: _name,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(labelText: loc.bookmarkFolderName),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(loc.bookmarkMetaSave)),
      ],
    );
  }
}
