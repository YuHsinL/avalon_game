// lib/models/player_model.dart

// 1. 定義角色枚舉 (Enum)
enum Role {
  // 正義方 (Good)
  merlin,     // 梅林
  percival,   // 派西維爾
  servant,    // 亞瑟的忠臣 (普通好人)

  // 邪惡方 (Evil)
  assassin,   // 刺客
  morgana,    // 莫甘娜
  mordred,    // 莫德雷德
  oberon,     // 奧伯倫
  minion      // 莫德雷德的爪牙 (普通壞人)
}

// 2. 定義陣營
enum Team { good, evil }

// 3. 玩家類別
class Player {
  final int id;         // 玩家編號 (0, 1, 2...)
  final Role role;      // 拿到的角色
  
  Player({required this.id, required this.role});

  // 判斷這個玩家是哪一個陣營的 helper function
  Team get team {
    if ([Role.merlin, Role.percival, Role.servant].contains(role)) {
      return Team.good;
    }
    return Team.evil;
  }

  // 取得角色的中文名稱 (用於顯示)
  String get roleName {
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

  // 取得圖片路徑 (之後我們會把圖片放在 assets/images/)
  String get imagePath => "assets/images/${role.name}.png";
}