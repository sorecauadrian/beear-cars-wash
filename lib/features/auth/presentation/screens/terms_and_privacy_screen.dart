import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class TermsAndPrivacyScreen extends StatelessWidget {
  final bool showTerms;

  const TermsAndPrivacyScreen({super.key, this.showTerms = true});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: showTerms ? 0 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Legal'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Termeni și condiții'),
              Tab(text: 'Politica de confidențialitate'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TermsContent(),
            _PrivacyContent(),
          ],
        ),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Termeni și Condiții de Utilizare', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text('Ultima actualizare: Martie 2026', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),

          _section(theme, '1. Acceptarea termenilor',
            'Prin crearea unui cont și utilizarea aplicației Beear Cars Wash („Aplicația"), '
            'acceptați acești Termeni și Condiții în totalitate. Dacă nu sunteți de acord cu '
            'oricare dintre prevederile de mai jos, vă rugăm să nu utilizați Aplicația.'),

          _section(theme, '2. Descrierea serviciului',
            'Beear Cars Wash oferă o platformă digitală de programare a serviciilor de '
            'spălare auto la fața locului. Aplicația facilitează comunicarea între clienți '
            '(persoane fizice sau juridice) și echipa Beear Cars Wash pentru programarea, '
            'gestionarea și urmărirea rezervărilor de spălare auto.'),

          _section(theme, '3. Contul de utilizator',
            'Pentru a utiliza Aplicația, trebuie să creați un cont furnizând informații '
            'corecte și complete. Sunteți responsabil pentru păstrarea confidențialității '
            'datelor de autentificare ale contului dumneavoastră. Ne rezervăm dreptul de a '
            'suspenda sau șterge conturile care încalcă acești termeni.'),

          _section(theme, '4. Rezervări și anulări',
            'Rezervările create prin Aplicație sunt supuse disponibilității echipei. '
            'Beear Cars Wash poate accepta, respinge sau reprograma o rezervare în funcție '
            'de calendarul operațional. Anularea unei rezervări trebuie comunicată cu cel '
            'puțin 2 ore înainte de intervalul programat.'),

          _section(theme, '5. Prețuri și plăți',
            'Prețurile serviciilor sunt afișate în Aplicație și pot fi modificate fără '
            'notificare prealabilă. Plata se efectuează conform înțelegerii dintre client '
            'și Beear Cars Wash, fie prin facturare, fie la momentul prestării serviciului.'),

          _section(theme, '6. Obligațiile utilizatorului',
            'Utilizatorul se obligă să:\n'
            '• Furnizeze informații corecte și actualizate\n'
            '• Asigure accesul la vehicul la locația și ora programată\n'
            '• Nu utilizeze Aplicația în scopuri ilegale sau neautorizate\n'
            '• Respecte programările și să comunice orice modificare'),

          _section(theme, '7. Limitarea răspunderii',
            'Beear Cars Wash nu este responsabil pentru daune indirecte, incidentale sau '
            'consecvente rezultate din utilizarea sau imposibilitatea utilizării Aplicației. '
            'Serviciul este oferit „ca atare", fără garanții de niciun fel.'),

          _section(theme, '8. Modificarea termenilor',
            'Ne rezervăm dreptul de a modifica acești termeni în orice moment. '
            'Modificările vor fi comunicate prin Aplicație. Continuarea utilizării '
            'Aplicației după publicarea modificărilor constituie acceptarea noilor termeni.'),

          _section(theme, '9. Contact',
            'Pentru orice întrebări legate de acești termeni, ne puteți contacta '
            'prin intermediul Aplicației sau la adresa de email disponibilă pe '
            'site-ul nostru.'),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Politica de Confidențialitate', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text('Ultima actualizare: Martie 2026', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),

          _section(theme, '1. Date colectate',
            'Colectăm următoarele categorii de date personale:\n\n'
            'Persoane fizice:\n'
            '• Nume complet\n'
            '• Adresă de email\n'
            '• Număr de telefon\n'
            '• Oraș\n\n'
            'Persoane juridice:\n'
            '• Denumire firmă, CUI, Nr. Registrul Comerțului\n'
            '• Adresă sediu social, oraș, județ\n'
            '• Date bancare (bancă, IBAN) — opțional\n'
            '• Email, telefon de contact\n\n'
            'Date operaționale:\n'
            '• Numere de înmatriculare vehicule\n'
            '• Adrese de locație pentru servicii\n'
            '• Istoricul rezervărilor și statusul acestora'),

          _section(theme, '2. Scopul colectării datelor',
            'Datele sunt colectate și prelucrate exclusiv pentru:\n'
            '• Crearea și gestionarea contului dumneavoastră\n'
            '• Programarea și prestarea serviciilor de spălare auto\n'
            '• Comunicarea privind rezervările (notificări, statusuri)\n'
            '• Emiterea facturilor (pentru persoane juridice)\n'
            '• Îmbunătățirea serviciilor noastre'),

          _section(theme, '3. Temeiul legal',
            'Prelucrarea datelor se bazează pe:\n'
            '• Executarea contractului de prestări servicii\n'
            '• Consimțământul dumneavoastră, acordat prin acceptarea acestei politici\n'
            '• Obligații legale (emiterea facturilor, evidențe contabile)'),

          _section(theme, '4. Stocarea datelor',
            'Datele sunt stocate în siguranță folosind serviciile Google Firebase, '
            'cu servere localizate în Uniunea Europeană. Implementăm măsuri tehnice '
            'și organizatorice adecvate pentru protejarea datelor dumneavoastră împotriva '
            'accesului neautorizat, pierderii sau distrugerii.'),

          _section(theme, '5. Partajarea datelor',
            'Nu vindem, închiriem sau partajăm datele dumneavoastră personale cu '
            'terți, cu excepția:\n'
            '• Furnizorilor de servicii tehnice (Firebase/Google) pentru funcționarea Aplicației\n'
            '• Autorităților competente, când legea o impune'),

          _section(theme, '6. Drepturile dumneavoastră (GDPR)',
            'Conform Regulamentului General privind Protecția Datelor (GDPR), aveți dreptul:\n'
            '• De acces — să solicitați o copie a datelor dumneavoastră\n'
            '• De rectificare — să corectați datele inexacte\n'
            '• De ștergere — să solicitați ștergerea datelor („dreptul de a fi uitat")\n'
            '• De restricționare a prelucrării\n'
            '• De portabilitate a datelor\n'
            '• De opoziție la prelucrare\n\n'
            'Pentru exercitarea acestor drepturi, contactați-ne prin intermediul Aplicației.'),

          _section(theme, '7. Păstrarea datelor',
            'Datele personale sunt păstrate atât timp cât contul dumneavoastră este activ. '
            'La cererea de ștergere a contului, datele vor fi eliminate în termen de 30 de zile, '
            'cu excepția datelor necesare pentru obligații legale (facturi — 10 ani conform legislației fiscale).'),

          _section(theme, '8. Cookie-uri și date tehnice',
            'Aplicația nu utilizează cookie-uri. Colectăm automat date tehnice minime '
            '(token-uri de notificare) necesare funcționării serviciului de notificări push.'),

          _section(theme, '9. Modificări ale politicii',
            'Această politică poate fi actualizată periodic. Vă vom notifica prin Aplicație '
            'despre orice modificare semnificativă.'),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

Widget _section(ThemeData theme, String title, String body) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant, height: 1.6)),
      ],
    ),
  );
}
