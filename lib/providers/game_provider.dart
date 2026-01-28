// lib/providers/game_provider.dart

import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player_model.dart';

class GameProvider with ChangeNotifier {
  int playerCount = 5;
  bool hasLakeLady = false;
  final Set<Role> selectedRoles = {};
  List<Player> players = [];
  int? kingIndex;

  final Map<int, Map<String, int>> rules = {
    5: {'good': 3, 'evil': 2},
    6: {'good': 4, 'evil': 2},
    7: {'good': 4, 'evil': 3},
    8: {'good': 5, 'evil': 3},
    9: {'good': 6, 'evil': 3},
    10: {'good': 6, 'evil': 4},
  };

  void updatePlayerCount(int count) {
    playerCount = count;
    notifyListeners();
  }

  void toggleRole(Role role) {
    if (selectedRoles.contains(role)) {
      selectedRoles.remove(role);
    } else {
      if (_canAddRole(role)) {
        selectedRoles.add(role);
      }
    }
    notifyListeners();
  }
  
  void toggleLakeLady(bool value) {
    hasLakeLady = value;
    notifyListeners();
  }

  bool _canAddRole(Role role) {
    int maxEvil = rules[playerCount]!['evil']!;
    int maxGood = rules[playerCount]!['good']!;
    int currentEvilSpecial = selectedRoles.where((r) => _isEvil(r)).length;
    int currentGoodSpecial = selectedRoles.where((r) => !_isEvil(r)).length;
    
    if (_isEvil(role)) {
      return currentEvilSpecial < (maxEvil - 1); // 扣掉刺客
    } else {
      return currentGoodSpecial < (maxGood - 1); // 扣掉梅林
    }
  }

  bool _isEvil(Role role) {
    return [Role.assassin, Role.morgana, Role.mordred, Role.oberon, Role.minion].contains(role);
  }

  String? validateSetup() {
    if (selectedRoles.contains(Role.percival)) {
      bool hasMorgana = selectedRoles.contains(Role.morgana);
      bool hasMordred = selectedRoles.contains(Role.mordred);
      if (!hasMorgana && !hasMordred) {
        return "加入派西維爾時，必須至少加入莫甘娜或莫德雷德其中之一！";
      }
    }
    return null;
  }

  // --- 重點修改：分配角色與圖片 ---
  void assignRoles() {
    List<Role> roleList = [];

    // 1. 準備角色清單
    roleList.add(Role.merlin);
    roleList.add(Role.assassin);
    roleList.addAll(selectedRoles);

    int maxGood = rules[playerCount]!['good']!;
    int maxEvil = rules[playerCount]!['evil']!;
    int currentGood = roleList.where((r) => !_isEvil(r)).length;
    int currentEvil = roleList.where((r) => _isEvil(r)).length;

    for (int i = 0; i < (maxGood - currentGood); i++) roleList.add(Role.servant);
    for (int i = 0; i < (maxEvil - currentEvil); i++) roleList.add(Role.minion);

    roleList.shuffle();

    // 2. 準備圖片資源池 (Pool)
    // 每次分配前都重新洗牌這些圖片列表，確保隨機性
    List<String> servantImages = [
      'servant1.jpg', 'servant2.jpg', 'servant3.jpg', 'servant4.jpg', 'servant5.jpg'
    ]..shuffle();

    List<String> minionImages = [
      'minion1.jpg', 'minion2.jpg', 'minion3.jpg'
    ]..shuffle();

    // 3. 生成玩家並綁定圖片
    players = List.generate(playerCount, (index) {
      Role role = roleList[index];
      String imagePath;

      // 根據角色決定圖片
      switch (role) {
        case Role.merlin:
          imagePath = 'merlin.jpg';
          break;
        case Role.percival:
          imagePath = 'percival.jpg';
          break;
        case Role.assassin:
          imagePath = 'assassin.jpg';
          break;
        case Role.morgana:
          imagePath = 'morgana.jpg';
          break;
        case Role.mordred:
          imagePath = 'mordred.jpg';
          break;
        case Role.oberon:
          imagePath = 'oberon.jpg';
          break;
        case Role.servant:
          // 從洗牌後的池子裡拿出一張，若不夠用就拿第一張(理論上不會發生)
          if (servantImages.isNotEmpty) {
            imagePath = servantImages.removeLast();
          } else {
            imagePath = 'servant1.jpg';
          }
          break;
        case Role.minion:
           if (minionImages.isNotEmpty) {
            imagePath = minionImages.removeLast();
          } else {
            imagePath = 'minion1.jpg';
          }
          break;
      }

      // 加上 assets/images/ 前綴
      return Player(
        id: index + 1, 
        role: role, 
        imagePath: "assets/images/$imagePath"
      );
    });

    kingIndex = Random().nextInt(playerCount);
    notifyListeners();
  }
}