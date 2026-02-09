import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playClick() async {
    await _player.stop();
    await _player.play(
      AssetSource('sounds/click2.mp3'),
      volume: 0.6, // optional
    );
  }

  static Future<void> playSuccess() async {
    await _player.stop();
    await _player.play(
      AssetSource('sounds/success.mp3'),
      volume: 0.6, // optional
    );
  }
}
  
