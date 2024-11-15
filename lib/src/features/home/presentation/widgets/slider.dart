import 'dart:async'; // Import the 'dart:async' library to use the Timer class

import 'package:flutter/material.dart';

class MySlider extends StatefulWidget {
  const MySlider({Key? key}) : super(key: key);

  @override
  State<MySlider> createState() {
    return _MySliderState();
  }
}

class _MySliderState extends State<MySlider> {
  PageController _pageController = PageController(viewportFraction: 0.87, initialPage: 1);
  int activePage = 0;
  List<String> images = [
    "assets/images/img_top1.jpeg",
    "assets/images/img_top3.jpeg",
    "assets/images/img_top2.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.87);
    // Start autoplay when the widget is built
    startAutoplay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Autoplay configuration
  final int _autoplayDurationMilliseconds = 4000;
  Timer? _timer;

  void startAutoplay() {
    _timer = Timer.periodic(Duration(milliseconds: _autoplayDurationMilliseconds), (timer) {
      if (_pageController.hasClients) {
        if (activePage == images.length - 1) {
          _pageController.animateToPage(0,
              duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
        } else {
          _pageController.nextPage(
              duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
        }
      }
    });
  }

  AnimatedContainer slider(images, pagePosition, active) {
    double margin = active ? 0 : 10;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage(
              '${(images[pagePosition])}',
            ),
            fit: BoxFit.fill),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  List<Widget> indicators(imagesLength, currentIndex) {
    return List<Widget>.generate(imagesLength, (index) {
      return Container(
        margin: const EdgeInsets.all(3),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            color: currentIndex == index ? Colors.black : Colors.black26, shape: BoxShape.circle),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          height: MediaQuery.of(context).size.width * 0.45,
          child: PageView.builder(
            itemCount: images.length,
            pageSnapping: true,
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                activePage = page;
              });
            },
            itemBuilder: (context, pagePosition) {
              bool active = pagePosition == activePage;
              return slider(images, pagePosition, active);
            },
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: indicators(images.length, activePage),
        )
      ],
    );
  }
}
