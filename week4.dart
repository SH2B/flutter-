import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SnakeGameScreen(),
    );
  }
}

class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({super.key});

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen> {
  // 키보드 입력을 받기 위한 FocusNode
  final FocusNode _focusNode = FocusNode();

  // 게임 그리드 설정
  final int rowSize = 20; // 한 줄에 들어갈 칸 수
  final int totalCells = 400; // 전체 칸 수 (20 * 20)

  // 게임 상태 변수
  List<int> snakePosition = []; // 지렁이의 몸통 위치를 저장하는 배열 (0번 인덱스가 머리)
  int foodPosition = -1; // 먹이 위치
  String currentDirection = 'right'; // 현재 이동 방향
  bool canChangeDirection = true; // 빠르게 키를 두 번 눌러 자살하는 버그 방지용

  bool hasStarted = false;
  bool isGameOver = false;
  int score = 0;

  Timer? gameTimer;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _initGameSetup();
  }

  // 초기 상태 세팅
  void _initGameSetup() {
    // 처음 지렁이 위치 (화면 중앙쯤 3칸 길이)
    snakePosition = [
      45, // 머리
      44, // 몸통
      43, // 꼬리
    ];
    currentDirection = 'right';
    _spawnFood();
  }

  // 게임 시작
  void startGame() {
    setState(() {
      hasStarted = true;
      isGameOver = false;
      score = 0;
      _initGameSetup();
    });

    _focusNode.requestFocus(); // 키보드 입력 활성화

    // 게임 루프 타이머 (속도 조절 가능 - 현재 150ms)
    gameTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      _updateGame();
    });
  }

  // 먹이 랜덤 생성
  void _spawnFood() {
    while (true) {
      foodPosition = random.nextInt(totalCells);
      // 먹이가 지렁이 몸 위에 생성되지 않도록 검사
      if (!snakePosition.contains(foodPosition)) {
        break;
      }
    }
  }

  // 매 틱(Tick)마다 게임 상태 업데이트
  void _updateGame() {
    setState(() {
      int currentHead = snakePosition.first;
      int nextHead = -1;

      // 1. 다음으로 이동할 머리의 위치 계산
      switch (currentDirection) {
        case 'up':
          nextHead = currentHead - rowSize;
          break;
        case 'down':
          nextHead = currentHead + rowSize;
          break;
        case 'left':
          nextHead = currentHead - 1;
          break;
        case 'right':
          nextHead = currentHead + 1;
          break;
      }

      // 2. 충돌 검사 (벽 또는 자기 자신의 몸)
      if (_checkCollision(currentHead, nextHead)) {
        _gameOver();
        return;
      }

      // 3. 지렁이 이동 처리 (새로운 머리를 배열 맨 앞에 추가)
      snakePosition.insert(0, nextHead);

      // 4. 먹이를 먹었는지 확인
      if (nextHead == foodPosition) {
        score += 10;
        _spawnFood(); // 새 먹이 생성 (꼬리는 자르지 않으므로 길이가 늘어남)
      } else {
        snakePosition.removeLast(); // 먹이를 안 먹었다면 꼬리를 잘라 이동 효과를 줌
      }

      // 방향 전환 가능 상태 초기화
      canChangeDirection = true;
    });
  }

  // 충돌 감지 로직
  bool _checkCollision(int currentHead, int nextHead) {
    // 1. 벽 충돌 검사
    if (currentDirection == 'up' && nextHead < 0) return true;
    if (currentDirection == 'down' && nextHead >= totalCells) return true;
    if (currentDirection == 'left' && currentHead % rowSize == 0) return true;
    if (currentDirection == 'right' && (currentHead + 1) % rowSize == 0)
      return true;

    // 2. 자기 몸 충돌 검사 (머리가 몸통 좌표 어딘가에 겹쳤는지)
    // 꼬리 부분은 이동 시 사라지므로 몸통 전체만 비교
    for (int i = 0; i < snakePosition.length; i++) {
      if (nextHead == snakePosition[i]) {
        return true;
      }
    }

    return false;
  }

  // 게임 오버 처리
  void _gameOver() {
    gameTimer?.cancel();
    setState(() {
      isGameOver = true;
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 배경색 지정
      body: SafeArea(
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          // 키보드 방향키 입력 처리
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && canChangeDirection) {
              if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
                  currentDirection != 'down') {
                currentDirection = 'up';
                canChangeDirection = false;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
                  currentDirection != 'up') {
                currentDirection = 'down';
                canChangeDirection = false;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                  currentDirection != 'right') {
                currentDirection = 'left';
                canChangeDirection = false;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
                  currentDirection != 'left') {
                currentDirection = 'right';
                canChangeDirection = false;
              }
            }
            return KeyEventResult.handled;
          },
          child: Column(
            children: [
              // 1. 점수 표시 영역
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'SCORE: $score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 2. 게임 플레이(그리드) 영역
              Expanded(
                flex: 4,
                child: GestureDetector(
                  onTap: () {
                    if (!hasStarted || isGameOver) startGame();
                  },
                  child: AspectRatio(
                    aspectRatio: 1.0, // 바둑판을 정사각형 비율로 유지
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade800,
                          width: 2,
                        ), // 경기장 테두리
                      ),
                      child: Stack(
                        children: [
                          // 격자 생성
                          GridView.builder(
                            physics:
                                const NeverScrollableScrollPhysics(), // 스크롤 방지
                            itemCount: totalCells,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: rowSize, // 가로로 20칸
                                ),
                            itemBuilder: (context, index) {
                              if (snakePosition.contains(index)) {
                                // 지렁이 몸통/머리 렌더링
                                bool isHead = index == snakePosition.first;
                                return Container(
                                  padding: const EdgeInsets.all(2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      color: isHead
                                          ? Colors.lightGreenAccent
                                          : Colors.green, // 머리는 조금 더 밝게
                                    ),
                                  ),
                                );
                              } else if (foodPosition == index) {
                                // 먹이 렌더링
                                return Container(
                                  padding: const EdgeInsets.all(2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(color: Colors.redAccent),
                                  ),
                                );
                              } else {
                                // 빈 공간
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.05),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.1),
                                    ), // 옅은 격자무늬
                                  ),
                                );
                              }
                            },
                          ),

                          // 게임 시작 전 / 오버 시 오버레이 UI
                          if (!hasStarted || isGameOver)
                            Container(
                              color: Colors.black54, // 반투명 배경
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    !hasStarted ? 'SNAKE GAME' : 'GAME OVER',
                                    style: TextStyle(
                                      color: !hasStarted
                                          ? Colors.white
                                          : Colors.redAccent,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    '화면을 탭하여 시작\n\n[조작 방법]\n방향키 ↑ ↓ ← → : 이동',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. 하단 여백 영역
              const Expanded(flex: 1, child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
