import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class FlappyBallGame extends StatefulWidget {
  const FlappyBallGame({super.key});

  @override
  State<FlappyBallGame> createState() => _FlappyBallGameState();
}

class _FlappyBallGameState extends State<FlappyBallGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  DateTime? _lastTickTime;

  double ballY = 0.4;
  double ballVelocity = 0.0;
  double ballSize = 60.0;
  bool gameStarted = false;
  bool gameOver = false;
  int score = 0;

  // Screen dimensions (updated in build method)
  double screenWidth = 1080.0;
  double screenHeight = 2340.0;

  // Gravity and jump constants (time-based)
  final double gravityPerSecond = 0.033; // tuned from original per-frame values
  final double jumpStrength = -0.010; // gentler jump
  final double ballRotation = 0.0;

  // Obstacles (pipes)
  List<Obstacle> obstacles = [];
  double obstacleSpeedPxPerSecond = 120.0; // 2px/frame * 60fps
  double obstacleSpawnProgressPx = 0.0;
  double obstacleSpawnIntervalPx = 340.0; // horizontal distance between spawns

  // Background scrolling
  double backgroundOffset = 0.0;
  // Scoring goal
  final int targetPoints = 2025;
  bool hasWon = false;
  // Keyboard focus
  final FocusNode _focusNode = FocusNode();
  bool _spaceIsDown = false; // prevent auto-repeat jumps
  late final AudioPlayer _bgm = AudioPlayer();
  bool _musicStarted = false;
  DateTime _lastJumpAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _jumpCooldown = Duration(milliseconds: 130);
  // Cached images for smoother rendering
  final AssetImage _bgImage = const AssetImage('assets/images/cr_game.png');
  final AssetImage _fallbackBgImage = const AssetImage(
    'assets/images/background.png',
  );
  final AssetImage _ballImage = const AssetImage(
    'assets/images/bowling_ball.png',
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    )..addListener(_onTick);
    // Start ticker for smooth updates
    _controller.repeat();

    // Background music (loops, ignores errors if asset missing)
    _bgm.setReleaseMode(ReleaseMode.loop);
    // Low volume so it’s not overwhelming; you can tweak later
    _bgm.setVolume(0.35);
    // Note: On web, autoplay often requires a user gesture; we start on first input.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache frequently used images for smoother frames
    precacheImage(_bgImage, context);
    precacheImage(_fallbackBgImage, context);
    precacheImage(_ballImage, context);
  }

  void _onTick() {
    final now = DateTime.now();
    final last = _lastTickTime ?? now;
    final dt = now.difference(last).inMicroseconds / 1000000.0;
    _lastTickTime = now;
    if (gameStarted && !gameOver) {
      setState(() {
        _updateGameState(dt.clamp(0.0, 0.05));
      });
    }
  }

  void _updateGameState(double dtSeconds) {
    // Update ball physics
    ballVelocity += gravityPerSecond * dtSeconds;
    ballY += ballVelocity;

    // Keep ball within screen bounds
    if (ballY < 0) {
      ballY = 0;
      ballVelocity = 0;
      _endGame();
    } else if (ballY > 1.0 - (ballSize / screenHeight)) {
      ballY = 1.0 - (ballSize / screenHeight);
      _endGame();
    }

    // Update background scrolling
    backgroundOffset += obstacleSpeedPxPerSecond * dtSeconds;
    if (backgroundOffset > 400) {
      backgroundOffset = 0;
    }

    // Update obstacles
    for (var obstacle in obstacles) {
      obstacle.x -= obstacleSpeedPxPerSecond * dtSeconds;
    }
    obstacles.removeWhere((obstacle) => obstacle.x + obstacle.width < 0);

    // Spawn new obstacles
    obstacleSpawnProgressPx += obstacleSpeedPxPerSecond * dtSeconds;
    if (obstacleSpawnProgressPx >= obstacleSpawnIntervalPx) {
      obstacleSpawnProgressPx = 0;
      _spawnObstacle();
    }

    // Check collisions
    _checkCollisions();

    // Update score
    for (var obstacle in obstacles) {
      if (!obstacle.passed &&
          obstacle.x + obstacle.width < screenWidth / 2 - ballSize / 2) {
        obstacle.passed = true;
        score++;
        // Increase speed every 50 points (up to a cap)
        final int tiers = score ~/ 50;
        final double newSpeedPxPerSec =
            120.0 + tiers * 18.0; // +0.3px/frame => 18 px/s
        if (newSpeedPxPerSec > obstacleSpeedPxPerSecond) {
          obstacleSpeedPxPerSecond = newSpeedPxPerSec.clamp(120.0, 420.0);
        }
        if (!gameOver && score >= targetPoints) {
          hasWon = true;
          gameOver = true;
        }
      }
    }
  }

  void _spawnObstacle() {
    // Responsive gap based on screen height
    final gapSize = (screenHeight * 0.28).clamp(140.0, 260.0);
    final minTopHeight = 100.0;
    final maxTopHeight = screenHeight - gapSize - minTopHeight;

    final topHeight =
        minTopHeight + Random().nextDouble() * (maxTopHeight - minTopHeight);

    obstacles.add(
      Obstacle(
        x: screenWidth,
        topHeight: topHeight,
        gapSize: gapSize,
        width: (screenWidth * 0.12).clamp(60.0, 120.0),
      ),
    );
  }

  void _checkCollisions() {
    final ballX = screenWidth / 2 - ballSize / 2;
    final ballTop = ballY * screenHeight;
    final ballBottom = ballTop + ballSize;
    final ballLeft = ballX;
    final ballRight = ballX + ballSize;

    for (var obstacle in obstacles) {
      // Top pipe collision
      if (ballRight > obstacle.x &&
          ballLeft < obstacle.x + obstacle.width &&
          ballTop < obstacle.topHeight) {
        _endGame();
        return;
      }

      // Bottom pipe collision
      final bottomPipeTop = obstacle.topHeight + obstacle.gapSize;
      if (ballRight > obstacle.x &&
          ballLeft < obstacle.x + obstacle.width &&
          ballBottom > bottomPipeTop) {
        _endGame();
        return;
      }
    }
  }

  // (level-based helpers removed; using fixed difficulty for points-only mode)

  void _jump() {
    if (!gameStarted) {
      gameStarted = true;
    }
    _ensureMusicStarted();
    if (!gameOver) {
      final now = DateTime.now();
      if (now.difference(_lastJumpAt) < _jumpCooldown) return;
      _lastJumpAt = now;
      ballVelocity = jumpStrength;
      HapticFeedback.mediumImpact();
    }
  }

  void _endGame() {
    if (!gameOver) {
      gameOver = true;
      HapticFeedback.heavyImpact();
    }
  }

  void _resetGame() {
    setState(() {
      ballY = 0.4;
      ballVelocity = 0.0;
      gameStarted = false;
      gameOver = false;
      score = 0;
      hasWon = false;
      obstacleSpeedPxPerSecond = 120.0;
      obstacles.clear();
      obstacleSpawnProgressPx = 0.0;
      backgroundOffset = 0.0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgm.stop();
    _bgm.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    try {
      // Try a specific provided track first, then fallback to music.mp3
      try {
        await _bgm.play(AssetSource('audio/mozart.mp3'));
      } catch (_) {
        await _bgm.play(AssetSource('audio/music.mp3'));
      }
    } catch (_) {
      // Silently ignore if the asset isn't present
    }
  }

  Future<void> _ensureMusicStarted() async {
    if (_musicStarted) return;
    _musicStarted = true;
    await _playBackgroundMusic();
  }

  @override
  Widget build(BuildContext context) {
    // Window size
    final windowWidth = MediaQuery.of(context).size.width;
    final windowHeight = MediaQuery.of(context).size.height;
    // Letterboxed portrait viewport with fixed aspect ratio for consistent layout
    const double targetAspect = 9 / 16; // portrait 9:16
    double viewportWidth = windowWidth;
    double viewportHeight = windowHeight;
    if (windowWidth / windowHeight > targetAspect) {
      // Too wide -> fit height, add side bars
      viewportHeight = windowHeight;
      viewportWidth = viewportHeight * targetAspect;
    } else {
      // Too tall -> fit width, add top/bottom bars
      viewportWidth = windowWidth;
      viewportHeight = viewportWidth / targetAspect;
    }
    // Use viewport size for game logic to stay consistent across screens
    screenWidth = viewportWidth;
    screenHeight = viewportHeight;
    // Responsive ball size based on viewport
    final minDim = min(screenWidth, screenHeight);
    ballSize = min(max(minDim * 0.08, 40.0), 90.0);

    return GestureDetector(
      // Mobile/tablet: tap anywhere on the entire screen to jump
      behavior: HitTestBehavior.opaque, // Ensures taps are detected even on transparent areas
      onTapDown: (_) {
        _ensureMusicStarted();
        if (gameOver) {
          _resetGame();
        } else {
          _jump();
        }
      },
      onTap: () {
        // Also handle tap for better mobile support
        _ensureMusicStarted();
        if (gameOver) {
          _resetGame();
        } else {
          _jump();
        }
      },
      child: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (event) {
          // Desktop: spacebar to jump
          if (event.logicalKey == LogicalKeyboardKey.space) {
            if (event is RawKeyDownEvent) {
              if (!_spaceIsDown) {
                _spaceIsDown = true;
                _ensureMusicStarted();
                if (gameOver) {
                  _resetGame();
                } else {
                  _jump();
                }
              }
            } else if (event is RawKeyUpEvent) {
              _spaceIsDown = false;
            }
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              // Fullscreen background (covers entire window)
              Positioned.fill(child: _buildBackground(windowWidth, windowHeight)),
              // Game viewport (centered, letterboxed)
              Center(
                child: SizedBox(
                  width: viewportWidth,
                  height: viewportHeight,
                  child: Stack(
                    children: [
                      // Obstacles
                      ...obstacles.map(
                        (obstacle) => _buildObstacle(obstacle, screenHeight),
                      ),

                      // Bowling ball
                      Positioned(
                        left: screenWidth / 2 - ballSize / 2,
                        top: ballY * screenHeight,
                        child: _buildBall(),
                      ),

                      // Score
                      Positioned(
                        top: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'Score: $score / $targetPoints',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Confetti overlay on win
                      if (gameOver && hasWon)
                        Positioned.fill(
                          child: CustomPaint(painter: ConfettiPainter()),
                        ),

                      // Game over or start screen
                      if (gameOver)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  hasWon ? 'You Win!' : 'Game Over!',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  hasWon
                                      ? 'Ai câștigat o Rună Gratuită de Bowling'
                                      : 'Final Score: $score',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                const Text(
                                  'Tap to Restart',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (!gameStarted)
                        Container(
                          color: Colors.black26,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Flappy Ball',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                        color: Colors.black87,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Tap or Press Space to Start',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Tap or Press Space to Make Ball Go Up',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(double width, double height) {
    // Background with gradient fallback and full-image containment
    return RepaintBoundary(
      child: Stack(
        children: [
          // Full-screen image (center crop ensures coverage)
          Positioned.fill(
            child: Image(
              image: _bgImage,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) {
                return Image(
                  image: _fallbackBgImage,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBall() {
    // Try to load the bowling ball image, fallback to custom painted ball
    return Transform.rotate(
      angle: ballVelocity * 10, // Rotate based on velocity
      child: SizedBox(
        width: ballSize,
        height: ballSize,
        child: Image(
          image: _ballImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback: custom painted bowling ball with stripes
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                border: Border.all(color: Colors.yellow, width: 3),
              ),
              child: CustomPaint(painter: BowlingBallPainter()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildObstacle(Obstacle obstacle, double screenHeight) {
    return Stack(
      children: [
        // Top pipe
        Positioned(
          left: obstacle.x,
          top: 0,
          child: SizedBox(
            width: obstacle.width,
            height: obstacle.topHeight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.black87, width: 3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
            ),
          ),
        ),
        // Bottom pipe
        Positioned(
          left: obstacle.x,
          top: obstacle.topHeight + obstacle.gapSize,
          child: SizedBox(
            width: obstacle.width,
            height: screenHeight - (obstacle.topHeight + obstacle.gapSize),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.black87, width: 3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Obstacle {
  double x;
  double topHeight;
  double gapSize;
  double width;
  bool passed;

  Obstacle({
    required this.x,
    required this.topHeight,
    required this.gapSize,
    required this.width,
    this.passed = false,
  });
}

class BowlingBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    // Draw yellow stripes pattern
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw diagonal stripes
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * pi / 5) - pi / 2;
      final startX = center.dx + radius * cos(angle);
      final startY = center.dy + radius * sin(angle);
      final endX = center.dx - radius * cos(angle);
      final endY = center.dy - radius * sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // Draw finger holes
    final holePaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;

    final holeRadius = radius * 0.15;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.2, center.dy - radius * 0.2),
      holeRadius,
      holePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.1, center.dy - radius * 0.2),
      holeRadius,
      holePaint,
    );
    canvas.drawCircle(
      Offset(center.dx - radius * 0.05, center.dy + radius * 0.1),
      holeRadius * 0.9,
      holePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // static confetti layout
    for (int i = 0; i < 180; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final r = 2.0 + random.nextDouble() * 5.0;
      final color = Color.fromARGB(
        255,
        150 + random.nextInt(105),
        120 + random.nextInt(135),
        120 + random.nextInt(135),
      );
      final paint = Paint()..color = color;
      switch (i % 3) {
        case 0:
          canvas.drawCircle(Offset(dx, dy), r, paint);
          break;
        case 1:
          canvas.drawRect(
            Rect.fromCenter(center: Offset(dx, dy), width: r * 2, height: r),
            paint,
          );
          break;
        default:
          final path =
              Path()
                ..moveTo(dx, dy - r)
                ..lineTo(dx - r, dy + r)
                ..lineTo(dx + r, dy + r)
                ..close();
          canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
