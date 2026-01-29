import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player_model.dart';
import '../providers/game_provider.dart';
import 'setup_screen.dart'; // 用於重新開始遊戲

class GameMainScreen extends StatefulWidget {
  const GameMainScreen({super.key});

  @override
  State<GameMainScreen> createState() => _GameMainScreenState();
}

class _GameMainScreenState extends State<GameMainScreen> {
  // --- 遊戲狀態變數 ---
  int _currentQuestIndex = 0; // 目前進行到第幾局 (0~4)
  List<bool?> _questResults = [null, null, null, null, null]; // 紀錄5局結果
  
  // 投票計數
  int _failedVoteCount = 0; 
  int _successVoteCount = 0;
  
  // 流程控制旗標
  bool _isSelectingTeam = true;  // 階段1: 任務準備
  bool _isVoting = false;        // 階段2: 投票中
  bool _isShowingResult = false; // 階段3: 顯示該局結果
  bool _isAssassinPhase = false; // 階段4: 刺殺梅林
  bool _isGameOver = false;      // 階段5: 遊戲結束

  // 遊戲結束資訊
  bool _finalGoodWon = false;
  String _finalReason = "";

  // 投票過程變數
  int _currentVoterIndex = 0;      // 現在輪到第幾位投票 (0, 1, 2...)
  int _currentQuestNeededPlayers = 0; // 這一局總共需要幾個人

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final questConfig = gameProvider.currentQuestConfig;
    final int neededPlayers = questConfig[_currentQuestIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // 深色背景
      appBar: AppBar(
        // 移除 title
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- 1. 上方記分板 ---
          _buildScoreboard(questConfig),
          
          const Divider(color: Colors.white24),

          // --- 2. 下方主要內容區 ---
          Expanded(
            child: _buildMainContent(neededPlayers),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard(List<int> config) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          Color color = Colors.grey;
          IconData? icon;
          
          if (_questResults[index] == true) {
            color = Colors.blueAccent; 
            icon = Icons.check;
          } else if (_questResults[index] == false) {
            color = Colors.redAccent; 
            icon = Icons.close;
          } else if (index == _currentQuestIndex && !_isGameOver) {
            color = Colors.amber; 
          }

          return Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  boxShadow: [
                    if (index == _currentQuestIndex && !_isGameOver)
                      BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 10)
                  ]
                ),
                child: Center(
                  child: icon != null 
                    ? Icon(icon, color: color, size: 30)
                    : Text(
                        "${config[index]}", 
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                      ),
                ),
              ),
              const SizedBox(height: 5),
              Text("任務 ${index + 1}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMainContent(int neededPlayers) {
    if (_isGameOver) {
      return _buildGameOverScreen();
    } else if (_isAssassinPhase) {
      return _buildAssassinScreen();
    } else if (_isShowingResult) {
      return _buildResultScreen();
    } else if (_isVoting) {
      return _buildVotingScreen();
    } else {
      return _buildTeamStartScreen(neededPlayers);
    }
  }

  // --- Phase 1: 任務準備 ---
  Widget _buildTeamStartScreen(int neededPlayers) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_alt, size: 80, color: Colors.white24),
          const SizedBox(height: 30),
          Text(
            "任務 ${_currentQuestIndex + 1}",
            style: const TextStyle(fontSize: 36, color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "本局需要 $neededPlayers 位玩家出任務",
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            "請隊長指派隊員，確認後按下開始投票",
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 60),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              onPressed: () {
                _startVotingPhase(neededPlayers);
              },
              child: const Text("開始投票", style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _startVotingPhase(int neededPlayers) {
    setState(() {
      _isVoting = true;
      _currentVoterIndex = 0;
      _currentQuestNeededPlayers = neededPlayers; 
      _successVoteCount = 0;
      _failedVoteCount = 0;
    });
  }

  // --- Phase 2: 傳閱投票 (修改重點) ---
  Widget _buildVotingScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "請將手機交給出任務的第 ${_currentVoterIndex + 1} 位玩家",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          
          const SizedBox(height: 10),
          Text(
            "(共 $_currentQuestNeededPlayers 位)",
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 50),
          
          Row(
            children: [
              // 成功票
              Expanded(
                child: _buildVoteCard(
                  title: "任務成功", 
                  imagePath: "assets/images/vote_success.jpg", 
                  color: Colors.blue, 
                  onTap: () => _handleVoteAttempt(isSuccessVote: true)
                ),
              ),
              const SizedBox(width: 20),
              
              // 失敗票
              Expanded(
                child: _buildVoteCard(
                  title: "任務失敗", 
                  imagePath: "assets/images/vote_fail.jpg", 
                  color: Colors.red, 
                  onTap: () => _handleVoteAttempt(isSuccessVote: false)
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _handleVoteAttempt({required bool isSuccessVote}) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(isSuccessVote ? "確認投下成功？" : "確認投下失敗？", style: const TextStyle(color: Colors.white)),
        content: const Text("送出後將無法更改。", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("取消")
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); 
              _submitVote(isSuccessVote);
            }, 
            child: const Text("確認", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
          ),
        ],
      )
    );
  }

  Widget _buildVoteCard({required String title, required String imagePath, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 5/8,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: color, width: 3),
                image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
              ),
            ),
          ),
          // (4) 修改：移除下方的 Text
          // const SizedBox(height: 10),
          // Text(title, ...),
        ],
      ),
    );
  }

  void _submitVote(bool isSuccess) {
    if (isSuccess) _successVoteCount++;
    else _failedVoteCount++;

    if (_currentVoterIndex < _currentQuestNeededPlayers - 1) {
      setState(() {
        _currentVoterIndex++;
      });
    } else {
      _calculateResult();
    }
  }

  // --- Phase 3: 結算 ---
  void _calculateResult() {
    final gameProvider = context.read<GameProvider>();
    bool isFail = false;

    if (gameProvider.needsTwoFails(_currentQuestIndex)) {
      isFail = _failedVoteCount >= 2; 
    } else {
      isFail = _failedVoteCount >= 1; 
    }

    setState(() {
      _questResults[_currentQuestIndex] = !isFail;
      _isVoting = false;
      _isShowingResult = true;
    });
  }

  Widget _buildResultScreen() {
    bool isSuccess = _questResults[_currentQuestIndex]!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSuccess ? Icons.emoji_events : Icons.cancel, 
            size: 100, 
            color: isSuccess ? Colors.blue : Colors.red
          ),
          const SizedBox(height: 20),
          Text(
            isSuccess ? "任務成功" : "任務失敗",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: isSuccess ? Colors.blue : Colors.red),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildResultCardCount("成功", _successVoteCount, "assets/images/vote_success.jpg"),
              const SizedBox(width: 30),
              _buildResultCardCount("失敗", _failedVoteCount, "assets/images/vote_fail.jpg"),
            ],
          ),
          const SizedBox(height: 50),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: _nextQuestOrEndGame,
              child: const Text("繼續遊戲", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultCardCount(String label, int count, String imgPath) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(image: AssetImage(imgPath), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 10),
        Text("$count 張", style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _nextQuestOrEndGame() {
    int goodWins = _questResults.where((r) => r == true).length;
    int evilWins = _questResults.where((r) => r == false).length;

    if (evilWins >= 3) {
      _showGameOver(goodWon: false, reason: "3次任務失敗，邪惡方獲勝！");
    } else if (goodWins >= 3) {
      setState(() {
        _isShowingResult = false;
        _isAssassinPhase = true;
      });
    } else {
      setState(() {
        _currentQuestIndex++;
        _isShowingResult = false;
      });
    }
  }

  // --- Phase 4: 刺殺梅林 ---
  Widget _buildAssassinScreen() {
    final gameProvider = context.read<GameProvider>();
    final players = gameProvider.players;
    
    Player? assassin;
    try {
      assassin = players.firstWhere((p) => p.role == Role.assassin);
    } catch (e) {
      // ignore
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Icon(Icons.gps_fixed, color: Colors.red, size: 60),
          const SizedBox(height: 10),
          const Text("刺殺梅林階段", style: TextStyle(fontSize: 28, color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            assassin != null ? "請 ${assassin.id} 號玩家 (刺客) 選擇目標" : "請壞人討論並選擇刺殺目標",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                bool isEvil = player.team == Team.evil;

                return GestureDetector(
                  onTap: isEvil ? null : () { 
                    _executeAssassination(player);
                  },
                  child: Opacity(
                    opacity: isEvil ? 0.3 : 1.0, 
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage(player.imagePath),
                          ),
                          const SizedBox(height: 5),
                          Text("${player.id}號", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _executeAssassination(Player target) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("確認刺殺", style: TextStyle(color: Colors.red)),
        content: Text("確定要刺殺 ${target.id} 號玩家嗎？", style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            if (target.role == Role.merlin) {
              _showGameOver(goodWon: false, reason: "梅林被刺殺！\n邪惡方逆轉獲勝！");
            } else {
              _showGameOver(goodWon: true, reason: "刺殺失敗 (刺到 ${target.roleName})！\n正義方獲得最終勝利！");
            }
          }, child: const Text("刺下去！", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      )
    );
  }

  // --- Phase 5: 遊戲結束 ---
  void _showGameOver({required bool goodWon, required String reason}) {
    setState(() {
      _finalGoodWon = goodWon;
      _finalReason = reason;
      _isAssassinPhase = false; 
      _isGameOver = true;
    });
  }

  Widget _buildGameOverScreen() {
    final players = context.read<GameProvider>().players;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Icon(
            _finalGoodWon ? Icons.emoji_events : Icons.whatshot,
            size: 80,
            color: _finalGoodWon ? Colors.blue : Colors.red,
          ),
          const SizedBox(height: 10),
          Text(
            _finalGoodWon ? "正義方獲勝！" : "邪惡方獲勝！",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _finalGoodWon ? Colors.blue : Colors.red),
          ),
          const SizedBox(height: 10),
          Text(
            _finalReason,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          const Text("--- 玩家身份揭曉 ---", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final p = players[index];
                return ListTile(
                  leading: Image.asset(p.imagePath, width: 40, height: 40, fit: BoxFit.cover),
                  title: Text("${p.id}號: ${p.roleName}", style: TextStyle(color: p.team == Team.good ? Colors.blueAccent : Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (_) => const SetupScreen()), 
                  (route) => false
                );
              }, 
              child: const Text("回到主選單 (開新局)", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}