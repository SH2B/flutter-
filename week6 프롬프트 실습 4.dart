import 'package:flutter/material.dart';

void main() {
  runApp(const GomokuApp());
}

class GomokuApp extends StatelessWidget {
  const GomokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오목 게임',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GomokuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GomokuScreen extends StatefulWidget {
  const GomokuScreen({super.key});

  @override
  State<GomokuScreen> createState() => _GomokuScreenState();
}

class _GomokuScreenState extends State<GomokuScreen> {
  static const int boardSize = 15;
  // 0: 빈칸, 1: 흑(Black), 2: 백(White)
  late List<List<int>> board;
  int currentPlayer = 1; 
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    _initBoard();
  }

  void _initBoard() {
    board = List.generate(boardSize, (_) => List.filled(boardSize, 0));
    currentPlayer = 1;
    gameOver = false;
  }

  void _resetGame() {
    setState(() {
      _initBoard();
    });
  }

  void _handleTap(TapUpDetails details, Size size) {
    if (gameOver) return;

    double cellSize = size.width / boardSize;
    // 터치한 위치를 인덱스로 변환
    int col = (details.localPosition.dx / cellSize).floor();
    int row = (details.localPosition.dy / cellSize).floor();

    // 보드 범위 안이고, 빈 공간일 경우에만 돌을 놓음
    if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
      if (board[row][col] == 0) {
        setState(() {
          board[row][col] = currentPlayer;

          if (_checkWin(row, col, currentPlayer)) {
            gameOver = true;
          } else {
            // 턴 변경
            currentPlayer = currentPlayer == 1 ? 2 : 1;
          }
        });
      }
    }
  }

  // 승리 판정 로직
  bool _checkWin(int r, int c, int player) {
    // 4가지 방향 (가로, 세로, 우하단 대각선, 우상단 대각선)
    final directions = [
      [0, 1],  // 가로
      [1, 0],  // 세로
      [1, 1],  // 대각선 \
      [1, -1]  // 대각선 /
    ];

    for (var dir in directions) {
      int count = 1; // 방금 놓은 돌 1개 포함

      // 한쪽 방향으로 연속된 돌 개수 세기
      int dr = dir[0];
      int dc = dir[1];
      
      // 정방향 체크
      int i = r + dr;
      int j = c + dc;
      while (i >= 0 && i < boardSize && j >= 0 && j < boardSize && board[i][j] == player) {
        count++;
        i += dr;
        j += dc;
      }

      // 역방향 체크
      i = r - dr;
      j = c - dc;
      while (i >= 0 && i < boardSize && j >= 0 && j < boardSize && board[i][j] == player) {
        count++;
        i -= dr;
        j -= dc;
      }

      // 5개 이상 연속되면 승리 (표준 오목의 '정확히 5개(육목 금지)' 룰은 제외한 심플 버전)
      if (count >= 5) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    String statusText;
    if (gameOver) {
      statusText = currentPlayer == 1 ? '🎉 흑돌 승리! 🎉' : '🎉 백돌 승리! 🎉';
    } else {
      statusText = currentPlayer == 1 ? '흑돌 차례입니다' : '백돌 차례입니다';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('오목 (Gomoku)'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: gameOver ? Colors.redAccent : Colors.black,
              ),
            ),
            const SizedBox(height: 30),
            // 오목판 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapUp: (details) => _handleTap(details, constraints.biggest),
                      child: CustomPaint(
                        size: constraints.biggest,
                        painter: BoardPainter(board),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _resetGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('게임 다시 시작', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// 오목판 및 돌을 그리는 CustomPainter
class BoardPainter extends CustomPainter {
  final List<List<int>> board;
  final int boardSize = 15;

  BoardPainter(this.board);

  @override
  void paint(Canvas canvas, Size size) {
    double cellSize = size.width / boardSize;

    // 1. 오목판 배경색 (나무색 느낌)
    Paint bgPaint = Paint()..color = const Color(0xFFDCB35C);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. 격자 선 그리기
    Paint linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    for (int i = 0; i < boardSize; i++) {
      double pos = i * cellSize + (cellSize / 2);
      // 가로선
      canvas.drawLine(
        Offset(cellSize / 2, pos), 
        Offset(size.width - (cellSize / 2), pos), 
        linePaint
      );
      // 세로선
      canvas.drawLine(
        Offset(pos, cellSize / 2), 
        Offset(pos, size.height - (cellSize / 2)), 
        linePaint
      );
    }

    // 3. 돌 그리기
    Paint blackPaint = Paint()..color = Colors.black;
    Paint whitePaint = Paint()..color = Colors.white;

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] != 0) {
          // 각 셀의 정중앙 좌표 계산
          double cx = c * cellSize + (cellSize / 2);
          double cy = r * cellSize + (cellSize / 2);
          double radius = cellSize * 0.42; // 돌 크기는 셀 크기의 84%

          canvas.drawCircle(
            Offset(cx, cy), 
            radius, 
            board[r][c] == 1 ? blackPaint : whitePaint
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return true; // 상태가 변경될 때마다 다시 그림
  }
}
