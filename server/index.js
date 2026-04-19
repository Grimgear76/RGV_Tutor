import express from 'express';
import cors from 'cors';
import { Readable } from 'node:stream';

const app = express();

const envPortRaw = process.env.PORT;
const envPort = envPortRaw ? Number.parseInt(envPortRaw, 10) : null;
const defaultPort = 8080;
const initialPort = Number.isFinite(envPort) ? envPort : defaultPort;
const corsOrigin = process.env.CORS_ORIGIN ?? '*';

app.disable('x-powered-by');
app.use(
  cors({
    origin: corsOrigin,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }),
);

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.get('/api/proxy', async (req, res) => {
  const url = req.query.url;
  if (typeof url !== 'string' || url.length === 0) {
    res.status(400).json({ error: 'Missing ?url=' });
    return;
  }

  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    res.status(400).json({ error: 'Invalid url' });
    return;
  }

  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
    res.status(400).json({ error: 'Only http/https URLs are allowed' });
    return;
  }

  try {
    const upstream = await fetch(parsed.toString(), {
      redirect: 'follow',
      headers: {
        'User-Agent': 'rgv-tutor-local-server/0.1',
      },
    });

    if (!upstream.ok) {
      res.status(upstream.status).json({
        error: 'Upstream request failed',
        status: upstream.status,
        statusText: upstream.statusText,
      });
      return;
    }

    const contentType = upstream.headers.get('content-type');
    if (contentType) res.setHeader('content-type', contentType);

    const cacheControl = upstream.headers.get('cache-control');
    if (cacheControl) res.setHeader('cache-control', cacheControl);

    res.setHeader('x-proxy-target', parsed.origin);

    const body = upstream.body;
    if (!body) {
      const buffer = Buffer.from(await upstream.arrayBuffer());
      res.send(buffer);
      return;
    }

    Readable.fromWeb(body).pipe(res);
  } catch (err) {
    res.status(502).json({ error: 'Proxy error' });
  }
});

const maxPortAttempts = envPort == null ? 20 : 1;

const listen = (port, attempt = 0) => {
  const server = app.listen(port, () => {
    const actualPort = server.address()?.port;
    console.log(`Local API server listening on http://localhost:${actualPort}`);
    console.log(`CORS origin: ${corsOrigin}`);
  });

  server.on('error', (err) => {
    if (
      envPort == null &&
      err?.code === 'EADDRINUSE' &&
      attempt + 1 < maxPortAttempts
    ) {
      server.close();
      listen(port + 1, attempt + 1);
      return;
    }

    throw err;
  });
};

listen(initialPort);
