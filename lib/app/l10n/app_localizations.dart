import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('it'), Locale('en')];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    _AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations not found in context');
    return value!;
  }

  bool get isItalian => locale.languageCode == 'it';

  String get appTitle => isItalian ? 'Thumbler' : 'Thumbler';
  String get navFeed => isItalian ? 'Feed' : 'Feed';
  String get navStudy => isItalian ? 'Studio' : 'Study';
  String get navExam => isItalian ? 'Esame' : 'Exam';
  String get navSaved => isItalian ? 'Salvati' : 'Saved';
  String get navProfile => isItalian ? 'Profilo' : 'Profile';

  String get onboardingHeroTitle => isItalian
      ? 'Impara qualcosa di nuovo in pochi secondi'
      : 'Learn something new in seconds';
  String get onboardingHeroSubtitle => isItalian
      ? 'Scorri tra le domande e allena la mente.'
      : 'Swipe through questions and train your mind.';
  String get onboardingInterestsTitle =>
      isItalian ? 'Cosa vuoi imparare?' : 'What do you want to learn?';
  String get onboardingInterestsSubtitle => isItalian
      ? 'Scegli uno o piu interessi e inizia subito dal Feed.'
      : 'Pick one or more interests and start the Feed instantly.';
  String get onboardingSkip => isItalian ? 'Salta' : 'Skip';
  String get onboardingStartLearning =>
      isItalian ? 'Inizia a imparare' : 'Start learning';
  String get onboardingStartFeed =>
      isItalian ? 'Inizia dal Feed' : 'Start Feed';
  String get onboardingBadge => isItalian ? 'Feed al centro' : 'Feed first';
  String get onboardingHeroBody => isItalian
      ? 'Apri l app, vedi una domanda, rispondi e vai avanti.'
      : 'Open the app, see a question, answer, keep going.';
  String get onboardingHeroFoot => isItalian
      ? 'Nessuna configurazione iniziale. Solo una domanda utile alla volta.'
      : 'No setup friction. Just one useful question at a time.';

  String get paywallTitle =>
      isItalian ? 'Sblocca Thumbler Pro' : 'Unlock Thumbler Pro';
  String paywallSubtitle(String feature) => isItalian
      ? '$feature fa parte del piano Pro. La versione gratuita resta centrata sul Feed quotidiano e su argomenti ampi.'
      : '$feature is part of the Pro plan. The free app stays focused on the daily Feed and broad learning topics.';
  String get paywallProActive => isItalian ? 'Pro attivo' : 'Pro active';
  String get paywallProFeature => isItalian ? 'Funzione Pro' : 'Pro feature';
  String get paywallHeroBadge =>
      isItalian ? 'Feed-first, Pro per andare oltre' : 'Feed-first, Pro deeper';
  String get paywallHeroTitle => isItalian
      ? 'Mantieni gratuito il Feed quotidiano. Sblocca i flussi di apprendimento personalizzati con Pro.'
      : 'Keep the daily Feed free. Unlock custom knowledge workflows with Pro.';
  String get paywallHeroBody => isItalian
      ? 'Pro e il livello in cui vivono deck personali, pack esame importati e generazione da appunti.'
      : 'Pro is where personal decks, imported exam packs, and note-based generation live.';
  String get paywallWhatProUnlocks =>
      isItalian ? 'Cosa sblocca Pro' : 'What Pro unlocks';
  String get paywallImportDecksTitle =>
      isItalian ? 'Importa deck JSON' : 'Import JSON decks';
  String get paywallImportDecksCopy => isItalian
      ? 'Importa pack certificazione o raccolte di domande strutturate.'
      : 'Bring in certification packs or your own structured question sets.';
  String get paywallGenerateNotesTitle =>
      isItalian ? 'Genera da appunti' : 'Generate from notes';
  String get paywallGenerateNotesCopy => isItalian
      ? 'Trasforma note o PDF in deck da rivedere prima del salvataggio.'
      : 'Turn pasted notes or PDFs into reviewable study decks.';
  String get paywallCreateDecksTitle =>
      isItalian ? 'Crea deck personali' : 'Create personal decks';
  String get paywallCreateDecksCopy => isItalian
      ? 'Costruisci percorsi di studio personalizzati per lavoro, scuola o esami.'
      : 'Build custom learning flows for your work, class, or exam prep.';
  String get paywallExamModeTitle =>
      isItalian ? 'Modalita esame' : 'Run exam mode';
  String get paywallExamModeCopy => isItalian
      ? 'Le sessioni a tempo restano Pro insieme alle future librerie certificazione.'
      : 'Timed practice is reserved for Pro and future certification libraries.';
  String get paywallWiringTitle => isItalian
      ? 'Abbonamento non ancora collegato'
      : 'Subscription wiring still pending';
  String paywallWiringBody(String feature) => isItalian
      ? 'RevenueCat non e ancora integrato, quindi $feature non puo ancora essere acquistata da questa build.'
      : 'RevenueCat has not been integrated yet, so $feature cannot be purchased from this build.';
  String get paywallPurchaseComing =>
      isItalian ? 'Acquisto disponibile a breve' : 'Purchase flow coming next';

  String get libraryTitle => isItalian ? 'Libreria' : 'Library';
  String get libraryRefresh =>
      isItalian ? 'Aggiorna libreria' : 'Refresh library';
  String get libraryAddStudyMaterial =>
      isItalian ? 'Aggiungi materiale di studio' : 'Add Study Material';
  String get libraryUnlockPersonalDecks =>
      isItalian ? 'Sblocca deck personali' : 'Unlock Personal Decks';
  String get libraryImportJson =>
      isItalian ? 'Importa deck JSON' : 'Import JSON Deck';
  String get libraryProImport => isItalian
      ? 'Pro: importa appunti, deck, esami'
      : 'Pro: import notes, decks, exams';
  String get libraryPublicBuildNote => isItalian
      ? 'Questa build pubblica include topic ampi per il Feed. Upload personali, pack esame e creazione deck custom sono Pro.'
      : 'This public build ships broad free topics for the Feed. Personal uploads, exam packs, and custom deck creation are Pro-only.';
  String get addStudyMaterialTitle =>
      isItalian ? 'Aggiungi materiale di studio' : 'Add Study Material';
  String get addStudyMaterialSubtitle => isItalian
      ? 'Deck personali, upload di appunti e import JSON fanno parte di Pro.'
      : 'Personal decks, note uploads, and JSON imports are part of Pro.';
  String get bookmarksEmptyTitle =>
      isItalian ? 'Nessuna lezione salvata' : 'No saved lessons yet';
  String get bookmarksEmptyMessage => isItalian
      ? 'Salva le card utili dal Feed per costruire qui una lista veloce di ripasso.'
      : 'Bookmark useful cards from the feed to build a quick review list here.';
  String get bookmarksErrorTitle => isItalian
      ? 'Lezioni salvate non disponibili'
      : 'Saved lessons unavailable';
  String feedLoadError(String error) => isItalian
      ? 'Qualcosa e andato storto\n$error'
      : 'Something went wrong\n$error';
  String get noActiveDeckTitle =>
      isItalian ? 'Nessun deck attivo' : 'No active deck';
  String noStudyCardsTitle(String deckTitle) => isItalian
      ? 'Nessuna card disponibile in $deckTitle'
      : 'No study cards available in $deckTitle';
  String get noStudyCardsMessage => isItalian
      ? 'Scegli un altro topic dalla Libreria oppure sblocca Pro per importare un deck personale.'
      : 'Select another topic from Library, or unlock Pro to import your own deck.';
  String get studyTitle => isItalian ? 'Studio' : 'Study';
  String cardsInDeck(int count) =>
      isItalian ? '$count carte nel deck' : '$count cards in deck';
  String activeDeckCards(String title, int count) =>
      isItalian ? '$title · $count carte' : '$title · $count cards';
  String get studyEmptyTitle =>
      isItalian ? 'Nessuna carta in Studio' : 'No cards in Study yet';
  String get studyEmptyMessage => isItalian
      ? 'Vai nel Feed e tocca "Aggiungi a Studio", oppure importa un pack dal pulsante Libreria qui sotto.'
      : "Go to Feed and tap 'Add to Study', or import a pack with the Library button below.";
  String get studySeedStarter =>
      isItalian ? 'Aggiungi 5 carte iniziali' : 'Add 5 starter cards';
  String get studyStartSession =>
      isItalian ? 'Avvia sessione studio' : 'Start Study Session';
  String get studyStartSpeed =>
      isItalian ? 'Avvia Speed Drill' : 'Start Speed Drill';
  String get studyImportCardsFirst =>
      isItalian ? 'Importa prima delle carte' : 'Import cards first';
  String get weakAreasTitle => isItalian ? 'Aree deboli' : 'Weak Areas';
  String get weakAreasSubtitle => isItalian
      ? 'Basato sulle risposte locali del deck attivo.'
      : 'Based on local answers in the active deck.';
  String get weakAreasHint => isItalian
      ? 'Rispondi a piu carte di studio o domande esame per sbloccare i suggerimenti sulle aree deboli.'
      : 'Answer more study cards or exam questions to unlock weak-area guidance.';
  String get weakAreasTrain =>
      isItalian ? 'Allena aree deboli' : 'Train Weak Areas';
  String answersWrong(int answered, int wrong) => isItalian
      ? '$answered risposte • $wrong errori'
      : '$answered answers • $wrong wrong';
  String get snapshotReviewed => isItalian ? 'Ripassate' : 'Reviewed';
  String get snapshotDueNow => isItalian ? 'Da fare ora' : 'Due Now';
  String get snapshotWeak => isItalian ? 'Deboli' : 'Weak';
  String studyStartWithQueue(String queueLabel, int queueCount) => isItalian
      ? 'Inizia studio • $queueLabel $queueCount'
      : 'Start Study • $queueLabel $queueCount';
  String get studyStart => isItalian ? 'Inizia studio' : 'Start Study';
  String focusedRunMinutes(int minutes) => isItalian
      ? '$minutes min di sessione mirata'
      : '$minutes min focused run';
  String get studyRandomFallback => isItalian
      ? 'Se serve, ripiega su una sessione casuale utile'
      : 'Falls back to a useful random run when needed';
  String get focusedPractice =>
      isItalian ? 'Pratica mirata' : 'Focused Practice';
  String get speedDrill => isItalian ? 'Speed Drill' : 'Speed Drill';
  String get sessionSettings =>
      isItalian ? 'Impostazioni sessione' : 'Session Settings';
  String sessionSettingsSummary(
    String queueLabel,
    int questionCount,
    int timerSeconds,
  ) => isItalian
      ? '$queueLabel • $questionCount domande • timer ${timerSeconds}s'
      : '$queueLabel • $questionCount questions • ${timerSeconds}s timer';
  String get examModeProTitle =>
      isItalian ? 'La modalita esame e Pro' : 'Exam mode is Pro';
  String get examModeProSubtitle => isItalian
      ? 'Il lancio pubblico di Thumbler resta gratuito attorno al Feed e ai topic generali. Le sessioni esame a tempo si sbloccano con Pro.'
      : 'The public launch keeps Thumbler free around the Feed and broad topic decks. Timed exam runs unlock with Pro.';
  String get examTitle => isItalian ? 'Esame' : 'Exam';
  String examQuestionsAvailable(int count) => isItalian
      ? '$count domande esame disponibili'
      : '$count exam questions available';
  String examQuestionsReady(String deckTitle, int count) => isItalian
      ? '$deckTitle · $count domande pronte per una sessione a tempo'
      : '$deckTitle · $count questions ready for timed practice';
  String get deckActive => isItalian ? 'Deck attivo' : 'Deck active';
  String get questionsLabel => isItalian ? 'Domande' : 'Questions';
  String timedRunLabel(int count) => isItalian
      ? 'Sessione a tempo: $count domande · $count minuti'
      : 'Timed run: $count questions · $count minutes';
  String get noExamQuestionsAvailable => isItalian
      ? 'Nessuna domanda esame disponibile'
      : 'No exam questions available';
  String startExamLabel(int count) => isItalian
      ? 'Avvia esame ($count domande)'
      : 'Start Exam ($count questions)';
  String get noExamHistoryYet => isItalian
      ? 'Nessuna cronologia esame per questo deck. Il prossimo risultato comparira qui.'
      : 'No completed exam history for this deck yet. Your next result will appear here.';
  String get examHistoryTitle => isItalian ? 'Storico esami' : 'Exam History';
  String get viewAll => isItalian ? 'Vedi tutto' : 'View all';
  String get shortExamPoolNote => isItalian
      ? 'Questo deck ha un pool esame piu corto, quindi le sessioni usano il numero di domande disponibile.'
      : 'This deck has a shorter exam pool, so runs use the available question count.';
  String get examInProgress =>
      isItalian ? 'Esame in corso' : 'Exam in Progress';
  String examResumeStatus(int answered, int total, String timeStr) => isItalian
      ? '$answered/$total risposte  ·  $timeStr rimanenti'
      : '$answered/$total answered  ·  $timeStr remaining';
  String get resume => isItalian ? 'Riprendi' : 'Resume';
  String get noExamQuestionsImported => isItalian
      ? 'Nessuna domanda esame importata'
      : 'No exam questions imported yet';
  String get noExamQuestionsImportedHelp => isItalian
      ? 'Vai su Studio → Libreria e importa un pack come "CompTIA Security+ SY0-701".'
      : 'Go to the Study tab → Library and import\na pack like "CompTIA Security+ SY0-701".';
  String onlyAvailableCount(int available) =>
      isItalian ? 'solo $available' : 'only $available';
  String historyCardTop(int correct, int total, String date) => isItalian
      ? '$correct/$total corrette  ·  $date'
      : '$correct/$total correct  ·  $date';
  String historyCardBottom(int wrong, String weakest) =>
      isItalian ? '$wrong errori  ·  $weakest' : '$wrong wrong  ·  $weakest';
  String get noWeakestDomain =>
      isItalian ? 'Nessun punto debole' : 'No weakest domain';
  String get passLabel => 'PASS';
  String get failLabel => 'FAIL';
  String get progressTitle => isItalian ? 'Progressi' : 'Progress';
  String get progressSubtitle => isItalian
      ? 'Una lettura leggera di cio che migliora, di cio che e debole e di quanto sei stato attivo di recente.'
      : 'A lightweight read of what is improving, what is weak, and how active you have been lately.';
  String get activeDeckScope =>
      isItalian ? 'Ambito del deck attivo' : 'Active Deck Scope';
  String get legacyUnscopedData => isItalian
      ? 'Dati locali legacy / non associati'
      : 'Legacy / unscoped local data';
  String get legacyUnscopedDataHelp => isItalian
      ? 'Queste metriche riflettono solo elementi e risultati locali senza un deck attivo associato.'
      : 'These metrics only reflect local items and results without an active deck binding.';
  String get overview => isItalian ? 'Panoramica' : 'Overview';
  String get answeredLabel => isItalian ? 'Risposte' : 'Answered';
  String get accuracyLabel => isItalian ? 'Accuratezza' : 'Accuracy';
  String get cardsReviewedLabel =>
      isItalian ? 'Carte ripassate' : 'Cards Reviewed';
  String get completedExamsLabel =>
      isItalian ? 'Esami completati' : 'Completed Exams';
  String examOverviewScores(int lastScore, int avgScore) => isItalian
      ? 'Ultimo esame: $lastScore%  •  Media esami: $avgScore%'
      : 'Last exam: $lastScore%  •  Average exam: $avgScore%';
  String get recentActivityTitle =>
      isItalian ? 'Attivita recente' : 'Recent Activity';
  String get recentActivitySubtitle => isItalian
      ? 'Carte ripassate ed esami completati negli ultimi 7 giorni'
      : 'Cards reviewed and exams completed in the last 7 days';
  String get noRecentActivity => isItalian
      ? 'Nessuna attivita locale recente di studio o esame.'
      : 'No recent local study or exam activity found.';
  String get byDomain => isItalian ? 'Per area' : 'By Domain';
  String get weakestDomains =>
      isItalian ? 'Aree piu deboli' : 'Weakest Domains';
  String get domainAnalyticsHint => isItalian
      ? 'Rispondi a carte di studio o domande esame per sbloccare le analytics per area.'
      : 'Answer study cards or exam questions to unlock domain analytics.';
  String get weakestDomainsHint => isItalian
      ? 'Le aree piu deboli compariranno dopo un numero sufficiente di risposte.'
      : 'Weakest domains will appear after you answer enough questions.';
  String domainStats(int answered, int correct, int wrong) => isItalian
      ? '$answered risposte  •  $correct corrette  •  $wrong errori'
      : '$answered answered  •  $correct correct  •  $wrong wrong';
  String weakDomainSummary(String domain, int accuracy, int answered) =>
      isItalian
      ? '$domain  •  $accuracy% di accuratezza su $answered risposte'
      : '$domain  •  $accuracy% accuracy across $answered answers';
  String get noAnalyticsYet =>
      isItalian ? 'Nessuna analisi ancora' : 'No analytics yet';
  String get noAnalyticsYetMessage => isItalian
      ? 'Ripassa carte di studio o completa un esame per sbloccare le analisi locali dei progressi.'
      : 'Study cards or complete an exam to unlock local progress analytics.';
  String get todaysQuest => isItalian ? 'Missione di oggi' : "Today's Quest";
  String get letsGo => isItalian ? 'Andiamo' : "Let's Go!";
  String get notNow => isItalian ? 'Non ora' : 'Not now';
  String get questComplete =>
      isItalian ? 'Missione completata!' : 'Quest Complete!';
  String get claimReward => isItalian ? 'Riscatta ricompensa' : 'Claim Reward';
  String questDescription(bool earnXp, int target) => isItalian
      ? (earnXp
            ? 'Guadagna $target XP oggi'
            : 'Rispondi correttamente a $target quiz')
      : (earnXp ? 'Earn $target XP today' : 'Answer $target quizzes correctly');
  String rewardTitle(String rewardKey) => switch (rewardKey) {
    'rareCard' => isItalian ? 'Carta rara sbloccata' : 'Rare Card Unlocked',
    'xpBoost' => isItalian ? 'Boost XP attivo' : 'XP Boost Active',
    'newCategory' =>
      isItalian ? 'Nuova categoria sbloccata' : 'New Category Unlocked',
    _ => rewardKey,
  };
  String rewardDescription(String rewardKey) => switch (rewardKey) {
    'rareCard' =>
      isItalian
          ? 'Una lezione rara speciale comparira nel tuo feed.'
          : 'A special rare lesson will appear in your feed.',
    'xpBoost' =>
      isItalian
          ? '+20% XP per il resto di oggi.'
          : '+20% XP for the rest of today.',
    'newCategory' =>
      isItalian
          ? 'Una nuova categoria di argomenti e ora disponibile.'
          : 'A new topic category is now available.',
    _ => rewardKey,
  };
  String get streakOneMore => isItalian
      ? 'Ancora 1 per mantenere la streak'
      : '1 more to keep your streak';
  String questRemaining(int count) => isItalian
      ? 'Ancora $count per chiudere l obiettivo di oggi'
      : '$count more to finish today\'s goal';
  String weakRemaining(int count) => isItalian
      ? 'Ancora $count per chiudere le domande deboli'
      : '$count more to clear weak questions';
  String quickRunRemaining(int count) => isItalian
      ? 'Ancora $count per finire questa mini sessione'
      : '$count more to finish this quick run';
  String get emptyDeck => isItalian ? 'Deck vuoto' : 'Empty deck';
  String feedProgressPercent(int percent) =>
      isItalian ? '$percent% completato' : '$percent% through';
  String dayStreak(int days) =>
      isItalian ? '$days giorni di streak' : '$days day streak';
  String streakToday(int streak, int today) => isItalian
      ? '$streak streak • $today/3 oggi'
      : '$streak streak • $today/3 today';
  String get done => isItalian ? 'Fatto!' : 'Done!';
  String questProgressLabel(int progress, int target) =>
      isItalian ? 'Missione $progress/$target' : 'Quest $progress/$target';
  String get swipeOrNext =>
      isItalian ? 'Scorri o vai avanti' : 'Swipe or tap next';
  String get feedCardLabel => isItalian ? 'Card feed' : 'Feed card';
  String get questionCard => isItalian ? 'Card domanda' : 'Question card';
  String get microLesson => isItalian ? 'Micro lezione' : 'Micro lesson';
  String cardInstruction({
    required bool repeatsQuestion,
    required bool revealed,
  }) {
    if (isItalian) {
      if (repeatsQuestion) {
        return revealed
            ? 'Leggi la spiegazione, rispondi una volta e poi continua a scorrere.'
            : 'Leggi la domanda, scopri la spiegazione e poi rispondi una volta.';
      }
      return revealed
          ? 'Rivedi la spiegazione, rispondi al controllo rapido e poi continua a scorrere.'
          : 'Scopri la spiegazione, rispondi al controllo rapido e poi passa alla card successiva.';
    }
    if (repeatsQuestion) {
      return revealed
          ? 'Read the explanation, answer once, then keep scrolling.'
          : 'Read the question, reveal the explanation, then answer once.';
    }
    return revealed
        ? 'Review the explanation, answer one quick check, then keep scrolling.'
        : 'Reveal the explanation, answer one quick check, then move to the next card.';
  }

  String get revealAnswerQuiz =>
      isItalian ? 'Mostra risposta + quiz' : 'Reveal Answer + Quiz';
  String get whyThisMatters => isItalian ? 'Perche conta' : 'Why this matters';
  String get savedLabel => isItalian ? 'Salvata' : 'Saved';
  String get saveLabel => isItalian ? 'Salva' : 'Save';
  String get inStudyLabel => isItalian ? 'In studio' : 'In Study';
  String get studyLabel => isItalian ? 'Studio' : 'Study';
  String get shareLabel => isItalian ? 'Condividi' : 'Share';
  String get nextLabel => isItalian ? 'Avanti' : 'Next';
  String get quickCheck => isItalian ? 'Controllo rapido' : 'Quick Check';
  String get chooseBestAnswer => isItalian
      ? 'Scegli la risposta migliore qui sotto.'
      : 'Choose the best answer below.';
  String get correctAnswerTitle =>
      isItalian ? 'Risposta corretta' : 'Correct answer';
  String get reviewBeforeScroll =>
      isItalian ? 'Rivedi prima di scorrere' : 'Review before you scroll';
  String get correctAnswerCopy => isItalian
      ? 'Ottima risposta. Hai guadagnato XP e puoi continuare la streak.'
      : 'Nice hit. You earned XP and can keep the streak moving.';
  String get reviewBeforeScrollCopy => isItalian
      ? 'La spiegazione sopra contiene l idea chiave. Leggila una volta e poi continua.'
      : 'The explanation above contains the key idea. Read it once, then continue.';

  String get profileTitle => isItalian ? 'Profilo' : 'Profile';
  String get profileSubtitle => isItalian
      ? 'Tieni traccia del ritmo, gestisci i dati locali e mantieni pulita la tua configurazione di studio.'
      : 'Track momentum, manage local data, and keep your study setup clean.';
  String get settingsSection => isItalian ? 'Impostazioni' : 'Settings';
  String get languageLabel => isItalian ? 'Lingua' : 'Language';
  String get languageHelp => isItalian
      ? 'Italiano e la lingua predefinita della versione pubblica.'
      : 'Italian is the default language for the public build.';
  String get italianLabel => isItalian ? 'Italiano' : 'Italian';
  String get englishLabel => isItalian ? 'Inglese' : 'English';
  String get appearanceLabel => isItalian ? 'Aspetto' : 'Appearance';
  String get appearanceSystem => isItalian
      ? 'L interfaccia segue il tema di sistema: chiaro o scuro.'
      : 'The interface follows the system theme: light or dark.';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
