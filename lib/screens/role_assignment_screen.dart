import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player_model.dart';
import '../providers/game_provider.dart';
// 我們稍後會建立這個夜間階段頁面，先註解掉或留著報錯提醒自己
// import 'night_phase_screen.dart'; 

class RoleAssignmentScreen extends StatefulWidget {
  const RoleAssignmentScreen({super.key});

  @override
  State<RoleAssignmentScreen> createState() => _RoleAssignmentScreenState();
}

class _RoleAssignmentScreenState extends State<RoleAssignmentScreen> {
  int _currentIndex = 0; // 目前輪到第幾位玩家
  bool _isCardFlipped = false; // 是否翻開了身份卡

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final players = gameProvider.players;
    final currentPlayer = players[_currentIndex];
    
    // 判斷是否為第一任國王
    final isKing = (_currentIndex == gameProvider.kingIndex);

    return Scaffold(
      appBar: AppBar(
        title: const Text("身份分配"),
        automaticallyImplyLeading: false, // 隱藏返回鍵，防止誤觸重來
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- 上方指示文字 ---
              Text(
                _isCardFlipped ? "請確認您的身份" : "傳閱階段",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 30),

              // --- 核心卡片區域 ---
              Expanded(
                child: _isCardFlipped
                    ? _buildIdentityCard(currentPlayer, isKing) // 翻開後：顯示身份
                    : _buildCoverCard(currentPlayer.id),        // 蓋牌時：顯示編號
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
            ],
          ),
        ),
      ),
    );
  }

  // 邏輯：處理「隱藏並傳閱」
  void _handleHideAndPass(int totalPlayers) {
    if (_currentIndex < totalPlayers - 1) {
      // 還有下一位玩家
      setState(() {
        _isCardFlipped = false;
        _currentIndex++;
      });
    } else {
      // 最後一位玩家看完了 -> 進入天黑閉眼 (夜間階段)
      // TODO: 這裡之後要跳轉到 NightPhaseScreen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("所有人已確認身份，進入天黑閉眼階段..."), backgroundColor: Colors.purple),
      );
      
      // 暫時先 pop 回首頁，之後改成跳轉
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NightPhaseScreen()));
    }
  }

  // UI：未翻開時的封面 (狀態 A)
  Widget _buildCoverCard(int playerId) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app, size: 80, color: Colors.amber),
          const SizedBox(height: 20),
          Text(
            "$playerId 號玩家",
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            "請將手機交給此玩家",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // UI：翻開後的身份卡 (狀態 B)
  Widget _buildIdentityCard(Player player, bool isKing) {
    // 根據陣營決定顏色
    Color teamColor = player.team == Team.good ? Colors.blueAccent : Colors.redAccent;
    String teamName = player.team == Team.good ? "正義方 (好人)" : "邪惡方 (壞人)";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [teamColor.withOpacity(0.4), teamColor.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teamColor, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 皇冠標記 (如果是國王)
          if (isKing) ...[
             const Icon(Icons.emoji_events, color: Colors.amber, size: 50),
             const Text("👑 第一任國王", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
             const SizedBox(height: 20),
          ],

          // 角色圖片 (暫時用 Icon 代替)
          Icon(
            player.team == Team.good ? Icons.shield : Icons.local_fire_department,
            size: 100,
            color: teamColor,
          ),
          
          const SizedBox(height: 20),
          
          // 角色名稱
          Text(
            player.roleName,
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          
          const SizedBox(height: 10),
          
          // 陣營名稱
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              teamName,
              style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}