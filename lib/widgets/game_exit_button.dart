import 'package:flutter/material.dart';
import '../screens/setup_screen.dart';

class GameExitButton extends StatelessWidget {
  const GameExitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.exit_to_app, color: Colors.white70),
      tooltip: "結束遊戲回到主選單",
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: const Text("結束遊戲？", style: TextStyle(color: Colors.white)),
            content: const Text("確定要回到主選單嗎？\n目前的遊戲進度將會消失。", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("取消", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  // 關閉 Dialog 並回到 SetupScreen (清空路由堆疊)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SetupScreen()),
                    (route) => false,
                  );
                },
                child: const Text("確定結束", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}