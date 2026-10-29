import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/quran_search_source.dart';
import 'quran_search_cubit.dart';
import 'quran_search_state.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key, this.initialQuery = ''});

  /// Text handed over by the surah index when its own filter found nothing;
  /// the screen opens on that search instead of an empty prompt.
  final String initialQuery;

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);

  @override
  void initState() {
    super.initState();
    final query = widget.initialQuery.trim();
    if (query.isNotEmpty) {
      context.read<QuranSearchCubit>().search(query);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.searchQuranTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: SearchField(
              hint: loc.searchQuranHint,
              controller: _controller,
              // Arriving with a query means the results are the point; only
              // the empty prompt wants the keyboard.
              autofocus: widget.initialQuery.trim().isEmpty,
              onChanged: context.read<QuranSearchCubit>().onQueryChanged,
            ),
          ),
          Expanded(
            child: BlocBuilder<QuranSearchCubit, QuranSearchState>(
              builder: (context, state) => switch (state) {
                QuranSearchLoading() => const LoadingView(),
                QuranSearchFailed() => errorPane(loc),
                QuranSearchReady(:final query, :final hits) =>
                  !quranSearchQueryUsable(query)
                      ? EmptyState(loc.searchQuranPrompt)
                      : hits.isEmpty
                          ? EmptyState(loc.noResults)
                          : _Results(ready: state),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.ready});

  final QuranSearchReady ready;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final showTail = ready.hasMore || ready.loadingMore || ready.moreFailed;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              loc.searchQuranResultsCount(ready.total.toArabicIndic),
              style: AppTheme.mutedFootnote(context),
            ),
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 400) {
                context.read<QuranSearchCubit>().loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: appScrollPadding(
                  context, const EdgeInsets.all(AppSpacing.md)),
              itemCount: ready.hits.length + (showTail ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == ready.hits.length) return _tail(context, loc);
                return _HitTile(hit: ready.hits[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _tail(BuildContext context, AppLocalizations loc) {
    if (ready.moreFailed) {
      return Center(
        child: TextButton(
          onPressed: context.read<QuranSearchCubit>().retryMore,
          child: Text(loc.retry),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit});

  final QuranSearchHit hit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(
          '${hit.surahId.toArabicIndic}:${hit.numberInSurah.toArabicIndic}',
          style: const TextStyle(fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
        title: Text(
          hit.textImlaei,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(hit.surahNameAr),
        onTap: () => context.push(quranReaderPath(
          surah: hit.surahId,
          ayah: hit.numberInSurah,
        )),
      ),
    );
  }
}
