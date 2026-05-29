/// User-facing labels for the daily checklist (supplements, habits, errands, etc.).
///
/// Internal models still use [Supplement] for storage compatibility.
abstract final class ChecklistCopy {
  static const sectionTitle = 'Daily checklist';
  static const sectionSubtitleToday = 'Check off what you did today';
  static const settingsTitle = 'Daily checklist';
  static const settingsSubtitle = 'Supplements, habits & reminders';
  static const emptyToday =
      'Add items in Settings — supplements, yoga, errands, or anything you want to remember.';
  static const emptySettings = 'No items yet. Tap Add to create one.';
  static const addDialogTitle = 'Add checklist item';
  static const editDialogTitle = 'Edit checklist item';
  static const nameLabel = 'Name';
  static const notesLabel = 'Notes (optional)';
  static const timeOfDayLabel = 'Time of day';
  static const summaryChecklistTitle = 'Checklist';
  static const summaryChecklistSubtitle = 'Days completed in the last 7 days';
  static const summaryChecklistEmpty =
      'Enable checklist items in Settings to see your progress here.';

  static String summaryDaysValue(int completed, int window) {
    if (window <= 0) return '—';
    if (completed == window) return '$completed days';
    return '$completed of $window days';
  }
  static const widgetSectionTitle = 'Checklist';
  static const widgetFallbackName = 'Item';
}
