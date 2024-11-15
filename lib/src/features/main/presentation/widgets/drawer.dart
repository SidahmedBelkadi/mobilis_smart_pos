import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/core/utils/enums/themes_enum.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/features/main/presentation/cubits/cubit/theme_cubit.dart';
import 'package:mobilis_smart_pos/src/features/main/presentation/widgets/change_password_tile.dart';
import 'package:mobilis_smart_pos/src/features/main/presentation/widgets/theme_tile.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';

import '../../../../config/routing/app_routes.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../../../core/utils/helpers/toast_helper.dart';
import '../../../../core/utils/ressources/app_images.dart';
import '../../../../dependency_injection/injection_container.dart' as di;
import '../../../sign_out/presentation/cubit/sign_out_cubit.dart';
import '../cubits/cubit/locale_cubit.dart';
import 'language_tile.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTheme =
        di.serviceLocator<SmartPosLocalStorage>().getCurrentTheme();
    return Drawer(
      backgroundColor: context.isDarkMode ? AppColors.darkGrey : Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              context.isArabicLocale
                  ? AppImages.mobilisAr
                  : AppImages.mobilisEn,
              width: context.width,
              height: 220.sp,
            ),
            ExpansionTile(
              iconColor: AppColors.primary,
              title: ExpansionTileTitle(
                  title: "preferences".tr(context),
                  icon: FontAwesomeIcons.wrench),
              children: [
                BlocBuilder<LocaleCubit, ChangeLocalState>(
                  builder: (context, state) {
                    return LanguageTile(
                      selectedLanguage: state.locale.languageCode,
                      onLanguageChanged: (value) {
                        context
                            .read<LocaleCubit>()
                            .changeLocale(languageCode: value.toString());
                      },
                    );
                  },
                ),
                const Divider(),
                BlocBuilder<ThemeCubit, ChangeThemeState>(
                  builder: (context, state) {
                    return ThemeTile(
                      selectedTheme: state.theme,
                      onThemeChanged: (value) {
                        context.read<ThemeCubit>().changeTheme(
                            value == AppThemes.darkTheme.name
                                ? AppThemes.darkTheme
                                : AppThemes.lightTheme);
                      },
                    );
                  },
                ),
              ],
            ),
            ExpansionTile(
              title: ExpansionTileTitle(
                  title: "confidentiality".tr(context),
                  icon: FontAwesomeIcons.lock),
              children: [
                ChangePasswordTile(
                  onTap: () {
                    Navigator.of(context).pushNamed(Routes.changePassword);
                  },
                ),
              ],
            ),
            ExpansionTile(
              title: ExpansionTileTitle(
                  title: "my_folder".tr(context),
                  icon: FontAwesomeIcons.folder),
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 10.0.sp),
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).pushNamed(Routes.pdvFolder);
                    },
                    leading: Icon(
                      FontAwesomeIcons.folderOpen,
                      size: 16.sp,
                      color: AppColors.secondary,
                    ),
                    title: Text(
                      "view_my_folder".tr(context),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10.0.sp),
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).pushNamed(Routes.updatePdvFolder);
                    },
                    leading: Icon(
                      FontAwesomeIcons.sync,
                      size: 16.sp,
                      color: AppColors.secondary,
                    ),
                    title: Text(
                      "update_my_folder".tr(context),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 32.sp),
            BlocConsumer<SignOutCubit, SignOutState>(
              listener: (context, state) {
                if (state is SignOutSuccessful) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(Routes.signIn, (route) => false);
                }
                if (state is SignOutUnSuccessful) {
                  AppToasts.showErrorToast(
                      message: state.message,
                      onAutoCompleteCompleted: (p0) {},
                      context: context);
                }
              },
              builder: (context, state) {
                if (state is SignOutLoading) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48.sp),
                    child: ElevatedButton(
                      onPressed: () {},
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.sp),
                        child: SizedBox(
                          height: 24.sp,
                          width: 24.sp,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48.sp),
                  child: ElevatedButton(
                    onPressed: () =>
                        context.read<SignOutCubit>().signOut(context),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text(
                      "deconnect".tr(context),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }
}

class ExpansionTileTitle extends StatelessWidget {
  const ExpansionTileTitle(
      {super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18.sp,
          color: AppColors.primary,
        ),
        SizedBox(width: 12.sp),
        Text(title),
      ],
    );
  }
}
