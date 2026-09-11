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

  async function click(x, y, wait = 1500) {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await new Promise(r => setTimeout(r, 60));
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await new Promise(r => setTimeout(r, 60));
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
    await new Promise(r => setTimeout(r, wait));
  }

  async function scroll(x, y, deltaY, wait = 1000) {
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x, y, deltaX: 0, deltaY });
    await new Promise(r => setTimeout(r, wait));
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

    // 1. Click Deals: x = 80, y = 478
    console.log('Clicking Deals at (80, 478)...');
    await click(80, 478, 2000);
    await shot('admin_deals_active_list.png');

    // 2. Click Banners: x = 80, y = 600
    console.log('Clicking Banners at (80, 600)...');
    await click(80, 600, 2000);
    // Scroll right content down to see the redesigned Sidebar Promo section
    console.log('Scrolling down to Sidebar Promo card...');
    await scroll(600, 400, 950, 1000);
    await shot('admin_sidebar_promo_card.png');

    // 3. Scroll sidebar down to see Help & Support
    console.log('Scrolling sidebar down...');
    await scroll(80, 400, 400, 800);
    // In sidebar after scrolling, let's capture to see where Help & Support is
    await shot('admin_sidebar_scrolled.png');

    ws.close();
    process.exit(0);
  };
}
main();
