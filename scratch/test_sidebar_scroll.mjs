import http from 'http';
import fs from 'fs';

async function main() {
  const pages = await new Promise((resolve) => {
    http.get('http://127.0.0.1:51338/json', res => {
      let d = ''; res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    });
  });
  const page = pages.find(p => p.type === 'page' && p.url.includes('53703'));
  if (!page) throw new Error('Page not found');

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let id = 1;
  const send = (m, p = {}) => new Promise(r => {
    const i = id++;
    const h = e => { const msg = JSON.parse(e.data); if (msg.id === i) { ws.removeEventListener('message', h); r(msg.result); } };
    ws.addEventListener('message', h);
    ws.send(JSON.stringify({ id: i, method: m, params: p }));
  });

  const wait = ms => new Promise(r => setTimeout(r, ms));

  ws.onopen = async () => {
    await send('Page.enable');
    await send('Input.enable');

    console.log('Scrolling sidebar down at (80, 500) by 300...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 80, y: 500, deltaX: 0, deltaY: 300 });
    await wait(1000);

    const ss = await send('Page.captureScreenshot', { format: 'png' });
    const targetPath = 'C:/Users/ahana/.gemini/antigravity-ide/brain/7bab53eb-7e8e-4858-875c-9b6d9807aa04/test_sidebar_scrolled.png';
    fs.writeFileSync(targetPath, Buffer.from(ss.data, 'base64'));
    console.log('Saved test_sidebar_scrolled.png');

    ws.close();
    process.exit(0);
  };
}
main();
