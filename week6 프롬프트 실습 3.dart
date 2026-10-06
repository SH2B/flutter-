import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const BrickBreakerApp());
}

class BrickBreakerApp extends StatelessWidget {
  const BrickBreakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}

// 벽돌의 상태와 위치 정보를 담는 클래스
class Brick {
  Rect rect;
  bool isBroken;
  Brick(this.rect, {this.isBroken = false});
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool isInitialized = false;
  bool hasStarted = false;
  bool isGameOver = false;

  double screenWidth = 0;
  double screenHeight = 0;

  // 공 변수
  double ballX = 0, ballY = 0;
  double ballDX = 5, ballDY = -5;
  final double ballSize = 15;

  // 패들 변수
  double paddleX = 0, paddleY = 0;
  final double paddleWidth = 100, paddleHeight = 20;

  // 벽돌 리스트 및 게임 루프
  List<Brick> bricks = [];
  Timer? gameLoop;

  // 화면 크기에 맞게 게임 요소들을 초기화
  void initGame(double width, double height) {
    screenWidth = width;
    screenHeight = height;

    paddleY = screenHeight - 80;
    paddleX = (screenWidth - paddleWidth) / 2;

    ballX = screenWidth / 2 - ballSize / 2;
    ballY = paddleY - ballSize;

    bricks.clear();
    int rows = 4;
    int cols = 5;
    double padding = 4;
    
    // 패딩을 고려한 벽돌 너비 동적 계산
    double brickW = (screenWidth - (padding * (cols + 1))) / cols;
    double brickH = 25;

    // 4행 5열 벽돌 배치
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        double bx = padding + c * (brickW + padding);
        double by = 60 + r * (brickH + padding);
        bricks.add(Brick(Rect.fromLTWH(bx, by, brickW, brickH)));
      }
    }

    isInitialized = true;
  }

  void resetGame() {
    setState(() {
      isInitialized = false;
      hasStarted = false;
      isGameOver = false;
    });
    gameLoop?.cancel();
  }

  void startGame() {
    setState(() {
      hasStarted = true;
      isGameOver = false;
    });
    
    // 약 60FPS (16ms) 주기의 게임 루프 실행
    gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void updateGame() {
    setState(() {
      ballX += ballDX;
      ballY += ballDY;

      // 1. 벽 충돌 처리 (좌/우/상)
      if (ballX <= 0) {
        ballX = 0;
        ballDX = ballDX.abs();
      } else if (ballX + ballSize >= screenWidth) {
        ballX = screenWidth - ballSize;
        ballDX = -ballDX.abs();
      }

      if (ballY <= 0) {
        ballY = 0;
        ballDY = ballDY.abs();
      } else if (ballY + ballSize >= screenHeight) {
        // 바닥에 닿으면 게임 오버
        isGameOver = true;
        gameLoop?.cancel();
      }

      // 충돌 판정을 위한 Rect 객체 생성
      Rect ballRect = Rect.fromLTWH(ballX, ballY, ballSize, ballSize);
      Rect paddleRect = Rect.fromLTWH(paddleX, paddleY, paddleWidth, paddleHeight);

      // 2. 패들 충돌 처리 (overlaps 활용)
      if (ballRect.overlaps(paddleRect)) {
        ballY = paddleY - ballSize; // 패들 안으로 파고드는 현상 방지
        ballDY = -ballDY.abs();
      }

      // 3. 벽돌 충돌 처리 (overlaps 활용)
      for (var brick in bricks) {
        if (!brick.isBroken && ballRect.overlaps(brick.rect)) {
          brick.isBroken = true;
          
          // 공 중심 위치에 따라 단순 반사각 계산
          double ballCenter = ballX + ballSize / 2;
          if (ballCenter > brick.rect.left && ballCenter < brick.rect.right) {
            ballDY = -ballDY; // 상하 충돌
          } else {
            ballDX = -ballDX; // 좌우 측면 충돌
          }
          break; // 한 프레임당 하나의 벽돌만 파괴되도록 처리
        }
      }
    });
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // 배경색 지정
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 화면 크기 제약조건을 받아온 후 초기화 진행
            if (!isInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  initGame(constraints.maxWidth, constraints.maxHeight);
                });
              });
              return const SizedBox.shrink();
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (isGameOver) {
                  resetGame();
                } else if (!hasStarted) {
                  startGame();
                }
              },
              onPanUpdate: (details) {
                if (hasStarted && !isGameOver) {
                  setState(() {
                    // 패들 이동 및 화면 밖 이탈 방지 (clamp)
                    paddleX += details.delta.dx;
                    paddleX = paddleX.clamp(0.0, screenWidth - paddleWidth);
                  });
                }
              },
              child: Stack(
                children: [
                  // 벽돌 렌더링
                  ...bricks.where((b) => !b.isBroken).map((brick) => Positioned(
                        left: brick.rect.left,
                        top: brick.rect.top,
                        child: Container(
                          width: brick.rect.width,
                          height: brick.rect.height,
                          color: Colors.blue,
                        ),
                      )),
                  // 패들 렌더링
                  Positioned(
                    left: paddleX,
                    top: paddleY,
                    child: Container(
                      width: paddleWidth,
                      height: paddleHeight,
                      color: Colors.white,
                    ),
                  ),
                  // 공 렌더링
                  Positioned(
                    left: ballX,
                    top: ballY,
                    child: Container(
                      width: ballSize,
                      height: ballSize,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // 상태 텍스트 오버레이
                  if (!hasStarted || isGameOver)
                    Center(
                      child: Text(
                        isGameOver ? "GAME OVER" : "TAP TO START",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
