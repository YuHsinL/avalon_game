import 'king_selection_screen.dart';
import 'role_assignment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/player_model.dart';
import '../providers/game_provider.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  // 定義統一的字體大小，方便管理
  final double mainFontSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final rules = gameProvider.rules[gameProvider.playerCount]!;

    // 邏輯修正：只有在「有派且無壞人頭目」時才顯示警告
    bool hasPercival = gameProvider.selectedRoles.contains(Role.percival);
    bool hasMorgana = gameProvider.selectedRoles.contains(Role.morgana);
    bool hasMordred = gameProvider.selectedRoles.contains(Role.mordred);
    
    // 顯示條件：有派西維爾 且 (沒有莫甘娜 且 沒有莫德雷德)
    bool showPercivalWarning = hasPercival && (!hasMorgana && !hasMordred);

    return Scaffold(
      appBar: AppBar(title: const Text("遊戲設置")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- 1. 人數與即時陣容區塊 ---
          Card(
            color: Colors.white10,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  // 滾輪選擇器
                  SizedBox(
                    height: 120,
                    child: CupertinoPicker(
                      backgroundColor: Colors.transparent,
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(
                        initialItem: gameProvider.playerCount - 5,
                      ),
                      onSelectedItemChanged: (int index) {
                        gameProvider.updatePlayerCount(index + 5);
                      },
                      children: List<Widget>.generate(6, (index) {
                        return Center(
                          child: Text(
                            "${index + 5} 人局",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: mainFontSize, // (2) 字體大小統一
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  
                  // 正反方詳細陣容顯示
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左邊：正義方陣容
                        Expanded(
                          child: _buildTeamDetail(
                            context, 
                            "正方", // (1) 改文字
                            rules['good']!, 
                            Colors.blueAccent, 
                            isEvilTeam: false
                          ),
                        ),
                        Container(width: 1, height: 100, color: Colors.white12),
                        // 右邊：邪惡方陣容
                        Expanded(
                          child: _buildTeamDetail(
                            context, 
                            "反方", // (1) 改文字
                            rules['evil']!, 
                            Colors.redAccent, 
                            isEvilTeam: true
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),

          // --- 2. 角色選擇區塊 ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左邊：正義方選項
              Expanded(
                child: Card(
                  color: Colors.blue.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        _buildRoleCheckbox(context, Role.percival, "派西維爾", Colors.blueAccent),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 右邊：邪惡方選項
              Expanded(
                child: Card(
                  color: Colors.red.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
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

          // --- 3. 派西維爾警告文字 (條件滿足時才出現) ---
          if (showPercivalWarning) // (4) 邏輯修正
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      "選擇派西維爾必須至少選擇莫甘娜或莫德雷德其中一個",
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // --- 4. 湖中女神 ---
          if (gameProvider.playerCount >= 7) ...[
             SwitchListTile(
               title: Text(
                 "加入「湖中女神」",
                 style: TextStyle(fontSize: mainFontSize, color: Colors.white), // (5) 字體大小統一
               ),
               value: gameProvider.hasLakeLady,
               activeColor: Colors.amber,
               contentPadding: const EdgeInsets.symmetric(horizontal: 4),
               onChanged: (val) => gameProvider.toggleLakeLady(val),
             ),
             const SizedBox(height: 10),
          ],

          // --- 5. 開始按鈕 ---
          SizedBox(
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                String? error = gameProvider.validateSetup();
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                } else {
                  // 1. 分配角色
                  gameProvider.assignRoles();

                  // 2. 改為跳轉到「選國王轉盤」
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const KingSelectionScreen()),
                  );
                }
              },
              child: const Text("下一步", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Helper: 動態計算並顯示陣容 ---
  Widget _buildTeamDetail(BuildContext context, String label, int totalCount, Color color, {required bool isEvilTeam}) {
    final gameProvider = context.watch<GameProvider>();
    final selectedRoles = gameProvider.selectedRoles;

    List<Role> specialRoles = [];
    if (isEvilTeam) {
      specialRoles = selectedRoles.where((r) => 
        [Role.morgana, Role.mordred, Role.oberon].contains(r)
      ).toList();
    } else {
      specialRoles = selectedRoles.where((r) => 
        [Role.percival].contains(r)
      ).toList();
    }

    int fixedRoleCount = 1; 
    int fillerCount = totalCount - fixedRoleCount - specialRoles.length;
    if (fillerCount < 0) fillerCount = 0;

    return Column(
      children: [
        // (1) 格式修改：正方：5人
        Text(
          "$label：$totalCount人",
          style: TextStyle(fontSize: mainFontSize, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(isEvilTeam ? "刺客 x 1" : "梅林 x 1", style: const TextStyle(color: Colors.white, fontSize: 14)), // (3) 改成白色
            
            ...specialRoles.map((role) => Text(
              "${_getRoleName(role)} x 1",
              style: const TextStyle(color: Colors.white, fontSize: 14), // (3) 改成白色
            )),

            if (fillerCount > 0)
              Text(
                "${isEvilTeam ? '莫德雷德的爪牙' : '亞瑟的忠臣'} x $fillerCount",
                style: const TextStyle(color: Colors.white, fontSize: 14), // (3) 改成白色
              ),
          ],
        )
      ],
    );
  }

  String _getRoleName(Role role) {
    switch (role) {
      case Role.merlin: return "梅林";
      case Role.percival: return "派西維爾";
      case Role.servant: return "亞瑟的忠臣";
      case Role.assassin: return "刺客";
      case Role.morgana: return "莫甘娜";
      case Role.mordred: return "莫德雷德";
      case Role.oberon: return "奧伯倫";
      case Role.minion: return "莫德雷德的爪牙";
    }
  }

  Widget _buildRoleCheckbox(BuildContext context, Role role, String label, Color color) {
    final gameProvider = context.watch<GameProvider>();
    final isSelected = gameProvider.selectedRoles.contains(role);
    
    return InkWell(
      onTap: () => gameProvider.toggleRole(role),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
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