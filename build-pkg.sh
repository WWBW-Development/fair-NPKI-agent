#!/bin/bash

set -e

echo "🔨 Building NPKI Agent .pkg installer..."
echo ""

# 1. 바이너리 빌드
echo "1️⃣ Building Node.js binary..."
npm run pack:mac
echo "✅ Binary built: build/npki-agent-macos"
echo ""

# 2. 패키지 구조 생성
echo "2️⃣ Creating package structure..."
rm -rf pkg_root
mkdir -p pkg_root/usr/local/bin
mkdir -p pkg_root/tmp

# 바이너리 복사
cp build/npki-agent-macos pkg_root/usr/local/bin/fair-npki-agent
chmod +x pkg_root/usr/local/bin/fair-npki-agent

# plist 파일을 /tmp에 복사 (postinstall에서 사용)
cp com.wwbw.fair-npki-agent.plist pkg_root/tmp/com.wwbw.fair-npki-agent.plist

echo "✅ Package structure created"
echo ""

# 3. .pkg 빌드
echo "3️⃣ Building .pkg installer..."
pkgbuild --root pkg_root \
         --scripts scripts \
         --identifier com.wwbw.fair-npki-agent \
         --version 1.0.0 \
         --install-location / \
         build/NPKIAgent.pkg

echo "✅ PKG built: build/NPKIAgent.pkg"
echo ""

# 4. 정리
# rm -rf pkg_root

# 5. 결과 출력
PKG_SIZE=$(du -h build/NPKIAgent.pkg | cut -f1)
echo "📦 Package Information:"
echo "   File: build/NPKIAgent.pkg"
echo "   Size: $PKG_SIZE"
echo ""
echo "🎉 Build complete!"
echo ""
echo "To test installation:"
echo "  sudo installer -pkg build/NPKIAgent.pkg -target /"
echo ""
echo "To check if running:"
echo "  launchctl list | grep npki"
echo "  curl http://localhost:62735/npki/health"
echo "  tail -f /tmp/fair-npki-agent.log"
