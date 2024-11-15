import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';

import '../../../../core/utils/helpers/toast_helper.dart';
import '../../domain/entities/invoice_entity.dart';
import '../cubit/invoices_cubit.dart';
import 'invoice_item.dart';
import 'invoice_skeleton.dart';
import 'no_more_invoices.dart';
import 'server_error.dart';
import 'skeleton_list.dart';

class InvoicesListView extends StatelessWidget {
  const InvoicesListView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvoicesCubit>();
    return BlocConsumer<InvoicesCubit, InvoicesState>(
      listener: (context, state) {
        if (state is GetInvoicesFailure) {
          AppToasts.showErrorToast(
            message: state.message.tr(context),
            context: context,
          );
        }
      },
      builder: (context, state) {
        if (state is GetInvoicesLoading) {
          return const SkeletonListView();
        }
        if (state is InvoicesWithData) {
          final invoices = state.invoices;
          if (invoices.isEmpty) {
            return SizedBox();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent &&
                      state is GetInvoicesSuccess &&
                      state.hasMoreInvoices &&
                      constraints.maxHeight < invoices.length * 100) {
                    // Dynamic condition
                    cubit.getInvoices(isFetchingMore: true);
                  }
                  return true;
                },
                child: RefreshIndicator(
                  onRefresh: () async {
                    await cubit.getInvoices(isFirstTime: true);
                  },
                  child: AnimationLimiter(
                    child: ListView.separated(
                      itemCount: invoices.length + 1,
                      itemBuilder: (context, index) {
                        if (index == invoices.length) {
                          if (state is FetchingMoreInvoices) {
                            return const InvoiceSkeleton();
                          } else if (state is GetInvoicesSuccess &&
                              !state.hasMoreInvoices) {
                            return const NoMoreInvoices();
                          }
                          return const SizedBox.shrink();
                        }

                        final InvoiceEntity invoice = invoices[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: -100,
                            child: Invoice(
                              invoiceEntity: invoice,
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return SizedBox(height: 16.sp);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        }

        if (state is GetInvoicesFailure) {
          return const ServerError();
        }

        return const SizedBox();
      },
    );
  }
}
