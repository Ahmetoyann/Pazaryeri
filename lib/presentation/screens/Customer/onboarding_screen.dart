import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  final void Function(BuildContext) onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'titleKey': 'onboarding_title_1',
      'descKey': 'onboarding_desc_1',
      'icon': Icons.map_outlined,
    },
    {
      'titleKey': 'onboarding_title_2',
      'descKey': 'onboarding_desc_2',
      'icon': Icons.storefront_outlined,
    },
    {
      'titleKey': 'onboarding_title_3',
      'descKey': 'onboarding_desc_3',
      'icon': Icons.people_outline,
    },
  ];

  Future<void> _finishOnboarding() async {
    await AuthService.instance.setOnboardingSeen();
    if (mounted) {
      widget.onDone(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Icon(
                            page['icon'],
                            size: MediaQuery.of(context).size.width * 0.25,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          langVM.translate(page['titleKey']),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          langVM.translate(page['descKey']),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sayfa göstergeleri (Dots)
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Butonlar
                  Row(
                    children: [
                      if (_currentPage < _pages.length - 1)
                        TextButton(
                          onPressed: _finishOnboarding,
                          child: Text(
                            langVM.translate('skip'),
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          } else {
                            _finishOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? langVM.translate('start')
                              : langVM.translate('next'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
