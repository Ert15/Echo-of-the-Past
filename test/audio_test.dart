import 'package:echo_of_the_past/audio.dart';
import 'package:echo_of_the_past/menu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('music and effects settings switch off independently', () async {
    final settings = MenuState();
    addTearDown(settings.dispose);

    await settings.toggleMusic();
    expect(Sfx.musicOn, isFalse);
    expect(Sfx.sfxOn, isTrue);

    await settings.toggleSfx();
    expect(Sfx.sfxOn, isFalse);
    expect(Sfx.musicOn, isFalse);

    await settings.toggleMusic();
    expect(Sfx.musicOn, isTrue);
    expect(Sfx.sfxOn, isFalse);

    await settings.toggleSfx();

    await Future.wait([
      Sfx.startMusic(),
      Sfx.setMusicEnabled(false),
      Sfx.setMusicEnabled(true),
    ]);
    expect(Sfx.musicOn, isTrue);
  });
}
