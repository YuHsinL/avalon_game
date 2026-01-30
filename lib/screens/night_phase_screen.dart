import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/player_model.dart';
import '../providers/game_provider.dart';
import 'game_main_screen.dart'; // 記得引入

class NightPhaseScreen extends StatefulWidget {
  const NightPhaseScreen({super.key});

  @override
  State<NightPhaseScreen> createState() => _NightPhaseScreenState();
}

class _NightPhaseScreenState extends State<NightPhaseScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, String>> _playlist = [];
  
  int _currentIndex = 0;
  bool _isPlaying = false;
  // bool _isFinished = false; // 不再需要用這個變數來切換介面

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _buildPlaylist();
    
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_currentIndex < _playlist.length - 1) {
        _playNext();
      } else {
        setState(() {
          _isPlaying = false;
          // _isFinished = true;
          _currentIndex++; 
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _buildPlaylist() {
    final gameProvider = context.read<GameProvider>();
    final roles = gameProvider.selectedRoles;
    
    bool hasOberon = roles.contains(Role.oberon);
    bool hasMordred = roles.contains(Role.mordred);
    bool hasPercival = roles.contains(Role.percival);
    bool hasMorgana = roles.contains(Role.morgana);

    _playlist.add({'file': '01_close_eyes.mp3', 'text': '請所有人閉上眼睛，單手握拳放在面前'});

    if (hasOberon) {
      _playlist.add({'file': '02_except_oberon.mp3', 'text': '除了奧伯倫之外'});
    }

    _playlist.add({'file': '03_minions.mp3', 'text': '所有壞人舉起大拇指並睜眼相認\n5...4...3...2...1...\n所有壞人閉眼，拇指繼續舉著'});

    if (hasOberon) {
      _playlist.add({'file': '04_oberon.mp3', 'text': '奧伯倫舉起大拇指'});
    }

    if (hasMordred) {
      _playlist.add({'file': '05_mordred.mp3', 'text': '莫德雷德放下大拇指'});
    }

    _playlist.add({'file': '06_merlin.mp3', 'text': '梅林睜眼確認壞人\n5...4...3...2...1...\n所有壞人放下大拇指，梅林閉眼'});

    if (hasPercival) {
      if (hasMorgana) {
        _playlist.add({'file': '07_merlin_morgana_up.mp3', 'text': '梅林和莫甘娜舉起大拇指\n派西維爾睜眼確認兩人'});
      } else {
        _playlist.add({'file': '08_merlin_up.mp3', 'text': '梅林舉起大拇指\n派西維爾睜眼確認'});
      }

      _playlist.add({'file': '09_percival_end.mp3', 'text': '5...4...3...2...1...\n派西維爾閉眼'});

      if (hasMorgana) {
        _playlist.add({'file': '10_merlin_morgana_down.mp3', 'text': '梅林和莫甘娜放下大拇指'});
      } else {
        _playlist.add({'file': '11_merlin_down.mp3', 'text': '梅林放下大拇指'});
      }
    }

    _playlist.add({'file': '12_open_eyes.mp3', 'text': '所有人睜眼，遊戲開始'});
  }

  Future<void> _playCurrent() async {
    if (_currentIndex >= _playlist.length) return;
    
    String fileName = _playlist[_currentIndex]['file']!;
    await _audioPlayer.play(AssetSource('audio/$fileName'));
    
    setState(() {
      _isPlaying = true;
    });

    _scrollToIndex(_currentIndex);
  }

  void _scrollToIndex(int index) {
    if (_scrollController.hasClients) {
      double offset = index * 45.0; // 稍微調整預估高度
      double target = offset - MediaQuery.of(context).size.height * 0.3;
      if (target < 0) target = 0;
      
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _playNext() {
    setState(() {
      _currentIndex++;
    });
    if (_currentIndex < _playlist.length) {
      _playCurrent();
    }
  }

  void _pause() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  void _restart() {
    _audioPlayer.stop();
    setState(() {
      _currentIndex = 0;
      // _isFinished = false;
      _isPlaying = false;
    });
    _scrollToIndex(0);
  }

  void _skipToGame() {
    _audioPlayer.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const GameMainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // (1) 拿掉標題：只保留 AppBar 結構但不放 title
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- 1. 歌詞列表區域 ---
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              itemCount: _playlist.length,
              itemBuilder: (context, index) {
                bool isActive = (index == _currentIndex);
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  // (2) 行距減小：從 20 改為 10
                  margin: const EdgeInsets.only(bottom: 0),
                  padding: const EdgeInsets.symmetric(vertical: 4), // 內距也稍微縮小
                  child: Text(
                    _playlist[index]['text']!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: isActive ? Colors.amber : Colors.white24,
                      fontSize: 20, 
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          ),

          // --- 2. 下方控制面板 (按鈕並排) ---
          Container(
            padding: const EdgeInsets.only(top: 20, bottom: 40),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, -10))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 平均分配空間
              children: [
                // 左邊：重播按鈕
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.replay, color: Colors.white54),
                      onPressed: _restart,
                    ),
                    const Text("重播", style: TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),

                // 中間：播放/暫停 (最大顆)
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber,
                  ),
                  child: IconButton(
                    iconSize: 50,
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      if (_isPlaying) {
                        _pause();
                      } else {
                        _playCurrent();
                      }
                    },
                  ),
                ),

                // (3) 右邊：進入遊戲 (綠色按鈕)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.greenAccent),
                      onPressed: _skipToGame,
                    ),
                    const Text("開始遊戲", style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}