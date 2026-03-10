/// Input validation utilities (Romanian messages)
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Emailul este obligatoriu';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Introdu o adresă de email validă';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = 'Câmpul'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName este obligatoriu';
    }
    return null;
  }

  static String? minLength(String? value, int min, {String fieldName = 'Câmpul'}) {
    if (value == null || value.length < min) {
      return '$fieldName trebuie să aibă cel puțin $min caractere';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Parola este obligatorie';
    }
    if (value.length < 6) {
      return 'Parola trebuie să aibă cel puțin 6 caractere';
    }
    return null;
  }

  static String? plateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Numărul de înmatriculare este obligatoriu';
    }
    if (value.length < 2) {
      return 'Numărul de înmatriculare este prea scurt';
    }
    return null;
  }
}

