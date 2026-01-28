

echo "🗑️  Uninstalling NPKI Agent..."
echo ""

LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/com.wwbw.fair-npki-agent.plist"

# 1. 서비스 중지
echo "1️⃣ Stopping service..."
if launchctl list | grep -q "com.wwbw.fair-npki-agent"; then
    launchctl stop com.wwbw.fair-npki-agent
    echo "✅ Service stopped"
else
    echo "⚠️  Service not running"
fi
echo ""

# 2. LaunchAgent 언로드
echo "2️⃣ Unloading LaunchAgent..."
if [ -f "$LAUNCH_AGENT_PATH" ]; then
    launchctl unload "$LAUNCH_AGENT_PATH"
    echo "✅ LaunchAgent unloaded"
else
    echo "⚠️  LaunchAgent not found"
fi
echo ""

# 3. 파일 삭제
echo "3️⃣ Removing files..."

# LaunchAgent plist 삭제
if [ -f "$LAUNCH_AGENT_PATH" ]; then
    rm "$LAUNCH_AGENT_PATH"
    echo "✅ Removed: $LAUNCH_AGENT_PATH"
fi

# 바이너리 삭제
if [ -f "/usr/local/bin/fair-npki-agent" ]; then
    sudo rm /usr/local/bin/fair-npki-agent
    echo "✅ Removed: /usr/local/bin/fair-npki-agent"
fi

# 로그 파일 삭제 (선택)
if [ -f "/tmp/fair-npki-agent.log" ]; then
    rm /tmp/fair-npki-agent.log
    echo "✅ Removed: /tmp/fair-npki-agent.log"
fi

if [ -f "/tmp/fair-npki-agent.error.log" ]; then
    rm /tmp/fair-npki-agent.error.log
    echo "✅ Removed: /tmp/fair-npki-agent.error.log"
fi

echo ""
echo "🎉 NPKI Agent has been completely uninstalled!"
echo ""
echo "To verify:"
echo "  launchctl list | grep npki  (should be empty)"
echo "  curl http://localhost:62735/npki/health  (should fail)"
