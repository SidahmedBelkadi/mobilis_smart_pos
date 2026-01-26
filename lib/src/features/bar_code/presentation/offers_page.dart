import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_floating_action_button.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/domain/entities/offer_entity.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/cubit/offers_cubit.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/offers_error.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/offers_item.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/offers_skeleton.dart';

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
    return SessionTimeout(
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
                return const ErrorGettingOffers();
              }
              if (state is GetAllOffersSuccess) {
                final offers = state.offers;
                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: Column(
                      children: [
                        Text(
                          "offers".tr(context),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 24.sp),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: offers.length,
                          itemBuilder: (_, index) {
                            final offer = offers[index];
                            return OfferItem(
                              title: offer.name,
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
                      ],
                    ),
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
