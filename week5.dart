import 'package:flutter/material.dart';

void main() {
  runApp(const GameTierListApp());
}

class GameTierListApp extends StatelessWidget {
  const GameTierListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Tier List',
      debugShowCheckedModeBanner: false,
      // 다크 모드 테마 설정
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        // 💡 오류의 원인이 될 수 있는 tabBarTheme 부분을 완전히 삭제했습니다.
      ),
      home: const TierListScreen(),
    );
  }
}

class TierListScreen extends StatelessWidget {
  const TierListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '종합 게임 티어표',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          // 💡 해결 방법: TabBar 위젯 내부에 직접 스타일 속성을 지정하여 호환성 문제를 해결했습니다.
          // (const 관련 오류를 방지하기 위해 TabBar의 const 키워드도 제거했습니다.)
          bottom: TabBar(
            indicatorColor: Colors.blueAccent, // 인디케이터(밑줄) 색상
            labelColor: Colors.white, // 선택된 탭 텍스트 색상
            unselectedLabelColor: Colors.grey, // 선택되지 않은 탭 텍스트 색상
            tabs: const [
              Tab(text: '캐릭터', icon: Icon(Icons.person)),
              Tab(text: '무기', icon: Icon(Icons.colorize)),
              Tab(text: '장비', icon: Icon(Icons.shield)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTierGrid(getMockData('캐릭터')),
            _buildTierGrid(getMockData('무기')),
            _buildTierGrid(getMockData('장비')),
          ],
        ),
      ),
    );
  }

  // 그리드 뷰 빌더
  Widget _buildTierGrid(List<TierItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 한 줄에 3개
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75, // 썸네일 비율 (가로/세로)
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return TierItemCard(item: items[index]);
      },
    );
  }
}

// 아이템 썸네일 및 티어 라벨 카드 위젯
class TierItemCard extends StatelessWidget {
  final TierItem item;

  const TierItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTierColor(item.tier).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // 썸네일 이미지 영역 (아이콘으로 대체)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // 티어 라벨 (좌측 상단)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getTierColor(item.tier),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Text(
                item.tier,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 티어별 고유 색상 반환 함수
  Color _getTierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'SS':
        return Colors.redAccent;
      case 'S':
        return Colors.orange;
      case 'A':
        return Colors.purpleAccent;
      case 'B':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }
}

// 아이템 데이터 모델
class TierItem {
  final String name;
  final String tier;

  TierItem({required this.name, required this.tier});
}

// 더미 데이터 생성 함수
List<TierItem> getMockData(String category) {
  return [
    TierItem(name: '$category 1', tier: 'SS'),
    TierItem(name: '$category 2', tier: 'SS'),
    TierItem(name: '$category 3', tier: 'S'),
    TierItem(name: '$category 4', tier: 'S'),
    TierItem(name: '$category 5', tier: 'S'),
    TierItem(name: '$category 6', tier: 'A'),
    TierItem(name: '$category 7', tier: 'A'),
    TierItem(name: '$category 8', tier: 'A'),
    TierItem(name: '$category 9', tier: 'B'),
    TierItem(name: '$category 10', tier: 'B'),
    TierItem(name: '$category 11', tier: 'B'),
    TierItem(name: '$category 12', tier: 'B'),
  ];
}
