# 배포 가이드

이 문서는 NPKI Agent 인스톨러를 GitHub Releases를 통해 배포하고, 프론트엔드에서 직접 다운로드하는 방법을 설명합니다.

## 🔄 배포 플로우

```
코드 푸시/태그
    ↓
GitHub Actions 빌드
    ├─ macOS installer 빌드
    └─ Windows installer 빌드
    ↓
GitHub Releases 생성
    ├─ dev 환경: v1.0.0-dev (prerelease)
    └─ prod 환경: v1.0.0 (release)
    ↓
프론트엔드에서 직접 접근
    ↓
GitHub Releases API
    ↓
사용자 다운로드
```

---

## 📋 왜 Public 저장소가 좋은가?

### ✅ 장점
1. **직접 다운로드**: 프론트엔드에서 GitHub Releases로 직접 접근
2. **인증 불필요**: GitHub Token 설정 필요 없음
3. **백엔드 불필요**: 별도 프록시 서버 필요 없음
4. **CDN 제공**: GitHub의 빠른 CDN 활용
5. **무료**: GitHub의 무제한 Releases 저장소

---

## 🚀 환경별 배포 방법

### Development 환경

```bash
# 1. develop 브랜치에 코드 푸시
git checkout develop
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin develop

# 2. dev 태그 생성 및 푸시
git tag v1.0.0-dev
git push origin v1.0.0-dev

# 3. GitHub Actions 자동 실행
# → dev prerelease 생성
# → fair-npki-agent-macos.pkg
# → fair-npki-agent-windows.exe
```

### Production 환경

```bash
# 1. main 브랜치에 머지
git checkout main
git merge develop
git push origin main

# 2. prod 태그 생성 및 푸시
git tag v1.0.0
git push origin v1.0.0

# 3. GitHub Actions 자동 실행
# → production release 생성
# → fair-npki-agent-macos.pkg
# → fair-npki-agent-windows.exe
```

---

## 💻 프론트엔드 구현 (Public 저장소)

### TypeScript 타입 정의

```typescript
// types/installer.ts
export type Platform = 'macos' | 'windows';
export type Environment = 'dev' | 'prod';

export interface GitHubAsset {
  name: string;
  size: number;
  browser_download_url: string;
  created_at: string;
}

export interface GitHubRelease {
  tag_name: string;
  name: string;
  prerelease: boolean;
  published_at: string;
  assets: GitHubAsset[];
}

export interface InstallerInfo {
  version: string;
  fileName: string;
  size: number;
  sizeHuman: string;
  releaseDate: string;
  downloadUrl: string;
}
```

---

### 유틸리티 함수

```typescript
// lib/installer.ts
const GITHUB_OWNER = 'your-org';  // 실제 조직/사용자명으로 변경
const GITHUB_REPO = 'fair-NPKI-agent';

// 사용자 OS 감지
export function detectOS(): Platform | 'unknown' {
  const userAgent = window.navigator.userAgent.toLowerCase();
  
  if (userAgent.includes('mac')) {
    return 'macos';
  } else if (userAgent.includes('win')) {
    return 'windows';
  }
  
  return 'unknown';
}

// 파일 크기 변환
function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

// Release 정보 가져오기
export async function getRelease(environment: Environment): Promise<GitHubRelease | null> {
  try {
    if (environment === 'dev') {
      // Dev: 모든 릴리즈에서 prerelease 찾기
      const response = await fetch(
        `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases`
      );
      const releases: GitHubRelease[] = await response.json();
      
      // prerelease이면서 -dev 태그 포함
      return releases.find(r => r.prerelease && r.tag_name.includes('-dev')) || null;
    } else {
      // Prod: latest release
      const response = await fetch(
        `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest`
      );
      return await response.json();
    }
  } catch (error) {
    console.error('Failed to fetch release:', error);
    return null;
  }
}

// 인스톨러 정보 가져오기
export async function getInstallerInfo(
  environment: Environment,
  platform: Platform
): Promise<InstallerInfo | null> {
  const release = await getRelease(environment);
  
  if (!release) {
    return null;
  }
  
  const extension = platform === 'macos' ? 'pkg' : 'exe';
  const fileName = `fair-npki-agent-${platform}.${extension}`;
  const asset = release.assets.find(a => a.name === fileName);
  
  if (!asset) {
    return null;
  }
  
  return {
    version: release.tag_name,
    fileName: asset.name,
    size: asset.size,
    sizeHuman: formatFileSize(asset.size),
    releaseDate: release.published_at,
    downloadUrl: asset.browser_download_url,
  };
}

// 인스톨러 다운로드
export async function downloadInstaller(
  environment: Environment,
  platform: Platform
): Promise<void> {
  const info = await getInstallerInfo(environment, platform);
  
  if (!info) {
    throw new Error('Installer not found');
  }
  
  // 다운로드 시작
  window.location.href = info.downloadUrl;
}
```

---

### React 컴포넌트

```tsx
// components/InstallerDownload.tsx
'use client';

import { useState, useEffect } from 'react';
import { 
  downloadInstaller, 
  getInstallerInfo, 
  detectOS 
} from '@/lib/installer';
import type { Platform, Environment, InstallerInfo } from '@/types/installer';

export default function InstallerDownload() {
  const [environment, setEnvironment] = useState<Environment>('prod');
  const [platform, setPlatform] = useState<Platform>('macos');
  const [info, setInfo] = useState<InstallerInfo | null>(null);
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(false);

  useEffect(() => {
    // 사용자 OS 자동 감지
    const detectedOS = detectOS();
    if (detectedOS !== 'unknown') {
      setPlatform(detectedOS);
    }
  }, []);

  useEffect(() => {
    // 인스톨러 정보 가져오기
    const fetchInfo = async () => {
      setFetching(true);
      try {
        const data = await getInstallerInfo(environment, platform);
        setInfo(data);
      } catch (error) {
        console.error('Failed to fetch installer info:', error);
        setInfo(null);
      } finally {
        setFetching(false);
      }
    };
    
    fetchInfo();
  }, [environment, platform]);

  const handleDownload = async () => {
    setLoading(true);
    try {
      await downloadInstaller(environment, platform);
    } catch (error) {
      console.error('Download failed:', error);
      alert('다운로드에 실패했습니다. 다시 시도해주세요.');
    } finally {
      // 다운로드는 새 탭/창에서 진행되므로 바로 loading을 해제
      setTimeout(() => setLoading(false), 1000);
    }
  };

  return (
    <div className="p-6 max-w-md mx-auto bg-white rounded-xl shadow-lg">
      <h2 className="text-2xl font-bold mb-4">NPKI Agent 다운로드</h2>
      
      {/* 환경 선택 */}
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

      {/* 플랫폼 선택 */}
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

      {/* 인스톨러 정보 */}
      {fetching ? (
        <div className="mb-4 p-3 bg-gray-50 rounded text-sm text-center">
          정보를 불러오는 중...
        </div>
      ) : info ? (
        <div className="mb-4 p-3 bg-gray-50 rounded text-sm">
          <p><strong>버전:</strong> {info.version}</p>
          <p><strong>파일:</strong> {info.fileName}</p>
          <p><strong>크기:</strong> {info.sizeHuman}</p>
          <p>
            <strong>릴리즈:</strong>{' '}
            {new Date(info.releaseDate).toLocaleDateString('ko-KR')}
          </p>
        </div>
      ) : (
        <div className="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded text-sm">
          인스톨러를 찾을 수 없습니다.
        </div>
      )}

      {/* 다운로드 버튼 */}
      <button
        onClick={handleDownload}
        disabled={loading || !info}
        className="w-full p-3 bg-blue-500 text-white rounded font-semibold hover:bg-blue-600 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
      >
        {loading ? '다운로드 중...' : info ? '인스톨러 다운로드' : '사용할 수 없음'}
      </button>

      {/* 안내 */}
      <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded text-sm">
        <p className="font-semibold mb-1">📌 설치 안내</p>
        <ol className="list-decimal list-inside space-y-1">
          <li>다운로드된 인스톨러를 실행합니다</li>
          <li>설치가 완료되면 자동으로 서버가 시작됩니다</li>
          <li>재부팅 후에도 자동으로 실행됩니다</li>
        </ol>
      </div>

      {/* GitHub 링크 */}
      <div className="mt-3 text-center text-sm text-gray-500">
        <a 
          href={`https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases`}
          target="_blank"
          rel="noopener noreferrer"
          className="hover:text-blue-500 underline"
        >
          모든 릴리즈 보기 →
        </a>
      </div>
    </div>
  );
}
```

---

### Vue.js 구현

```vue
<!-- components/InstallerDownload.vue -->
<template>
  <div class="installer-download">
    <h2>NPKI Agent 다운로드</h2>
    
    <!-- 환경 선택 -->
    <div class="form-group">
      <label>환경</label>
      <select v-model="environment">
        <option value="dev">Development</option>
        <option value="prod">Production</option>
      </select>
    </div>

    <!-- 플랫폼 선택 -->
    <div class="form-group">
      <label>플랫폼</label>
      <div class="platform-buttons">
        <button 
          @click="platform = 'macos'" 
          :class="{ active: platform === 'macos' }"
        >
          🍎 macOS
        </button>
        <button 
          @click="platform = 'windows'" 
          :class="{ active: platform === 'windows' }"
        >
          🪟 Windows
        </button>
      </div>
    </div>

    <!-- 인스톨러 정보 -->
    <div v-if="fetching" class="installer-info loading">
      정보를 불러오는 중...
    </div>
    <div v-else-if="info" class="installer-info">
      <p><strong>버전:</strong> {{ info.version }}</p>
      <p><strong>파일:</strong> {{ info.fileName }}</p>
      <p><strong>크기:</strong> {{ info.sizeHuman }}</p>
      <p><strong>릴리즈:</strong> {{ formatDate(info.releaseDate) }}</p>
    </div>
    <div v-else class="installer-info error">
      인스톨러를 찾을 수 없습니다.
    </div>

    <!-- 다운로드 버튼 -->
    <button 
      @click="handleDownload" 
      :disabled="loading || !info"
      class="download-button"
    >
      {{ loading ? '다운로드 중...' : info ? '인스톨러 다운로드' : '사용할 수 없음' }}
    </button>

    <!-- 안내 -->
    <div class="guide">
      <p class="guide-title">📌 설치 안내</p>
      <ol>
        <li>다운로드된 인스톨러를 실행합니다</li>
        <li>설치가 완료되면 자동으로 서버가 시작됩니다</li>
        <li>재부팅 후에도 자동으로 실행됩니다</li>
      </ol>
    </div>

    <!-- GitHub 링크 -->
    <div class="github-link">
      <a 
        :href="`https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases`"
        target="_blank"
        rel="noopener noreferrer"
      >
        모든 릴리즈 보기 →
      </a>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';

type Platform = 'macos' | 'windows';
type Environment = 'dev' | 'prod';

const GITHUB_OWNER = 'your-org';  // 실제 값으로 변경
const GITHUB_REPO = 'fair-NPKI-agent';

const environment = ref<Environment>('prod');
const platform = ref<Platform>('macos');
const info = ref<any>(null);
const loading = ref(false);
const fetching = ref(false);

// 사용자 OS 자동 감지
onMounted(() => {
  const userAgent = window.navigator.userAgent.toLowerCase();
  if (userAgent.includes('mac')) {
    platform.value = 'macos';
  } else if (userAgent.includes('win')) {
    platform.value = 'windows';
  }
});

// 환경/플랫폼 변경 시 정보 가져오기
watch([environment, platform], async () => {
  await fetchInfo();
}, { immediate: true });

async function fetchInfo() {
  fetching.value = true;
  info.value = null;
  
  try {
    let releaseUrl: string;
    if (environment.value === 'dev') {
      releaseUrl = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases`;
    } else {
      releaseUrl = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest`;
    }
    
    const response = await fetch(releaseUrl);
    let release;
    
    if (environment.value === 'dev') {
      const releases = await response.json();
      release = releases.find((r: any) => r.prerelease && r.tag_name.includes('-dev'));
    } else {
      release = await response.json();
    }
    
    if (release) {
      const extension = platform.value === 'macos' ? 'pkg' : 'exe';
      const fileName = `fair-npki-agent-${platform.value}.${extension}`;
      const asset = release.assets.find((a: any) => a.name === fileName);
      
      if (asset) {
        info.value = {
          version: release.tag_name,
          fileName: asset.name,
          size: asset.size,
          sizeHuman: formatFileSize(asset.size),
          releaseDate: release.published_at,
          downloadUrl: asset.browser_download_url,
        };
      }
    }
  } catch (error) {
    console.error('Failed to fetch installer info:', error);
  } finally {
    fetching.value = false;
  }
}

async function handleDownload() {
  if (!info.value) return;
  
  loading.value = true;
  window.location.href = info.value.downloadUrl;
  setTimeout(() => {
    loading.value = false;
  }, 1000);
}

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

function formatDate(dateString: string) {
  return new Date(dateString).toLocaleDateString('ko-KR');
}
</script>

<style scoped>
.installer-download {
  padding: 1.5rem;
  max-width: 28rem;
  margin: 0 auto;
  background: white;
  border-radius: 0.75rem;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
}

.form-group {
  margin-bottom: 1rem;
}

.platform-buttons {
  display: flex;
  gap: 1rem;
}

.platform-buttons button {
  flex: 1;
  padding: 0.5rem;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
  background: white;
  cursor: pointer;
}

.platform-buttons button.active {
  background: #3b82f6;
  color: white;
}

.installer-info {
  margin-bottom: 1rem;
  padding: 0.75rem;
  background: #f9fafb;
  border-radius: 0.375rem;
  font-size: 0.875rem;
}

.installer-info.loading {
  text-align: center;
  color: #6b7280;
}

.installer-info.error {
  background: #fef3c7;
  border: 1px solid #fbbf24;
}

.download-button {
  width: 100%;
  padding: 0.75rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 0.375rem;
  font-weight: 600;
  cursor: pointer;
}

.download-button:hover:not(:disabled) {
  background: #2563eb;
}

.download-button:disabled {
  background: #d1d5db;
  cursor: not-allowed;
}

.guide {
  margin-top: 1rem;
  padding: 0.75rem;
  background: #dbeafe;
  border: 1px solid #93c5fd;
  border-radius: 0.375rem;
  font-size: 0.875rem;
}

.guide-title {
  font-weight: 600;
  margin-bottom: 0.25rem;
}

.github-link {
  margin-top: 0.75rem;
  text-align: center;
  font-size: 0.875rem;
  color: #6b7280;
}

.github-link a {
  color: #6b7280;
  text-decoration: underline;
}

.github-link a:hover {
  color: #3b82f6;
}
</style>
```

---

## 🧪 테스트

### GitHub API 직접 테스트

```bash
# Latest release 조회
curl https://api.github.com/repos/your-org/fair-NPKI-agent/releases/latest

# 모든 releases 조회
curl https://api.github.com/repos/your-org/fair-NPKI-agent/releases

# 특정 release 조회
curl https://api.github.com/repos/your-org/fair-NPKI-agent/releases/tags/v1.0.0-dev
```

---

## 📊 릴리즈 태그 전략

### Development (Prerelease)
```bash
git tag v1.0.0-dev
git tag v1.0.1-dev
git tag v1.1.0-dev
```

### Production (Release)
```bash
git tag v1.0.0
git tag v1.1.0
git tag v2.0.0
```

---

## 💡 요약

**Public 저장소의 장점:**
- ✅ **프론트엔드에서 직접 다운로드** - GitHub API로 바로 접근
- ✅ **인증 불필요** - GitHub Token 설정 필요 없음
- ✅ **백엔드 불필요** - 별도 프록시 서버 불필요
- ✅ **빠른 CDN** - GitHub의 글로벌 CDN 활용
- ✅ **간단한 구조** - 유지보수 용이

**핵심:**
- GitHub Releases API 직접 호출
- `browser_download_url`로 즉시 다운로드
- 환경별 구분은 prerelease 플래그와 태그로 관리

---

## 📚 참고 문서

- [GitHub Releases API 문서](https://docs.github.com/en/rest/releases)
- [README.md](./README.md) - 프로젝트 개요
