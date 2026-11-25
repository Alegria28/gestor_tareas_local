// Servidor estático mínimo para probar la versión release en el navegador.
//
//   flutter build web --release
//   node tool/serve_web.js
//
// Envía COOP/COEP para que el navegador habilite OPFS. Sin esas cabeceras
// Drift usa IndexedDB y la persistencia también funciona.
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..', 'build', 'web');
const port = Number(process.env.PORT || 8080);
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.ico': 'image/x-icon',
  '.map': 'application/json',
};

http
  .createServer((req, res) => {
    const urlPath = decodeURIComponent(req.url.split('?')[0]);
    let file = path.join(root, urlPath);
    if (!file.startsWith(root)) {
      res.writeHead(403).end();
      return;
    }
    if (urlPath === '/' || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
      file = path.join(root, 'index.html');
    }
    const body = fs.readFileSync(file);
    res.writeHead(200, {
      'Content-Type': types[path.extname(file)] || 'application/octet-stream',
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cache-Control': 'no-store',
    });
    res.end(body);
  })
  .listen(port, '127.0.0.1', () => {
    console.log(`http://127.0.0.1:${port}`);
  });
