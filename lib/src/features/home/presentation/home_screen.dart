import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'widgets/CustomCuvedEdges.dart';
import '../../main/presentation/widgets/drawer.dart';
import '../../sign_in/data/data_sources/smart_pos_local_storage.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../../../dependency_injection/injection_container.dart' as di;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final storedCredentials = di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials();
    String? businessName = '';
    if (storedCredentials != null && storedCredentials.businessName != null) {
      businessName = storedCredentials.businessName;
    }
    return Scaffold(
      drawer: const HomeDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: Customcuvededges(),
              child: Container(
                height: 120.sp,
                color: AppColors.primary,
                child: SizedBox(
                  width: context.width,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "welcome".tr(context),
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: context.isDarkMode ? Colors.white : Colors.black),
                              ),
                              Flexible(
                                  child: Text(
                                businessName ?? "",
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                    color: context.isDarkMode ? Colors.white : Colors.black),
                              )),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                          child: FaIcon(
                            Icons.menu,
                            color: context.isDarkMode ? Colors.white : Colors.black,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: context.height - 180,
              //color: Colors.red,
              padding: EdgeInsets.fromLTRB(24.sp, 0, 24.sp, 24.sp),
              width: context.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    height: 220.sp,
                    width: context.width,
                    child: HomeBanner(
                      banners: const [
                        AppImages.bannerBonus,

                        // AppImages.ban1,
                        // AppImages.ban2,
                        AppImages.ban3,
                        // AppImages.ban4,
                        AppImages.bannerOmra,
                      ],
                      currentIndex: currentIndex,
                      onPageChanged: (index) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          HomeIcon(
                            onTap: () => {},
                            image: AppImages.paymentFactures,
                            title: "mesFactures".tr(context),
                          ),
                          SizedBox(width: 32.sp),
                          HomeIcon(
                            image: AppImages.ereselli,
                            title: "erselli".tr(context),
                            onTap: () {},
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          HomeIcon(
                            image: AppImages.activations,
                            title: "mesActivations".tr(context),
                            onTap: () => Navigator.of(context)
                                .pushReplacementNamed(Routes.main, arguments: {'index': 1}),
                          ),
                          SizedBox(width: 32.sp),
                          HomeIcon(
                            image: AppImages.operations,
                            title: "mesOperations".tr(context),
                            onTap: () => Navigator.of(context).pushNamed(Routes.invoices),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeBanner extends StatelessWidget {
  final List<String> banners;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const HomeBanner({
    super.key,
    required this.banners,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CarouselSlider(
          items: banners
              .map(
                (imageUrl) => ClipRRect(
                  borderRadius: BorderRadius.circular(16.0.sp),
                  child: Image(
                    image: AssetImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              )
              .toList(),
          options: CarouselOptions(
            viewportFraction: 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 500),
            pauseAutoPlayOnTouch: true,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) => onPageChanged(index),
          ),
        ),
        SizedBox(height: 24.0.h), // Adjust the height as needed
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(seconds: 1),
              height: 6.h,
              width: currentIndex == index ? 30.w : 6.w,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HomeIcon extends StatelessWidget {
  const HomeIcon({
    super.key,
    required this.image,
    required this.title,
    this.onTap,
    this.isDisabled = false,
  });

  final String image;
  final String title;
  final void Function()? onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(image, height: 100.sp, width: 120.sp),
          // SizedBox(height: 8.sp),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
