# Roblox Game Factory

> Enterprise-level AI-driven Roblox game development. Claude Code + Blender MCP + Rojo + CI/CD = полностью автономное создание, тестирование и деплой игр.

---

## Стратегия

### Цель

Войти в топ-10 разработчиков Roblox по доходу, используя ИИ для максимальной автоматизации всего pipeline: от аналитики рынка до публикации и LiveOps.

### Подход: "Улучшенный ремейк"

1. **Найти** заброшенные игры с доказанным спросом (высокий пик CCU, но упавшая аудитория)
2. **Проанализировать** почему аудитория ушла (низкий Like%, отзывы, отсутствие обновлений)
3. **Создать свою версию** с нуля — свой код, свои ассеты, улучшенный UX
4. **Запустить** с TikTok/YouTube маркетингом
5. **Итерировать** на основе A/B тестов и метрик (DAU, retention, ARPDAU)

### Монетизация

- Game Passes (VIP, Skip Stage, Speed Boost)
- Developer Products (пакеты валюты, бустеры)
- Подписки (ежемесячный VIP)
- Creator Rewards (5 Robux за качественного игрока/день)
- Rewarded Video Ads
- Private Servers
- UGC (аксессуары/одежда через Blender)

### Целевые метрики (enterprise-level)

| Метрика | Цель | Топ-10 бенчмарк |
|---|---|---|
| Session Time | 10+ мин | 20-40 мин |
| D1 Retention | 15%+ | 30-45% |
| D7 Retention | 5%+ | 15-25% |
| D30 Retention | 2%+ | 8-15% |
| Like % | 70%+ | 85-95% |
| CCU | 1,000+ | 50,000-500,000 |
| ARPDAU | $0.01+ | $0.05-0.15 |

---

## Арсенал

### Тулчейн (Rokit — enterprise toolchain manager)

| Инструмент | Версия | Назначение |
|---|---|---|
| **Rokit** | 1.2.0 | Менеджер тулчейна нового поколения (замена Aftman/Foreman). Per-project версионирование |
| **Rojo** | 7.6.1 | Синхронизация Luau-кода с Roblox Studio. Filesystem-first workflow |
| **Wally** | 0.3.2 | Пакетный менеджер. npm/Cargo для Roblox |
| **Selene** | 0.30.1 | Линтер — находит баги, unused vars, потенциальные уязвимости |
| **StyLua** | 2.4.0 | Автоформатирование — единый code style |
| **Lune** | 0.10.4 | Luau-рантайм вне Roblox (Node.js для Luau). CI/CD скрипты, тесты, автоматизация |
| **Darklua** | 0.18.0 | Код-процессор: dead code elimination, require-path rewriting, минификация |
| **Asphalt** | 1.2.0 | Asset pipeline: автозагрузка текстур/звуков/моделей в Roblox, codegen asset IDs |
| **rbxcloud** | 0.17.0 | Roblox Open Cloud CLI: публикация, DataStores, MessagingService, Luau Execution |
| **ImageMagick** | latest | Обработка изображений: иконки, thumbnails, текстуры |

### Wally-пакеты (библиотеки)

| Пакет | Назначение |
|---|---|
| **Promise** | Async/await, отмена, race conditions — замена сырых coroutines |
| **Fusion** | Реактивный UI-фреймворк (signals-based). Декларативный UI вместо ручного Instance.new |
| **TestEZ** | BDD-тестирование (describe/it/expect) |
| **ProfileStore** | Session-locked DataStore обёртка с auto-save (замена ProfileService) |
| **GameAnalytics SDK** | Аналитика: события, воронки, retention, revenue tracking |

### VSCode расширения

| Расширение | Назначение |
|---|---|
| **Rojo** | Синхронизация с Studio из VSCode |
| **Luau LSP** | Language server: автодополнение, проверка типов, диагностика, sourcemap-aware |
| **Roblox UI** | Визуальный редактор интерфейсов |

### Визуальный контроль (Claude Code "видит")

| Инструмент | Что видит |
|---|---|
| **screenshot.sh screen** | Весь экран — общая картина |
| **screenshot.sh studio** | Окно Roblox Studio — viewport, explorer, properties |
| **screenshot.sh blender** | Окно Blender — 3D модели |
| **Blender MCP viewport** | Viewport Blender напрямую через MCP |
| **ClaudeCodeBridge** | Дерево сцены Studio, свойства объектов, исходники скриптов |

Команды ClaudeCodeBridge в Studio:

- `get_scene_tree` — полное дерево сцены
- `create_part` — создать объект с позицией, размером, цветом, материалом
- `create_script` — создать Script/LocalScript/ModuleScript с кодом
- `execute_luau` — выполнить произвольный Luau-код в Studio
- `set_property` — изменить свойства любого объекта
- `find_objects` — поиск по имени/классу
- `delete_object` — удалить объект
- `get_stats` — количество частей, скриптов, мешей

### MCP-серверы

| MCP | Назначение |
|---|---|
| **Blender MCP** | Полный контроль Blender: создание моделей, текстурирование, экспорт |
| **n8n MCP** | Автоматизация workflow: маркетинг, мониторинг, уведомления |

Blender MCP возможности:

- Генерация 3D-моделей через промпты (Hyper3D, Hunyuan3D)
- Скачивание ассетов с PolyHaven и Sketchfab
- Программное управление сценой
- Экспорт в .fbx/.obj для Roblox Studio

### CI/CD Pipeline (GitHub Actions)

```
push → lint (Selene) → format check (StyLua) → test (Lune) → build (Rojo) → deploy (rbxcloud)
```

Автоматически при каждом пуше:

1. **Lint** — Selene проверяет код на ошибки
2. **Format** — StyLua проверяет стиль
3. **Test** — Lune запускает тесты
4. **Build** — Wally install → Darklua process → Rojo build → .rbxl
5. **Deploy** — rbxcloud публикует на Roblox (только из main)

### Аналитика конкурентов

| Инструмент | Назначение |
|---|---|
| **Profitable.app** | Фильтры "Hidden Gems", "Popular but Abandoned" |
| **Rolimon's Game Table** | Peak vs Current CCU — массовый скрининг |
| **RoMonitor Stats** | Исторические графики, Chrome-расширение |
| **Rotrends** | Revenue, session time, 100K+ игр |
| **RTrack** | Поминутные данные, многолетняя история |
| **analyzer.py** | Наш скрипт — парсит данные, генерирует отчёт |

### API-ключи

| Ключ | Файл | Назначение |
|---|---|---|
| Roblox Open Cloud | `roblox_api` (в .gitignore) | Публикация, DataStores, MessagingService, Assets |

---

## Структура проекта

```
roblox/
├── .github/workflows/
│   └── ci.yml                 # CI/CD: lint → test → build → deploy
├── src/
│   ├── server/                # Серверные скрипты (логика, данные, безопасность)
│   │   └── init.server.luau
│   ├── client/
│   │   ├── gui/               # UI (ScreenGui, магазин, HUD)
│   │   └── scripts/           # Клиентские скрипты (ввод, камера, эффекты)
│   │       └── init.client.luau
│   ├── shared/                # Общие модули (server + client)
│   │   └── init.luau
│   └── storage/               # ServerStorage (шаблоны, данные)
├── tests/
│   └── runner.luau            # Тесты через Lune
├── assets/                    # Исходники ассетов (текстуры, звуки, модели)
├── studio-plugin/
│   └── ClaudeCodeBridge.server.lua  # Плагин Studio для удалённого доступа
├── tools/
│   ├── screenshot.sh          # Захват скриншотов (screen/studio/blender)
│   └── studio-bridge.py       # HTTP-мост Claude Code ↔ Studio
├── default.project.json       # Rojo: маппинг файлов → Studio
├── rokit.toml                 # Тулчейн: версии всех инструментов
├── wally.toml                 # Зависимости: Promise, Fusion, TestEZ
├── selene.toml                # Конфигурация линтера
├── .stylua.toml               # Конфигурация форматтера
├── .darklua.json              # Код-процессор: dead code, require paths
├── asphalt.toml               # Asset pipeline конфигурация
├── analyzer.py                # Скрипт аналитики конкурентов
├── analytics-report.md        # Отчёт: заброшенные игры с потенциалом
├── roblox-guide.md            # Гайд: от нуля до заработка
└── presentation.html          # Презентация стратегии
```

---

## Workflow: от идеи до топ-10

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Аналитика   │───>│  Разработка  │───>│   CI/CD      │───>│   LiveOps    │
│              │    │              │    │              │    │              │
│ analyzer.py  │    │ Claude Code  │    │ GitHub Actions│    │ A/B тесты   │
│ Profitable   │    │ Rojo + Wally │    │ Selene+StyLua│    │ GameAnalytics│
│ Rolimon's    │    │ Blender MCP  │    │ Lune tests   │    │ Обновления  │
│ RoMonitor    │    │ Fusion UI    │    │ rbxcloud     │    │ n8n workflow │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

### 1. Аналитика

```bash
python analyzer.py                    # Найти заброшенные игры с потенциалом
```

### 2. Инициализация

```bash
wally install                         # Установить пакеты (Promise, Fusion, TestEZ)
rojo serve                            # Запустить синхронизацию с Studio
```

### 3. Разработка (Claude Code автономно)

- Пишет Luau-скрипты в `src/` → Rojo синхронизирует в Studio
- Создаёт 3D-модели через Blender MCP → экспорт в .fbx
- Строит реактивный UI через Fusion
- Делает скриншоты для визуального контроля

### 4. Качество

```bash
selene src/                           # Lint — поиск ошибок
stylua src/                           # Format — единый стиль
lune run tests/runner                 # Тесты
```

### 5. Build & Deploy

```bash
rojo sourcemap default.project.json -o sourcemap.json
darklua process src/ dist/            # Dead code elimination, require paths
rojo build default.project.json -o build/game.rbxl
rbxcloud experience publish ...       # Публикация на Roblox
```

### 6. Asset Pipeline

```bash
asphalt sync                          # Загрузить ассеты в Roblox, сгенерировать IDs
```

---

## Быстрый старт

### Проверка всех инструментов

```bash
rokit --version     # 1.2.0   — тулчейн менеджер
rojo --version      # 7.6.1   — синхронизация с Studio
wally --version     # 0.3.2   — пакетный менеджер
selene --version    # 0.30.1  — линтер
stylua --version    # 2.4.0   — форматтер
lune --version      # 0.10.4  — Luau рантайм (CI/скрипты)
darklua --version   # 0.18.0  — код-процессор
asphalt --version   # 1.2.0   — asset pipeline
rbxcloud --version  # 0.17.0  — Roblox Open Cloud CLI
magick --version    # ImageMagick — обработка изображений
```

### PATH (в ~/.zshrc)

```bash
export PATH="$HOME/.rokit/bin:$HOME/.aftman/bin:$HOME/.cargo/bin:$PATH"
```

---

## Что даёт enterprise-уровень

| Что делают обычные разработчики | Что делаем мы |
|---|---|
| Редактируют код прямо в Studio | Filesystem-first: VSCode + Git + Rojo |
| Копируют модули вручную | Wally + версионирование зависимостей |
| Нет тестов | TestEZ + Lune для автоматических тестов |
| Ручная публикация | CI/CD: push → lint → test → build → deploy |
| Instance.new для UI | Fusion — реактивный декларативный UI |
| Сырые DataStores | ProfileStore — session-locked, auto-save, миграции |
| Нет аналитики | GameAnalytics + AnalyticsService + A/B тесты |
| Ручная загрузка ассетов | Asphalt — automated asset pipeline + codegen |
| Нет код-процессинга | Darklua — dead code elimination, минификация |
| Один язык (Luau) | Luau + Lune для build-скриптов + Python для аналитики |
| Не видят что делает ИИ | Screenshots + ClaudeCodeBridge + Blender MCP viewport |
