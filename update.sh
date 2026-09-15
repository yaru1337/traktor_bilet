#!/bin/bash
# Быстрое обновление веб-версии после правок в tickets.json
cp /c/traktor/editor/tickets.json assets/tickets.json
flutter build web --release --base-href /traktor_bilet/
cp -r build/web/* .
git add .
git commit -m "Update tickets"
git push
echo "Готово. Подождите 1-2 минуты."