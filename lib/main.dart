import 'screens/setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. 引入 provider 套件
import 'providers/game_provider.dart';   // 2. 引入我們剛寫好的邏輯

void main() {
  runApp(
    // 3. 使用 MultiProvider 包住整個 App
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const AvalonApp(),
    ),
  );
}

class AvalonApp extends StatelessWidget {
  const AvalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avalon Game',
      debugShowCheckedModeBanner: false, // 去掉右上角 debug 標籤
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        useMaterial3: true,
        // 設定一些預設的文字樣式
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white70),
        ),
      ),
      home: const SetupScreen(),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. 這裡簡單測試一下 Provider 是否運作正常
    // 我們嘗試讀取 Provider 裡的玩家人數
    final int count = context.watch<GameProvider>().playerCount;

    return Scaffold(
      appBar: AppBar(title: const Text("阿瓦隆核心測試")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("目前設定人數：$count 人", style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 20),
            const Text("邏輯層載入成功！", style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}