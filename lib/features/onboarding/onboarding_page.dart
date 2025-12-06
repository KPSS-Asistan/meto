import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              left: -323,
              bottom: 0,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF1F4FF),
                    width: 2,
                  ),
                ),
              ),
            ),
            Positioned(
              left: -264,
              bottom: 60,
              child: Container(
                width: 372,
                height: 372,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF1F4FF),
                    width: 2,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -200,
              top: -200,
              child: Container(
                width: 496,
                height: 496,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF8F9FF),
                    width: 3,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -300,
              top: -380,
              child: Container(
                width: 635,
                height: 635,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF8F9FF),
                ),
              ),
            ),
            // Main content
            Column(
              children: [
                const SizedBox(height: 60),
                // Logo - Optimize edilmiş
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 280,
                    height: 280,
                    cacheWidth: 560, // 2x için optimize
                    cacheHeight: 560,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                // Texts
                Text(
                  'KPSS Sınavına\nHazırlanın',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.3,
                    letterSpacing: -0.5,
                    fontFamily:
                        Theme.of(context).textTheme.headlineLarge?.fontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'KPSS 2026 sınavına hazırlanmanın\nen kolay ve etkili yolu',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF666666),
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 60),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Login button
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFCBD6FF),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => context.go('/auth'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Giriş Yap',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      // Register button
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () => context.go('/register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0A0A0A),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Kayıt Ol',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
