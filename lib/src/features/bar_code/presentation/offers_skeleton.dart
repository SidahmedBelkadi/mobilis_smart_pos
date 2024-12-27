import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/offers_item.dart';
import 'package:skeletonizer/skeletonizer.dart';

class OffersSkeleton extends StatelessWidget {
  const OffersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Container(
        padding: EdgeInsets.all(16.0.sp),
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Text(
              "Available Offers",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24.sp),
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) => OfferItem(
                  title: "Offer Name",
                  price: '2000 DA',
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
