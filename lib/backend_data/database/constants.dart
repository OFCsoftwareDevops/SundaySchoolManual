const List<String> ownerEmails = [
  "olaoluwa.ogunseye@gmail.com",
  // add more later
];

class AppConstants {
  // Quarter definitions
  static const List<List<int>> quarterMonths = [
    [12, 1, 2],     // Q1: January – March
    [3, 4, 5],     // Q2: April – June
    [6, 7, 8],     // Q3: July – September
    [9, 10, 11],  // Q4: October – December
  ];

  static const List<String> quarterLabels = [
    'Q1',
    'Q2',
    'Q3',
    'Q4'
  ];

  // Optional: Full month names (if used elsewhere)
  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
}
