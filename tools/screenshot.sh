#!/bin/bash
# Скрипт для захвата скриншотов — даёт Claude Code "глаза"
# Использование: ./tools/screenshot.sh [target] [output]
#   target: screen (весь экран), studio (окно Roblox Studio), blender (окно Blender)
#   output: путь к файлу (по умолчанию /tmp/screenshot.png)

TARGET="${1:-screen}"
OUTPUT="${2:-/tmp/screenshot.png}"

case "$TARGET" in
    screen)
        screencapture -x "$OUTPUT"
        ;;
    studio)
        # Захват окна Roblox Studio по имени
        WINDOW_ID=$(osascript -e '
            tell application "System Events"
                set studioWindows to (every window of every process whose name contains "RobloxStudio")
                if (count of studioWindows) > 0 then
                    return id of item 1 of item 1 of studioWindows
                end if
            end tell
        ' 2>/dev/null)
        if [ -n "$WINDOW_ID" ]; then
            screencapture -x -l "$WINDOW_ID" "$OUTPUT"
        else
            # Fallback: попробуем через имя приложения
            osascript -e 'tell application "RobloxStudio" to activate' 2>/dev/null
            sleep 0.5
            screencapture -x "$OUTPUT"
        fi
        ;;
    blender)
        WINDOW_ID=$(osascript -e '
            tell application "System Events"
                set blenderWindows to (every window of every process whose name contains "Blender")
                if (count of blenderWindows) > 0 then
                    return id of item 1 of item 1 of blenderWindows
                end if
            end tell
        ' 2>/dev/null)
        if [ -n "$WINDOW_ID" ]; then
            screencapture -x -l "$WINDOW_ID" "$OUTPUT"
        else
            osascript -e 'tell application "Blender" to activate' 2>/dev/null
            sleep 0.5
            screencapture -x "$OUTPUT"
        fi
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Usage: screenshot.sh [screen|studio|blender] [output_path]"
        exit 1
        ;;
esac

if [ -f "$OUTPUT" ]; then
    SIZE=$(stat -f%z "$OUTPUT" 2>/dev/null || stat --printf="%s" "$OUTPUT" 2>/dev/null)
    DIMS=$(magick identify -format "%wx%h" "$OUTPUT" 2>/dev/null || sips -g pixelWidth -g pixelHeight "$OUTPUT" 2>/dev/null | grep pixel | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
    echo "Screenshot saved: $OUTPUT ($DIMS, ${SIZE} bytes)"
else
    echo "Failed to capture screenshot"
    exit 1
fi
