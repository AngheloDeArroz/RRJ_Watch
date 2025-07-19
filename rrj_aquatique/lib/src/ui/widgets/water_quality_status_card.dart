import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VisualAquariumCard extends StatelessWidget {
  const VisualAquariumCard({super.key});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance
        .collection('current-water-quality')
        .doc('live');

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No water quality data available',
                  style: TextStyle(fontFamily: 'Lexend'),
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final double? temp = (data['temperature'] as num?)?.toDouble();
        final double? ph = (data['ph'] as num?)?.toDouble();
        final double? turbidity = (data['turbidity'] as num?)?.toDouble();

        final isTempOk = temp != null && temp >= 22 && temp <= 28;
        final isPhOk = ph != null && ph >= 6.5 && ph <= 7.8;
        final isTurbidityOk = turbidity != null && turbidity < 10;
        final isHealthy = isTempOk && isPhOk && isTurbidityOk;

        // Detailed status text with reasons
        String statusText;
        if (isHealthy) {
          statusText = 'All systems stable. Water quality is optimal.';
        } else {
          List<String> issues = [];

          if (temp == null) {
            issues.add('Temperature data unavailable');
          } else if (temp < 22) {
            issues.add('Temperature is too low');
          } else if (temp > 28) {
            issues.add('Temperature is too high');
          }

          if (ph == null) {
            issues.add('pH data unavailable');
          } else if (ph < 6.5) {
            issues.add('pH is too low');
          } else if (ph > 7.8) {
            issues.add('pH is too high');
          }

          if (turbidity == null) {
            issues.add('Turbidity data unavailable');
          } else if (turbidity >= 10) {
            issues.add('Turbidity is too high');
          }

          statusText = 'Attention needed. ' + issues.join(', ') + '.';
        }

        final imageAsset = isHealthy
            ? 'assets/images/healthy.gif'
            : 'assets/images/unhealthy.gif';

        final badgeColor = isHealthy ? Colors.green : Colors.red;

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: isHealthy
                    ? Colors.blueAccent.withOpacity(0.6)
                    : Colors.redAccent.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 0),
              ),
            ],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Card(
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Background image
                Image.asset(
                  imageAsset,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                // Gradient overlay
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),

                // Status and info
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        label: Text(
                          isHealthy ? 'Healthy' : 'Unhealthy',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lexend',
                          ),
                        ),
                        backgroundColor: badgeColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Aquarium Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Lexend',
                            ),
                          ),
                          const SizedBox(width: 6),
                          HoldableTooltip(
                            message:
                                'Safe Parameters:\nTemperature: 22°C - 28°C\npH: 6.5 - 7.8\nTurbidity: < 10 NTU',
                            child: const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 250,
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontFamily: 'Lexend',
                          ),
                          softWrap: true,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Metric panel
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 1),
                        _buildMetricRow(
                          'Temp',
                          temp != null ? '${temp.toStringAsFixed(1)} °C' : '—',
                        ),
                        _buildMetricRow(
                          'pH',
                          ph != null ? '${ph.toStringAsFixed(1)}' : '—',
                        ),
                        _buildMetricRow(
                          'Turbidity',
                          turbidity != null
                              ? '${turbidity.toStringAsFixed(1)} NTU'
                              : '—',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontFamily: 'Lexend',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lexend',
            ),
          ),
        ],
      ),
    );
  }
}

class HoldableTooltip extends StatefulWidget {
  final Widget child;
  final String message;

  const HoldableTooltip({super.key, required this.child, required this.message});

  @override
  State<HoldableTooltip> createState() => _HoldableTooltipState();
}

class _HoldableTooltipState extends State<HoldableTooltip> {
  OverlayEntry? _overlayEntry;

  void _showTooltip() {
    if (_overlayEntry != null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context);

    if (renderBox == null || overlay == null) return;

    final target = renderBox.localToGlobal(renderBox.size.topCenter(Offset.zero));

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: target.dy - 90,
        left: target.dx - 70,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _showTooltip();
      },
      onTapUp: (_) {
        _hideTooltip();
      },
      onTapCancel: () {
        _hideTooltip();
      },
      child: widget.child,
    );
  }
}
