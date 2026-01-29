#!/bin/bash

# NSSM (Non-Sucking Service Manager) 다운로드 스크립트
# Windows 서비스 등록을 위해 필요

set -e

NSSM_VERSION="2.24"
# GitHub mirror (more reliable than nssm.cc)
NSSM_URL="https://github.com/kirillkovalenko/nssm/releases/download/${NSSM_VERSION}/nssm-${NSSM_VERSION}.zip"
TOOLS_DIR="$(dirname "$0")/../tools"
DOWNLOAD_DIR="/tmp/nssm-download"

echo "📦 Downloading NSSM ${NSSM_VERSION} from GitHub..."

# 임시 디렉토리 생성
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# NSSM 다운로드 (재시도 3회)
echo "⬇️  Downloading from ${NSSM_URL}..."
curl -L -o nssm.zip --retry 3 --retry-delay 5 "$NSSM_URL"

# 압축 해제
echo "📂 Extracting..."
unzip -q nssm.zip

# 64bit 버전만 복사
echo "📋 Copying nssm.exe (64-bit)..."
mkdir -p "$TOOLS_DIR"
cp "nssm-${NSSM_VERSION}/win64/nssm.exe" "$TOOLS_DIR/nssm.exe"

# 정리
cd -
rm -rf "$DOWNLOAD_DIR"

echo "✅ NSSM downloaded successfully to tools/nssm.exe"
ls -lh "$TOOLS_DIR/nssm.exe"
