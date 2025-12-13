import 'package:intl/intl.dart';

/// Utility class for parsing and formatting dates
/// Backend returns dates in UTC format: "2025-12-10 19:36:26"
/// This utility converts them to local timezone for display
class DateTimeUtils {
  /// Parse backend date string (UTC) to DateTime
  /// Format: "2025-12-10 19:36:26"
  static DateTime? parseBackendDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Parse as UTC since backend sends UTC times
      final utcDateTime = DateTime.parse('${dateStr.replaceAll(' ', 'T')}Z');
      return utcDateTime.toLocal();
    } catch (e) {
      // Try alternative format without Z suffix
      try {
        final parts = dateStr.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('-');
          final timeParts = parts[1].split(':');

          if (dateParts.length == 3 && timeParts.length >= 2) {
            final utcDateTime = DateTime.utc(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
              timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
            );
            return utcDateTime.toLocal();
          }
        }
      } catch (_) {}
      return null;
    }
  }

  /// Format DateTime for display
  /// Example output: "10 Dec, 02:36 AM"
  static String formatForDisplay(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';

    final formatter = DateFormat('dd MMM, hh:mm a', 'id_ID');
    return formatter.format(dateTime);
  }

  /// Format DateTime with full date
  /// Example output: "10 December 2025, 02:36 AM"
  static String formatFullDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';

    final formatter = DateFormat('dd MMMM yyyy, hh:mm a', 'id_ID');
    return formatter.format(dateTime);
  }

  /// Format as relative time (e.g., "5 minutes ago")
  static String formatRelative(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return formatForDisplay(dateTime);
    }
  }

  /// Get day name from day_of_week number (0=Sunday, 1=Monday, etc.)
  static String getDayName(int dayOfWeek) {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    if (dayOfWeek >= 0 && dayOfWeek < 7) {
      return days[dayOfWeek];
    }
    return 'Unknown';
  }

  /// Format DateTime for backend API
  /// Output format: "2025-12-10 19:36:26" (UTC)
  static String formatForBackend(DateTime dateTime) {
    final utc = dateTime.toUtc();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(utc);
  }

  /// Format time only
  /// Example output: "02:36"
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    final formatter = DateFormat('HH:mm');
    return formatter.format(dateTime);
  }

  /// Format date only
  /// Example output: "10 Dec 2025"
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    return formatter.format(dateTime);
  }
}
