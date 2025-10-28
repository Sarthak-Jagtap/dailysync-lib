import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart'; 
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:confetti/confetti.dart';

// --- CombinedHealthSummaryCard (Contains Water, Calories, and Steps) ---

class CombinedHealthSummaryCard extends StatefulWidget {
  final double waterLevel;
  final int caloriesConsumed;
  final int caloriesTarget;
  final int stepsCount;
  final int stepsTarget;

  const CombinedHealthSummaryCard({
    super.key,
    required this.waterLevel,
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.stepsCount,
    required this.stepsTarget,
  });

  @override
  State<CombinedHealthSummaryCard> createState() => _CombinedHealthSummaryCardState();
}

class _CombinedHealthSummaryCardState extends State<CombinedHealthSummaryCard> {
  late ConfettiController _confettiController;
  // State variable to track if the confetti has played for the current goal state
  bool _hasConfettiPlayed = false; 

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Helper to determine dynamic message based on health metrics
  String getDailyStatus() {
    final calProgress = (widget.caloriesConsumed / widget.caloriesTarget);
    if (calProgress >= 1.0) return "🎉 Calorie Goal Achieved!";
    if (widget.waterLevel >= 1.0) return "💧 Perfectly Hydrated!";
    if (widget.stepsCount >= widget.stepsTarget) return "🏃‍♂️ Steps Target Met!";
    
    // Default message when not all goals are met
    if (calProgress > 0.8) return "Dashboard Summary";
    return "Daily Wellness Checkup";
  }

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 220;
    
    final double calorieProgress =
        (widget.caloriesConsumed / widget.caloriesTarget).clamp(0.0, 1.0);
    final int caloriesRemaining = (widget.caloriesTarget - widget.caloriesConsumed).clamp(0, widget.caloriesTarget);
    
    final double stepsProgress =
        (widget.stepsCount / widget.stepsTarget).clamp(0.0, 1.0);

    final String statusMessage = getDailyStatus();
    final bool goalMet = widget.caloriesConsumed >= widget.caloriesTarget;

    // Confetti trigger logic
    if (goalMet) {
      if (!_hasConfettiPlayed) {
        _confettiController.play();
        _hasConfettiPlayed = true; 
      }
    } else {
      if (_hasConfettiPlayed) {
        _confettiController.stop();
        _hasConfettiPlayed = false;
      }
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0), // Space for status bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Animated Status Bar (Title/Header)
              SizedBox(
                height: 30,
                child: AnimatedTextKit(
                  key: ValueKey(statusMessage), 
                  repeatForever: true,
                  animatedTexts: [
                    FlickerAnimatedText(
                      statusMessage,
                      textStyle: TextStyle(
                        fontSize: 18.0, 
                        fontWeight: FontWeight.w800, 
                        // FIX: Using index [] for shade access
                        color: statusMessage.contains('Achieved') || statusMessage.contains('Perfectly') || statusMessage.contains('Met')
                          ? Colors.green[700]!
                          : Colors.blueGrey[800]!,
                      ),
                      speed: const Duration(milliseconds: 3000),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              /// Main Summary Card (Water | Calories + Steps)
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  height: cardHeight,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 2,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// 1. 💧 Water Bottle (Left Side)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Hydration", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          const SizedBox(height: 8),
                          Container(
                            height: cardHeight * 0.7,
                            width: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: LiquidLinearProgressIndicator(
                              value: widget.waterLevel,
                              backgroundColor: Colors.blue.shade50,
                              valueColor: const AlwaysStoppedAnimation(Color.fromARGB(255, 68, 138, 255)),
                              borderColor: Colors.blue[900]!, // FIX: Using index []
                              borderWidth: 3.0,
                              borderRadius: 16.0,
                              direction: Axis.vertical,
                              center: Text(
                                '${(widget.waterLevel * 100).round()}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),

                      /// 2. Metrics Column (Right Side)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            /// 🍕 Calorie Meter (Circular - Top)
                            CircularPercentIndicator(
                              radius: 50.0,
                              lineWidth: 12.0,
                              animation: true,
                              percent: calorieProgress,
                              center: SizedBox(
                                width: 90,
                                height: 50,
                                child: AnimatedTextKit(
                                  repeatForever: true,
                                  animatedTexts: [
                                    WavyAnimatedText(
                                      "KCAL",
                                      textStyle: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18.0,
                                          color: Colors.deepOrange[800]!), // FIX: Using index []
                                    ),
                                    TyperAnimatedText(
                                      "$caloriesRemaining Left",
                                      textStyle: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.0,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              footer: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "🔥 ${widget.caloriesConsumed} / ${widget.caloriesTarget}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 14, 
                                    color: Colors.deepOrange
                                  ),
                                ),
                              ),
                              circularStrokeCap: CircularStrokeCap.round,
                              progressColor: calorieProgress >= 1.0 ? Colors.green.shade600 : Colors.deepOrange.shade400,
                              backgroundColor: Colors.orange.shade100,
                            ),
                            
                            const SizedBox(height: 16),

                            /// 🏃 Steps Meter (Linear - Bottom)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Steps Goal',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
                                ),
                                const SizedBox(height: 4),
                                LinearPercentIndicator(
                                  animation: true,
                                  animationDuration: 1000,
                                  lineHeight: 12.0,
                                  percent: stepsProgress,
                                  center: Text(
                                    "${widget.stepsCount} / ${widget.stepsTarget}",
                                    style: const TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  linearStrokeCap: LinearStrokeCap.roundAll,
                                  progressColor: Colors.teal.shade400,
                                  backgroundColor: Colors.teal.shade100,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        /// 🎉 Confetti for milestone
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
              gravity: 0.3,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
            ),
          ),
        ),
      ],
    );
  }
}
