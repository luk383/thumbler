import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/ui/app_surfaces.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.privacyPolicyTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          AppPageIntro(
            title: l10n.privacyPolicyTitle,
            subtitle: l10n.settingsPrivacyHint,
          ),
          const SizedBox(height: 20),
          const _Section(
            title: 'Data Storage',
            titleIt: 'Archiviazione dei dati',
            body:
                'All data (study progress, XP, streaks, bookmarks, exam history) '
                'is stored exclusively on your device using local storage (Hive). '
                'Nothing is transmitted to external servers.',
            bodyIt:
                'Tutti i dati (progressi di studio, XP, streak, segnalibri, cronologia esami) '
                'sono archiviati esclusivamente sul tuo dispositivo tramite storage locale (Hive). '
                'Nessun dato viene trasmesso a server esterni.',
          ),
          const SizedBox(height: 14),
          const _Section(
            title: 'No Personal Data Collected',
            titleIt: 'Nessun dato personale raccolto',
            body:
                'Wolf Lab does not collect, process, or share any personal '
                'information. No account registration is required. '
                'No email addresses, names, or device identifiers are collected.',
            bodyIt:
                'Wolf Lab non raccoglie, elabora o condivide alcuna informazione personale. '
                'Non e richiesta alcuna registrazione. '
                'Non vengono raccolti indirizzi email, nomi o identificatori del dispositivo.',
          ),
          const SizedBox(height: 14),
          const _Section(
            title: 'Analytics & Tracking',
            titleIt: 'Analytics e tracciamento',
            body:
                'Wolf Lab does not use any analytics, advertising, or tracking SDKs. '
                'No third-party trackers are present in this application.',
            bodyIt:
                'Wolf Lab non utilizza analytics, pubblicita o SDK di tracciamento. '
                'Non sono presenti tracker di terze parti in questa applicazione.',
          ),
          const SizedBox(height: 14),
          const _Section(
            title: 'In-App Purchases',
            titleIt: 'Acquisti in-app',
            body:
                'Purchase transactions are handled by Apple App Store / Google Play '
                'and RevenueCat. These services have their own privacy policies. '
                'Wolf Lab only receives confirmation of your subscription status — '
                'no payment details are accessible to the app.',
            bodyIt:
                'Le transazioni di acquisto sono gestite da Apple App Store / Google Play '
                'e RevenueCat. Questi servizi hanno le proprie informative sulla privacy. '
                'Wolf Lab riceve solo la conferma dello stato del tuo abbonamento — '
                'nessun dato di pagamento e accessibile all\'app.',
          ),
          const SizedBox(height: 14),
          const _Section(
            title: 'Data Deletion',
            titleIt: 'Cancellazione dei dati',
            body:
                'You can delete all locally stored data at any time from '
                'Profile → Data Management → Reset All App Data. '
                'Uninstalling the app also removes all local data.',
            bodyIt:
                'Puoi eliminare tutti i dati archiviati localmente in qualsiasi momento da '
                'Profilo → Gestione dati → Reset dati dell\'app. '
                'Disinstallare l\'app rimuove anch\'essa tutti i dati locali.',
          ),
          const SizedBox(height: 14),
          const _Section(
            title: 'Contact',
            titleIt: 'Contatti',
            body:
                'For any privacy-related question, contact us at: privacy@wolf_lab.app',
            bodyIt:
                'Per qualsiasi domanda sulla privacy, contattaci a: privacy@wolf_lab.app',
          ),
          const SizedBox(height: 24),
          Text(
            'Last updated: March 2026',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.titleIt,
    required this.body,
    required this.bodyIt,
  });

  final String title;
  final String titleIt;
  final String body;
  final String bodyIt;

  @override
  Widget build(BuildContext context) {
    final isItalian = context.l10n.isItalian;
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isItalian ? titleIt : title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isItalian ? bodyIt : body,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
