import express, { Request, Response } from 'express';
import packageJson from '../package.json';
import cors from 'cors';
import FormData from 'form-data';
import fs from 'fs';
import { findCertificates } from './certificate-finder';

const app = express();
const PORT = 62735;

const allowedOrigins = [
  /^https?:\/\/localhost(:\d+)?$/, // HTTP/HTTPS 모두
  'https://fair-mobile-frontend-test.azurewebsites.net',
  'https://fair.wwbw.ai',
];

// CORS 설정
app.use(
  cors({
    origin: (origin, callback) => {
      // origin이 없거나 localhost인 경우만 허용
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(null, false);
      }
    },
    credentials: true,
  })
);

app.get('/npki/health', (_: Request, res: Response) => {
  res.json({
    status: 'ok',
    version: packageJson.version,
  });
});

app.get('/npki/certificates', async (_: Request, res: Response) => {
  try {
    const certs = await findCertificates();
    const form = new FormData();

    // 메타데이터
    const metadata = certs.map((cert, index) => ({
      index: index,
      id: cert.id,
      issuer: cert.issuer,
      fileName: cert.fileName,
      size: cert.size,
      modifiedDate: cert.modifiedDate,
    }));

    form.append('metadata', JSON.stringify(metadata));

    // 각 파일 추가
    certs.forEach((cert, index) => {
      const fileBuffer = fs.readFileSync(cert.path);
      form.append(`certificate_${index}`, fileBuffer, {
        filename: cert.fileName,
      });
    });

    res.setHeader('Content-Type', `multipart/form-data; boundary=${form.getBoundary()}`);
    form.pipe(res);
  } catch (error) {
    console.error('Error getting certificates:', error);
    res.status(500).json({ error: 'Failed to retrieve certificates' });
  }
});

export const startServer = async (): Promise<void> => {
  return new Promise(async (resolve) => {
    app.listen(PORT, () => {
      console.log(`Server running on http://localhost:${PORT}`);
      resolve();
    });
  });
};
