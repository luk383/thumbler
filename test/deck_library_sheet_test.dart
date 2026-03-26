import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolf_lab/app/l10n/app_localizations.dart';
import 'package:wolf_lab/features/study/data/deck_pack.dart';
import 'package:wolf_lab/features/study/presentation/controllers/deck_library_controller.dart';
import 'package:wolf_lab/features/study/presentation/widgets/deck_library_sheet.dart';

void main() {
  testWidgets('library shows available AWS certification tracks', (
    tester,
  ) async {
    const saaDeck = DeckPackMeta(
      id: 'aws_certified_solutions_architect_associate_saa_c03',
      assetPath:
          'assets/decks/aws_certified_solutions_architect_associate_saa_c03.json',
      provider: 'aws',
      certificationId: 'aws_saa',
      certificationTitle: 'AWS Certified Solutions Architect - Associate',
      track: 'Associate',
      title: 'AWS Certified Solutions Architect - Associate',
      category: 'AWS Architecture',
      examCode: 'SAA-C03',
      description: 'Architecture study deck',
      questionCount: 100,
      domains: ['Design Secure Architectures'],
      examQuestionCount: 40,
      microCardCount: 60,
    );
    const scsDeck = DeckPackMeta(
      id: 'aws_certified_security_specialty_scs_c02',
      assetPath: 'assets/decks/aws_certified_security_specialty_scs_c02.json',
      provider: 'aws',
      certificationId: 'aws_scs',
      certificationTitle: 'AWS Certified Security - Specialty',
      track: 'Specialty',
      title: 'AWS Certified Security - Specialty',
      category: 'AWS Security',
      examCode: 'SCS-C02',
      description: 'Security study deck',
      questionCount: 100,
      domains: ['Threat Detection and Monitoring'],
      examQuestionCount: 40,
      microCardCount: 60,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckLibraryProvider.overrideWith(
            () => _FakeDeckLibraryNotifier(
              const DeckLibraryState(
                packs: [saaDeck, scsDeck],
                activeDeckId:
                    'aws_certified_solutions_architect_associate_saa_c03',
              ),
            ),
          ),
          deckProgressSummariesProvider.overrideWithValue(const {
            'aws_certified_solutions_architect_associate_saa_c03':
                DeckProgressSummary(
                  deckId: 'aws_certified_solutions_architect_associate_saa_c03',
                  totalItems: 100,
                  reviewedItems: 8,
                ),
          }),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: DeckLibrarySheet()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('AWS Certified Solutions Architect - Associate'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('AWS Certified Security - Specialty'), findsOneWidget);
  });
}

class _FakeDeckLibraryNotifier extends DeckLibraryNotifier {
  _FakeDeckLibraryNotifier(this._state);

  final DeckLibraryState _state;

  @override
  DeckLibraryState build() => _state;
}
