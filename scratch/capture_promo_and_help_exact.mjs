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

  async function click(x, y, wait = 1000) {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await new Promise(r => setTimeout(r, 60));
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await new Promise(r => setTimeout(r, 60));
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
    await new Promise(r => setTimeout(r, wait));
  }

  async function pressKey(key, code) {
    await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key, code, windowsVirtualKeyCode: code === 'PageDown' ? 34 : 0 });
    await send('Input.dispatchKeyEvent', { type: 'keyUp', key, code });
    await new Promise(r => setTimeout(r, 600));
  }

  async function typeText(text) {
    for (const char of text) {
      await send('Input.dispatchKeyEvent', { type: 'keyDown', text: char, unmodifiedText: char });
      await send('Input.dispatchKeyEvent', { type: 'keyUp' });
      await new Promise(r => setTimeout(r, 30));
    }
    await new Promise(r => setTimeout(r, 600));
  }

  async function shot(filename) {
    const ss = await send('Page.captureScreenshot', { format: 'png' });
    const targetPath = `C:/Users/ahana/.gemini/antigravity-ide/brain/7bab53eb-7e8e-4858-875c-9b6d9807aa04/${filename}`;
    fs.writeFileSync(targetPath, Buffer.from(ss.data, 'base64'));
    console.log(`Saved screenshot: ${filename}`);
  }

  ws.onopen = async () => {
    await send('Page.enable');
    await send('Input.enable');

    // 1. Currently on Banners page! Click on main content and press PageDown to reveal Sidebar Promo section
    console.log('Focusing main content and pressing PageDown...');
    await click(600, 300, 500);
    await pressKey('PageDown', 'PageDown');
    await shot('admin_sidebar_promo_verified.png');

    // 2. Click SYSTEM & HELP at (80, 712) in sidebar to expand it
    console.log('Clicking SYSTEM & HELP in sidebar (80, 712)...');
    await click(80, 712, 1000);
    await shot('admin_system_help_expanded.png');

    // 3. Click Help & Support (which appears at y ~ 755)
    console.log('Clicking Help & Support (80, 755)...');
    await click(80, 755, 1500);
    await shot('admin_help_support_verified.png');

    // 4. Click Search bar in Help & Support (x: 450, y: 190) and search "load picture on product uploads"
    console.log('Typing query into Help & Support search...');
    await click(450, 190, 500);
    await typeText('load picture on product uploads');
    await shot('admin_help_search_verified.png');

    ws.close();
    process.exit(0);
  };
}
main();
