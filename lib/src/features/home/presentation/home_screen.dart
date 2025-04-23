import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:edge_detection_plus/edge_detection_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:mobilis_smart_pos/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/banners_bloc_builder.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/custom_green_clipper.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/home_icons.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../main/presentation/widgets/drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    context.read<HomeCubit>().loadHomeBannersUrls();
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  Future<void> _scanWithEdgeDetection() async {
    final dir = await getApplicationDocumentsDirectory();
    final imagePath = p.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpeg',
    );

    try {
      bool success = await EdgeDetectionPlus.detectEdge(
        imagePath,
        canUseGallery: false,
      );

      if (success && File(imagePath).existsSync()) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScanPreviewScreen(filePath: imagePath),
          ),
        );
      } else {
        debugPrint("❌ EdgeDetection cancelled or failed.");
      }
    } catch (e) {
      debugPrint("❌ EdgeDetection error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _scanWithEdgeDetection,
        child: const Icon(Icons.camera_alt_outlined),
      ),
      drawer: const HomeDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const CustomGreenClipper(),
            Container(
              height: context.height - 180,
              padding: EdgeInsets.fromLTRB(24.sp, 0, 24.sp, 24.sp),
              width: context.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  HomeBannersBlocBuilder(
                    currentIndex: currentIndex,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                  ),
                  SizedBox(height: 24.sp),
                  const HomeIcons(),
                  SizedBox(height: 24.sp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanPreviewScreen extends StatelessWidget {
  final String filePath;

  const ScanPreviewScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanned Image")),
      body: Center(
        child: Image.file(File(filePath)),
      ),
    );
  }
}
