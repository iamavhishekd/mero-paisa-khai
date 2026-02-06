import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paisa_khai/blocs/settings/settings_bloc.dart';
import 'package:paisa_khai/blocs/source/source_bloc.dart';
import 'package:paisa_khai/blocs/transaction/transaction_bloc.dart';
import 'package:paisa_khai/models/source.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:paisa_khai/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

  // Step 4: Sources
  final List<Source> _tempSources = [];
  bool _isProcessing = false;
  final TextEditingController _sourceNameController = TextEditingController();
  final TextEditingController _initialBalanceController =
      TextEditingController();
  SourceType _selectedSourceType = SourceType.bank;

  // Animation for card swipe
  double _swipeOffset = 0;
  bool _isSwiping = false;

  // Color palette for cards
  static const List<String> _cardColors = [
    '0xFF6366F1', // Indigo
    '0xFFEC4899', // Pink
    '0xFF10B981', // Emerald
    '0xFFF59E0B', // Amber
    '0xFF3B82F6', // Blue
    '0xFF8B5CF6', // Violet
    '0xFFEF4444', // Red
    '0xFF14B8A6', // Teal
    '0xFFF97316', // Orange
    '0xFF84CC16', // Lime
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _sourceNameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    // Prevent moving past sources screen (index 4) without adding at least one source
    if (_currentPage == 4 && _tempSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one wallet to continue'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentPage < _totalPages - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isProcessing) return;

    if (_tempSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one source to continue'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      unawaited(
        _pageController.animateToPage(
          4,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate a small delay for better UX and to ensure state updates
      await Future<dynamic>.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      for (final source in _tempSources) {
        context.read<SourceBloc>().add(AddSource(source));

        if (source.initialBalance != 0) {
          final initialTx = Transaction(
            id: const Uuid().v4(),
            title: 'Initial Balance - ${source.name}',
            amount: source.initialBalance.abs(),
            date: DateTime.now(),
            type: source.initialBalance > 0
                ? TransactionType.income
                : TransactionType.expense,
            category: 'Initial Balance',
            sources: [
              TransactionSourceSplit(
                sourceId: source.id,
                amount: source.initialBalance.abs(),
              ),
            ],
          );
          context.read<TransactionBloc>().add(AddTransaction(initialTx));
        }
      }

      context.read<SettingsBloc>().add(CompleteOnboarding());

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing onboarding: $e')),
        );
      }
    }
  }

  void _addSource() {
    final name = _sourceNameController.text.trim();
    final balanceStr = _initialBalanceController.text.trim();
    final balance = double.tryParse(balanceStr) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a source name')),
      );
      return;
    }

    final newSource = Source(
      id: const Uuid().v4(),
      name: name,
      type: _selectedSourceType,
      icon: _getIconForType(_selectedSourceType),
      color: _cardColors[_tempSources.length % _cardColors.length],
      initialBalance: balance,
    );

    setState(() {
      _tempSources.insert(0, newSource);
      _sourceNameController.clear();
      _initialBalanceController.clear();
    });

    FocusScope.of(context).unfocus();
  }

  String _getIconForType(SourceType type) {
    switch (type) {
      case SourceType.bank:
        return '🏛️';
      case SourceType.wallet:
        return '👛';
      case SourceType.cash:
        return '💵';
    }
  }

  void _handleSwipeUp() {
    if (_tempSources.length < 2) return;
    setState(() {
      final top = _tempSources.removeAt(0);
      _tempSources.add(top);
    });
  }

  void _handleSwipeDown() {
    if (_tempSources.length < 2) return;
    setState(() {
      final bottom = _tempSources.removeLast();
      _tempSources.insert(0, bottom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Background Decorative Orbs
            if (isDark) ...[
              Positioned(
                top: -100,
                right: -100,
                child: _buildOrb(
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  400,
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: _buildOrb(
                  theme.colorScheme.secondary.withValues(alpha: 0.1),
                  500,
                ),
              ),
            ] else ...[
              Positioned(
                top: -100,
                right: -100,
                child: _buildOrb(
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                  400,
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: _buildOrb(
                  theme.colorScheme.secondary.withValues(alpha: 0.05),
                  500,
                ),
              ),
            ],

            // Blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),

            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      physics: const ClampingScrollPhysics(),
                      clipBehavior: Clip.none,
                      children: [
                        _buildIntroStep(theme),
                        _buildFeaturesStep(theme),
                        _buildSecurityStep(theme),
                        _buildNotificationsStep(theme),
                        _buildSourcesStep(theme, isDark),
                        _buildFinalStep(theme, isDark),
                      ],
                    ),
                  ),
                  _buildFooter(theme, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildIntroStep(ThemeData theme) {
    return _buildResponsiveFlexStep(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Paisa Khai?',
      description:
          'Stop wondering where your money went. Start tracking every penny with elegance and precision.',
      theme: theme,
    );
  }

  Widget _buildFeaturesStep(ThemeData theme) {
    return _buildResponsiveFlexStep(
      icon: Icons.auto_graph_rounded,
      title: 'Deep Insights',
      description:
          'Visualize your spending habits with intuitive charts, trends, and detailed category reports.',
      theme: theme,
    );
  }

  Widget _buildSecurityStep(ThemeData theme) {
    return _buildResponsiveFlexStep(
      icon: Icons.security_rounded,
      title: 'Private & Secure',
      description:
          'Your financial data stays 100% on your device. We respect your privacy above all else.',
      theme: theme,
    );
  }

  Widget _buildNotificationsStep(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLarge = constraints.maxWidth > 800;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isLarge ? 40 : 24),
          child: isLarge
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepIcon(
                      Icons.notifications_active_rounded,
                      theme,
                      120,
                    ),
                    const SizedBox(width: 60),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepText(
                            'Stay Notified',
                            'Receive daily reminders to track your expenses and get insights into your financial health.',
                            theme,
                            true,
                            true,
                          ),
                          const SizedBox(height: 24),
                          _buildPermissionButton(theme),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepIcon(
                      Icons.notifications_active_rounded,
                      theme,
                      80,
                    ),
                    const SizedBox(height: 32),
                    _buildStepText(
                      'Stay Notified',
                      'Receive daily reminders to track your expenses and get insights into your financial health.',
                      theme,
                      false,
                      false,
                    ),
                    const SizedBox(height: 28),
                    _buildPermissionButton(theme),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPermissionButton(ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: () async {
        await NotificationService().requestPermissions();
        // Skip if user already enabled or just to move forward implicitly
        if (!mounted) return;
        await _nextPage();
      },
      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
      label: const Text('ENABLE NOTIFICATIONS'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildResponsiveFlexStep({
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLarge = constraints.maxWidth > 800;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isLarge ? 40 : 24),
          child: isLarge
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepIcon(icon, theme, 120),
                    const SizedBox(width: 60),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: _buildStepText(
                        title,
                        description,
                        theme,
                        true,
                        true,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepIcon(icon, theme, 80),
                    const SizedBox(height: 32),
                    _buildStepText(title, description, theme, false, false),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStepIcon(IconData icon, ThemeData theme, double size) {
    return Container(
      padding: EdgeInsets.all(size / 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Icon(icon, size: size, color: theme.colorScheme.primary),
    );
  }

  Widget _buildStepText(
    String title,
    String description,
    ThemeData theme,
    bool isLarge,
    bool alignLeft,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isLarge ? 56 : 32,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isLarge ? 24 : 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSourcesStep(ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLarge = constraints.maxWidth > 900;

        if (isLarge) {
          // Desktop/Web: Side-by-side layout, vertically centered
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Wallets',
                            style: GoogleFonts.outfit(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add your regular income sources.\nSwipe the cards to cycle through.',
                            style: TextStyle(
                              fontSize: 20,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 48),
                          _buildAddSourceCard(theme, true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 60),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: SizedBox(
                            height: 400,
                            child: _buildCardStackArea(theme, true),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Mobile/Tablet: Single column, vertically centered
        return Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Wallets',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),
                _buildAddSourceCard(theme, false),
                const SizedBox(height: 32),
                SizedBox(
                  height: 280,
                  child: _buildCardStackArea(theme, false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardStackArea(ThemeData theme, bool isLarge) {
    if (_tempSources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Ensure minimum vertical size
          children: [
            Icon(
              Icons.add_card_rounded,
              size: isLarge ? 100 : 80, // Responsive icon size
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12), // Reduced spacing
            Flexible(
              // Allow text to wrap if needed
              child: Text(
                'No wallets added yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  fontSize: isLarge ? 20 : 16, // Responsive font size
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _swipeOffset += details.delta.dy;
          _isSwiping = true;
        });
      },
      onVerticalDragEnd: (details) {
        if (_swipeOffset.abs() > 80) {
          if (_swipeOffset < 0) {
            _handleSwipeUp();
          } else {
            _handleSwipeDown();
          }
        }
        setState(() {
          _swipeOffset = 0;
          _isSwiping = false;
        });
      },
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: _tempSources
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key;
                final source = entry.value;

                if (index > 4) return const SizedBox.shrink();

                final bool isTop = index == 0;
                final double activeOffset = isTop ? _swipeOffset : 0;
                final double passiveOffset = isTop
                    ? 0
                    : (_swipeOffset.abs() / 150) * 20;

                return AnimatedPositioned(
                  key: ValueKey(source.id),
                  duration: _isSwiping
                      ? Duration.zero
                      : const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  top:
                      (index * (isLarge ? 40.0 : 30.0)) +
                      activeOffset -
                      passiveOffset,
                  left: 0,
                  right: 0,
                  child: AnimatedScale(
                    duration: _isSwiping
                        ? Duration.zero
                        : const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    scale: 1.0 - (index * 0.08) + (passiveOffset / 400),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: 1.0 - (index * 0.2),
                      child: _buildCreditCard(source, theme, index, isLarge),
                    ),
                  ),
                );
              })
              .toList()
              .reversed
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAddSourceCard(ThemeData theme, bool isLarge) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 32 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(isLarge ? 24 : 16),
        boxShadow: [
          if (theme.brightness == Brightness.dark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sourceNameController,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Source Name',
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.05,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isLarge ? 16 : 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButton<SourceType>(
                  value: _selectedSourceType,
                  underline: const SizedBox(),
                  onChanged: (val) =>
                      setState(() => _selectedSourceType = val!),
                  items: SourceType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            _getIconForType(type),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _initialBalanceController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Balance',
                    prefixText: 'Rs. ',
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.05,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isLarge ? 16 : 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addSource,
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text('ADD'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface,
                  foregroundColor: theme.colorScheme.surface,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isLarge ? 18 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(
    Source source,
    ThemeData theme,
    int index,
    bool isLarge,
  ) {
    final color = Color(int.parse(source.color));
    final String lastFour = (source.id.hashCode % 10000).toString().padLeft(
      4,
      '0',
    );

    return Container(
      height: isLarge ? 280 : 220,
      width: double.infinity,
      padding: EdgeInsets.all(isLarge ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARD HOLDER',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      source.name.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              _buildCardBrand(source.type),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _buildChip(),
              const SizedBox(width: 24),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '****  ****  ****  $lastFour',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: isLarge ? 28 : 22,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BALANCE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rs. ${source.initialBalance.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: isLarge ? 44 : 28,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index == 0)
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    onPressed: () =>
                        setState(() => _tempSources.removeAt(index)),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBrand(SourceType type) {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _getIconForType(type),
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildChip() {
    return Container(
      width: 50,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [Colors.yellow.shade200, Colors.yellow.shade700],
        ),
      ),
      child: Stack(
        children: List.generate(
          4,
          (i) => Positioned(
            left: i * 12.0 + 6,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: Colors.black12),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalStep(ThemeData theme, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepIcon(Icons.auto_awesome_rounded, theme, 120),
                const SizedBox(height: 32),
                Text(
                  'Choose your vibe',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: MediaQuery.of(context).size.width > 600 ? 56 : 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 56),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isLarge = constraints.maxWidth > 700;
                    return isLarge
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildThemeOption(
                                  ThemeMode.light,
                                  'Light Mode',
                                  'Clean and bright',
                                  Icons.light_mode_rounded,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildThemeOption(
                                  ThemeMode.dark,
                                  'Dark Mode',
                                  'Easy on the eyes',
                                  Icons.dark_mode_rounded,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildThemeOption(
                                  ThemeMode.system,
                                  'System Settings',
                                  'Follow device',
                                  Icons.brightness_auto_rounded,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildThemeOption(
                                ThemeMode.light,
                                'Light Mode',
                                'Clean and bright experience',
                                Icons.light_mode_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildThemeOption(
                                ThemeMode.dark,
                                'Dark Mode',
                                'Easy on the eyes, sleek look',
                                Icons.dark_mode_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildThemeOption(
                                ThemeMode.system,
                                'System Settings',
                                'Follow your device settings',
                                Icons.brightness_auto_rounded,
                              ),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    ThemeMode mode,
    String label,
    String description,
    IconData icon,
  ) {
    final isSelected = context.watch<SettingsBloc>().state.themeMode == mode;
    return _ThemeOption(
      label: label,
      description: description,
      icon: icon,
      isSelected: isSelected,
      onTap: () => context.read<SettingsBloc>().add(UpdateThemeMode(mode)),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 500;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 24 : 60,
            vertical: isSmall ? 24 : 48,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isSmall)
                    Row(
                      children: List.generate(
                        _totalPages,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 14),
                          width: _currentPage == index ? 48 : 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: List.generate(
                        _totalPages,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          width: _currentPage == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 20 : 32,
                        vertical: isSmall ? 14 : 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
                      ),
                      backgroundColor: theme.colorScheme.onSurface,
                      foregroundColor: theme.colorScheme.surface,
                      elevation: 0,
                      textStyle: GoogleFonts.outfit(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isSmall ? 14 : 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.black, // Since initial theme is light
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == _totalPages - 1
                                    ? 'GET STARTED'
                                    : 'CONTINUE',
                              ),
                              SizedBox(width: isSmall ? 8 : 12),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: isSmall ? 20 : 24,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                size: 32,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 16,
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
}
