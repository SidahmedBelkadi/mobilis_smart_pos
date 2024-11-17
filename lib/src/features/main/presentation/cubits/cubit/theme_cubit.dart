import 'package:bloc/bloc.dart';
import '../../../../../core/utils/enums/themes_enum.dart';
import '../../../../sign_in/data/data_sources/smart_pos_local_storage.dart';

import '../../../../../dependency_injection/injection_container.dart' as di;

part 'theme_state.dart';

class ThemeCubit extends Cubit<ChangeThemeState> {
  ThemeCubit() : super(ChangeThemeState(theme: AppThemes.lightTheme));

  getSavedTheme() {
    final AppThemes cahedTheme = di.serviceLocator<SmartPosLocalStorage>().getCurrentTheme();

    emit(ChangeThemeState(theme: cahedTheme));
  }

  changeTheme(AppThemes theme) async {
    await di.serviceLocator<SmartPosLocalStorage>().saveTheme(theme);
    emit(ChangeThemeState(theme: theme));
  }
}
