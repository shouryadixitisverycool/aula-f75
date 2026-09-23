#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="$DIR/web"

echo "========================================="
echo "       AULA F75 Linux Controller         "
echo "========================================="

# 1. Check udev rule
if [ ! -f /etc/udev/rules.d/99-aula-f75.rules ]; then
    echo ""
    echo "⚠️  [Notice] udev rule is not installed yet."
    echo "To allow Chromium to talk to your keyboard without root, run:"
    echo "  sudo cp \"$DIR/udev/99-aula-f75.rules\" /etc/udev/rules.d/"
    echo "  sudo udevadm control --reload-rules && sudo udevadm trigger"
    echo "Then unplug and replug your keyboard."
    echo ""
fi

cd "$WEB_DIR"

# 2. Automatically install npm dependencies if missing
if [ ! -d "node_modules" ]; then
    echo "📦 node_modules not found. Downloading npm dependencies..."
    npm install
fi

# 3. Automatically build production files if missing
if [ ! -d ".next" ]; then
    echo "⚙️  Production build not found. Building project..."
    npm run build
fi

echo "🚀 Starting server at http://localhost:3000 ..."

# 4. Start Next.js server in the background
npm start &
SERVER_PID=$!

# Ensure server process is terminated on script exit
trap "kill $SERVER_PID 2>/dev/null || true" EXIT INT TERM

# 5. Wait for the server to respond
for i in {1..20}; do
    if curl -s -o /dev/null http://localhost:3000; then
        break
    fi
    sleep 0.5
done

# 6. Launch in Chromium-based browser
echo "🌐 Opening Chromium at http://localhost:3000 ..."
if command -v chromium >/dev/null 2>&1; then
    chromium http://localhost:3000 >/dev/null 2>&1 &
elif command -v google-chrome-stable >/dev/null 2>&1; then
    google-chrome-stable http://localhost:3000 >/dev/null 2>&1 &
elif command -v google-chrome >/dev/null 2>&1; then
    google-chrome http://localhost:3000 >/dev/null 2>&1 &
elif command -v brave >/dev/null 2>&1; then
    brave http://localhost:3000 >/dev/null 2>&1 &
elif command -v microsoft-edge >/dev/null 2>&1; then
    microsoft-edge http://localhost:3000 >/dev/null 2>&1 &
else
    echo "⚠️  No Chromium-based browser detected."
    echo "👉 Please open http://localhost:3000 in your browser."
fi

echo ""
echo "✅ Server running! (Press Ctrl+C to stop)"
wait $SERVER_PID
