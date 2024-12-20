import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_floating_action_button.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/domain/entities/offer_entity.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/bar_code_screen.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/cubit/offers_cubit.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  String? selectedOfferName;
  int? selectedOfferID;

  @override
  void initState() {
    super.initState();
    context.read<OffersCubit>().getAllOffers();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: selectedOfferID != null && selectedOfferName != null
            ? CustomFAB(
                label: '',
                icon: FontAwesomeIcons.check,
                onPressed: () {
                  Navigator.of(context).pop(
                    {
                      'offerId': selectedOfferID,
                      'offerName': selectedOfferName,
                    },
                  );
                },
              )
            : null,
        body: Padding(
          padding: EdgeInsets.all(24.sp),
          child: BlocBuilder<OffersCubit, OffersState>(
            builder: (context, state) {
              if (state is GetAllOffersLoading) {
                return const OffersSkeleton();
              }
              if (state is GetAllOffersFailure) {
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
              if (state is GetAllOffersSuccess) {
                final offers = state.offers;
                return Padding(
                  padding: EdgeInsets.all(16.0.sp),
                  child: Column(
                    children: [
                      Text(
                        "offers".tr(context),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 24.sp),
                      Expanded(
                        child: ListView.builder(
                          itemCount: offers.length,
                          itemBuilder: (_, index) {
                            final OfferEntity offer = offers[index];
                            return OfferItem(
                              title: offer.name,
                              price: context.isArabicLocale
                                  ? offer.formattedPriceAr
                                  : offer.formattedPrice,
                              onTap: () {
                                setState(() {
                                  selectedOfferName = offer.name;
                                  selectedOfferID = offer.id;
                                });
                              },
                              isSelected:
                                  selectedOfferName == offer.name && selectedOfferID == offer.id,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
