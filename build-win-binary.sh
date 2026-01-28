#!/bin/bash
# Build Windows binary on macOS
# This only builds the binary, not the installer

set -e

echo "🔨 Building Windows binary on macOS..."
echo ""

# Step 1: Type check
echo "[1/2] Type checking..."
npm run type-check
echo ""

# Step 2: Build Windows binary
echo "[2/2] Building Windows binary with @yao-pkg/pkg..."
npx pkg . --targets node22-win-x64 --output build/npki-agent-win.exe

# Check if binary exists
if [ ! -f "build/npki-agent-win.exe" ]; then
    echo "❌ Error: Binary not found at build/npki-agent-win.exe"
    exit 1
fi

# Get binary size
BINARY_SIZE=$(stat -f%z "build/npki-agent-win.exe" 2>/dev/null || echo "0")
BINARY_MB=$((BINARY_SIZE / 1048576))

echo ""
echo "========================================="
echo "✅ Windows binary build complete!"
echo "========================================="
echo ""
echo "Binary: build/npki-agent-win.exe"
echo "Size: ${BINARY_SIZE} bytes (~${BINARY_MB}MB)"
echo ""
echo "📝 Next steps:"
echo ""
echo "To create Windows installer (.exe):"
echo "  1. Transfer build/npki-agent-win.exe to a Windows machine"
echo "  2. Install Inno Setup: https://jrsoftware.org/isdl.php"
echo "  3. Install NSSM: choco install nssm"
echo "  4. Run: build-installer.bat"
echo ""
echo "Or distribute the binary directly:"
echo "  - Users can run: npki-agent-win.exe"
echo "  - Or install as service: cd scripts && install.bat"
echo ""
