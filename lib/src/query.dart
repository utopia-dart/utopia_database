class Query {
// Filter methods
  static const String typeEqual = 'equal';
  static const String typeNotEqual = 'notEqual';
  static const String typeLesser = 'lessThan';
  static const String typeLesserEqual = 'lessThanEqual';
  static const String typeGreater = 'greaterThan';
  static const String typeGreaterEqual = 'greaterThanEqual';
  static const String typeContains = 'contains';
  static const String typeSearch = 'search';
  static const String typeIsNull = 'isNull';
  static const String typeIsNotNull = 'isNotNull';
  static const String typeBetween = 'between';
  static const String typeStartsWith = 'startsWith';
  static const String typeEndsWith = 'endsWith';

  static const String typeSelect = 'select';

// Order methods
  static const String typeOrderDesc = 'orderDesc';
  static const String typeOrderAsc = 'orderAsc';

// Pagination methods
  static const String typeLimit = 'limit';
  static const String typeOffset = 'offset';
  static const String typeCursorAfter = 'cursorAfter';
  static const String typeCursorBefore = 'cursorBefore';

  static const String charSingleQuote = '\'';
  static const String charDoubleQuote = '"';
  static const String charComma = ',';
  static const String charSpace = ' ';
  static const String charBracketStart = '[';
  static const String charBracketEnd = ']';
  static const String charParenthesesStart = '(';
  static const String charParenthesesEnd = ')';
  static const String charBackslash = '\\';

  String method = '';
  String attribute = '';
  List<dynamic> values = [];
}
