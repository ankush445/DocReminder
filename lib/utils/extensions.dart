import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// DateTime extensions for formatting and calculations
extension DateTimeExtensions on DateTime {
  /// Format date as "MMM dd, yyyy" (e.g., "Jan 15, 2024")
  String toFormattedDate() {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  /// Format date as "MMM dd" (e.g., "Jan 15")
  String toShortDate() {
    return DateFormat('MMM dd').format(this);
  }

  /// Format time as "hh:mm a" (e.g., "09:30 AM")
  String toFormattedTime() {
    return DateFormat('hh:mm a').format(this);
  }

  /// Format date and time as "MMM dd, yyyy hh:mm a"
  String toFormattedDateTime() {
    return DateFormat('MMM dd, yyyy hh:mm a').format(this);
  }

  /// Get days remaining until this date
  int get daysRemaining {
    final now = DateTime.now();
    final diff = difference(now);
    return diff.inDays;
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Check if date is in the past
  bool get isPast {
    return isBefore(DateTime.now());
  }

  /// Check if date is in the future
  bool get isFuture {
    return isAfter(DateTime.now());
  }

  /// Get relative time string (e.g., "2 days ago", "in 3 days")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.isNegative) {
      // Future date
      final futureDifference = this.difference(now);
      if (futureDifference.inDays == 0) {
        return 'Today';
      } else if (futureDifference.inDays == 1) {
        return 'Tomorrow';
      } else if (futureDifference.inDays < 7) {
        return 'in ${futureDifference.inDays} days';
      } else {
        return toFormattedDate();
      }
    } else {
      // Past date
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return toFormattedDate();
      }
    }
  }
}

/// String extensions for validation and formatting
extension StringExtensions on String {
  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is empty or whitespace only
  bool get isBlank {
    return trim().isEmpty;
  }

  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Get file extension
  String get fileExtension {
    if (!contains('.')) return '';
    return split('.').last.toLowerCase();
  }

  /// Get file name without extension
  String get fileNameWithoutExtension {
    if (!contains('.')) return this;
    return substring(0, lastIndexOf('.'));
  }

  /// Truncate string to max length with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - 3)}...';
  }
}

/// BuildContext extensions for common operations
extension BuildContextExtensions on BuildContext {
  /// Get theme data
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get media query data
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get screen size
  Size get screenSize => mediaQuery.size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Check if device is in landscape
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;

  /// Check if device is in portrait
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;

  /// Check if device is small (width < 600)
  bool get isSmallDevice => screenWidth < 600;

  /// Check if device is medium (width >= 600 && width < 900)
  bool get isMediumDevice => screenWidth >= 600 && screenWidth < 900;

  /// Check if device is large (width >= 900)
  bool get isLargeDevice => screenWidth >= 900;

  /// Get device padding (safe area)
  EdgeInsets get devicePadding => mediaQuery.padding;

  /// Get device view insets (keyboard height, etc.)
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  /// Pop with result
  void popWithResult<T>(T result) {
    Navigator.of(this).pop(result);
  }

  /// Push named route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Show snackbar
  void showSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: duration,
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }
}

/// List extensions for common operations
extension ListExtensions<T> on List<T> {
  /// Get first element or null
  T? get firstOrNull {
    return isEmpty ? null : first;
  }

  /// Get last element or null
  T? get lastOrNull {
    return isEmpty ? null : last;
  }

  /// Check if list is not empty
  bool get isNotEmpty => length > 0;

  /// Get element at index or null
  T? getOrNull(int index) {
    return index >= 0 && index < length ? this[index] : null;
  }
}
