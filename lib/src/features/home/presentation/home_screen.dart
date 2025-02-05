import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/banners_bloc_builder.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/custom_green_clipper.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/home_icons.dart';

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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const HomeDrawer(),
      body: SingleChildScrollView(
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
}
