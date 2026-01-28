// lib/models/player_model.dart

enum Role {
  merlin, percival, servant, 
  assassin, morgana, mordred, oberon, minion 
}

enum Team { good, evil }

class Player {
  final int id;
  final Role role;
  final String imagePath; // 直接儲存分配到的圖片路徑
  
  Player({
    required this.id, 
    required this.role,
    required this.imagePath,
  });

  Team get team {
    if ([Role.merlin, Role.percival, Role.servant].contains(role)) {
      return Team.good;
    }
    return Team.evil;
  }

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
}