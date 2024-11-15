import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/helpers/app_localization_cache_helper.dart';

part 'locale_state.dart';

class LocaleCubit extends Cubit<ChangeLocalState> {
  LocaleCubit() : super(ChangeLocalState(locale: const Locale('ar')));

  Future<void> getSavedLanguage() async {
    final String getCahedLanguageCode = await LanguageCacheHelper.getCachedLanguageCode();

    emit(ChangeLocalState(locale: Locale(getCahedLanguageCode)));
  }

  Future<void> changeLocale({required String languageCode}) async {
    await LanguageCacheHelper.cacheLanguageCode(languageCode);

    emit(ChangeLocalState(locale: Locale(languageCode)));
  }
}
