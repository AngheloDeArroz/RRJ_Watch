import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContainerLevelsCard extends StatelessWidget {
  const ContainerLevelsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('container-levels')
          .doc('status')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text(
              'No container data found.',
              style: TextStyle(fontFamily: 'Lexend'),
            ),
          );
        }

        final data = snapshot.data!.data();
        final foodLevel = data?['foodLevel'] ?? 0;
        final phSolutionLevel = data?['phSolutionLevel'] ?? 0;

        return ContainerSection(
          title: 'Resource Monitor',
          children: [
            const SizedBox(height: 6),
            _ContainerPager(
              foodLevel: foodLevel,
              phSolutionLevel: phSolutionLevel,
            ),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}

class ContainerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ContainerSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.blueGrey.shade200,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black, // changed from Colors.blueGrey
                fontFamily: 'Lexend',
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ContainerPager extends StatefulWidget {
  final int foodLevel;
  final int phSolutionLevel;

  const _ContainerPager({
    required this.foodLevel,
    required this.phSolutionLevel,
  });

  @override
  State<_ContainerPager> createState() => _ContainerPagerState();
}

class _ContainerPagerState extends State<_ContainerPager> {
  final PageController controller = PageController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _ContainerCard(
        title: 'Food Container',
        level: widget.foodLevel,
        visual: _FoodImageContainer(level: widget.foodLevel),
        label: 'Food Level',
        description:
            'Pellets for feeding your aquatic pets. Keep it stocked to maintain feeding schedules.',
      ),
      _ContainerCard(
        title: 'pH Solution',
        level: widget.phSolutionLevel,
        visual: _PHBottle(level: widget.phSolutionLevel),
        label: 'pH Solution Level',
        description:
            'Automatically balances the water’s pH. Important for aquatic health and stability.',
      ),
    ];

    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: pages.length,
            controller: controller,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(left: 36.0, right: 16.0),
                child: pages[index],
              );
            },
          ),
          if (currentIndex == 0)
            const Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(Icons.chevron_right, size: 28, color: Colors.grey),
              ),
            )
          else if (currentIndex == 1)
            const Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(Icons.chevron_left, size: 28, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContainerCard extends StatelessWidget {
  final String title;
  final int level;
  final Widget visual;
  final String label;
  final String description;

  const _ContainerCard({
    required this.title,
    required this.level,
    required this.visual,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (level >= 70) {
      color = Colors.blue;
    } else if (level >= 40) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        visual,
        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      title.contains('Food') ? Icons.food_bank : Icons.science,
                      color: Colors.blueGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lexend',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Chip(
                  label: Text(
                    '$level% Full',
                    style: TextStyle(
                      color: color,
                      fontFamily: 'Lexend',
                    ),
                  ),
                  backgroundColor: color.withOpacity(0.2),
                ),
                if (level < 20)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Refill soon',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontFamily: 'Lexend',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                    fontFamily: 'Lexend',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodImageContainer extends StatefulWidget {
  final int level;
  const _FoodImageContainer({required this.level});

  @override
  State<_FoodImageContainer> createState() => _FoodImageContainerState();
}

class _FoodImageContainerState extends State<_FoodImageContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final double containerHeight = 160.0;
  final double containerWidth = 80.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int level = widget.level.clamp(0, 100);

    return SizedBox(
      width: containerWidth,
      height: containerHeight + 10,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Container shape
          Container(
            width: containerWidth,
            height: containerHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.orange.shade100, Colors.orange.shade200],
              ),
              border: Border.all(
                color: Colors.deepOrange.shade200,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),

          // Wave painter
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(
                  size: Size(containerWidth, containerHeight),
                  painter: WavePainter(
                    color: Colors.deepOrangeAccent,
                    animationValue: _controller.value,
                    levelPercent: level,
                  ),
                ),
              );
            },
          ),

          // Cap
          Positioned(
            top: 0,
            child: Container(
              width: containerWidth * 0.7,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.orange.shade800,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PHBottle extends StatefulWidget {
  final int level;
  const _PHBottle({required this.level});

  @override
  State<_PHBottle> createState() => _PHBottleState();
}

class _PHBottleState extends State<_PHBottle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final double bottleHeight = 160.0;
  final double bottleWidth = 80.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLow = widget.level < 20;

    return SizedBox(
      width: bottleWidth,
      height: bottleHeight + 10,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: bottleWidth,
            height: bottleHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
              border: Border.all(
                color: isLow ? Colors.redAccent : Colors.blueGrey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isLow
                      ? Colors.redAccent.withOpacity(0.3)
                      : Colors.blue.shade100,
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(
                  size: Size(bottleWidth, bottleHeight),
                  painter: WavePainter(
                    color: isLow ? Colors.redAccent : Colors.blueAccent,
                    animationValue: _controller.value,
                    levelPercent: widget.level,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            child: Container(
              width: bottleWidth * 0.7,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final int levelPercent;

  WavePainter({
    required this.color,
    required this.animationValue,
    required this.levelPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    double baseHeight = size.height * (1 - levelPercent / 100.0);
    double waveHeight = 6.0;
    double waveLength = size.width;

    path.moveTo(0, size.height);
    for (double x = 0.0; x <= size.width; x++) {
      double y = waveHeight *
          sin((2 * pi / waveLength) * x + animationValue * 2 * pi);
      path.lineTo(x, baseHeight + y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.levelPercent != levelPercent;
}