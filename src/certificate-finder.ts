import fs from 'fs';
import path from 'path';
import os from 'os';

export type Certificate = {
  id: string;
  issuer: string;
  fileName: string;
  path: string;
  size: number;
  modifiedDate: string;
};

// NPKI 폴더 경로 가져오기
const getNPKIPaths = (): string[] => {
  const platform = os.platform();
  console.log('platform', platform);

  if (platform === 'darwin') {
    // macOS: 현재 사용자만
    const homeDir = os.homedir();
    console.log('homeDir', homeDir);
    return [path.join(homeDir, 'Library', 'Preferences', 'NPKI'), path.join(homeDir, 'Documents')];
  } else if (platform === 'win32') {
    // Windows: 모든 사용자 폴더 스캔
    const usersDir = 'C:\\Users';
    const paths: string[] = [];

    try {
      if (fs.existsSync(usersDir)) {
        const users = fs.readdirSync(usersDir);
        console.log(`📂 Found ${users.length} user folders in ${usersDir}`);

        for (const user of users) {
          // 시스템 폴더 제외
          if (['Public', 'Default', 'Default User', 'All Users'].includes(user)) {
            continue;
          }

          const userPaths = [
            path.join(usersDir, user, 'AppData', 'LocalLow', 'NPKI'),
            path.join(usersDir, user, 'Documents', 'NPKI'),
          ];

          paths.push(...userPaths);
          console.log(`👤 Added paths for user: ${user}`);
        }
      }
    } catch (error) {
      console.error('Failed to scan users directory:', error);
      // Fallback: 현재 사용자 경로만 사용
      const homeDir = os.homedir();
      console.log('Fallback to current user homeDir:', homeDir);
      return [
        path.join(homeDir, 'AppData', 'LocalLow', 'NPKI'),
        path.join(homeDir, 'Documents', 'NPKI'),
      ];
    }

    return paths;
  }

  return [];
};

// 디렉토리에서 재귀적으로 인증서 파일 찾기
const findCertificateFiles = (baseDir: string): string[] => {
  const results: string[] = [];

  if (!fs.existsSync(baseDir)) {
    return results;
  }

  function traverse(dir: string) {
    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);

        if (entry.isDirectory()) {
          console.log('fullPath', fullPath);
          traverse(fullPath);
        } else if (entry.isFile()) {
          const ext = path.extname(entry.name).toLowerCase();
          if (ext === '.pfx' || ext === '.p12' || ext === '.der' || ext === '.key') {
            results.push(fullPath);
          }
        }
      }
    } catch (error) {
      // 권한 오류 등은 무시
      console.error(`Error reading directory ${dir}:`, error);
    }
  }

  traverse(baseDir);
  return results;
};

// 발급기관 추출 (경로에서)
const extractIssuer = (filePath: string): string => {
  const parts = filePath.split(path.sep);
  const npkiIndex = parts.findIndex((p) => p.toUpperCase() === 'NPKI');

  if (npkiIndex >= 0 && npkiIndex + 1 < parts.length) {
    return parts[npkiIndex + 1];
  }

  return 'Unknown';
};

// 인증서 ID 생성 (파일 경로 기반 해시)
const generateCertId = (filePath: string): string => {
  // 간단한 ID 생성 (경로 기반)
  return Buffer.from(filePath).toString('base64').substring(0, 32);
};

// 모든 인증서 찾기
export const findCertificates = async (): Promise<Certificate[]> => {
  const certificates: Certificate[] = [];
  const npkiPaths = getNPKIPaths();

  console.log('=== findCertificates 시작 ===');
  console.log('현재 시간:', new Date().toISOString());

  console.log('📂 NPKI 경로 목록:', npkiPaths);
  console.log('📂 경로 개수:', npkiPaths.length);

  for (const npkiPath of npkiPaths) {
    const certFiles = findCertificateFiles(npkiPath);

    console.log('📂 인증서 파일:', certFiles);
    console.log('📂 인증서 파일 개수:', certFiles.length);

    for (const certFile of certFiles) {
      try {
        const stats = fs.statSync(certFile);
        const fileName = path.basename(certFile);
        const issuer = extractIssuer(certFile);
        const id = generateCertId(certFile);

        certificates.push({
          id,
          issuer,
          fileName,
          path: certFile,
          size: stats.size,
          modifiedDate: stats.mtime.toISOString(),
        });
      } catch (error) {
        console.error(`Error reading certificate file ${certFile}:`, error);
      }
    }
  }

  return certificates;
};
