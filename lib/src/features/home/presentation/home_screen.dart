import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/core/api/end_points.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/banners_bloc_builder.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/custom_green_clipper.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/home_icons.dart';
import 'package:mobilis_smart_pos/src/features/notifications/presentation/cubit/notification_cubit.dart';

import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../main/presentation/widgets/drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    context.read<HomeCubit>().loadHomeBannersUrls();
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listenWhen: (previous, current) => previous.unreadCount == 0 && current.unreadCount > 0,
      listener: (context, state) {
        //_showNotificationPopup(context, state.unreadCount);
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            const CustomGreenClipper(),
            Container(
              height: context.height - 180,
              padding: EdgeInsets.fromLTRB(24.sp, 0, 24.sp, 24.sp),
              width: context.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (EndPoints.baseUrl != dotenv.env['BASE_URL_DEV'])
                    HomeBannersBlocBuilder(
                      currentIndex: currentIndex,
                      onPageChanged: (index) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                    ),
                  SizedBox(height: 24.sp),
                  const HomeIcons(),
                  SizedBox(height: 24.sp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationPopup(BuildContext context, int count) {
    final notificationCubit = context.read<NotificationCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: dialogContext.isDarkMode ? AppColors.darkGrey : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  FontAwesomeIcons.bell,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "new_notifications".tr(dialogContext),
                style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dialogContext.isDarkMode ? Colors.white : Colors.black,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                "you_have_unread_notifications"
                    .tr(dialogContext)
                    .replaceFirst('{count}', count.toString()),
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: dialogContext.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        "later".tr(dialogContext),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.pushNamed(context, "/notifications",
                            arguments: notificationCubit);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "show_notifications".tr(dialogContext),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
