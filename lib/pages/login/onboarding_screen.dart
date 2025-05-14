import 'loginPage.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPage = 0;
  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Explore Upcoming and Nearby Events',
      'description':
          'In publishing and graphic design, Lorem is a placeholder text commonly.',
      'image': 'assets/images/img1.png',
    },
    {
      'title': 'To Look Up More Events or\nActivities Nearby By Map',
      'description':
          'In publishing and graphic design, Lorem is a placeholder text commonly.',
      'image': 'assets/images/img2.png',
    },
    {
      'title': 'Web Have Modern Events\nCalendar Feature',
      'description':
          'In publishing and graphic design, Lorem is a placeholder text commonly.',
      'image': 'assets/images/img3.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
          ), // Background image that changes with each page
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(onboardingData[currentPage]['image']!),
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Semi-transparent overlay for better text readability

          // Bottom content area
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 305,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF5669FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(48),
                  topRight: Radius.circular(48),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          onboardingData[currentPage]['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 25.5,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          onboardingData[currentPage]['description']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignInScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                onboardingData.length,
                                (index) => GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentPage = index;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          currentPage == index
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  if (currentPage < onboardingData.length - 1) {
                                    currentPage++;
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignInScreen(),
                                      ),
                                    );
                                  }
                                });
                              },
                              child: const Text(
                                'Next',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
