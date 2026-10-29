import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_app_bar.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../features/home/presentation/cubit/home_cubit.dart';
import '../../data/models/notification_model.dart';
import '../cubit/notification_cubit.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    final cubit = context.read<NotificationCubit>();
    // The cubit outlives this screen (it belongs to the main screen): a list loaded
    // on a previous visit is shown at once, then replaced by the server's latest.
    if (cubit.state is NotificationLoaded) {
      cubit.getNotifications(isRefresh: true);
    } else {
      cubit.getNotifications();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<NotificationCubit>().getNotifications(isLoadMore: true);
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "notifications".tr(context),
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationError) {
            return _ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<NotificationCubit>().getNotifications(),
            );
          } else if (state is NotificationLoaded || state is NotificationLoadingMore) {
            final notifications = state is NotificationLoaded
                ? state.notifications
                : (state as NotificationLoadingMore).notifications;

            final hasMore = state is NotificationLoaded ? state.hasMore : true;

            if (notifications.rows.isEmpty) {
              return _EmptyStateWidget(
                onRefresh: () =>
                    context.read<NotificationCubit>().getNotifications(isRefresh: true),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<NotificationCubit>().getNotifications(isRefresh: true),
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.all(16.sp),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: hasMore ? notifications.rows.length + 1 : notifications.rows.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.sp),
                itemBuilder: (context, index) {
                  if (index >= notifications.rows.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final notification = notifications.rows[index];
                  return _NotificationTile(notification: notification);
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyStateWidget({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: context.height - 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24.sp),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.bellSlash,
                    size: 64.sp,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 24.sp),
                Text(
                  "no_notifications".tr(context),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: context.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 12.sp),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48.sp),
                  child: Text(
                    "you_are_all_caught_up".tr(context),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(height: 32.sp),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: Text("refresh".tr(context)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorStateWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.sp),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 64.sp,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 24.sp),
            Text(
              "oops_something_went_wrong".tr(context),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: context.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 12.sp),
            SizedBox(height: 32.sp),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text("retry".tr(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 16.sp),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final title = notification.title.getLocalized(locale);
    final description = notification.description.getLocalized(locale);
    final priorityLabel = notification.priority.tr(context);
    final date = _formatDate(notification.receivedAt, locale);

    final priorityColor = _getPriorityColor(notification.priority);
    final typeIcon = _getTypeIcon(notification.type);

    return InkWell(
      onTap: () => _showNotificationDetailModal(context, notification),
      borderRadius: BorderRadius.circular(16.sp),
      child: Container(
        padding: EdgeInsets.all(12.sp),
        decoration: BoxDecoration(
          color: context.isDarkMode ? AppColors.darkGrey : Colors.white,
          borderRadius: BorderRadius.circular(16.sp),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: notification.isRead
              ? Border.all(color: Colors.grey.withOpacity(0.1))
              : Border.all(color: priorityColor.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.sp),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(typeIcon, color: priorityColor, size: 20.sp),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 15.sp,
                            color: context.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8.sp,
                          height: 8.sp,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 13.sp,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8.sp),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetailModal(BuildContext context, NotificationModel notification) {
    final cubit = context.read<NotificationCubit>();
    HomeCubit? homeCubit;
    try {
      homeCubit = context.read<HomeCubit>();
    } catch (_) {
      // HomeCubit might not be available in some contexts, safe to ignore
    }
    // Read as soon as it is opened. The badge is refreshed once the server has saved it,
    // otherwise it would still count this notification.
    cubit.markAsRead(notification.notificationPdvId).then((_) => homeCubit?.getUnreadCount());

    final locale = Localizations.localeOf(context).languageCode;
    final title = notification.title.getLocalized(locale);
    final description = notification.description.getLocalized(locale);
    final date = _formatDate(notification.receivedAt, locale);
    final priorityColor = _getPriorityColor(notification.priority);
    final typeIcon = _getTypeIcon(notification.type);
    final priorityIcon = _getPriorityIcon(notification.priority);
    final priorityLabel = notification.priority.tr(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: context.height * 0.75,
        decoration: BoxDecoration(
          color: context.isDarkMode ? AppColors.darkGrey : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.sp)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12.sp),
            Container(
              width: 40.sp,
              height: 4.sp,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.sp),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(20.sp),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(typeIcon, color: priorityColor, size: 40.sp),
                      ),
                    ),
                    SizedBox(height: 24.sp),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.sp),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(priorityIcon, color: priorityColor, size: 12.sp),
                            SizedBox(width: 6.sp),
                            Text(
                              priorityLabel.toUpperCase(),
                              style: TextStyle(
                                color: priorityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.sp),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: context.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.sp),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 24.sp),
                    Container(
                      padding: EdgeInsets.all(16.sp),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16.sp),
                      ),
                      child: Linkify(
                        text: description,
                        onOpen: (link) async {
                          final uri = Uri.parse(link.url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        style: TextStyle(
                          fontSize: 16.sp,
                          height: 1.6,
                          color: context.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                        linkStyle: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(height: 32.sp),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16.sp),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.sp),
                          ),
                        ),
                        child: Text(
                          "ok".tr(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return AppColors.primary;
      case 'low':
        return Colors.blueGrey;
      default:
        return AppColors.primary;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return FontAwesomeIcons.circleExclamation;
      case 'high':
        return FontAwesomeIcons.triangleExclamation;
      case 'normal':
      case 'low':
        return FontAwesomeIcons.circleInfo;
      default:
        return FontAwesomeIcons.circleInfo;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'publicity':
        return FontAwesomeIcons.bullhorn;
      case 'informational':
        return FontAwesomeIcons.circleInfo;
      case 'awareness':
        return FontAwesomeIcons.lightbulb;
      case 'maintenance':
        return FontAwesomeIcons.wrench;
      case 'service_unavailability':
        return FontAwesomeIcons.ban;
      case 'update':
        return FontAwesomeIcons.rocket;
      default:
        return FontAwesomeIcons.bell;
    }
  }

  String _formatDate(DateTime date, String locale) {
    String formatted = DateFormat.yMMMd(locale).add_jm().format(date);
    if (locale == 'ar') {
      // Replace Eastern Arabic numerals with Western (Latin) numerals
      const easternArabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      const westernArabic = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      for (int i = 0; i < 10; i++) {
        formatted = formatted.replaceAll(easternArabic[i], westernArabic[i]);
      }

      // Replace Middle Eastern month names with Algerian/Maghreb month names
      final monthReplacements = {
        'يناير': 'جانفي',
        'فبراير': 'فيفري',
        'أبريل': 'أفريل',
        'مايو': 'ماي',
        'يونيو': 'جوان',
        'يوليو': 'جويلية',
        'أغسطس': 'أوت',
      };

      monthReplacements.forEach((oldMonth, newMonth) {
        formatted = formatted.replaceAll(oldMonth, newMonth);
      });
    }
    return formatted;
  }
}
