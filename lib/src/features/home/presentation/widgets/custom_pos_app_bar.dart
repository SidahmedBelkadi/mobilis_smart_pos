import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
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
              Flexible(
                  child: Text(
                businessName ?? "",
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(color: context.isDarkMode ? Colors.black : Colors.white),
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
            color: context.isDarkMode ? Colors.black : Colors.white,
          ),
        )
      ],
    );
  }
}
