import fs from 'fs';
import path from 'path';
import os from 'os';

// API 응답 타입 (클라이언트에서 사용)
export type Certificate = {
  folderName: string; // 현재 폴더명 (인증서가 있는 폴더)
  pfxFileBase64?: string; // base64
  derFileBase64?: string; // base64
  keyFileBase64?: string; // base64
};

// 파일을 base64로 인코딩 (클라이언트의 base64ToFile 형식에 맞춤)
const fileToBase64WithFilename = (filePath: string, fileName: string): string => {
  const buffer = fs.readFileSync(filePath);
  const base64Data = buffer.toString('base64');

  // 클라이언트에서 decodeURIComponent(atob(encodedFilename))로 디코딩하므로
  // 서버에서는 encodeURIComponent -> base64 순서로 인코딩
  const uriEncodedFilename = encodeURIComponent(fileName);
  const encodedFilename = Buffer.from(uriEncodedFilename).toString('base64');

  // MIME 타입 결정
  const ext = fileName.toLowerCase().split('.').pop();
  let mimeType = 'application/octet-stream';
  if (ext === 'pfx' || ext === 'p12') {
    mimeType = 'application/x-pkcs12';
  } else if (ext === 'der') {
    mimeType = 'application/x-x509-ca-cert';
  } else if (ext === 'key') {
    mimeType = 'application/pkcs8';
  }

  // data:mime;base64,xxxxx&encodedFilename 형식
  return `data:${mimeType};base64,${base64Data}&${encodedFilename}`;
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

// 디렉토리에서 재귀적으로 인증서 찾기 (바로 base64로 인코딩해서 반환)
const findCertificateFiles = (baseDir: string): Certificate[] => {
  const results: Certificate[] = [];
  const processedDerFiles = new Set<string>(); // 이미 처리된 .der 파일 추적

  if (!fs.existsSync(baseDir)) {
    return results;
  }

  function traverse(dir: string) {
    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });

      // 같은 폴더에 있는 .der, .key, .pfx 파일 수집
      const derFiles: { fileName: string; path: string }[] = [];
      const keyFiles: { fileName: string; path: string }[] = [];
      const pfxFiles: { fileName: string; path: string }[] = [];

      // entries를 순회하며 바로 분류
      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);

        if (entry.isDirectory()) {
          console.log('fullPath', fullPath);
          traverse(fullPath);
        } else if (entry.isFile()) {
          const ext = path.extname(entry.name).toLowerCase();

          if (ext === '.der') {
            derFiles.push({ fileName: entry.name, path: fullPath });
          } else if (ext === '.key') {
            keyFiles.push({ fileName: entry.name, path: fullPath });
          } else if (ext === '.pfx' || ext === '.p12') {
            pfxFiles.push({ fileName: entry.name, path: fullPath });
          }
        }
      }

      // .der과 .key를 쌍으로 묶기 (현재 폴더에 둘 다 있으면 쌍으로 간주)
      if (derFiles.length > 0 && keyFiles.length > 0) {
        derFiles.forEach((derFile) => {
          if (processedDerFiles.has(derFile.path)) return;

          // 현재 폴더의 .key 파일과 매칭
          const matchingKeyFile = keyFiles[0]; // 같은 폴더에 하나만 있을 것으로 가정

          try {
            const folderName = path.basename(dir);

            results.push({
              folderName,
              derFileBase64: fileToBase64WithFilename(derFile.path, derFile.fileName),
              keyFileBase64: fileToBase64WithFilename(
                matchingKeyFile.path,
                matchingKeyFile.fileName
              ),
            });

            processedDerFiles.add(derFile.path);
          } catch (error) {
            console.error(`Error reading der-key pair ${derFile.path}:`, error);
          }
        });
      }

      // .pfx / .p12 파일 처리
      pfxFiles.forEach((pfxFile) => {
        try {
          const folderName = path.basename(dir);

          results.push({
            folderName,
            pfxFileBase64: fileToBase64WithFilename(pfxFile.path, pfxFile.fileName),
          });
        } catch (error) {
          console.error(`Error reading pfx file ${pfxFile.path}:`, error);
        }
      });
    } catch (error) {
      // 권한 오류 등은 무시
      console.error(`Error reading directory ${dir}:`, error);
    }
  }

  traverse(baseDir);
  return results;
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
    // findCertificateFiles가 이미 쌍으로 묶어서 Certificate[] 반환
    const certs = findCertificateFiles(npkiPath);
    console.log(`📂 ${npkiPath}에서 발견된 인증서 쌍:`, certs.length);
    certificates.push(...certs);
  }

  console.log('📋 총 인증서 쌍 개수:', certificates.length);
  return certificates;
};
