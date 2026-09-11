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

  async function click(x, y, delay = 1200) {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await wait(60);
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await wait(60);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
    await wait(delay);
  }

  async function scroll(x, y, deltaY, delay = 1000) {
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x, y, deltaX: 0, deltaY });
    await wait(delay);
  }

  async function shot(filename) {
    const ss = await send('Page.captureScreenshot', { format: 'png' });
    const targetPath = `C:/Users/ahana/.gemini/antigravity-ide/brain/7bab53eb-7e8e-4858-875c-9b6d9807aa04/${filename}`;
    fs.writeFileSync(targetPath, Buffer.from(ss.data, 'base64'));
    console.log(`Saved screenshot: ${filename}`);
  }

  ws.onopen = async () => {
    await send('Page.enable');

    console.log('1. Reloading page...');
    await send('Page.reload');
    await wait(4500);

    console.log('2. Clicking Admin in header at (1440, 38)...');
    await click(1440, 38, 2500);

    console.log('3. Scrolling sidebar down to reveal Banners...');
    await scroll(80, 400, 450, 1000);

    console.log('4. Clicking Banners at (80, 585)...');
    await click(80, 585, 2000);

    console.log('5. Scrolling right content down to Feature / Trust Badges editor...');
    await scroll(600, 400, 2000, 1500);

    console.log('6. Taking screenshot...');
    await shot('admin_trust_badges_editor_live.png');

    ws.close();
    process.exit(0);
  };
}
main();
