import http from 'http';
import fs from 'fs';

async function main() {
  const pages = await new Promise((resolve) => {
    http.get('http://127.0.0.1:51338/json', res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    });
  });
  console.log('Available pages:', pages.map(p => ({ title: p.title, url: p.url })));
  const page = pages.find(p => p.type === 'page' && p.url.includes('53703'));
  if (!page) {
    console.error('Target page not found on 53703!');
    process.exit(1);
  }

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let id = 1;
  const send = (m, p = {}) => new Promise(r => {
    const i = id++;
    const h = e => { const msg = JSON.parse(e.data); if (msg.id === i) { ws.removeEventListener('message', h); r(msg.result); } };
    ws.addEventListener('message', h);
    ws.send(JSON.stringify({ id: i, method: m, params: p }));
  });

  async function shot(filename) {
    const ss = await send('Page.captureScreenshot', { format: 'png' });
    const targetPath = `C:/Users/ahana/.gemini/antigravity-ide/brain/7bab53eb-7e8e-4858-875c-9b6d9807aa04/${filename}`;
    fs.writeFileSync(targetPath, Buffer.from(ss.data, 'base64'));
    console.log(`Saved screenshot to: ${targetPath}`);
  }

  ws.onopen = async () => {
    await send('Page.enable');
    await send('Runtime.enable');

    // Capture initial current view
    console.log('Capturing current view...');
    await shot('verified_current_view.png');

    // Get current window / URL
    const evalRes = await send('Runtime.evaluate', { expression: 'window.location.href' });
    console.log('Current URL in browser:', evalRes?.result?.value);

    ws.close();
    process.exit(0);
  };
}
main();
