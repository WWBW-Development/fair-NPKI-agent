import { startServer } from './server';

const main = async () => {
  try {
    await startServer();
    console.log('NPKI Agent is running on http://localhost:62735');
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1); // 비정상 종료
  }
};

main();
