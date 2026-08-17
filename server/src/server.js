import { createApp } from './app.js';
import { getConfig } from './config.js';

const config = getConfig();
createApp(config).listen(config.port, config.host, () => {
  console.info(`WildSight identification backend listening on ${config.host}:${config.port}`);
});
