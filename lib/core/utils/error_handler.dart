import 'package:firebase_auth/firebase_auth.dart';

class AppErrorHandler {
  AppErrorHandler._();

  static String userFriendlyMessage(Object error) {
    final message = error.toString();

    if (error is FirebaseAuthException) {
      return _firebaseAuthMessage(error.code);
    }

    if (message.contains('firebase_auth')) {
      final codeMatch = RegExp(r'\[firebase_auth/([\w-]+)\]').firstMatch(message);
      if (codeMatch != null) {
        return _firebaseAuthMessage(codeMatch.group(1)!);
      }
    }

    if (message.contains('network-request-failed') ||
        message.contains('SocketException') ||
        message.contains('ClientException')) {
      return 'Verifică conexiunea la internet și încearcă din nou.';
    }

    if (message.contains('permission-denied')) {
      return 'Nu ai permisiunea de a efectua această acțiune.';
    }

    if (message.contains('not-found')) {
      return 'Resursa nu a fost găsită.';
    }

    if (message.contains('unavailable')) {
      return 'Serviciul este temporar indisponibil. Încearcă din nou.';
    }

    final cleaned = message
        .replaceFirst('Exception: ', '')
        .replaceFirst('FormatException: ', '')
        .replaceFirst(RegExp(r'\[[\w/\-]+\]\s*'), '');

    if (cleaned.length > 200) {
      return 'A apărut o eroare neașteptată. Încearcă din nou.';
    }

    return cleaned;
  }

  static String _firebaseAuthMessage(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email sau parolă incorectă.';
      case 'user-not-found':
        return 'Nu există un cont cu acest email.';
      case 'email-already-in-use':
        return 'Există deja un cont cu acest email.';
      case 'weak-password':
        return 'Parola este prea slabă. Folosește cel puțin 6 caractere.';
      case 'invalid-email':
        return 'Adresa de email nu este validă.';
      case 'user-disabled':
        return 'Acest cont a fost dezactivat.';
      case 'too-many-requests':
        return 'Prea multe încercări. Așteaptă câteva minute.';
      case 'requires-recent-login':
        return 'Te rugăm să te deconectezi și să te autentifici din nou.';
      case 'network-request-failed':
        return 'Verifică conexiunea la internet și încearcă din nou.';
      case 'operation-not-allowed':
        return 'Această operațiune nu este permisă.';
      case 'expired-action-code':
        return 'Link-ul a expirat. Solicită unul nou.';
      case 'invalid-action-code':
        return 'Link-ul este invalid sau a fost deja folosit.';
      default:
        return 'Eroare de autentificare. Încearcă din nou.';
    }
  }
}
