#!/bin/bash

# Сначала проверяем, что tickets.json на месте
SRC="/d/traktor/tickets.json"    # ← ЗАМЕНИТЕ на реальный путь
if [ ! -f "$SRC" ]; then
  echo "❌ Не найден файл: $SRC"
  echo "Проверьте путь и запустите заново."
  exit 1
fi

cp "$SRC" assets/tickets.json
echo "✓ tickets.json обновлён"

# MSYS_NO_PATHCONV=1 отключает преобразование путей в Git Bash
MSYS_NO_PATHCONV=1 flutter build web --release --base-href /traktor_bilet/

cp -r build/web/* .
git add .
git commit -m "Update tickets"
git push

echo "✓ Готово. Через 1–2 минуты обновится сайт."