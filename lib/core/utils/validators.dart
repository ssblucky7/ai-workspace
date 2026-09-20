import '../constants/app_constants.dart';

/// Reusable form-field validators.
///
/// Every validator returns `null` when the value is valid, or a user-friendly
/// error message otherwise — matching Flutter's `FormFieldValidator` shape so
/// the same logic is shared by every screen instead of being duplicated.
abstract final class Validators {
  static String? validateFullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Please enter your full name.';
    if (name.length < AppConstants.fullNameMinLength) {
      return 'Name must be at least ${AppConstants.fullNameMinLength} characters.';
    }
    if (name.length > AppConstants.fullNameMaxLength) {
      return 'Name must be ${AppConstants.fullNameMaxLength} characters or fewer.';
    }
    if (!RegExp('[A-Za-z]').hasMatch(name)) {
      return 'Name must contain letters.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email address.';
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    if (!pattern.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please enter a password.';
    if (password.length < AppConstants.passwordMinLength) {
      return 'Password must be at least ${AppConstants.passwordMinLength} characters.';
    }
    if (password.length > AppConstants.passwordMaxLength) {
      return 'Password must be ${AppConstants.passwordMaxLength} characters or fewer.';
    }
    return null;
  }

  static String? validatePasswordConfirmation(String? value, String password) {
    final confirmation = value ?? '';
    if (confirmation.isEmpty) return 'Please confirm your password.';
    if (confirmation != password) return 'Passwords do not match.';
    return null;
  }

  static String? validateConversationTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Title cannot be empty.';
    if (title.length > AppConstants.titleMaxLength) {
      return 'Keep the title under ${AppConstants.titleMaxLength} characters.';
    }
    return null;
  }

  static String? validateChatInput(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Type a message first.';
    if (text.length > AppConstants.messageMaxLength) {
      return 'Message is too long (max ${AppConstants.messageMaxLength} characters).';
    }
    return null;
  }

  static String? validateProviderName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Provider name is required.';
    if (name.length > AppConstants.providerNameMaxLength) {
      return 'Provider name must be ${AppConstants.providerNameMaxLength} characters or fewer.';
    }
    return null;
  }

  static String? validateBaseUrl(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return 'Base URL is required.';
    if (url.length > AppConstants.baseUrlMaxLength) {
      return 'Base URL is too long.';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) {
      return 'Enter a valid HTTP or HTTPS URL.';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Only HTTP or HTTPS URLs are supported.';
    }
    // Plain HTTP is only tolerated for local development endpoints.
    if (uri.scheme == 'http' && !_isLocalHost(uri.host)) {
      return 'HTTP is only allowed for localhost development. Use HTTPS for remote endpoints.';
    }
    return null;
  }

  static bool _isLocalHost(String host) =>
      host == 'localhost' ||
      host == '::1' ||
      host == '127.0.0.1' ||
      host.startsWith('127.');

  static String? validateApiKey(String? value, {bool allowEmpty = false}) {
    final key = value?.trim() ?? '';
    if (key.isEmpty) {
      return allowEmpty ? null : 'API key is required.';
    }
    return null;
  }

  static String? validateModelId(String? value) {
    final model = value?.trim() ?? '';
    if (model.isEmpty) return 'Select or enter a model ID.';
    if (model.length > AppConstants.modelIdMaxLength) {
      return 'Model ID must be ${AppConstants.modelIdMaxLength} characters or fewer.';
    }
    return null;
  }

  static String? validateTemperature(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Temperature is required.';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Temperature must be a number.';
    if (parsed < AppConstants.minTemperature ||
        parsed > AppConstants.maxTemperature) {
      return 'Temperature must be between '
          '${AppConstants.minTemperature} and ${AppConstants.maxTemperature}.';
    }
    return null;
  }

  static String? validateMaxTokens(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Maximum tokens is required.';
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Maximum tokens must be a whole number.';
    if (parsed < AppConstants.minMaxTokens ||
        parsed > AppConstants.maxMaxTokens) {
      return 'Maximum tokens must be between '
          '${AppConstants.minMaxTokens} and ${AppConstants.maxMaxTokens}.';
    }
    return null;
  }

  static String? validateOrganizationId(String? value) {
    final orgId = value?.trim() ?? '';
    // Organization ID is optional: empty is valid.
    if (orgId.isEmpty) return null;
    if (orgId.contains(RegExp(r'\s'))) {
      return 'Organization ID cannot contain spaces.';
    }
    if (orgId.length > AppConstants.organizationIdMaxLength) {
      return 'Organization ID must be ${AppConstants.organizationIdMaxLength} characters or fewer.';
    }
    return null;
  }
}
