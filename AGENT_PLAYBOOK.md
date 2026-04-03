# Agent Playbook: Roblox Game Factory

> Экспертное руководство для AI-агента. Полный подход топ-10 студий: от анализа рынка до LiveOps. Читай перед каждой задачей.

---

## Философия топ-студий

**Главный принцип:** Игра — это продукт, не проект. Продукт живёт годами, обновляется еженедельно, управляется данными, а не интуицией.

Топ-студии (Adopt Me, Pet Simulator, Brookhaven, Jailbreak) побеждают не потому что у них лучший код. Они побеждают потому что:
1. Выбирают нишу с доказанным спросом (аналитика, не гадание)
2. Итерируют быстро (CI/CD, не ручной деплой)
3. Принимают решения на основе данных (A/B тесты, retention, ARPDAU)
4. Обновляются каждую неделю (алгоритм Roblox повышает активные игры)
5. Монетизация встроена в дизайн с первого дня

---

## Порядок работы (Production Pipeline)

### Фаза 1: Аналитика и выбор ниши

```bash
python analyzer.py    # Скрипт парсит Rolimon's + RoMonitor
```

**Что ищем:**
- Peak CCU > 5,000, текущий CCU < 500 → доказанный спрос, аудитория ушла
- Like% 40-70% при высоких визитах → идея хорошая, реализация плохая
- Не обновлялась 6+ месяцев → разработчик бросил

**Критерии выбора ниши:**
- Обби, тайкун, симулятор — лучшие для начала (проще, понятная монетизация)
- 60% игроков на мобильных — интерфейс должен работать на телефоне
- Вирусный потенциал для TikTok (визуально яркие моменты)

### Фаза 2: Прототип (1-2 дня)

```bash
wally install                    # Установить пакеты
rojo serve dev.project.json      # Dev-режим с debug-инструментами
```

**Порядок создания:**
1. Core loop (основная механика — что игрок ДЕЛАЕТ каждые 10 секунд)
2. Progression system (зачем возвращаться — уровни, стадии, прокачка)
3. Monetization hooks (где естественно предложить покупку)
4. UI (минимальный, работающий на мобильных)

### Фаза 3: Разработка (1-4 недели)

**Архитектура кода:**
```
src/
├── server/
│   ├── services/
│   │   ├── DataService.luau       # Сохранение данных (ProfileStore)
│   │   ├── EconomyService.luau    # Валюта, покупки, транзакции
│   │   ├── GameplayService.luau   # Core loop, прогрессия
│   │   └── SecurityService.luau   # Rate limiting, валидация
│   └── init.server.luau           # Инициализация всех сервисов
├── client/
│   ├── controllers/
│   │   ├── InputController.luau   # Обработка ввода
│   │   ├── CameraController.luau  # Камера
│   │   └── UIController.luau      # Управление UI
│   ├── gui/
│   │   └── components/            # Fusion UI компоненты
│   └── scripts/
│       └── init.client.luau       # Инициализация клиента
└── shared/
    ├── constants/
    │   ├── GameConfig.luau        # ВСЕ числа балансировки — ЗДЕСЬ
    │   └── FeatureFlags.luau      # Переключатели функций
    ├── types/
    │   └── PlayerData.luau        # Схема данных игрока
    ├── network/                   # Определения сетевых событий
    └── utils/
        ├── RateLimit.luau         # Rate limiting
        └── ObjectPool.luau        # Пул объектов
```

**Правила кода (ОБЯЗАТЕЛЬНО):**
- `task.wait()` вместо `wait()`, `task.spawn()` вместо `coroutine.wrap()`
- Parent ставить ПОСЛЕДНИМ при `Instance.new()`
- Все сервисы через `game:GetService()`, никогда `game.ServiceName`
- Числа балансировки — ТОЛЬКО в `GameConfig.luau`, нигде больше
- Каждый RemoteEvent проходит через `t` (type check) + `RateLimit`
- Cleanup через `Trove` — никогда не оставлять болтающиеся соединения

### Фаза 4: Quality Assurance

```bash
selene src/                   # Lint — найти ошибки
stylua src/                   # Format — единый стиль
lune run tests/runner         # Тесты
lune run lune/build           # Полный билд
```

**Чеклист перед публикацией:**
- [ ] Все RemoteEvent'ы валидируют аргументы через `t`
- [ ] Rate limiting на всех remote'ах
- [ ] Вся логика валюты/прогрессии на сервере
- [ ] UI работает на мобильных (протестировать в Studio эмуляторе)
- [ ] Like% > 70% в тестовых сессиях
- [ ] Session time > 10 минут
- [ ] Нет утечек памяти (все Trove.Destroy вызываются)
- [ ] StreamingEnabled включен
- [ ] Меньше 10,000 частей в Workspace

### Фаза 5: Публикация

```bash
lune run lune/build                      # Полный билд pipeline
rojo build default.project.json -o build/game.rbxl
rbxcloud experience publish \
  --api-key $(cat roblox_api) \
  --universe-id UNIVERSE_ID \
  --place-id PLACE_ID \
  --version-type published \
  --filename build/game.rbxl
```

**Или через CI/CD:** push в main → GitHub Actions деплоит автоматически.

### Фаза 6: LiveOps (после запуска)

**Еженедельный цикл:**
1. Понедельник: анализ метрик за неделю (DAU, retention, revenue)
2. Вторник-Четверг: разработка обновления
3. Пятница: деплой обновления
4. Суббота-Воскресенье: мониторинг, сбор feedback

**Ключевые метрики для решений:**
- D1 Retention < 15% → core loop не затягивает, переделать
- Session time < 5 мин → не хватает контента или UI запутанный
- Like% < 70% → найти и починить top-3 жалобы в отзывах
- ARPDAU не растёт → переработать монетизацию, добавить оффер

---

## Инструменты: экспертное использование

### Rojo — синхронизация файлов с Studio

```bash
rojo serve                               # Dev-режим: Studio подключается к VSCode
rojo serve dev.project.json              # Dev-режим с debug-инструментами
rojo build default.project.json -o game.rbxl  # Production build
rojo sourcemap default.project.json -o sourcemap.json  # Для Luau LSP
```

**Структура project.json:**
- `$path` = папка на диске → Instance в Studio
- `$className` = тип Instance
- `$properties` = свойства Instance
- `init.server.luau` = Script, `init.client.luau` = LocalScript, `init.luau` = ModuleScript

### Wally — управление зависимостями

```bash
wally install     # Установить пакеты из wally.toml → папка Packages/
wally update      # Обновить до latest compatible versions
```

**Как добавить пакет:** Изменить `wally.toml`, затем `wally install`.

**Ключевые пакеты и зачем:**
| Пакет | Зачем | Пример |
|---|---|---|
| Promise | Async без callback hell | `promise:andThen(fn):catch(fn)` |
| Signal | События без Instance | `signal:Fire(data)`, `signal:Connect(fn)` |
| Trove | Cleanup всего | `trove:Add(connection)`, `trove:Destroy()` |
| t | Type-check remote args | `t.tuple(t.string, t.number)` |
| Comm | Typed remotes | `comm:CreateSignal("Name")` |
| Fusion | Реактивный UI | Declarative UI, signals, computed values |
| Component | Tag-based components | `Component.new({Tag = "Coin"})` |
| Timer | Таймеры/интервалы | `Timer.Simple(5, fn)` |
| TableUtil | Работа с таблицами | `TableUtil.Map()`, `TableUtil.Filter()` |

### Selene — линтер

```bash
selene src/        # Проверить весь код
selene file.luau   # Проверить один файл
```

Конфигурация в `selene.toml`. Ловит: unused variables, incorrect API usage, shadowing, циклические зависимости.

### StyLua — форматтер

```bash
stylua src/              # Отформатировать
stylua --check src/      # Проверить без изменений (для CI)
```

Конфигурация в `.stylua.toml`. Единый стиль: табы, 120 символов, sorted requires.

### Lune — Luau вне Roblox

```bash
lune run lune/build      # Полный build pipeline
lune run lune/dev        # Dev server
lune run tests/runner    # Тесты
```

Встроенные API: файловая система (`@lune/fs`), HTTP (`@lune/net`), процессы (`@lune/process`), stdio, Roblox файлы (`@lune/roblox`).

### Darklua — код-процессор

```bash
darklua process src/ dist/ --config .darklua.json
```

Что делает: удаляет мёртвый код, переписывает `require` пути (Wally → Roblox), инлайнит переменные.

### Asphalt — asset pipeline

```bash
asphalt sync              # Загрузить ассеты в Roblox
asphalt sync --dry-run    # Проверить что загрузится (для CI)
```

Конфигурация в `asphalt.toml`. Автоматически загружает текстуры/звуки и генерирует Luau-модуль с asset ID.

### rbxcloud — Roblox Open Cloud

```bash
# Публикация
rbxcloud experience publish --api-key KEY --universe-id UID --place-id PID --filename game.rbxl

# DataStores
rbxcloud datastore list --api-key KEY --universe-id UID
rbxcloud datastore get --api-key KEY --universe-id UID --datastore-name PlayerData --key UserId_123

# Messaging
rbxcloud messaging publish --api-key KEY --universe-id UID --topic Shutdown --message "Server update"
```

### Blender MCP — 3D модели через Claude Code

Доступные команды:
- `execute_blender_code` — выполнить Python-код в Blender
- `get_viewport_screenshot` — скриншот viewport
- `get_scene_info` / `get_object_info` — информация о сцене/объекте
- `set_texture` — наложить текстуру
- `generate_hyper3d_model_via_text` — сгенерировать модель из текста
- `generate_hunyuan3d_model` — альтернативный генератор
- `search_polyhaven_assets` / `download_polyhaven_asset` — бесплатные ассеты
- `search_sketchfab_models` / `download_sketchfab_model` — модели со Sketchfab

**Workflow для модели:**
1. Генерируем/скачиваем модель
2. Скриншот viewport → проверяем визуально
3. Экспортируем в .fbx
4. Импортируем в Roblox Studio

### Screenshot — визуальный контроль

```bash
./tools/screenshot.sh screen        # Весь экран
./tools/screenshot.sh studio        # Окно Roblox Studio
./tools/screenshot.sh blender       # Окно Blender
```

После скриншота — Read tool для просмотра результата.

### ClaudeCodeBridge — управление Studio

Плагин установлен в `~/Documents/Roblox/Plugins/`. Команды:
- `get_scene_tree` — дерево всех объектов сцены
- `create_part({name, position, size, color, material})` — создать объект
- `create_script({name, source, scriptType, parent})` — создать скрипт
- `execute_luau(code)` — выполнить код в Studio
- `set_property({path, properties})` — изменить свойства
- `find_objects({className, name, parent})` — поиск объектов
- `delete_object({path})` — удалить объект
- `get_stats()` — статистика сцены

### ImageMagick — обработка изображений

```bash
magick input.png -resize 512x512 icon.png                    # Ресайз
magick input.png -resize 512x512 -quality 85 thumbnail.jpg   # Thumbnail
magick -size 512x512 xc:transparent canvas.png                # Пустой canvas
magick composite overlay.png base.png -gravity center result.png  # Наложение
```

---

## Безопасность (5 слоёв защиты)

### Слой 1: Type Validation (библиотека `t`)
```luau
local t = require(Packages.t)
local validatePurchase = t.tuple(t.string, t.numberPositive)

remote.OnServerEvent:Connect(function(player, itemId, quantity)
    if not validatePurchase(itemId, quantity) then return end
    -- ...
end)
```

### Слой 2: Rate Limiting
```luau
local RateLimit = require(Shared.utils.RateLimit)
local GameConfig = require(Shared.constants.GameConfig)

remote.OnServerEvent:Connect(function(player, ...)
    if not RateLimit.check(player, "purchase", 3, 5) then return end
    -- ...
end)
```

### Слой 3: Sanity Checks
- Расстояние: игрок в радиусе взаимодействия?
- Владение: игрок владеет этим предметом?
- Кулдаун: прошло ли достаточно времени?
- Whitelist: действие в списке допустимых?

### Слой 4: Server Authority
- Сервер ВЛАДЕЕТ всем состоянием (HP, монеты, инвентарь)
- Клиент отправляет НАМЕРЕНИЯ ("хочу атаковать"), не результаты
- Никогда: клиент → "я нанёс 50 урона". Только: клиент → "я атакую", сервер → считает урон

### Слой 5: Behavioral Detection
- Скорость > WalkSpeed + допуск → подозрительно
- Невозможные действия (заблокированный контент) → бан
- Аномальная частота → лог + кик

---

## Производительность

### Бюджеты
- Parts в Workspace: < 10,000 (StreamingEnabled управляет)
- Текстуры: 512x512 max, предпочтительно 256x256
- Треугольники модели: < 5,000 на объект
- RemoteEvent: batch (один вызов с массивом, не N вызовов)

### Паттерны
- **Object Pooling** — для пуль, монет, эффектов (см. `src/shared/utils/ObjectPool.luau`)
- **StreamingEnabled** — включено в `default.project.json`
- **Trove cleanup** — каждое соединение/инстанс через Trove
- **Cache references** — `FindFirstChild` не в hot loops
- **BulkMoveTo** — для массового перемещения частей

---

## Монетизация (встроена в дизайн)

### Принцип: "Fun First, Pay for Convenience"
Игра должна быть полностью играбельна бесплатно. Платные фичи = ускорение + косметика.

### Структура офферов
1. **Game Passes** (одноразовые): VIP, Speed Boost, Double Coins, Skip Stage
2. **Developer Products** (многоразовые): пакеты валюты, одноразовые бустеры
3. **Подписки** (ежемесячные): VIP-клуб с эксклюзивами
4. **Creator Rewards** (пассивный): 5 Robux за качественного игрока/день
5. **Rewarded Ads**: игрок смотрит рекламу → награда в игре
6. **Private Servers**: платная подписка на приватный сервер

### Ценообразование
- Impulse buy: 25-99 R$ (монеты, бустеры)
- Value buy: 99-299 R$ (VIP, Double Coins)
- Premium: 299-799 R$ (All Access, Mega Pack)
- Подписки: 49-199 R$/месяц

### Где предлагать покупку (без раздражения)
- После смерти: "Хочешь респавн здесь? 25 R$"
- Достижение: "Поздравляем! VIP даст x2 награды: 199 R$"
- Progression gate: "Следующая зона через 2 часа, или сейчас: 49 R$"
- Daily shop: ротация ограниченных предложений

---

## Маркетинг

### TikTok (главный канал)
- 9-15 секунд POV-геймплея
- Трендовые звуки
- 2-3 публикации в день
- CTA: "Играй бесплатно — ссылка в био"

### YouTube Shorts
- Те же клипы + "Как я создал игру в Roblox" формат

### Discord
- Сервер для комьюнити
- Анонсы обновлений
- Feedback channel

### Roblox Sponsored Experiences
- Начать с 1,000-5,000 R$ бюджета
- Мониторить конверсию (визит → игра > 5 мин)
- Масштабировать если ROI > 2x

---

## Метрики для решений

| Метрика | Хорошо | Плохо | Что делать если плохо |
|---|---|---|---|
| D1 Retention | > 20% | < 10% | Переделать core loop, добавить цель |
| D7 Retention | > 10% | < 3% | Добавить долгосрочную прогрессию |
| Session Time | > 10 мин | < 3 мин | Больше контента, лучший onboarding |
| Like % | > 80% | < 60% | Почитать отзывы, починить top-3 жалобы |
| CCU trend | Рост | Падение | Обновление + маркетинг-пуш |
| ARPDAU | > $0.02 | < $0.005 | Пересмотреть ценообразование и офферы |
