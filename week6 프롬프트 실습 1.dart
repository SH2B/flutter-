import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const BrickBreakerApp());
}

class BrickBreakerApp extends StatelessWidget {
  const BrickBreakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Brick Breaker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // 게임 설정
  static const double paddleWidth = 100;
  static const double paddleHeight = 15;
  static const double ballSize = 15;
  
  // 상태 변수
  bool hasStarted = false;
  bool isGameOver = false;
  double paddleX = 0; // 화면 중앙을 0으로 기준
  double ballX = 0;
  double ballY = 0;
  double ballDx = 4.0;
  double ballDy = -4.0;
  
  // 벽돌 리스트 (Rect 객체로 저장)
  List<Rect> bricks = [];
  Timer? gameLoop;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (bricks.isEmpty) {
      _initializeBricks();
    }
  }

  void _initializeBricks() {
    final screenWidth = MediaQuery.of(context).size.width;
    const int columns = 5;
    const int rows = 4;
    final double brickWidth = (screenWidth - (columns + 1) * 10) / columns;
    const double brickHeight = 30;

    bricks.clear();
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        double dx = 10.0 + j * (brickWidth + 10);
        double dy = 50.0 + i * (brickHeight + 10);
        bricks.add(Rect.fromLTWH(dx, dy, brickWidth, brickHeight));
      }
    }
  }

  void startGame() {
    if (hasStarted) return;
    hasStarted = true;
    isGameOver = false;
    ballX = MediaQuery.of(context).size.width / 2;
    ballY = MediaQuery.of(context).size.height / 2;
    ballDx = 4.0;
    ballDy = -4.0;

    gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void updateGame() {
    final screenSize = MediaQuery.of(context).size;

    setState(() {
      ballX += ballDx;
      ballY += ballDy;

      // 벽 충돌 처리 (좌/우/상단)
      if (ballX <= 0 || ballX >= screenSize.width - ballSize) {
        ballDx = -ballDx;
      }
      if (ballY <= 0) {
        ballDy = -ballDy;
      }

      // 바닥에 닿음 (게임 오버)
      if (ballY >= screenSize.height) {
        gameLoop?.cancel();
        hasStarted = false;
        isGameOver = true;
      }

      // 패들 충돌 처리
      double paddleY = screenSize.height - 50;
      if (ballY + ballSize >= paddleY &&
          ballY + ballSize <= paddleY + paddleHeight &&
          ballX + ballSize >= paddleX &&
          ballX <= paddleX + paddleWidth) {
        ballDy = -ballDy.abs(); // 위로 튕겨냄
      }

      // 벽돌 충돌 처리
      Rect ballRect = Rect.fromLTWH(ballX, ballY, ballSize, ballSize);
      for (int i = 0; i < bricks.length; i++) {
        if (ballRect.overlaps(bricks[i])) {
          bricks.removeAt(i);
          ballDy = -ballDy;
          break; // 한 번에 하나의 벽돌만 깨도록
        }
      }

      // 게임 클리어 (모든 벽돌을 깸)
      if (bricks.isEmpty) {
        gameLoop?.cancel();
        hasStarted = false;
        _initializeBricks();
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
    final screenSize = MediaQuery.of(context).size;
    
    // 초기 패들 위치 설정
    if (!hasStarted && !isGameOver && paddleX == 0) {
      paddleX = (screenSize.width - paddleWidth) / 2;
      ballX = screenSize.width / 2 - ballSize / 2;
      ballY = screenSize.height / 2;
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            paddleX += details.delta.dx;
            // 패들이 화면 밖으로 나가지 않도록 제한
            if (paddleX < 0) paddleX = 0;
            if (paddleX > screenSize.width - paddleWidth) {
              paddleX = screenSize.width - paddleWidth;
            }
          });
        },
        onTap: startGame,
        child: Stack(
          children: [
            // 벽돌 그리기
            ...bricks.map((brick) => Positioned(
                  left: brick.left,
                  top: brick.top,
                  child: Container(
                    width: brick.width,
                    height: brick.height,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )),
            
            // 패들 그리기
            Positioned(
              left: paddleX,
              bottom: 50 - paddleHeight, // 패들 높이 보정
              child: Container(
                width: paddleWidth,
                height: paddleHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            // 공 그리기
            Positioned(
              left: ballX,
              top: ballY,
              child: Container(
                width: ballSize,
                height: ballSize,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // 시작 전 / 게임 오버 텍스트
            if (!hasStarted)
              Center(
                child: Text(
                  isGameOver ? 'GAME OVER\nTap to Restart' : 'TAP TO START',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
