import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static bool get _enabled => Hive.box('settings').get('sound_enabled', defaultValue: true);

  static Future<void> playClick() async {
    if (!_enabled) return;
    await _player.stop();
    await _player.play(
      AssetSource('sounds/click2.mp3'),
      volume: 0.6, // optional
    );
  }

  static Future<void> playSuccess() async {
    if (!_enabled) return;
    await _player.stop();
    await _player.play(
      AssetSource('sounds/success.mp3'),
      volume: 0.6, // optional
    );
  }
}

class AppSounds {
  static bool get soundEnabled =>
      Hive.box('settings').get('sound_enabled', defaultValue: true) as bool;
}

  
