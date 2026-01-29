# NPKI Certificate Auto-Discovery Agent

NPKI 인증서를 자동으로 탐색하고 HTTP API로 제공하는 백그라운드 Node.js 에이전트입니다.

## 기능

- 백그라운드에서 창 없이 실행
- HTTP 서버 (localhost:62735)
- NPKI 인증서 자동 탐색 (.pfx, .p12, .der/.key)
- REST API를 통한 인증서 제공

## 설치

```bash
npm install
```

## 개발 실행

```bash
npm run dev
```

또는

```bash
npm start
```

## 설치 방법

### macOS - .pkg 인스톨러 (추천)

**가장 쉬운 방법**: 설치 후 자동으로 백그라운드 서버가 실행되고, 재부팅해도 자동 시작됩니다.

#### 빌드

```bash
npm run build:mac
# 출력: build/fair-npki-agent-macos.pkg (~25MB)
```

#### 설치

```bash
# 더블클릭으로 설치
open build/fair-npki-agent-macos.pkg
```

#### 설치 후 자동 실행

- ✅ 설치 즉시 `localhost:62735`에서 서버 시작
- ✅ 재부팅 후에도 자동으로 시작
- ✅ 프로세스가 종료되어도 자동으로 재시작

#### 상태 확인

```bash
# 서비스 실행 확인
launchctl list | grep wwbw

# 서버 응답 확인
curl http://localhost:62735/npki/health

# 로그 확인
tail -f /tmp/fair-npki-agent.log
```

#### 제거

```bash
./uninstall.sh
```

---

### Windows - .exe 인스톨러 (추천)

**가장 쉬운 방법**: 설치 후 자동으로 백그라운드 서비스가 실행되고, 재부팅해도 자동 시작됩니다.

#### 빌드 (GitHub Actions 자동)

GitHub Actions가 자동으로 Windows 인스톨러를 빌드합니다:
- NSSM이 인스톨러에 포함됨 (별도 설치 불필요)
- Inno Setup으로 `.exe` 인스톨러 생성
- 출력: `build/fair-npki-agent-windows.exe` (~56MB)

#### 설치

```powershell
# 관리자 권한으로 인스톨러 실행
.\fair-npki-agent-windows.exe
```

#### 설치 후 자동 실행

- ✅ 설치 즉시 `localhost:62735`에서 서버 시작
- ✅ Windows 서비스로 자동 등록
- ✅ 재부팅 후에도 자동으로 시작
- ✅ 프로세스가 종료되어도 자동으로 재시작

#### 상태 확인

```powershell
# 서비스 상태 확인
sc query NPKIAgent

# 서버 응답 확인
curl http://localhost:62735/npki/health

# 서비스 관리
services.msc  # GUI로 서비스 관리
```

#### 수동 제거

```powershell
# 프로그램 추가/제거에서 제거
# 또는 수동 제거
cd "C:\Program Files\NPKIAgent"
.\uninstall.bat
```

---

### Windows - 수동 설치 (개발자용)

인스톨러 없이 수동으로 설치하려면:

```powershell
# 1. 바이너리 빌드 (macOS에서)
npm run pack:win

# 2. NSSM 다운로드 (Windows에서)
# https://nssm.cc/download

# 3. Service 설치 (Windows에서)
cd scripts
.\install.bat
```

**방법 2: 수동 설치**
```powershell
# 1. 바이너리 실행 테스트
.\npki-agent-win.exe

# 2. Service 등록 (선택)
cd scripts
.\install.bat
```

#### 설치 후 확인

```powershell
# 서비스 상태 확인
sc query NPKIAgent

# 서버 응답 확인
curl http://localhost:62735/npki/health

# 로그 확인
type %TEMP%\fair-npki-agent.log
```

#### 제거

```powershell
# 인스톨러로 설치한 경우
# 설정 > 앱 > "NPKI Agent" 제거

# 수동 설치한 경우
cd scripts
.\uninstall.bat
```

---

### 바이너리 직접 실행 (개발/테스트용)

단일 실행 파일로 패키징하여 수동으로 실행할 수 있습니다:

#### macOS

```bash
npm run pack:mac
# 출력: build/npki-agent-macos

# 실행
./build/npki-agent-macos
```

#### Windows

```powershell
npm run pack:win
# 출력: build/npki-agent-win.exe

# 실행
.\build\npki-agent-win.exe
```

#### 모든 플랫폼 (macOS + Windows)

```bash
npm run pack
```

---

## 수동 백그라운드 실행 (고급)

**인스톨러를 사용하면 이 과정이 자동화됩니다!** 아래는 직접 설정하려는 경우입니다.

### macOS - launchd

```bash
# 1. 바이너리를 시스템 경로로 복사
sudo cp build/npki-agent-macos /usr/local/bin/fair-npki-agent
sudo chmod +x /usr/local/bin/fair-npki-agent

# 2. LaunchAgent 설치
cp com.wwbw.fair-npki-agent.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.wwbw.fair-npki-agent.plist
launchctl start com.wwbw.fair-npki-agent
```

### Windows - 수동 Service 설정

#### 사전 준비: NSSM 설치

```powershell
# Chocolatey로 설치
choco install nssm

# 또는 수동 다운로드
# https://nssm.cc/download
```

#### Service 설치

```powershell
# 관리자 권한으로 실행
cd scripts
.\install.bat
```

또는 수동으로:

```powershell
# 바이너리 복사
copy build\npki-agent-win.exe "C:\Program Files\NPKIAgent\fair-npki-agent.exe"

# Service 등록
nssm install NPKIAgent "C:\Program Files\NPKIAgent\fair-npki-agent.exe"
nssm set NPKIAgent DisplayName "NPKI Certificate Agent"
nssm set NPKIAgent Description "NPKI Certificate Auto-Discovery Agent"
nssm set NPKIAgent Start SERVICE_AUTO_START

# Service 시작
nssm start NPKIAgent
```

#### Service 제거

```powershell
# 관리자 권한으로 실행
cd scripts
.\uninstall.bat
```

## API 명세

### 1. Health Check

```
GET /npki/health
```

**응답:**

```json
{
  "status": "ok",
  "version": "1.0.0"
}
```

### 2. 인증서 조회

```
GET /npki/certificates
```

**응답 형식:** `multipart/form-data`

**응답 구조:**

- `metadata`: JSON 문자열 (인증서 메타데이터 배열)
- `certificate_0`: 첫 번째 .pfx/.p12 파일 (바이너리)
- `certificate_1`: 두 번째 .pfx/.p12 파일 (바이너리)
- `certificate_N`: N번째 .pfx/.p12 파일 (바이너리)

**메타데이터 형식:**

```json
[
  {
    "index": 0,
    "id": "인증서_고유_ID",
    "issuer": "발급기관명",
    "fileName": "파일명.pfx",
    "size": 파일크기(바이트),
    "modifiedDate": "수정일시(ISO8601)"
  }
]
```


## NPKI 탐색 경로

### macOS

- `~/Library/Preferences/NPKI`
- `~/Documents/NPKI`

### Windows

- `%USERPROFILE%/AppData/LocalLow/NPKI`
- `%USERPROFILE%/Documents/NPKI`

## CORS 설정

localhost의 모든 포트에서 접근 가능합니다.

## 기술 스택

- **TypeScript**: 타입 안전성
- **Node.js 22 (LTS)**: 런타임
- **Express**: HTTP 서버
- **CORS**: Cross-Origin 지원
- **form-data**: multipart/form-data 지원
- **@yao-pkg/pkg**: 단일 실행 파일 패키징

## 프로젝트 구조

```
fair-NPKI-agent/
├── src/
│   ├── main.ts                    # Node.js 진입점
│   ├── server.ts                  # Express 서버 및 API
│   └── certificate-finder.ts      # NPKI 인증서 탐색 로직
├── scripts/
│   ├── postinstall                # macOS .pkg 설치 후 실행 스크립트
│   ├── install.bat                # Windows Service 설치 스크립트
│   └── uninstall.bat              # Windows Service 제거 스크립트
├── installer/
│   └── setup.iss                  # Inno Setup 인스톨러 스크립트 (Windows 환경에서 사용)
├── dist/                          # 컴파일된 JavaScript (빌드 후)
├── build/                         # 패키징된 바이너리 및 인스톨러 (빌드 후)
│   ├── npki-agent-macos           # macOS 바이너리
│   ├── npki-agent-win.exe         # Windows 바이너리
│   ├── fair-npki-agent-macos.pkg  # macOS 인스톨러
│   └── fair-npki-agent-windows.exe # Windows 인스톨러 (Windows에서 빌드)
├── com.wwbw.fair-npki-agent.plist # macOS LaunchAgent 설정
├── build-pkg.sh                   # macOS .pkg 빌드 스크립트 (macOS에서 실행)
├── build-win-binary.sh            # Windows 바이너리 빌드 스크립트 (macOS에서 실행)
├── build-installer.bat            # Windows .exe 인스톨러 빌드 스크립트 (Windows에서 실행)
├── uninstall.sh                   # macOS 제거 스크립트
├── package.json
├── tsconfig.json
└── README.md
```

## 개발 워크플로우 (macOS 기반)

### 로컬 개발
```bash
npm run dev              # 개발 서버 실행
npm run type-check       # TypeScript 검사
```

### 빌드
```bash
# macOS 인스톨러 빌드
npm run build:mac        # → build/fair-npki-agent-macos.pkg

# Windows 바이너리 빌드
npm run build:win        # → build/npki-agent-win.exe

# 양쪽 플랫폼 바이너리 빌드
npm run pack             # → build/npki-agent-macos, build/npki-agent-win.exe
```

### Windows 인스톨러 (Windows 환경 필요)
```bash
# 1. macOS에서 Windows 바이너리 빌드
npm run build:win

# 2. build/npki-agent-win.exe를 Windows로 전송

# 3. Windows에서 실행
build-installer.bat      # → build/fair-npki-agent-windows.exe
```

---

## 🚀 GitHub Actions를 통한 자동 빌드 및 배포

Windows 인스톨러를 macOS에서 직접 빌드할 수 없지만, **GitHub Actions를 사용하면 양쪽 플랫폼 인스톨러를 자동으로 빌드하고 GitHub Releases에 배포**할 수 있습니다!

### 설정 방법

`.github/workflows/build.yml` 파일이 이미 포함되어 있습니다. 태그를 푸시하면 자동으로 빌드 및 Release 생성이 시작됩니다.

### 환경별 배포

#### Development 환경
```bash
# Dev 태그 생성 및 푸시
git tag v1.0.0-dev
git push origin v1.0.0-dev

# → GitHub Prerelease 생성
```

#### Production 환경
```bash
# Prod 태그 생성 및 푸시
git tag v1.0.0
git push origin v1.0.0

# → GitHub Release 생성
```

### 빌드 및 배포 플로우

```
태그 푸시 (v1.0.0-dev 또는 v1.0.0)
    ↓
GitHub Actions 실행
    ├─ macOS runner: fair-npki-agent-macos.pkg 빌드
    └─ Windows runner: fair-npki-agent-windows.exe 빌드
    ↓
GitHub Releases 생성
    ├─ dev: Prerelease (v*-dev 태그)
    └─ prod: Release (v* 태그)
    ↓
프론트엔드에서 직접 접근
    ↓
GitHub Releases API
    ↓
사용자 다운로드
```

### 프론트엔드에서 다운로드

```typescript
// GitHub API로 직접 접근 (Public 저장소)
const GITHUB_OWNER = 'your-org';
const GITHUB_REPO = 'fair-NPKI-agent';

async function downloadInstaller(environment: 'dev' | 'prod', platform: 'macos' | 'windows') {
  // 1. Release 정보 가져오기
  let releaseUrl: string;
  if (environment === 'dev') {
    releaseUrl = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases`;
  } else {
    releaseUrl = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest`;
  }
  
  const response = await fetch(releaseUrl);
  let release;
  
  if (environment === 'dev') {
    const releases = await response.json();
    release = releases.find(r => r.prerelease && r.tag_name.includes('-dev'));
  } else {
    release = await response.json();
  }
  
  // 2. 인스톨러 파일 찾기
  const extension = platform === 'macos' ? 'pkg' : 'exe';
  const fileName = `fair-npki-agent-${platform}.${extension}`;
  const asset = release.assets.find(a => a.name === fileName);
  
  // 3. 다운로드
  window.location.href = asset.browser_download_url;
}
```

> 💡 **Public 저장소의 장점**
> - 프론트엔드에서 GitHub Releases로 직접 접근 가능
> - 별도 백엔드 서버 불필요
> - GitHub Token 설정 불필요
> - GitHub CDN으로 빠른 다운로드

자세한 구현 예시는 [DEPLOYMENT.md](./DEPLOYMENT.md)를 참고하세요.

### 장점

- ✅ macOS에서도 Windows 인스톨러 자동 빌드
- ✅ 환경별 자동 배포 (dev/prod)
- ✅ GitHub Releases 자동 생성
- ✅ 프론트엔드에서 직접 다운로드
- ✅ 별도 백엔드 인프라 불필요
- ✅ GitHub CDN으로 빠른 다운로드
- ✅ 푸시할 때마다 자동 검증
- ✅ 일관된 빌드 환경
- ✅ Windows 환경 불필요

---

## 라이선스

MIT
