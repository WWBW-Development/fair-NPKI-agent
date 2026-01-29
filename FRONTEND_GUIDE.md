# 프론트엔드 통합 가이드

NPKI Agent 인스톨러를 프론트엔드에서 다운로드하는 방법입니다.

## 🎯 개요

Public 저장소이므로 프론트엔드에서 **GitHub API로 직접 접근**하여 인스톨러를 다운로드할 수 있습니다.

- ✅ 백엔드 서버 불필요
- ✅ GitHub Token 불필요
- ✅ 인증 불필요

---

## 🔗 GitHub 정보

```typescript
const GITHUB_OWNER = 'your-org';  // 실제 조직/사용자명으로 변경
const GITHUB_REPO = 'fair-NPKI-agent';
```

---

## 📥 빠른 시작

### 1. 기본 다운로드 (가장 간단)

```typescript
// 최신 프로덕션 버전 다운로드
const owner = 'your-org';
const repo = 'fair-NPKI-agent';
const platform = 'macos'; // 또는 'windows'
const extension = platform === 'macos' ? 'pkg' : 'exe';

// Latest release에서 직접 다운로드
window.location.href = `https://github.com/${owner}/${repo}/releases/latest/download/fair-npki-agent-${platform}.${extension}`;
```

---

### 2. 환경별 다운로드 (dev/prod 구분)

```typescript
async function downloadInstaller(
  environment: 'dev' | 'prod',
  platform: 'macos' | 'windows'
) {
  const owner = 'your-org';
  const repo = 'fair-NPKI-agent';
  
  // 1. Release 정보 가져오기
  let release;
  if (environment === 'dev') {
    // Dev: 모든 릴리즈에서 prerelease 찾기
    const response = await fetch(`https://api.github.com/repos/${owner}/${repo}/releases`);
    const releases = await response.json();
    release = releases.find(r => r.prerelease && r.tag_name.includes('-dev'));
  } else {
    // Prod: latest release
    const response = await fetch(`https://api.github.com/repos/${owner}/${repo}/releases/latest`);
    release = await response.json();
  }
  
  if (!release) {
    throw new Error('Release not found');
  }
  
  // 2. 인스톨러 파일 찾기
  const extension = platform === 'macos' ? 'pkg' : 'exe';
  const fileName = `fair-npki-agent-${platform}.${extension}`;
  const asset = release.assets.find(a => a.name === fileName);
  
  if (!asset) {
    throw new Error('Installer not found');
  }
  
  // 3. 다운로드
  window.location.href = asset.browser_download_url;
}

// 사용 예시
downloadInstaller('prod', 'macos');
downloadInstaller('dev', 'windows');
```

---

## 📦 완전한 구현 예시

### TypeScript

```typescript
// types/installer.ts
export type Platform = 'macos' | 'windows';
export type Environment = 'dev' | 'prod';

export interface InstallerInfo {
  version: string;
  fileName: string;
  size: number;
  sizeHuman: string;
  releaseDate: string;
  downloadUrl: string;
}

// lib/installer.ts
const GITHUB_OWNER = 'your-org';
const GITHUB_REPO = 'fair-NPKI-agent';

export function detectOS(): Platform | 'unknown' {
  const ua = window.navigator.userAgent.toLowerCase();
  if (ua.includes('mac')) return 'macos';
  if (ua.includes('win')) return 'windows';
  return 'unknown';
}

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

export async function getInstallerInfo(
  environment: Environment,
  platform: Platform
): Promise<InstallerInfo | null> {
  try {
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
    
    if (!release) return null;
    
    const extension = platform === 'macos' ? 'pkg' : 'exe';
    const fileName = `fair-npki-agent-${platform}.${extension}`;
    const asset = release.assets.find(a => a.name === fileName);
    
    if (!asset) return null;
    
    return {
      version: release.tag_name,
      fileName: asset.name,
      size: asset.size,
      sizeHuman: formatFileSize(asset.size),
      releaseDate: release.published_at,
      downloadUrl: asset.browser_download_url,
    };
  } catch (error) {
    console.error('Failed to fetch installer info:', error);
    return null;
  }
}

export async function downloadInstaller(
  environment: Environment,
  platform: Platform
): Promise<void> {
  const info = await getInstallerInfo(environment, platform);
  
  if (!info) {
    throw new Error('Installer not found');
  }
  
  window.location.href = info.downloadUrl;
}
```

---

### React 컴포넌트 예시

```tsx
import { useState, useEffect } from 'react';
import { downloadInstaller, getInstallerInfo, detectOS } from '@/lib/installer';
import type { Platform, Environment } from '@/types/installer';

export default function InstallerDownload() {
  const [environment, setEnvironment] = useState<Environment>('prod');
  const [platform, setPlatform] = useState<Platform>('macos');
  const [info, setInfo] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const os = detectOS();
    if (os !== 'unknown') setPlatform(os);
  }, []);

  useEffect(() => {
    getInstallerInfo(environment, platform).then(setInfo);
  }, [environment, platform]);

  const handleDownload = async () => {
    setLoading(true);
    try {
      await downloadInstaller(environment, platform);
    } catch (error) {
      alert('다운로드에 실패했습니다.');
    } finally {
      setTimeout(() => setLoading(false), 1000);
    }
  };

  return (
    <div className="p-6 max-w-md mx-auto bg-white rounded-xl shadow-lg">
      <h2 className="text-2xl font-bold mb-4">NPKI Agent 다운로드</h2>
      
      <div className="mb-4">
        <label className="block text-sm font-medium mb-2">환경</label>
        <select
          value={environment}
          onChange={(e) => setEnvironment(e.target.value as Environment)}
          className="w-full p-2 border rounded"
        >
          <option value="dev">Development</option>
          <option value="prod">Production</option>
        </select>
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium mb-2">플랫폼</label>
        <div className="flex gap-4">
          <button
            onClick={() => setPlatform('macos')}
            className={`flex-1 p-2 border rounded ${
              platform === 'macos' ? 'bg-blue-500 text-white' : 'bg-white'
            }`}
          >
            🍎 macOS
          </button>
          <button
            onClick={() => setPlatform('windows')}
            className={`flex-1 p-2 border rounded ${
              platform === 'windows' ? 'bg-blue-500 text-white' : 'bg-white'
            }`}
          >
            🪟 Windows
          </button>
        </div>
      </div>

      {info && (
        <div className="mb-4 p-3 bg-gray-50 rounded text-sm">
          <p><strong>버전:</strong> {info.version}</p>
          <p><strong>파일:</strong> {info.fileName}</p>
          <p><strong>크기:</strong> {info.sizeHuman}</p>
        </div>
      )}

      <button
        onClick={handleDownload}
        disabled={loading || !info}
        className="w-full p-3 bg-blue-500 text-white rounded font-semibold hover:bg-blue-600 disabled:bg-gray-300"
      >
        {loading ? '다운로드 중...' : '인스톨러 다운로드'}
      </button>
    </div>
  );
}
```

---

## 🔗 GitHub API 엔드포인트

### Latest Release (Prod)
```
GET https://api.github.com/repos/{owner}/{repo}/releases/latest
```

**응답 예시:**
```json
{
  "tag_name": "v1.0.0",
  "name": "Release v1.0.0",
  "prerelease": false,
  "published_at": "2026-01-26T12:00:00Z",
  "assets": [
    {
      "name": "fair-npki-agent-macos.pkg",
      "size": 26214400,
      "browser_download_url": "https://github.com/.../fair-npki-agent-macos.pkg"
    },
    {
      "name": "fair-npki-agent-windows.exe",
      "size": 55574528,
      "browser_download_url": "https://github.com/.../fair-npki-agent-windows.exe"
    }
  ]
}
```

### All Releases (Dev 포함)
```
GET https://api.github.com/repos/{owner}/{repo}/releases
```

**필터링:**
```javascript
const devRelease = releases.find(r => r.prerelease && r.tag_name.includes('-dev'));
```

---

## 🎯 환경별 구분

| 환경 | GitHub Release | API 엔드포인트 | 필터 |
|------|----------------|----------------|------|
| **Dev** | Prerelease | `/releases` | `prerelease=true && tag_name.includes('-dev')` |
| **Prod** | Release (Latest) | `/releases/latest` | 자동 |

---

## 📱 다운로드 URL 형식

### Direct Download (가장 빠름)
```
https://github.com/{owner}/{repo}/releases/latest/download/{fileName}
```

예시:
- `https://github.com/your-org/fair-NPKI-agent/releases/latest/download/fair-npki-agent-macos.pkg`
- `https://github.com/your-org/fair-NPKI-agent/releases/latest/download/fair-npki-agent-windows.exe`

### API Download (더 많은 정보 필요 시)
```
asset.browser_download_url
```

---

## 🧪 테스트

```bash
# Latest release 정보
curl https://api.github.com/repos/your-org/fair-NPKI-agent/releases/latest

# 모든 releases
curl https://api.github.com/repos/your-org/fair-NPKI-agent/releases

# 직접 다운로드
curl -L -O https://github.com/your-org/fair-NPKI-agent/releases/latest/download/fair-npki-agent-macos.pkg
```

---

## 💡 주의사항

### Rate Limiting
GitHub API는 시간당 60 requests 제한이 있습니다 (인증 없는 경우).

**해결방법:**
- 프론트엔드에서 캐싱 사용
- 사용자 액션(버튼 클릭)에만 API 호출
- 정보를 자주 갱신하지 않음

### CORS
GitHub API는 CORS를 지원하므로 프론트엔드에서 직접 호출 가능합니다.

### 파일 크기
- macOS: ~25MB
- Windows: ~53MB

다운로드 시간을 고려하여 UI에 진행 상태를 표시하는 것이 좋습니다.

---

## 📚 참고 문서

- [DEPLOYMENT.md](./DEPLOYMENT.md) - 전체 배포 가이드 및 Vue.js 예시
- [GitHub Releases API](https://docs.github.com/en/rest/releases)
- [README.md](./README.md) - 프로젝트 개요
