import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 引入 iOS 風格元件
import 'package:provider/provider.dart';
import '../models/player_model.dart';
import '../providers/game_provider.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 取得 Provider 狀態
    final gameProvider = context.watch<GameProvider>();
    final rules = gameProvider.rules[gameProvider.playerCount]!;

    return Scaffold(
      appBar: AppBar(title: const Text("遊戲設置")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- 1. 人數選擇區塊 (改為滾輪) ---
          _buildSectionTitle("1. 選擇玩家人數"),
          Card(
            color: Colors.white10, // 稍微透一點的背景
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  // 滾輪選擇器
                  SizedBox(
                    height: 150, // 給滾輪一個固定高度
                    child: CupertinoPicker(
                      // 設定滾輪的背景顏色 (深色模式適配)
                      backgroundColor: Colors.transparent, 
                      itemExtent: 40, // 每個選項的高度
                      scrollController: FixedExtentScrollController(
                        initialItem: gameProvider.playerCount - 5, // 設定初始位置
                      ),
                      onSelectedItemChanged: (int index) {
                        // index 0 代表 5人, index 1 代表 6人...
                        gameProvider.updatePlayerCount(index + 5);
                      },
                      children: List<Widget>.generate(6, (index) {
                        return Center(
                          child: Text(
                            "${index + 5} 人",
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 22,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  // 顯示好人壞人配置
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTeamInfo("正義方", rules['good']!, Colors.blueAccent),
                        Container(width: 1, height: 30, color: Colors.white24), // 分隔線
                        _buildTeamInfo("邪惡方", rules['evil']!, Colors.redAccent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // --- 2. 角色選擇區塊 (左右分欄) ---
          _buildSectionTitle("2. 選擇特殊角色"),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左邊：正義方
              Expanded(
                child: Card(
                  color: Colors.blue.withOpacity(0.1), // 淡淡的藍色背景
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Text("正義方", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        const Divider(color: Colors.blueAccent),
                        // 正方選項
                        _buildRoleCheckbox(context, Role.percival, "派西維爾", Colors.blueAccent),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 右邊：邪惡方
              Expanded(
                child: Card(
                  color: Colors.red.withOpacity(0.1), // 淡淡的紅色背景
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Text("邪惡方", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        const Divider(color: Colors.redAccent),
                        // 反方選項
                        _buildRoleCheckbox(context, Role.morgana, "莫甘娜", Colors.redAccent),
                        _buildRoleCheckbox(context, Role.mordred, "莫德雷德", Colors.redAccent),
                        _buildRoleCheckbox(context, Role.oberon, "奧伯倫", Colors.redAccent),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- 3. 湖中女神 (7人以上才出現) ---
          if (gameProvider.playerCount >= 7) ...[
             _buildSectionTitle("3. 進階選項"),
             SwitchListTile(
               title: const Text("加入「湖中女神」"),
               value: gameProvider.hasLakeLady,
               activeColor: Colors.amber,
               onChanged: (val) => gameProvider.toggleLakeLady(val),
             ),
             const SizedBox(height: 20),
          ],

          // --- 4. 開始按鈕 ---
          SizedBox(
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, // 按鈕改成顯眼的金色
                foregroundColor: Colors.black, // 文字黑色
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                String? error = gameProvider.validateSetup();
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                } else {
                  gameProvider.assignRoles();
                  // 顯示簡單提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("分配完成！"), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text("前往角色分配", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 小幫手：標題樣式
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
    );
  }

  // 小幫手：顯示隊伍人數
  Widget _buildTeamInfo(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  // 小幫手：角色勾選框 (簡化版)
  Widget _buildRoleCheckbox(BuildContext context, Role role, String label, Color color) {
    final gameProvider = context.watch<GameProvider>();
    final isSelected = gameProvider.selectedRoles.contains(role);
    
    return InkWell( // 讓整個條目都能點擊
      onTap: () => gameProvider.toggleRole(role),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // 自製 Checkbox 外觀
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}