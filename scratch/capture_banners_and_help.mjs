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

  async function click(x, y, wait = 1200) {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await new Promise(r => setTimeout(r, 60));
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await new Promise(r => setTimeout(r, 60));
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
    await new Promise(r => setTimeout(r, wait));
  }

  async function scroll(x, y, deltaY, wait = 800) {
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

    // Scroll sidebar to top first
    await scroll(80, 300, -1000, 400);

    // Banners is at x = 80, y = 601 (752 / 1.25)
    console.log('Clicking Banners at (80, 601)...');
    await click(80, 601, 1500);

    // Scroll right area down by 1400 to show Sidebar Promo Card
    console.log('Scrolling down to Sidebar Promo card...');
    await scroll(600, 400, 1400, 1000);
    await shot('admin_sidebar_promo_card.png');

    // Now scroll sidebar down to find SYSTEM & HELP / Help & Support
    console.log('Scrolling sidebar down...');
    await scroll(80, 400, 500, 800);
    // Click Help & Support (in expanded SYSTEM & HELP, y ~ 640 after scrolling)
    console.log('Clicking Help & Support...');
    await click(80, 640, 1500);
    await shot('admin_help_support_page.png');

    // Test Search query: "load picture on product uploads"
    console.log('Searching in Help & Support...');
    await click(450, 235, 500);
    await typeText('load picture on product uploads');
    await shot('admin_help_search_matched.png');

    ws.close();
    process.exit(0);
  };
}
main();
