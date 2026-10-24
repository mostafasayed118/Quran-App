import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';

/// Attribution and license surface: the shipped Quran/tafsir/hadith/audio
/// sources, the two mushaf font terms, and the open-source package licenses.
///
/// The HafsSmart EULA and the me_quran terms ship as assets (the font name
/// table carries them, but the user must be able to read them in-app).
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  static const String _hafsEula = 'assets/licenses/HafsSmart-EULA.txt';
  static const String _meQuranTerms = 'assets/licenses/me_quran-terms.txt';
  static const String _cairoOfl = 'assets/fonts/Cairo-OFL.txt';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.licensesTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          SectionHeader(title: loc.licensesContentSection),
          _InfoTile(
            icon: Icons.menu_book_outlined,
            text: loc.licensesQuranText,
          ),
          _InfoTile(icon: Icons.translate_outlined, text: loc.licensesSiraj),
          _InfoTile(
              icon: Icons.translate_outlined, text: loc.licensesPickthall),
          _InfoTile(
              icon: Icons.library_books_outlined, text: loc.licensesBukhari),
          _InfoTile(icon: Icons.spa_outlined, text: loc.licensesAzkar),
          _InfoTile(icon: Icons.headphones_outlined, text: loc.licensesAudio),
          SectionHeader(title: loc.licensesFontsSection),
          _AssetTile(
            icon: Icons.font_download_outlined,
            title: loc.licensesHafsSmart,
            action: loc.licensesHafsEula,
            asset: _hafsEula,
          ),
          _AssetTile(
            icon: Icons.font_download_outlined,
            title: loc.licensesMeQuran,
            action: loc.licensesMeQuranTerms,
            asset: _meQuranTerms,
          ),
          _AssetTile(
            icon: Icons.font_download_outlined,
            title: loc.licensesCairo,
            action: loc.licensesCairoOfl,
            asset: _cairoOfl,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(loc.licensesOpenSource),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Quran Yahdi',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              loc.licensesWithdrawn,
              style: AppTheme.mutedFootnote(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.icon,
    required this.title,
    required this.action,
    required this.asset,
  });

  final IconData icon;
  final String title;
  final String action;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(action),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(context, title, asset),
    );
  }

  Future<void> _open(BuildContext context, String title, String asset) async {
    final loc = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: FutureBuilder<String>(
            future: rootBundle.loadString(asset),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text(loc.licensesUnavailable);
              final text = snapshot.data;
              if (text == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                child: Text(text, style: const TextStyle(fontSize: 13)),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.licensesClose),
          ),
        ],
      ),
    );
  }
}
