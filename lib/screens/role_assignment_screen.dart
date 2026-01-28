import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player_model.dart';
import '../providers/game_provider.dart';

class RoleAssignmentScreen extends StatefulWidget {
  const RoleAssignmentScreen({super.key});

  @override
  State<RoleAssignmentScreen> createState() => _RoleAssignmentScreenState();
}

class _RoleAssignmentScreenState extends State<RoleAssignmentScreen> {
  int _currentIndex = 0; 
  bool _isCardFlipped = false; 

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final players = gameProvider.players;
    final currentPlayer = players[_currentIndex];
    
    final isKing = (_currentIndex == gameProvider.kingIndex);

    return Scaffold(
      appBar: AppBar(
        title: const Text("身份分配"),
        automaticallyImplyLeading: false, 
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- (1) 上方顯示玩家編號 ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "${currentPlayer.id} 號玩家",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ),

            // --- (2) 中間大卡牌區域 (修正比例 5:8) ---
            Expanded(
              child: Center( // 讓卡片在可用空間內居中
                child: AspectRatio(
                  aspectRatio: 5 / 8, // 強制鎖定長寬比為 5:8
                  child: Container(
                    width: double.infinity, // 讓它填滿 AspectRatio 給的寬度
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect( 
                      borderRadius: BorderRadius.circular(20),
                      child: _isCardFlipped
                          ? _buildRealCardImage(currentPlayer, isKing)
                          : Image.asset(
                              "assets/images/identity_back.jpg",
                              // 使用 cover 配合 5:8 的容器，可以完美填滿且不變形
                              fit: BoxFit.cover, 
                              errorBuilder: (ctx, err, stack) => _buildFallbackCover(),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- 下方操作按鈕 ---
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCardFlipped ? Colors.grey : Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  if (_isCardFlipped) {
                    _handleHideAndPass(players.length);
                  } else {
                    setState(() {
                      _isCardFlipped = true;
                    });
                  }
                },
                child: Text(
                  _isCardFlipped 
                    ? (_currentIndex == players.length - 1 ? "我知道了，開始遊戲" : "隱藏身份 (傳給下一位)") 
                    : "點擊查看身份",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _handleHideAndPass(int totalPlayers) {
    if (_currentIndex < totalPlayers - 1) {
      setState(() {
        _isCardFlipped = false;
        _currentIndex++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("進入天黑閉眼階段..."), backgroundColor: Colors.purple),
      );
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NightPhaseScreen()));
    }
  }

  // --- Helper 1: 顯示真實卡牌圖片 ---
  Widget _buildRealCardImage(Player player, bool isKing) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. 底圖
        Image.asset(
          player.imagePath,
          fit: BoxFit.cover, // 強制填滿 5:8 的區域
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (ctx, err, stack) => _buildFallbackIdentity(player),
        ),

        // 2. 皇冠疊加層 (如果是國王)
        if (isKing)
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
            ),
          ),
      ],
    );
  }

  // --- Helper 2: 備案卡背圖 ---
  Widget _buildFallbackCover() {
    return Container(
      color: Colors.blueGrey.shade900,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 80, color: Colors.white24),
            SizedBox(height: 10),
            Text("缺少 identity_back.jpg", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- Helper 3: 備案文字身份 ---
  Widget _buildFallbackIdentity(Player player) {
    return Container(
      color: player.team == Team.good ? Colors.blue.shade900 : Colors.red.shade900,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(player.team == Team.good ? Icons.shield : Icons.local_fire_department, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(player.roleName, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("圖片載入失敗", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 5),
            Text("路徑: ${player.imagePath}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}