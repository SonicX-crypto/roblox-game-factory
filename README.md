# Roblox Game Factory

> AI-driven разработка Roblox-игр. Claude Code + Blender MCP + Rojo = автономное создание игр от идеи до публикации.

---

## Стратегия

### Цель
Создать прибыльную Roblox-игру с минимальным ручным трудом, используя ИИ для написания кода, генерации 3D-моделей и аналитики рынка.

### Подход: "Улучшенный ремейк"
1. **Найти** заброшенные игры с доказанным спросом (высокий пик CCU, но упавшая аудитория)
2. **Проанализировать** почему аудитория ушла (низкий Like%, отзывы, отсутствие обновлений)
3. **Создать свою версию** с нуля — свой код, свои ассеты, улучшенный UX
4. **Запустить** с TikTok/YouTube маркетингом
5. **Итерировать** на основе метрик (DAU, retention, ARPDAU)

### Монетизация
- Game Passes (VIP, Skip Stage, Speed Boost)
- Developer Products (пакеты валюты, бустеры)
- Подписки (ежемесячный VIP)
- Creator Rewards (5 Robux за качественного игрока/день)
- Rewarded Video Ads
- Private Servers

### Целевые метрики
| Метрика | Цель |
|---|---|
| Session Time | 10+ мин |
| D1 Retention | 15%+ |
| Like % | 70%+ |
| DAU | Рост неделя к неделе |

---

## Арсенал

### CLI-инструменты (Roblox Toolchain)

| Инструмент | Версия | Назначение |
|---|---|---|
| **Rojo** | 7.7.0-rc.1 | Синхронизация Luau-кода с Roblox Studio. Позволяет писать код в VSCode и автоматически передавать в Studio |
| **Wally** | 0.3.2 | Пакетный менеджер для Luau. Установка библиотек: Knit (фреймворк), ProfileService (сохранение данных), Promise и др. |
| **Selene** | 0.30.1 | Линтер для Luau. Находит ошибки, неиспользуемые переменные, потенциальные баги до запуска |
| **StyLua** | 2.4.0 | Автоформатирование Luau-кода. Единый стиль во всём проекте |
| **rbxcloud** | 0.17.0 | CLI для Roblox Open Cloud API. Публикация, управление DataStores, MessagingService, ассетами |
| **Aftman** | 0.3.0 | Менеджер тулчейна. Управляет версиями Rojo, Wally, Selene, StyLua |

### VSCode расширения

| Расширение | Назначение |
|---|---|
| **Rojo** | Интеграция Rojo в VSCode — кнопки синхронизации, автоподключение к Studio |
| **Luau** | Подсветка синтаксиса, автодополнение, проверка типов для языка Luau |
| **Roblox UI** | Визуальный редактор интерфейсов (ScreenGui, Frames, TextLabels) |

### Визуальный контроль (Claude Code "видит" что делает)

| Инструмент | Назначение |
|---|---|
| **screenshot.sh** | Захват экрана, окна Roblox Studio или Blender — Claude Code видит результат |
| **ClaudeCodeBridge** | Плагин Studio — доступ к сцене, объектам, выполнение Luau-кода удалённо |
| **studio-bridge.py** | HTTP-мост между Claude Code и Studio plugin |
| **Blender MCP viewport** | Скриншот 3D-viewport Blender через MCP |
| **ImageMagick** | Обработка изображений — иконки, thumbnails, ресайз текстур |

Как Claude Code "видит":

- `./tools/screenshot.sh studio` — скриншот окна Roblox Studio
- `./tools/screenshot.sh blender` — скриншот окна Blender
- `./tools/screenshot.sh screen` — весь экран
- Blender MCP → `get_viewport_screenshot` — viewport Blender напрямую
- ClaudeCodeBridge → `get_scene_tree` — полное дерево объектов сцены Studio

### MCP-серверы (AI-интеграции)

| MCP | Назначение |
|---|---|
| **Blender MCP** | Claude Code управляет Blender напрямую — создание 3D-моделей, текстурирование, экспорт в .fbx для импорта в Studio |

Возможности Blender MCP:
- Генерация 3D-моделей через текстовые промпты (Hyper3D, Hunyuan3D)
- Скачивание готовых ассетов с PolyHaven и Sketchfab
- Программное управление сценой (создание объектов, материалов, анимаций)
- Скриншоты viewport для превью
- Экспорт в форматы, совместимые с Roblox Studio (.fbx, .obj)

### Приложения

| Приложение | Назначение |
|---|---|
| **Roblox Studio** | Основная среда — сборка мира, тестирование, публикация |
| **Blender** | 3D-моделирование (управляется через MCP) |
| **ImageMagick** | CLI для обработки изображений (иконки, текстуры, thumbnails) |

### Аналитические инструменты

| Инструмент | Назначение |
|---|---|
| **Profitable.app** | Фильтры "Hidden Gems", "Popular but Abandoned" — поиск ниш |
| **Rolimon's Game Table** | Сравнение Peak CCU vs Current — массовый скрининг |
| **RoMonitor Stats** | Исторические графики CCU, Chrome-расширение |
| **Rotrends** | Revenue, session time, trending lists, 100K+ игр |
| **RTrack** | Поминутные данные, многолетняя история |
| **analyzer.py** | Наш скрипт — парсит Rolimon's + RoMonitor, генерирует отчёт по заброшенным играм |

### API-ключи

| Ключ | Файл | Назначение |
|---|---|---|
| Roblox Open Cloud | `roblox_api` | Публикация, DataStores, MessagingService, управление ассетами |

---

## Структура проекта

```
roblox/
├── README.md              # Этот файл — стратегия и арсенал
├── aftman.toml             # Конфигурация тулчейна (Rojo, Wally, Selene, StyLua)
├── roblox_api              # API-ключ Roblox Open Cloud (в .gitignore)
├── analyzer.py             # Скрипт аналитики — парсинг Rolimon's, RoMonitor Stats
├── analytics-report.md     # Отчёт: заброшенные игры с потенциалом для ремейка
├── studio-plugin/
│   └── ClaudeCodeBridge.server.lua  # Плагин Studio — удалённый доступ к сцене
├── tools/
│   ├── screenshot.sh       # Захват скриншотов (экран, Studio, Blender)
│   └── studio-bridge.py    # HTTP-мост Claude Code <-> Studio plugin
├── roblox-guide.md         # Полный гайд: от нуля до заработка на Roblox с ИИ
└── presentation.html       # Презентация стратегии
```

---

## Workflow: от идеи до публикации

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐
│  Аналитика  │───>│  Разработка  │───>│  Публикация  │
│ analyzer.py │    │  Claude Code  │    │   rbxcloud   │
│ Rolimon's   │    │  + Rojo      │    │ Roblox Studio│
│ RoMonitor   │    │  + Blender   │    │              │
└─────────────┘    └──────────────┘    └──────────────┘
       │                  │                    │
       v                  v                    v
  Выбор ниши      Luau-скрипты          Маркетинг
  и концепта      3D-модели             TikTok/YouTube
                  UI/UX                 Обновления
```

### 1. Аналитика (найти нишу)
```bash
python analyzer.py          # Парсит данные, генерирует analytics-report.md
```

### 2. Инициализация проекта
```bash
rojo init my-game           # Создать структуру Rojo-проекта
wally init                  # Инициализировать пакетный менеджер
wally install               # Установить зависимости (Knit, ProfileService и т.д.)
```

### 3. Разработка (Claude Code делает автономно)
- Пишет Luau-скрипты (серверные, клиентские, модули)
- Создаёт 3D-модели через Blender MCP
- Проверяет код: `selene src/` + `stylua src/`
- Синхронизирует с Studio: `rojo serve`

### 4. Тестирование
- Rojo синхронизирует код → тестируешь в Roblox Studio (F5)
- Проверка на мобильных устройствах (эмулятор в Studio)

### 5. Публикация
```bash
rbxcloud experience publish --api-key $(cat roblox_api) ...
```
Или через Roblox Studio: File → Publish to Roblox

---

## Быстрый старт

### Предусловия
- [x] Roblox Studio установлен
- [x] Blender установлен + MCP подключен
- [x] VSCode + расширения (Rojo, Luau, Roblox UI)
- [x] CLI-инструменты установлены (aftman.toml)
- [x] Roblox API ключ получен

### Проверка инструментов
```bash
rojo --version      # 7.7.0-rc.1
wally --version     # 0.3.2
selene --version    # 0.30.1
stylua --version    # 2.4.0
rbxcloud --version  # 0.17.0
```

### PATH (добавлено в ~/.zshrc)
```bash
export PATH="$HOME/.aftman/bin:$HOME/.cargo/bin:$PATH"
```
