import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BrickBreakerGame(),
  ));
}

class BrickBreakerGame extends StatefulWidget {
  const BrickBreakerGame({Key? key}) : super(key: key);

  @override
  State<BrickBreakerGame> createState() => _BrickBreakerGameState();
}

class Brick {
  Rect rect;
  bool isDestroyed;
  Brick({required this.rect, this.isDestroyed = false});
}

class _BrickBreakerGameState extends State<BrickBreakerGame> {
  bool isPlaying = false;
  bool isGameOver = false;
  bool isVictory = false;

  double screenWidth = 0;
  double screenHeight = 0;

  // 공 변수
  double ballX = 0;
  double ballY = 0;
  double ballSize = 16;
  double ballDx = 4;
  double ballDy = -4;

  // 패들 변수
  double paddleX = 0;
  double paddleY = 0;
  double paddleWidth = 100;
  double paddleHeight = 16;

  // 벽돌 변수
  List<Brick> bricks = [];
  final int rows = 4;
  final int cols = 5;

  Timer? _timer;

  void initGame(double width, double height) {
    screenWidth = width;
    screenHeight = height;

    // 패들 초기 위치 (화면 하단 중앙)
    paddleWidth = screenWidth * 0.25; // 화면 비율에 맞게 패들 크기 조정
    paddleX = (screenWidth - paddleWidth) / 2;
    paddleY = screenHeight - 80;

    // 공 초기 위치 (패들 바로 위)
    ballX = (screenWidth - ballSize) / 2;
    ballY = paddleY - ballSize - 10;
    ballDx = 5;
    ballDy = -5;

    // 벽돌 동적 배치 (4행 5열)
    double padding = 8.0;
    double brickWidth = (screenWidth - (padding * (cols + 1))) / cols;
    double brickHeight = 24.0;

    bricks.clear();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        double bx = padding + c * (brickWidth + padding);
        double by = 60.0 + r * (brickHeight + padding);
        bricks.add(Brick(rect: Rect.fromLTWH(bx, by, brickWidth, brickHeight)));
      }
    }
  }

  void startGame() {
    if (isPlaying) return;
    setState(() {
      isPlaying = true;
      isGameOver = false;
      isVictory = false;
    });

    // 16ms(약 60FPS) 주기로 게임 루프 실행
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void updateGame() {
    setState(() {
      // 공 이동
      ballX += ballDx;
      ballY += ballDy;

      // 플러터 내장 Rect를 이용한 충돌 판정용 객체 생성
      Rect ballRect = Rect.fromLTWH(ballX, ballY, ballSize, ballSize);
      Rect paddleRect = Rect.fromLTWH(paddleX, paddleY, paddleWidth, paddleHeight);

      // 1. 벽 충돌 감지
      if (ballX <= 0 || ballX + ballSize >= screenWidth) {
        ballDx = -ballDx; // 좌우 벽
      }
      if (ballY <= 0) {
        ballDy = -ballDy; // 천장
      }

      // 2. 바닥 충돌 (게임 오버)
      if (ballY + ballSize >= screenHeight) {
        isGameOver = true;
        isPlaying = false;
        _timer?.cancel();
      }

      // 3. 패들 충돌 감지 (overlaps 활용)
      if (ballRect.overlaps(paddleRect)) {
        ballDy = -ballDy.abs(); // 무조건 위로 튕겨내기
      }

      // 4. 벽돌 충돌 감지 (overlaps 활용)
      bool hitBrick = false;
      for (var brick in bricks) {
        if (!brick.isDestroyed && ballRect.overlaps(brick.rect)) {
          brick.isDestroyed = true;
          hitBrick = true;
          break; // 한 프레임에 여러 벽돌이 동시에 깨지는 현상 방지
        }
      }

      if (hitBrick) {
        ballDy = -ballDy; // 벽돌을 맞추면 방향 전환
      }

      // 5. 게임 클리어(승리) 조건
      if (bricks.every((b) => b.isDestroyed)) {
        isVictory = true;
        isPlaying = false;
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // 어두운 배경
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 최초 빌드 시 화면 크기 측정 및 초기화
          if (screenWidth == 0) {
            initGame(constraints.maxWidth, constraints.maxHeight);
          }

          return GestureDetector(
            onPanUpdate: (details) {
              if (isPlaying) {
                setState(() {
                  // 유저 컨트롤: 드래그하는 만큼 패들 이동 및 화면 밖 이탈 방지
                  paddleX += details.delta.dx;
                  if (paddleX < 0) paddleX = 0;
                  if (paddleX + paddleWidth > screenWidth) {
                    paddleX = screenWidth - paddleWidth;
                  }
                });
              }
            },
            onTap: () {
              // 화면 터치로 게임 시작 및 재시작
              if (!isPlaying && !isGameOver && !isVictory) {
                startGame();
              } else if (isGameOver || isVictory) {
                initGame(constraints.maxWidth, constraints.maxHeight);
                startGame();
              }
            },
            child: Stack(
              children: [
                // 벽돌 렌더링
                for (var brick in bricks)
                  if (!brick.isDestroyed)
                    Positioned(
                      left: brick.rect.left,
                      top: brick.rect.top,
                      width: brick.rect.width,
                      height: brick.rect.height,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                // 패들 렌더링
                Positioned(
                  left: paddleX,
                  top: paddleY,
                  width: paddleWidth,
                  height: paddleHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                // 공 렌더링
                Positioned(
                  left: ballX,
                  top: ballY,
                  width: ballSize,
                  height: ballSize,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // UI: 게임 시작 전
                if (!isPlaying && !isGameOver && !isVictory)
                  const Center(
                    child: Text(
                      "TAP TO START",
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),

                // UI: 게임 오버
                if (isGameOver)
                  const Center(
                    child: Text(
                      "GAME OVER\nTap to Restart",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),

                // UI: 게임 클리어
                if (isVictory)
                  const Center(
                    child: Text(
                      "CLEAR!\nTap to Restart",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueAccent, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
