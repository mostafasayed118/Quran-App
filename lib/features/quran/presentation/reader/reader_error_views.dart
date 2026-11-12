part of 'reader_screen.dart';

/// The reader failure body, shared by the full route and the workspace pane.
class ReaderErrorBody extends StatelessWidget {
  /// Creates the failure body for [state].
  const ReaderErrorBody({super.key, required this.state});

  /// The failed reader state.
  final ReaderFailed state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final emptySurahId = state.emptySurahId;
    return AppContentFrame.reading(
      child: Column(
        children: [
          Expanded(
            child: emptySurahId == null
                ? errorPane(loc)
                // A surah without readable ayahs is its own failure: the
                // generic pane would blame a transient error.
                : ErrorView(loc.readerNoAyahs(loc.number(emptySurahId))),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 32 + appBottomInset(context)),
            child: FilledButton(
              onPressed: () => context.read<ReaderCubit>().reload(),
              child: Text(loc.retry),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderErrorView extends StatelessWidget {
  const _ReaderErrorView({required this.state});

  final ReaderFailed state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.quran)),
      body: ReaderErrorBody(state: state),
    );
  }
}
