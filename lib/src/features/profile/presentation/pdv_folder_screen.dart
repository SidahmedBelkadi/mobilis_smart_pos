import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:lottie/lottie.dart';
import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/custom_app_bar.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../.././dependency_injection/injection_container.dart' as di;
import '../../../core/api/end_points.dart';
import '../../../core/utils/ressources/app_colors.dart';

final authenticationLocalDataSource = di.serviceLocator<SmartPosLocalStorage>();
final pdvCode = authenticationLocalDataSource.getSavedLoginCredentials()!.pdvCode!;
final accessToken = authenticationLocalDataSource.getSavedLoginCredentials()!.accessToken;
final baseUrl = "${EndPoints.baseUrl}/file/employee/$pdvCode/0";
final timestamp = DateTime.now().millisecondsSinceEpoch;

final passportUrl = "$baseUrl/passport";
final commercialRegisterUrl = "$baseUrl/register_com";
final nifUrl = "$baseUrl/nif";
final frontIdCardUrl = "$baseUrl/card_id_recto";
final backIdCardUrl = "$baseUrl/card_id_verso";

class PdvFolderScreen extends StatefulWidget {
  const PdvFolderScreen({super.key});

  @override
  State<PdvFolderScreen> createState() => _PdvFolderScreenState();
}

class _PdvFolderScreenState extends State<PdvFolderScreen> {
  final List<String> imagesList = [
    frontIdCardUrl,
    backIdCardUrl,
    commercialRegisterUrl,
    nifUrl,
    passportUrl,
  ];

  List<String> validImagesList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    filterValidImages();
  }

  Future<void> filterValidImages() async {
    List<String> tempValidImages = [];
    for (var imageUrl in imagesList) {
      bool exists = await imageExists(imageUrl);
      if (exists) {
        tempValidImages.add(imageUrl);
      }
    }
    setState(() {
      validImagesList = tempValidImages;
      isLoading = false;
    });
  }

  Future<bool> imageExists(String url) async {
    try {
      final response = await http.head(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "my_folder".tr(context)),
      body: isLoading
          ? const ImagesSkeleton()
          : validImagesList.isEmpty
              ? SizedBox(
                  width: context.width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LottieBuilder.asset(
                        AppImages.emptyBox,
                        height: 280.sp,
                        width: 280.sp,
                      ),
                      Text(
                        "pdv_folder_empty".tr(context),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 42.sp),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed(Routes.updatePdvFolder);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "update_now".tr(context),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            SizedBox(width: 8.sp),
                            Icon(
                              FontAwesomeIcons.upload,
                              size: 16.sp,
                              color: context.isDarkMode ? Colors.white : Colors.black,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              : Container(
                  height: context.height,
                  width: context.width,
                  padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 24.sp),
                  child: GridView.builder(
                    itemCount: validImagesList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8.sp,
                      crossAxisSpacing: 10.sp,
                    ),
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.sp),
                          border: Border.all(color: Colors.green),
                        ),
                        child: BuildImage(url: validImagesList[index]),
                      );
                    },
                  ),
                ),
    );
  }
}

class BuildImage extends StatelessWidget {
  const BuildImage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider>(
      future: fetchImageWithToken(url, accessToken),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Container();
        } else {
          return InstaImageViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.sp),
              child: Image(
                image: snapshot.data!,
                height: 180.sp,
              ),
            ),
          );
        }
      },
    );
  }
}

// Helper function to fetch image with token and timeout
Future<ImageProvider> fetchImageWithToken(
  String url,
  String token,
) async {
  // Create an HTTP client
  final client = http.Client();

  try {
    // Set a 30-second timeout for the request
    final response = await client.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return MemoryImage(response.bodyBytes);
    } else {
      throw Exception('Failed to load image');
    }
  } catch (e) {
    throw Exception('Request timed out or failed: $e');
  } finally {
    client.close();
  }
}

class ImagesSkeleton extends StatelessWidget {
  const ImagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Container(
        height: context.height,
        width: context.width,
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 24.sp),
        child: GridView.builder(
          itemCount: 4,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8.sp,
            crossAxisSpacing: 10.sp,
          ),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(
                  color: context.isDarkMode ? Colors.black : AppColors.secondaryLight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.sp),
                child: Image.asset(
                  AppImages.ban1,
                  height: 180.sp,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
