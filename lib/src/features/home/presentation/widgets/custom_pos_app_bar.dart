import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:mobilis_smart_pos/src/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../../../dependency_injection/injection_container.dart' as di;

class CustomPosAppBar extends StatelessWidget {
  const CustomPosAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final storedCredentials = di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials();
    String? businessName = '';
    if (storedCredentials != null && storedCredentials.businessName != null) {
      businessName = storedCredentials.businessName;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "welcome".tr(context),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: context.isDarkMode ? Colors.black : Colors.white),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  businessName ?? "",
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: context.isDarkMode ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                return Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.notifications,
                                arguments: context.read<NotificationCubit>())
                            .then((_) {
                          if (context.mounted) {
                            context.read<HomeCubit>().getUnreadCount();
                          }
                        });
                      },
                      icon: FaIcon(
                        FontAwesomeIcons.bell,
                        color: context.isDarkMode ? Colors.black : Colors.white,
                        size: 22,
                      ),
                    ),
                    if (state.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            state.unreadCount > 99 ? '99+' : state.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: FaIcon(
                Icons.menu,
                color: context.isDarkMode ? Colors.black : Colors.white,
              ),
            ),
          ],
        )
      ],
    );
  }
}
