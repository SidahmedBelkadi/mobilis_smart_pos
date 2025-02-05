import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class HomeBanner extends StatelessWidget {
  final List<String> banners;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final bool isNetworkBanners;

  const HomeBanner({
    super.key,
    required this.banners,
    required this.currentIndex,
    required this.onPageChanged,
    this.isNetworkBanners = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220.sp,
      width: context.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CarouselSlider(
            items: banners
                .map(
                  (imageUrl) => ClipRRect(
                    borderRadius: BorderRadius.circular(16.0.sp),
                    child: isNetworkBanners
                        ? CachedNetworkImage(
                            imageUrl: "http://192.168.1.12:3002$imageUrl",
                            imageBuilder: (context, imageProvider) => Container(
                                  width: context.width,
                                  height: 220.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(12.0),
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                            progressIndicatorBuilder: (context, url, downloadProgress) {
                              return Shimmer.fromColors(
                                baseColor:
                                    context.isDarkMode ? AppColors.darkerGrey : AppColors.grey,
                                highlightColor:
                                    context.isDarkMode ? AppColors.darkGrey : AppColors.lightGrey,
                                child: Container(
                                  width: context.width,
                                  height: 220.sp,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            })
                        : Image.asset(
                            imageUrl,
                            fit: BoxFit.fill,
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
      ),
    );
  }
}
