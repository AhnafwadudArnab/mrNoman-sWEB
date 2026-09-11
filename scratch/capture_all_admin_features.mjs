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
    await new Promise(r => setTimeout(r, 500));
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

    // 1. Click Deals in sidebar (x ~ 80, y ~ 598)
    console.log('Navigating to Deals...');
    await click(80, 598, 1500);
    await shot('admin_deals_active_list.png');

    // 2. Click Collections in sidebar (x ~ 80, y ~ 222)
    console.log('Navigating to Collections...');
    await click(80, 222, 1500);
    // Click on the second collection card to see its linked products
    await click(400, 280, 1000);
    await shot('admin_collections_products.png');

    // 3. Click Stock Management in sidebar (x ~ 80, y ~ 168)
    console.log('Navigating to Stock Management...');
    await click(80, 168, 1500);
    await shot('admin_stock_management.png');

    // 4. Click Banners in sidebar (x ~ 80, y ~ 750)
    console.log('Navigating to Banners...');
    await click(80, 750, 1500);
    // Scroll down to Sidebar Promo card section
    console.log('Scrolling down to Sidebar Promo...');
    await scroll(600, 500, 900, 1000);
    await shot('admin_sidebar_promo.png');

    // 5. Scroll sidebar down to reach SYSTEM & HELP
    console.log('Scrolling sidebar...');
    await scroll(80, 500, 600, 800);
    // Click Help & Support
    console.log('Navigating to Help & Support...');
    await click(80, 810, 1500);
    await shot('admin_help_support_initial.png');

    // Focus search and search "load picture on product uploads"
    console.log('Searching in Help & Support...');
    await click(450, 235, 500);
    await typeText('load picture on product uploads');
    await shot('admin_help_search_load_picture.png');

    ws.close();
    process.exit(0);
  };
}
main();
