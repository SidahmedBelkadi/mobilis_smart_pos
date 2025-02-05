import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_images.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/banners_skeleton.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/home_banner_widget.dart';

class HomeBannersBlocBuilder extends StatelessWidget {
  const HomeBannersBlocBuilder({
    super.key,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final int currentIndex;
  final void Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeBannersLoading) {
          return const BannersSkeleton();
        }
        if (state is HomeBannersLoadedSuccessfully) {
          return HomeBanner(
            banners: state.bannersUrls,
            currentIndex: currentIndex,
            onPageChanged: onPageChanged,
          );
        }

        return HomeBanner(
          isNetworkBanners: false,
          banners: const [AppImages.ban4],
          currentIndex: currentIndex,
          onPageChanged: onPageChanged,
        );
      },
    );
  }
}
