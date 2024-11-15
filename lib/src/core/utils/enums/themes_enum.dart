class AppThemes {

  const AppThemes._(this.name, this.index);

  final String name;
  final int index;


  static const lightTheme = AppThemes._("light", 0);
  static const darkTheme = AppThemes._("dark", 1);
}