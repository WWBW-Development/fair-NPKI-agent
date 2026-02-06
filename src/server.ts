import express, { Request, Response } from 'express';
import packageJson from '../package.json';
import cors from 'cors';
import { findCertificates, Certificate } from './certificate-finder';

const app = express();
const PORT = 62735;

const allowedOrigins = [
  /^https?:\/\/localhost(:\d+)?$/, // HTTP/HTTPS 모두
  'https://fair-mobile-frontend-test.azurewebsites.net',
  'https://fair.wwbw.ai',
];

const checkOrigin = (origin: string | undefined) => {
  //  동일 출처 허용
  if (!origin) {
    return true;
  }

  //  허용된 출처 확인
  return allowedOrigins.some((allowed) =>
    allowed instanceof RegExp ? allowed.test(origin) : allowed === origin
  );
};

// CORS 설정
app.use(
  cors({
    origin: (origin, callback) => {
      callback(null, checkOrigin(origin));
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

    // findCertificates가 이미 base64로 인코딩된 Certificate[]를 반환
    res.json(certs);
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
