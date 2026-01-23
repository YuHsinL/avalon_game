// lib/providers/game_provider.dart

import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player_model.dart';

class GameProvider with ChangeNotifier {
  // --- 狀態變數 ---

  int playerCount = 5; // 預設 5 人
  bool hasLakeLady = false; // 是否有湖中女神
  
  // 使用 Set 來存儲被勾選的特殊角色，避免重複
  final Set<Role> selectedRoles = {};

  // 最終生成的玩家列表
  List<Player> players = [];
  
  // 第一任國王的位置 (index)
  int? kingIndex;

  // --- 遊戲規則設定 (依據你的需求) ---
  final Map<int, Map<String, int>> rules = {
    5: {'good': 3, 'evil': 2},
    6: {'good': 4, 'evil': 2},
    7: {'good': 4, 'evil': 3},
    8: {'good': 5, 'evil': 3},
    9: {'good': 6, 'evil': 3},
    10: {'good': 6, 'evil': 4},
  };

  // --- 方法 (Actions) ---

  // 1. 更新玩家人數
  void updatePlayerCount(int count) {
    playerCount = count;
    // 如果人數變少，導致壞人坑位不夠，可能需要移除一些已選角色，這裡簡化處理，
    // 每次變更人數時，我們保持 selectedRoles 不變，但在 validate 時檢查
    
    // 湖中女神規則：7人以上才建議開啟，但我們先不強制關閉，讓使用者自己選
    notifyListeners();
  }

  // 2. 切換特殊角色勾選狀態
  void toggleRole(Role role) {
    if (selectedRoles.contains(role)) {
      selectedRoles.remove(role);
    } else {
      // 檢查是否超過該陣營的人數上限
      if (_canAddRole(role)) {
        selectedRoles.add(role);
      }
    }
    notifyListeners();
  }
  
  // 切換湖中女神
  void toggleLakeLady(bool value) {
    hasLakeLady = value;
    notifyListeners();
  }

  // 內部檢查：還能不能加這個角色？
  bool _canAddRole(Role role) {
    int maxEvil = rules[playerCount]!['evil']!;
    int maxGood = rules[playerCount]!['good']!;
    
    // 計算目前已選的特殊角色數量
    int currentEvilSpecial = selectedRoles.where((r) => _isEvil(r)).length;
    int currentGoodSpecial = selectedRoles.where((r) => !_isEvil(r)).length;

    // 必帶角色佔用名額：梅林(正)、刺客(反)
    // 所以實際可用名額 = 上限 - 1
    
    if (_isEvil(role)) {
      // 壞人特殊角色不能超過 (總壞人 - 1個刺客)
      return currentEvilSpecial < (maxEvil - 1);
    } else {
      // 好人特殊角色不能超過 (總好人 - 1個梅林)
      return currentGoodSpecial < (maxGood - 1);
    }
  }

  bool _isEvil(Role role) {
    return [Role.assassin, Role.morgana, Role.mordred, Role.oberon, Role.minion].contains(role);
  }

  // 3. 驗證設置是否合法 (回傳錯誤訊息，若是 null 代表合法)
  String? validateSetup() {
    // 規則：有派西維爾就必須至少有莫甘娜或莫德雷德其中一個
    if (selectedRoles.contains(Role.percival)) {
      bool hasMorgana = selectedRoles.contains(Role.morgana);
      bool hasMordred = selectedRoles.contains(Role.mordred);
      if (!hasMorgana && !hasMordred) {
        return "加入派西維爾時，必須至少加入莫甘娜或莫德雷德其中之一！";
      }
    }
    return null; // 通過驗證
  }

  // 4. 開始遊戲：生成角色並洗牌
  void assignRoles() {
    List<Role> roleList = [];

    // A. 加入必帶角色
    roleList.add(Role.merlin);
    roleList.add(Role.assassin);

    // B. 加入已選的特殊角色
    roleList.addAll(selectedRoles);

    // C. 補滿剩下的位置
    int maxGood = rules[playerCount]!['good']!;
    int maxEvil = rules[playerCount]!['evil']!;

    int currentGood = roleList.where((r) => !_isEvil(r)).length;
    int currentEvil = roleList.where((r) => _isEvil(r)).length;

    // 補好人 (忠臣)
    for (int i = 0; i < (maxGood - currentGood); i++) {
      roleList.add(Role.servant);
    }

    // 補壞人 (爪牙)
    for (int i = 0; i < (maxEvil - currentEvil); i++) {
      roleList.add(Role.minion);
    }

    // D. 洗牌
    roleList.shuffle();

    // E. 生成 Player 物件
    players = List.generate(playerCount, (index) {
      return Player(id: index + 1, role: roleList[index]);
    });

    // F. 隨機決定第一任國王
    kingIndex = Random().nextInt(playerCount);

    notifyListeners();
  }
}