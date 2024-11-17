import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../../../core/utils/helpers/toast_helper.dart';
import '../../../../dependency_injection/injection_container.dart' as di;
import '../../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../cubit/profile_cubit.dart';
import 'personnel_info_skeleton.dart';
import 'profile_item_field.dart';

class ProfilePersonalInformations extends StatelessWidget {
  const ProfilePersonalInformations({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileInfo(
              authenticationLocalDataSource: di.serviceLocator(),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildShimmerEffect(BuildContext context) {
  return Skeletonizer(
    child: Container(
      width: context.width / 2.5,
      height: 120.h,
      color: Colors.white,
    ),
  );
}

class ProfileInfo extends StatelessWidget {
  const ProfileInfo({
    super.key,
    required this.authenticationLocalDataSource,
  });

  final SmartPosLocalStorage authenticationLocalDataSource;

  String modifyNumber(String number, BuildContext context) {
    if (number.startsWith('213')) {
      return context.isArabicLocale ? '${number.substring(3)} 06' : '06 ${number.substring(3)}';
    }
    return number;
  }

  Future<ImageProvider> fetchImageWithToken(String url, String token) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return MemoryImage(response.bodyBytes);
    } else {
      throw Exception('Failed to load image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileInfoFailure) {
          AppToasts.showErrorToast(message: state.message.tr(context), context: context);
        }
      },
      builder: (context, state) {
        if (state is ProfileInfoLoading) {
          return const PersonalInfoSkeleton();
        }

        if (state is ProfielInfoSuccess) {
          final profile = state.profileResponseEntity;

          return Column(
            children: [
              SizedBox(height: 12.h),
              ProfileItem(label: "name".tr(context), value: profile.fullName),
              SizedBox(height: 16.h),
              ProfileItem(label: "enterprise".tr(context), value: profile.entrepriseName),
              SizedBox(height: 16.h),
              ProfileItem(
                label: "msisdn_apn".tr(context),
                value: modifyNumber(
                  profile.msisdnAPN,
                  context,
                ),
              ),
              SizedBox(height: 16.h),
              ProfileItem(
                label: "msisdn_erselli".tr(context),
                value: modifyNumber(
                  profile.msisdnErselli,
                  context,
                ),
              ),
              SizedBox(height: 16.h),
              ProfileItem(
                  label: "secret_code".tr(context),
                  value: profile.secretCode,
                  obsecureOption: true),
              SizedBox(height: 16.h),
              ProfileItem(
                  label: "commercial_register".tr(context), value: profile.commercialRegister),
              SizedBox(height: 16.h),
              ProfileItem(label: "nif".tr(context), value: profile.nif),
              SizedBox(height: 16.h),
              ProfileItem(label: "address".tr(context), value: profile.address),
              SizedBox(height: 48.h),
              /*
              if (profile.folderFiles != "")
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "my_documents".tr(context),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.sp),
                    SizedBox(
                      height: 120.sp,
                      child: Row(
                        children: [
                          Flexible(
                            child: FutureBuilder<ImageProvider>(
                              future: fetchImageWithToken(
                                  "$baseUrl/register_com?timestamp=$timestamp", accessToken),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done) {
                                  if (snapshot.hasError) {
                                    return const SizedBox();
                                  } else {
                                    return InstaImageViewer(
                                      child: Image(
                                        image: snapshot.data!,
                                      ),
                                    );
                                  }
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 12.sp),
                          Flexible(
                            child: FutureBuilder<ImageProvider>(
                              future: fetchImageWithToken(
                                  "$baseUrl/nif?timestamp=$timestamp", accessToken),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done) {
                                  if (snapshot.hasError) {
                                    return const SizedBox();
                                  } else {
                                    return InstaImageViewer(
                                      child: Image(
                                        image: snapshot.data!,
                                      ),
                                    );
                                  }
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 120.sp,
                      child: Row(
                        children: [
                          Flexible(
                            child: FutureBuilder<ImageProvider>(
                              future: fetchImageWithToken(
                                  "$baseUrl/card_id_recto?timestamp=$timestamp", accessToken),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done) {
                                  if (snapshot.hasError) {
                                    return const SizedBox.shrink();
                                  } else {
                                    return InstaImageViewer(
                                      child: Image(
                                        image: snapshot.data!,
                                      ),
                                    );
                                  }
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 12.sp),
                          Flexible(
                            child: FutureBuilder<ImageProvider>(
                              future: fetchImageWithToken(
                                  "$baseUrl/card_id_verso?timestamp=$timestamp", accessToken),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done) {
                                  if (snapshot.hasError) {
                                    return const SizedBox.shrink();
                                  } else {
                                    return InstaImageViewer(
                                      child: Image(
                                        image: snapshot.data!,
                                      ),
                                    );
                                  }
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<ImageProvider>(
                      future: fetchImageWithToken(
                          "$baseUrl/passport?timestamp=$timestamp", accessToken),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasError) {
                            return const SizedBox();
                          } else {
                            return InstaImageViewer(
                              child: Image(
                                height: 120.sp,
                                image: snapshot.data!,
                              ),
                            );
                          }
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    ),
                    SizedBox(height: 48.h),
                  ],
                ),

               */
            ],
          );
        }

        return const SizedBox();
      },
    );
  }
}
