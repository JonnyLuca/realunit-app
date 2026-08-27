import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/referral/load_referral_terms.dart';

void main() {
  test('prefers non-empty API markdown over bundled assets', () async {
    final loaded = <String>[];
    final result = await loadReferralTermsMarkdown(
      languageCode: 'en',
      apiText: '# From API',
      loadAsset: (path) async {
        loaded.add(path);
        return '# unused';
      },
    );

    expect(result, '# From API');
    expect(loaded, isEmpty);
  });

  test('skips blank API markdown and loads the locale asset', () async {
    final result = await loadReferralTermsMarkdown(
      languageCode: 'en',
      apiText: '   ',
      loadAsset: (path) async {
        if (path.endsWith('referral_terms_en.md')) return '# English TB';
        throw Exception('missing $path');
      },
    );

    expect(result, '# English TB');
  });

  test('falls back to the German TB when the locale asset is missing', () async {
    final result = await loadReferralTermsMarkdown(
      languageCode: 'en',
      loadAsset: (path) async {
        if (path.endsWith('referral_terms_de.md')) return '# DE TB 14.08.2026';
        throw Exception('missing $path');
      },
    );

    expect(result, '# DE TB 14.08.2026');
  });

  test('returns null when API and bundled assets are all empty', () async {
    final result = await loadReferralTermsMarkdown(
      languageCode: 'de',
      apiText: '',
      loadAsset: (_) async => throw Exception('missing'),
    );

    expect(result, isNull);
  });
}
