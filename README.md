# Echo of the Past — пиксельная бета, уровень 1

Реальное время, фиксированный шаг 60 тиков/с. Вся графика рисуется кодом (внутренний экран 320x180, целочисленный масштаб).

## Запуск
```
cd echo_of_the_past
flutter create --project-name echo_of_the_past .
flutter pub get
flutter test
flutter run -d chrome        # или windows / android
```
Управление: A/D или стрелки, Пробел — прыжок, R — заново. На телефоне — кнопки на экране.

## Файлы
- lib/sim.dart  — физика, уровень, Эхо (чистый Dart, покрыт тестами)
- lib/art.dart  — палитра, фон, спрайты, свет, дождь
- lib/game.dart — игровой цикл Flame, отрисовка, HUD
- lib/main.dart — запуск, клавиатура, экранные кнопки
