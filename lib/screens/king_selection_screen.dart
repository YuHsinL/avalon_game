import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'role_assignment_screen.dart'; // 用於按鈕跳轉

class KingSelectionScreen extends StatefulWidget {
  const KingSelectionScreen({super.key});

  @override
  State<KingSelectionScreen> createState() => _KingSelectionScreenState();
}

class _KingSelectionScreenState extends State<KingSelectionScreen> {
  int _highlightIndex = -1; // 目前亮燈的位置 (0-based index)
  Timer? _timer;
  bool _isSpinning = true;
  
  // 用來儲存最終選出的國王 index，以便計算女神
  //int _finalKingIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSpinning();
    });
  }

  void _startSpinning() {
    final gameProvider = context.read<GameProvider>();
    final playerCount = gameProvider.playerCount;
    
    // 1. 先決定最終結果 (隨機)
    final targetIndex = Random().nextInt(playerCount);
    //_finalKingIndex = targetIndex;
    
    // 2. 計算總共要跳幾步 (轉至少 3 圈 + 到達目標的距離)
    int currentStep = 0;
    int totalSteps = (playerCount * 3) + targetIndex; 
    
    // 3. 動畫邏輯 (速度由快變慢)
    double speed = 50; // 初始速度 (毫秒)
    
    void runStep() {
      if (currentStep >= totalSteps) {
        // 停止
        _timer?.cancel();
        
        // 更新 Provider
        gameProvider.setKingIndex(targetIndex);

        setState(() {
          _isSpinning = false;
          _highlightIndex = targetIndex;
          // (1) 這裡不再自動跳轉
        });
        return;
      }

      setState(() {
        _highlightIndex = currentStep % playerCount;
      });

      currentStep++;
      
      // 減速邏輯
      if (totalSteps - currentStep < playerCount) {
        speed += 30; 
      } else if (totalSteps - currentStep < playerCount * 2) {
        speed += 5; 
      }

      _timer = Timer(Duration(milliseconds: speed.toInt()), runStep);
    }

    runStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final playerCount = gameProvider.playerCount;

    // (2) 決定顯示的文字
    String statusText;
    if (_isSpinning) {
      statusText = "正在選出第一任國王...";
    } else {
      // 國王號碼 (1-based)
      int kingId = _highlightIndex + 1;
      statusText = "第一任國王為 $kingId 號玩家";

      // 如果有湖中女神，計算女神是誰 (國王的前一位)
      if (gameProvider.hasLakeLady) {
        // 邏輯：(國王Index - 1 + 總人數) % 總人數
        int ladyIndex = (_highlightIndex - 1 + playerCount) % playerCount;
        int ladyId = ladyIndex + 1;
        statusText += "\n第一位湖中女神為 $ladyId 號玩家";
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // (2) 移除獎盃 Icon
            // const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
            
            const SizedBox(height: 20),
            
            // 狀態文字顯示
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold, height: 1.5),
            ),
            
            const SizedBox(height: 50),
            
            // 轉盤繪製區
            SizedBox(
              width: 300,
              height: 300,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double centerX = constraints.maxWidth / 2;
                  double centerY = constraints.maxHeight / 2;
                  double radius = 120; // 圓半徑

                  return Stack(
                    children: List.generate(playerCount, (index) {
                      // 計算每個圓圈的座標 (從上方 -90度 開始)
                      double angle = (2 * pi * index / playerCount) - (pi / 2);
                      double x = centerX + radius * cos(angle);
                      double y = centerY + radius * sin(angle);
                      
                      bool isHighlighted = index == _highlightIndex;

                      return Positioned(
                        left: x - 25, 
                        top: y - 25,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isHighlighted ? Colors.amber : Colors.white10,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isHighlighted ? Colors.orange : Colors.grey,
                              width: isHighlighted ? 4 : 2,
                            ),
                            boxShadow: isHighlighted ? [
                              BoxShadow(color: Colors.amber.withOpacity(0.8), blurRadius: 20, spreadRadius: 5)
                            ] : [],
                          ),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,
                                color: isHighlighted ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            const SizedBox(height: 50),

            // (1) 新增：前往角色分配按鈕 (只在停止後顯示)
            if (!_isSpinning)
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const RoleAssignmentScreen()),
                    );
                  },
                  child: const Text("前往角色分配", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              )
            else
              // 佔位，避免轉盤跳動
              const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}