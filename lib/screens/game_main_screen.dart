import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player_model.dart';
import '../providers/game_provider.dart';
import '../widgets/game_exit_button.dart';
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
  List<int> _questFailCounts = [0, 0, 0, 0, 0]; // 紀錄每一局失敗票數
  
  // 投票計數
  int _failedVoteCount = 0; 
  int _successVoteCount = 0;
  
  // 流程控制旗標
  //bool _isSelectingTeam = true;  // 階段1: 任務準備
  bool _isVoting = false;        // 階段2: 投票中
  bool _isShowingResult = false; // 階段3: 顯示該局結果
  bool _isResultRevealed = false; // 階段3-2: 是否已翻牌
  bool _isLadyPhase = false;     // 階段3-3: 湖中女神階段
  bool _isAssassinPhase = false; // 階段4: 刺殺梅林
  bool _isGameOver = false;      // 階段5: 遊戲結束

  // 遊戲結束資訊
  bool _finalGoodWon = false;
  String _finalReason = "";

  // 投票過程變數
  int _currentVoterIndex = 0;      // 現在輪到第幾位投票
  int _currentQuestNeededPlayers = 0; // 這一局總共需要幾個人
  
  // 暫存當前投票者的選擇
  bool? _tempSelectedVote; 

  // 湖中女神相關變數
  int _currentLadyIndex = 0; 
  Set<int> _previousLadies = {}; // 紀錄所有當過女神的人 (包含初始持有者)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerCount = context.read<GameProvider>().playerCount;
      setState(() {
        _currentLadyIndex = playerCount - 1; // 預設給最後一位玩家
        _previousLadies.add(_currentLadyIndex); // 初始持有者也算「當過」
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final questConfig = gameProvider.currentQuestConfig;
    final int neededPlayers = questConfig[_currentQuestIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // 深色背景
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50, 
        leading: const GameExitButton(),
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
      padding: const EdgeInsets.only(bottom: 10), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(5, (index) {
          Color color = Colors.grey;
          IconData? icon;
          
          bool shouldHideResult = (index == _currentQuestIndex && _isShowingResult && !_isResultRevealed);
          bool isSuccess = _questResults[index] == true;
          bool isFailed = _questResults[index] == false;
          
          if (!shouldHideResult && isSuccess) {
            color = Colors.blueAccent; 
            icon = Icons.check;
          } else if (!shouldHideResult && isFailed) {
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
              
              if (!shouldHideResult && isFailed)
                Text("${_questFailCounts[index]}張反對", style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold))
              else
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
    } else if (_isLadyPhase) {
      return _buildLadyScreen();
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
          const SizedBox(height: 50),
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
      _tempSelectedVote = null;
    });
  }

  // --- Phase 2: 傳閱投票 ---
  Widget _buildVotingScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "請將手機交給出任務的第 ${_currentVoterIndex + 1} 位玩家",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          
          const SizedBox(height: 5),
          Text(
            "(共 $_currentQuestNeededPlayers 位)",
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildSelectableVoteCard(
                  isSuccessCard: true,
                  imagePath: "assets/images/vote_success.jpg", 
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildSelectableVoteCard(
                  isSuccessCard: false,
                  imagePath: "assets/images/vote_fail.jpg", 
                  color: Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _tempSelectedVote == null ? Colors.grey.shade800 : Colors.amber,
                foregroundColor: _tempSelectedVote == null ? Colors.grey : Colors.black,
              ),
              onPressed: _tempSelectedVote == null ? null : _handleConfirmButtonPress,
              child: const Text("確認投票", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableVoteCard({required bool isSuccessCard, required String imagePath, required Color color}) {
    bool isSelected = _tempSelectedVote == isSuccessCard;
    bool isDimmed = _tempSelectedVote != null && !isSelected;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tempSelectedVote = isSuccessCard;
        });
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDimmed ? 0.3 : 1.0, 
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: isSelected ? Border.all(color: color, width: 4) : null,
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 15)] : [],
          ),
          child: ClipRRect(
             borderRadius: BorderRadius.circular(11), 
             child: AspectRatio(
              aspectRatio: 5/8,
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  void _handleConfirmButtonPress() {
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(_tempSelectedVote == true ? "確認投下成功？" : "確認投下失敗？", style: const TextStyle(color: Colors.white)),
        content: const Text("送出後將無法更改。", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("取消")
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); 
              _submitVote(_tempSelectedVote!);
            }, 
            child: const Text("確認", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
          ),
        ],
      )
    );
  }

  void _submitVote(bool isSuccess) {
    if (isSuccess) _successVoteCount++;
    else _failedVoteCount++;

    if (_currentVoterIndex < _currentQuestNeededPlayers - 1) {
      setState(() {
        _currentVoterIndex++;
        _tempSelectedVote = null; 
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
    
    _questFailCounts[_currentQuestIndex] = _failedVoteCount;

    setState(() {
      _questResults[_currentQuestIndex] = !isFail;
      _isVoting = false;
      _isShowingResult = true;
      _isResultRevealed = false; 
    });
  }

  Widget _buildResultScreen() {
    List<String> resultImages = [];
    if (_isResultRevealed) {
      for (var i = 0; i < _successVoteCount; i++) resultImages.add("assets/images/vote_success.jpg");
      for (var i = 0; i < _failedVoteCount; i++) resultImages.add("assets/images/vote_fail.jpg");
      resultImages.shuffle(); 
    } else {
      for (var i = 0; i < _currentQuestNeededPlayers; i++) resultImages.add("assets/images/vote_back.jpg");
    }

    bool isSuccess = _questResults[_currentQuestIndex]!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          
          Text(
            _isResultRevealed 
              ? (isSuccess ? "任務成功" : "任務失敗") 
              : "投票收集完成",
            style: TextStyle(
              fontSize: 40, 
              fontWeight: FontWeight.bold, 
              color: _isResultRevealed ? (isSuccess ? Colors.blue : Colors.red) : Colors.white
            ),
          ),
          const SizedBox(height: 30),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 15,
              runSpacing: 15,
              children: resultImages.map((imgPath) {
                return Container(
                  width: 80, 
                  height: 128, 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(image: AssetImage(imgPath), fit: BoxFit.cover),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),
          
          if (_isResultRevealed)
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text("成功：$_successVoteCount票", style: const TextStyle(color: Colors.blueAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                 const SizedBox(width: 30),
                 Text("失敗：$_failedVoteCount票", style: const TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold)),
               ],
             )
          else 
             const SizedBox(height: 26), 
          
          const SizedBox(height: 30),
          
          SizedBox(
            width: 220,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: _isResultRevealed 
                ? _nextQuestOrEndGame 
                : () {
                    setState(() {
                      _isResultRevealed = true;
                    });
                  },
              child: Text(
                _isResultRevealed ? "繼續遊戲" : "揭開投票結果", 
                style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)
              ),
            ),
          )
        ],
      ),
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
      // 判斷是否進入湖中女神階段
      final gameProvider = context.read<GameProvider>();
      // 規則：有開女神 且 第2,3,4局結束後
      if (gameProvider.hasLakeLady && (_currentQuestIndex == 1 || _currentQuestIndex == 2 || _currentQuestIndex == 3)) {
        setState(() {
          _isShowingResult = false;
          _isLadyPhase = true;
        });
      } else {
        setState(() {
          _currentQuestIndex++;
          _isShowingResult = false;
        });
      }
    }
  }

  // --- Phase 3.5: 湖中女神 (修正後：鎖住已當過的人) ---
  Widget _buildLadyScreen() {
    final players = context.read<GameProvider>().players;
    final currentLady = players[_currentLadyIndex];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text("湖中女神", style: TextStyle(fontSize: 32, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            "請 ${currentLady.id} 號玩家持有手機", 
            style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 5),
          const Text("選擇一名玩家查驗身份", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final targetPlayer = players[index];
                
                // (1) 判斷是否鎖住：當前持有者 OR 曾經當過女神的人
                // 邏輯：_previousLadies 存的是玩家的 index (0-based)
                // targetPlayer.id - 1 就是該玩家的 index
                bool isLocked = _previousLadies.contains(targetPlayer.id - 1) || (targetPlayer.id - 1 == _currentLadyIndex);

                return GestureDetector(
                  onTap: isLocked ? null : () {
                    _showLadyCheckDialog(targetPlayer);
                  },
                  child: Opacity(
                    opacity: isLocked ? 0.3 : 1.0, // 被鎖住變暗
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          "${targetPlayer.id}號", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
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

  void _showLadyCheckDialog(Player target) {
    String alignmentText = target.team == Team.good ? "正義方 (好人)" : "邪惡方 (壞人)";
    Color alignmentColor = target.team == Team.good ? Colors.blue : Colors.red;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("確認查驗", style: TextStyle(color: Colors.white)),
        content: Text("確定要查驗 ${target.id} 號玩家嗎？", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx2) => AlertDialog(
                  backgroundColor: Colors.grey.shade900,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.remove_red_eye, size: 50, color: Colors.white),
                      const SizedBox(height: 20),
                      Text("${target.id} 號玩家是", style: const TextStyle(color: Colors.white, fontSize: 18)),
                      const SizedBox(height: 10),
                      Text(alignmentText, style: TextStyle(color: alignmentColor, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      const Text("女神卡將移交給該玩家", style: TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                        onPressed: () {
                          Navigator.pop(ctx2);
                          // 完成女神階段
                          setState(() {
                            int newLadyIndex = target.id - 1;
                            _currentLadyIndex = newLadyIndex; 
                            _previousLadies.add(newLadyIndex); // (1) 將新女神加入「已當過」名單
                            _isLadyPhase = false;
                            _currentQuestIndex++;
                          });
                        },
                        child: const Text("我知道了 (進入下一局)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                )
              );
            },
            child: const Text("確認", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );
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
          const SizedBox(height: 30),
          const Text("刺殺梅林", style: TextStyle(fontSize: 32, color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(
            assassin != null ? "請 ${assassin.id} 號玩家 (刺客) 選擇目標" : "請壞人討論並選擇刺殺目標",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 30),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5, 
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
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
                        border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          "${player.id}號", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
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