"""
Roblox Game Analyzer — поиск "заброшенных" игр с хорошими концепциями.

Источники данных:
1. Rolimon's Game Table — peak vs current CCU, лайки, визиты (~617 игр)
2. RoMonitor Stats API — тренды, детальная статистика, жанры
3. Rotrends — revenue, session time, дата обновления

Стратегия: найти игры где Peak CCU >> Current CCU + низкий Like% = хорошая идея, плохая реализация.
"""

import requests
import re
import json
import time
import os
from datetime import datetime, timezone

# ─── Настройки ────────────────────────────────────────────────────────────────

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
    "Accept": "application/json, text/html",
}

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))


# ─── 1. Rolimon's: Peak vs Current CCU ──────────────────────────────────────

def fetch_rolimons_data():
    """Парсит game_details из HTML страницы Rolimon's Game Table."""
    print("\n📊 [1/3] Загрузка данных Rolimon's Game Table...")

    url = "https://www.rolimons.com/gametable"
    resp = requests.get(url, headers=HEADERS, timeout=30)
    resp.raise_for_status()

    match = re.search(r'var\s+game_details\s*=\s*(\{.*?\});', resp.text, re.DOTALL)
    if not match:
        print("   ❌ Не удалось найти game_details в HTML")
        return {}

    games = json.loads(match.group(1))
    print(f"   ✅ Загружено {len(games)} игр из Rolimon's")

    # Преобразуем в удобный формат
    # [0] name, [1] genre, [2] image, [3] current_players, [4] visits,
    # [5] likes, [6] dislikes, [7] favorites, [8] timestamp, [9] peak_players
    parsed = {}
    for game_id, data in games.items():
        if len(data) < 10:
            continue
        name, genre, img, current, visits, likes, dislikes, favs, ts, peak = data
        like_pct = (likes / (likes + dislikes) * 100) if (likes + dislikes) > 0 else 0
        drop_ratio = (peak / current) if current > 0 else float('inf')

        parsed[game_id] = {
            "id": game_id,
            "name": name,
            "genre": genre,
            "current_players": current,
            "peak_players": peak,
            "drop_ratio": drop_ratio,
            "visits": visits,
            "likes": likes,
            "dislikes": dislikes,
            "like_pct": round(like_pct, 1),
            "favorites": favs,
            "image": img,
        }

    return parsed


# ─── 2. RoMonitor Stats API: детальная статистика ───────────────────────────

def fetch_romonitor_game_profile(place_id):
    """Получает профиль игры из RoMonitor Stats API."""
    url = f"https://romonitorstats.com/api/v1/stats/game-profile/get/?placeId={place_id}"
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        if resp.status_code == 200:
            return resp.json()
    except Exception:
        pass
    return None


def fetch_romonitor_game_stats(place_id):
    """Получает детальную статистику игры из RoMonitor Stats API."""
    url = f"https://romonitorstats.com/api/v1/stats/game-general/get/?placeId={place_id}"
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        if resp.status_code == 200:
            return resp.json()
    except Exception:
        pass
    return None


def fetch_romonitor_top_games(sort_code="top-playing-now", pages=3):
    """Получает список топ-игр из RoMonitor Stats API."""
    print(f"\n📊 [2/3] Загрузка данных RoMonitor Stats (sort: {sort_code})...")

    all_games = []
    for page in range(1, pages + 1):
        url = f"https://romonitorstats.com/api/v1/stats/sort/get/?code={sort_code}&page={page}"
        try:
            resp = requests.get(url, headers=HEADERS, timeout=15)
            if resp.status_code == 200:
                data = resp.json()
                if isinstance(data, list):
                    all_games.extend(data)
                elif isinstance(data, dict) and "data" in data:
                    all_games.extend(data["data"])
                elif isinstance(data, dict) and "experiences" in data:
                    all_games.extend(data["experiences"])
            time.sleep(0.5)  # не спамим API
        except Exception as e:
            print(f"   ⚠️ Ошибка на странице {page}: {e}")

    print(f"   ✅ Загружено {len(all_games)} игр из RoMonitor Stats")
    return all_games


# ─── 3. Rotrends: revenue и дата обновления ─────────────────────────────────

def fetch_rotrends_game(game_id):
    """Парсит данные отдельной игры со страницы Rotrends."""
    url = f"https://rotrends.com/game/{game_id}"
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        if resp.status_code != 200:
            return None

        html = resp.text
        data = {}

        # Извлекаем ключевые метрики из HTML
        patterns = {
            "revenue_7d": r'7-Day RAP.*?<[^>]*>([^<]*)\$([0-9,.]+)',
            "revenue_7d_alt": r'\$([0-9,.]+).*?7-Day RAP',
            "last_updated": r'Last Updated.*?<[^>]*>([^<]+)',
            "last_updated_alt": r'Updated\s*:?\s*(\d{4}-\d{2}-\d{2})',
            "session_duration": r'Session Duration.*?<[^>]*>([0-9,.]+)',
            "earning_rank": r'Earning Rank.*?#?(\d+)',
        }

        for key, pattern in patterns.items():
            match = re.search(pattern, html, re.IGNORECASE | re.DOTALL)
            if match:
                data[key] = match.group(1) if len(match.groups()) == 1 else match.group(2)

        return data
    except Exception:
        return None


# ─── Анализ: находим "заброшенные алмазы" ───────────────────────────────────

def analyze_abandoned_gems(rolimons_data, min_peak=1000, max_current_ratio=0.02):
    """
    Находит игры где:
    - Peak CCU >= min_peak (доказанный интерес)
    - Current / Peak <= max_current_ratio (потеряли аудиторию)

    Сортирует по потенциалу (peak * visits * favorites).
    """
    gems = []

    for game_id, game in rolimons_data.items():
        peak = game["peak_players"]
        current = game["current_players"]

        if peak < min_peak:
            continue

        if current > 0 and (current / peak) > max_current_ratio:
            continue

        # Скор потенциала: чем больше пик, визитов и фаворитов — тем лучше идея
        potential = (peak * (game["visits"] / 1e9) * (game["favorites"] / 1e6))

        gems.append({
            **game,
            "potential_score": round(potential, 2),
        })

    gems.sort(key=lambda x: x["potential_score"], reverse=True)
    return gems


def analyze_low_rated_popular(rolimons_data, min_visits=10_000_000, max_like_pct=75):
    """
    Находит игры с большим количеством визитов но низким рейтингом.
    = идея привлекает, но реализация разочаровывает.
    """
    candidates = []

    for game_id, game in rolimons_data.items():
        if game["visits"] < min_visits:
            continue
        if game["like_pct"] >= max_like_pct or game["like_pct"] == 0:
            continue

        candidates.append(game)

    candidates.sort(key=lambda x: x["visits"], reverse=True)
    return candidates


# ─── Обогащение данных через RoMonitor ──────────────────────────────────────

def enrich_with_romonitor(games, limit=20):
    """Добавляет данные RoMonitor Stats к найденным играм."""
    print(f"\n🔍 Обогащение данных через RoMonitor Stats ({limit} игр)...")

    enriched = 0
    for game in games[:limit]:
        game_id = game["id"]

        profile = fetch_romonitor_game_profile(game_id)
        if profile:
            game["rm_genre"] = profile.get("genre", profile.get("genres", ""))
            game["rm_creation"] = profile.get("creationDate", "")
            game["rm_update"] = profile.get("updateDate", "")
            enriched += 1

        stats = fetch_romonitor_game_stats(game_id)
        if stats:
            game["rm_avg_players"] = stats.get("averagePlayers", "")
            game["rm_yesterday_visits"] = stats.get("yesterdayVisits", "")
            game["rm_highest"] = stats.get("highestPlayers", "")
            game["rm_rating"] = stats.get("rating", "")
            game["rm_favorites"] = stats.get("favorites", "")

        time.sleep(0.3)  # Rate limiting

    print(f"   ✅ Обогащено {enriched}/{limit} игр")
    return games


# ─── Форматирование результатов ─────────────────────────────────────────────

def format_number(n):
    if n >= 1_000_000_000:
        return f"{n / 1_000_000_000:.1f}B"
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K"
    return str(n)


def generate_report(abandoned_gems, low_rated, romonitor_trending):
    """Генерирует MD-отчёт с результатами анализа."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    lines = []
    lines.append(f"# Roblox: Аналитика заброшенных игр с потенциалом")
    lines.append(f"> Сгенерировано: {now}\n")
    lines.append(f"---\n")

    # ── Секция 1: Заброшенные алмазы ──
    lines.append("## 1. Заброшенные игры с высоким пиком (abandoned gems)\n")
    lines.append("Игры, которые когда-то имели тысячи игроков, но сейчас почти пусты.")
    lines.append("**Стратегия:** изучи концепцию, пойми что зацепило людей, сделай свою версию лучше.\n")

    lines.append("| # | Игра | Peak CCU | Сейчас | Падение | Визиты | Лайк% | Фавориты | Потенциал |")
    lines.append("|---|------|----------|--------|---------|--------|-------|----------|-----------|")

    for i, g in enumerate(abandoned_gems[:30], 1):
        current_str = str(g['current_players']) if g['current_players'] > 0 else "0"
        drop = f"{g['drop_ratio']:.0f}x" if g['drop_ratio'] != float('inf') else "∞"
        lines.append(
            f"| {i} | **{g['name']}** | {format_number(g['peak_players'])} | "
            f"{current_str} | {drop} | {format_number(g['visits'])} | "
            f"{g['like_pct']}% | {format_number(g['favorites'])} | {g['potential_score']} |"
        )

    # Дополнительные данные RoMonitor
    has_rm = any("rm_update" in g for g in abandoned_gems[:30])
    if has_rm:
        lines.append("\n### Детали (RoMonitor Stats)\n")
        for i, g in enumerate(abandoned_gems[:30], 1):
            if "rm_update" in g and g.get("rm_update"):
                update_date = g['rm_update'][:10] if g.get('rm_update') else "?"
                genre = g.get('rm_genre', '?')
                lines.append(f"- **{g['name']}** — жанр: {genre}, последнее обновление: {update_date}")

    # ── Секция 2: Популярные но нелюбимые ──
    lines.append(f"\n---\n")
    lines.append("## 2. Популярные, но с низким рейтингом\n")
    lines.append("Игры с миллионами визитов, но Like% ниже 75%.")
    lines.append("**Стратегия:** идея привлекает людей, но реализация разочаровывает. Сделай лучше.\n")

    lines.append("| # | Игра | Визиты | Лайк% | Сейчас CCU | Peak CCU | Фавориты |")
    lines.append("|---|------|--------|-------|-----------|----------|----------|")

    for i, g in enumerate(low_rated[:20], 1):
        lines.append(
            f"| {i} | **{g['name']}** | {format_number(g['visits'])} | "
            f"**{g['like_pct']}%** | {g['current_players']} | "
            f"{format_number(g['peak_players'])} | {format_number(g['favorites'])} |"
        )

    # ── Секция 3: Что сейчас в тренде (для контекста) ──
    if romonitor_trending:
        lines.append(f"\n---\n")
        lines.append("## 3. Сейчас в тренде (RoMonitor Stats)\n")
        lines.append("Для понимания рынка — какие игры сейчас на вершине.\n")

        lines.append("| # | Игра | CCU сейчас |")
        lines.append("|---|------|-----------|")

        for i, g in enumerate(romonitor_trending[:20], 1):
            if isinstance(g, dict):
                name = g.get("name", g.get("formattedName", "?"))
                playing = g.get("playing", "?")
            else:
                name = str(g)
                playing = "?"
            lines.append(f"| {i} | {name} | {format_number(playing) if isinstance(playing, (int, float)) else playing} |")

    # ── Секция 4: Рекомендации ──
    lines.append(f"\n---\n")
    lines.append("## 4. Рекомендации по действиям\n")
    lines.append("### Топ-5 возможностей для ремейка:\n")

    for i, g in enumerate(abandoned_gems[:5], 1):
        lines.append(f"### {i}. {g['name']}")
        lines.append(f"- **Был пик:** {format_number(g['peak_players'])} игроков")
        lines.append(f"- **Сейчас:** {g['current_players']} игроков")
        lines.append(f"- **Всего визитов:** {format_number(g['visits'])}")
        lines.append(f"- **Рейтинг:** {g['like_pct']}%")
        if g.get("rm_genre"):
            lines.append(f"- **Жанр:** {g['rm_genre']}")
        if g.get("rm_update"):
            lines.append(f"- **Последнее обновление:** {g['rm_update'][:10]}")
        lines.append(f"- **Что делать:** Поиграй в эту игру, прочитай отзывы, пойми что нравилось игрокам и что бесило. Создай свою версию с улучшениями.")
        lines.append("")

    lines.append("### Следующие шаги:\n")
    lines.append("1. Выбери 3-5 игр из списка выше")
    lines.append("2. Поиграй в каждую — запиши плюсы и минусы")
    lines.append("3. Прочитай отзывы и комментарии игроков")
    lines.append("4. Выбери одну игру для ремейка")
    lines.append("5. Создай свою версию с нуля (свой код, свои ассеты, свои улучшения)")
    lines.append("6. Запусти + TikTok маркетинг\n")

    return "\n".join(lines)


# ─── Main ────────────────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("  ROBLOX GAME ANALYZER — поиск заброшенных алмазов")
    print("=" * 60)

    # 1. Rolimon's
    rolimons = fetch_rolimons_data()
    if not rolimons:
        print("❌ Не удалось загрузить данные Rolimon's. Прерываю.")
        return

    # 2. RoMonitor trending (для контекста рынка)
    trending = fetch_romonitor_top_games("top-playing-now", pages=2)

    # 3. Анализ
    print("\n🔎 [3/3] Анализ данных...")

    abandoned = analyze_abandoned_gems(rolimons, min_peak=1000, max_current_ratio=0.02)
    print(f"   ✅ Найдено {len(abandoned)} заброшенных игр с высоким пиком")

    low_rated = analyze_low_rated_popular(rolimons, min_visits=10_000_000, max_like_pct=75)
    print(f"   ✅ Найдено {len(low_rated)} популярных игр с низким рейтингом")

    # 4. Обогащение топ-игр данными RoMonitor
    abandoned = enrich_with_romonitor(abandoned, limit=20)

    # 5. Генерация отчёта
    print("\n📝 Генерация отчёта...")
    report = generate_report(abandoned, low_rated, trending)

    output_path = os.path.join(OUTPUT_DIR, "analytics-report.md")
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(report)

    print(f"\n✅ Отчёт сохранён: {output_path}")
    print(f"   Заброшенных алмазов: {len(abandoned)}")
    print(f"   Низкорейтинговых популярных: {len(low_rated)}")
    print(f"   Трендовых (контекст): {len(trending)}")
    print("\n" + "=" * 60)


if __name__ == "__main__":
    main()
