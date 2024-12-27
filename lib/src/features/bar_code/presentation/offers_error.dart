import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/cubit/offers_cubit.dart';

class ErrorGettingOffers extends StatelessWidget {
  const ErrorGettingOffers({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "error_getting_offers".tr(context),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 18.sp),
            ElevatedButton(
                onPressed: () {
                  context.read<OffersCubit>().getAllOffers();
                },
                child: const Icon(FontAwesomeIcons.repeat))
          ],
        ),
      ),
    );
  }
}
