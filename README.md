# VIctory: сборка для NVIDIA (на основе fxceless)

Слой совместимости, который запускает игру с Xbox Series нативно на Windows из
файлов, которые пользователь предоставляет сам. Эта сборка — форк
[fxceless/victory-fork](https://github.com/fxceless/victory-fork), в который по
одному перенесены проверенные фиксы из
[avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX) и
[trustno1-coder/VIctory-NVIDIA](https://github.com/trustno1-coder/VIctory-NVIDIA).
Цель — скорость на видеокарте NVIDIA без потери освещения.

**В репозитории нет файлов, кода или ресурсов игры.** Нужна своя копия игры.
Проект не связан с разработчиком или издателем игры.

## Что это за сборка

- **Основа:** fxceless/victory-fork на коммите `9c184b3` (версия до обновления
  25.11.2026, вечер). Более позднее обновление fxceless (19 коммитов) было
  перенесено и проверено, но **после него пропадало освещение**, поэтому оно
  вынесено в отдельную ветку `with-upstream-nov25` и в эту сборку не входит.
- **Поверх основы:** фиксы из 7900XTX и VIctory-NVIDIA, только те, что
  проверены на этой машине и не ломают картинку (список ниже).
- **Ветка:** `integrate-7900xtx`. Каждый фикс — отдельный коммит с указанием
  источника, любой можно откатить через `git revert`.

## Где она сейчас (2026-11-26)

Проверено на одной машине: ноутбук с RTX 5070 Ti Laptop 12 ГБ, Windows 11,
экран 2560×1600, сборка `diag`, игра 1.0.2.1.

| Запуск | Кадр в мире | Работа игры на видеокарте |
|---|---|---|
| fxceless, настройки по умолчанию | 320–440 мс (2–3 fps) | — |
| `scripts\play.ps1` (быстрый набор fxceless + пакеты indirect) | ~190–240 мс (4–5 fps) | ~170 мс |
| `scripts\play-nvidia.ps1` (Series S, половинный масштаб) | **~110–150 мс (7–9 fps)** | **~80 мс** |

Освещение в обоих режимах как в исходном fxceless (отражённого трассированного
света в fxceless нет и раньше не было). Длинная сессия: около 15 минут без
падений и потери устройства.

## Как запустить

Нужно: Windows 10/11 x64, процессор с AVX2, видеокарта Direct3D 12 с shader
model 6.6 и mesh-шейдерами, Rust (версия закреплена в `rust-toolchain.toml`),
MSVC build tools, своя копия игры.

```powershell
copy victory.example.toml victory.toml      # указать game_dir (вне этой папки)
cargo build --locked --profile diag -p victory --features diagnostics
```

**Рекомендуемый запуск на NVIDIA** (самый быстрый):

```powershell
scripts\play-nvidia.ps1 -Exe <путь к game_scarlett_master.exe>
```

Параметры `play-nvidia.ps1`:

- `-NoSmoothMotion` — запускать сам `victory.exe`. По умолчанию запускается
  копия `victory_sm.exe`; если для неё в NVIDIA App включить Smooth Motion,
  драйвер будет вставлять сгенерированные кадры (управление остаётся на
  реальной частоте кадров).
- `-SeriesX` — профиль Series X вместо Series S (медленнее, полное качество).
- `-Log <файл>` — писать лог в файл.
- `-More @{...}` — дополнительные ключи, например
  `-More @{VICTORY_RENDER_SCALE='1'}` для полного масштаба рендера.

**Запуск без патчей игры** (профиль Series X, полное разрешение):

```powershell
scripts\play.ps1 -Exe <путь к game_scarlett_master.exe>
```

Параметры `play.ps1`: `-Safe` (настройки fxceless по умолчанию, для сравнения),
`-Console series-x|series-s`, `-Display WxH` (какой экран сообщается игре;
по умолчанию 3840×2160), `-Log`, `-More`.

## Что изменено относительно fxceless

### Из VIctory-7900XTX

| Коммит | Что | Включено |
|---|---|---|
| `dba0299` | DXIL `Log` уже по основанию 2: уровень мипа кубических текстур был в 1.44 раза выше, отражения размыты (DexNom 921d8d3b). С тестом. | всегда |
| `442765d` | Ограничения indirect-аргументов пакетами (`VICTORY_INDIRECT_BATCH`): около 2 300 отдельных проходов между полными ожиданиями карты на кадр сводятся в пакеты; кадр примерно на 13 % короче. Шейдер пакета приведён к правилам fxceless, тест на WARP сверяет его с одиночным. Выключается после первой ошибки драйвера. | в обоих скриптах (`=2`) |
| `29586c0` | Удержание частот карты между отправками (`VICTORY_CARD_AWAKE`). На этой карте прироста не дало. | выключено |

### Из VIctory-NVIDIA

| Коммит | Что | Включено |
|---|---|---|
| `8dc0dd9` | Патчи игры (victory-perf, из ZigZagBoi1/ScarlettPort): масштаб рендера (`VICTORY_RENDER_SCALE`), собственный апскейлер игры вместо FSR (`VICTORY_OWN_UPSCALER`), отключение сторожевого таймера (`VICTORY_NO_WATCHDOG`). Каждый патч проверяет хеш сборки 1.0.2.1 и точные байты на месте, иначе ничего не делает. | `play-nvidia.ps1` (0.5 и апскейлер) |
| `6140743` | Слой интерфейса Series S (`VICTORY_COMPOSE`, порт fxceless PR 1189 от Tissma95): без него на Series S меню, загрузки и субтитры чёрные. | `play-nvidia.ps1` |
| `8a529ef` | Те же рендер-таргеты не ставятся повторно (после ZJOU acf478b8). `VICTORY_BIND_CACHE=0` — старое поведение. | всегда |
| `8dbd6f3` | Повторно привязанный пайплайн не удерживается и не регистрируется заново (от Belobug 92d353f8, romainhedouin). | всегда |
| `2dca8fb`, `d2dbe36` | `scripts\play-nvidia.ps1`: настройки VIctory-NVIDIA, которые есть в этой сборке. | — |

`play-nvidia.ps1` также включает собственные ключи fxceless: сравнение памяти
на карте (`VICTORY_CARD_BUFFERS_MIN_MB=1`, `VICTORY_CARD_BUFFERS_MB=1536`) и
ожидание новых шейдеров вместо пропуска рисований
(`VICTORY_PIPELINE_WAIT_MS=10000`).

## Что пробовали и не взяли

- **Обновление fxceless от 25.11 (19 коммитов):** после него пропадало
  освещение. Лежит в ветке `with-upstream-nov25`.
- **`VICTORY_BVH_MISS` (VIctory-NVIDIA):** экономит время, но убирает
  отражённый свет, тёмные места становятся темнее. Лежит в ветке
  `with-nvidia-fixes`.
- **Нормализованные коды буферов и вспомогательные линии пиксельных шейдеров
  (7900XTX):** на NVIDIA дали чёрный экран и сильное падение fps в прологе;
  откачены (`247c09d`, `31612f5`).
- **Dispatch больше 65 535 групп (7900XTX):** работает только на AMD.
- **`SHOW_AFTER`, `THIN`, `CARD_STEPS`, переписанные `watch.rs` и
  `descriptor/host.rs` (7900XTX):** это целые подсистемы, а не отдельные
  фиксы; в fxceless их нет.
- **Динамические слоты дескрипторов (VIctory-NVIDIA):** здесь они не
  кончаются (0 отказов за запуск), нужны были только с `THIN`.
- **Коммиты Belobug `c96525d`, `b32fb99`:** опираются на код 7900XTX.
- **XCL:** лицензия GPL-2.0-only несовместима с этой (GPL-3.0-or-later), код
  оттуда не переносится.

## Известные проблемы

- С `play-nvidia.ps1` (Series S, половинный масштаб) часть текстур пропадает
  или появляется поздно; причина ещё не найдена. Для проверки:
  `-SeriesX` (виноват ли профиль) или `-More @{VICTORY_RENDER_SCALE='1'}`
  (виноват ли масштаб).
- В мире видеокарта остаётся главным ограничением: несколько compute-шейдеров
  игры занимают по 17–18 мс за запуск; wave64-шейдеры консоли на NVIDIA
  работают как две волны по 32 с обменом через общую память.
- Первые минуты после изменения транслятора шейдеров идёт повторный перевод
  шейдеров, игра подтормаживает сильнее обычного.
- Тесты: `cargo test -p victory-gpu --features diagnostics` и
  `cargo test -p victory-shader` проходят; часть WARP-тестов `victory-gpu`
  изредка падает при параллельном запуске и в исходном fxceless тоже.

## Ветки

- `integrate-7900xtx` — эта сборка.
- `with-upstream-nov25` — то же плюс обновление fxceless от 25.11 (без света).
- `with-nvidia-fixes` — промежуточное состояние с `VICTORY_BVH_MISS`.

## Благодарности

Это дерево чужой работы с небольшими доработками поверх.

- [Marvisak/VIctory](https://github.com/Marvisak/VIctory) и его участники:
  загрузчик, сервисы среды, бэкенд Direct3D 12, перекомпилятор шейдеров.
- [fxceless/victory-fork](https://github.com/fxceless/victory-fork) и авторы
  его pull request'ов: основа этой сборки; Tissma95 — слой интерфейса Series S.
- [avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX):
  пакеты indirect-аргументов, удержание частот, тест кубических мипов.
- [trustno1-coder/VIctory-NVIDIA](https://github.com/trustno1-coder/VIctory-NVIDIA):
  патчи масштаба рендера и апскейлера (через victory-perf и
  ZigZagBoi1/ScarlettPort), скрипт запуска для NVIDIA.
- [DexNom/VIctory](https://github.com/DexNom/VIctory),
  [Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD)
  (romainhedouin),
  [FQY55kai/ZJOU-VICTORY](https://github.com/FQY55kai/ZJOU-VICTORY) — через
  форки выше.
- Изменения этой сборки сделаны с помощью [Claude Code](https://claude.com/claude-code).

Исходный README fxceless с описанием команд, отладочных ключей и истории:
[docs/README-fxceless.md](docs/README-fxceless.md).

## Лицензия

GPL-3.0-or-later, как VIctory. См. [LICENSE](LICENSE); файл, на который она
не распространяется, назван в [docs/asset-policy.md](docs/asset-policy.md).
