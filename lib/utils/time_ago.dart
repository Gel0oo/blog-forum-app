String timeAgo(String isoTimestamp) {
  final date = DateTime.parse(isoTimestamp);
  final diff = DateTime.now().difference(date);

  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

String formatDate(String isoTimestamp) {
  final date = DateTime.parse(isoTimestamp);
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}