import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/utils/enums/themes_enum.dart';
import 'features/main/presentation/cubits/cubit/theme_cubit.dart';

import '../src/dependency_injection/injection_container.dart' as di;
import 'config/routing/app_routes.dart';
import 'config/theming/app_theme.dart';
import 'core/api/dio_consumer.dart';
import 'core/utils/helpers/route_helper.dart';
import 'core/utils/ressources/app_constants.dart';
import 'features/main/presentation/cubits/cubit/locale_cubit.dart';
import 'features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import 'features/sign_out/domain/use_cases/sign_out_use_case.dart';
import 'features/sign_out/presentation/cubit/sign_out_cubit.dart';

import 'features/notifications/presentation/cubit/notification_cubit.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SmartPos extends StatelessWidget {
  const SmartPos({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Resolution of pixel 6 pro (Android Studio)
      designSize: const Size(384, 832),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return const AppConfigMultiBlocProvider(
          child: LocaleAndThemeBlocBuilder(),
        );
      },
    );
  }
}

class AppConfigMultiBlocProvider extends StatelessWidget {
  const AppConfigMultiBlocProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [
      BlocProvider(
        create: (context) => LocaleCubit()..getSavedLanguage(),
      ),
      BlocProvider(
        create: (context) => ThemeCubit()..getSavedTheme(),
      ),
      BlocProvider(
        create: (_) => SignOutCubit(
          localDataSource: di.serviceLocator<SmartPosLocalStorage>(),
          useCase: di.serviceLocator<SignOutUseCase>(),
        ),
      ),
    ], child: child);
  }
}

class LocaleAndThemeBlocBuilder extends StatelessWidget {
  const LocaleAndThemeBlocBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    final initialRouteHelper = di.serviceLocator<InitialRouteHelper>();

    return BlocBuilder<LocaleCubit, ChangeLocalState>(
      builder: (context, localeState) {
        return BlocBuilder<ThemeCubit, ChangeThemeState>(
          builder: (context, themeState) {
            if (!di.serviceLocator.isRegistered<DioConsumer>()) {
              di.serviceLocator.registerLazySingleton<DioConsumer>(
                () => DioConsumer(client: di.serviceLocator(), context: context),
              );
            }

            return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'MOBILIS SMART POS',
              theme: themeState.theme.name == AppThemes.darkTheme.name
                  ? smartDealerThemeDark(localeState.locale)
                  : smartDealerTheme(localeState.locale),
              onGenerateRoute: AppRoutes.onGenerateRoute,
              initialRoute: initialRouteHelper.determineInitialRoute(),

              // ==== Localization ==== //
              locale: localeState.locale,
              supportedLocales: supportedLocales,
              localizationsDelegates: localizationsDelegates,
              localeResolutionCallback: (deviceLocale, supportedLocales) {
                for (var locale in supportedLocales) {
                  if (deviceLocale != null && (deviceLocale.languageCode == locale.languageCode)) {
                    return deviceLocale;
                  }
                }
                return const Locale("ar");
              },
              // ==== Localization ==== //
            );
          },
        );
      },
    );
  }
}
