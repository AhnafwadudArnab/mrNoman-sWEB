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

    // 1. Click Deals: x = 80, y = 640
    console.log('Navigating to Deals (80, 640)...');
    await click(80, 640, 2000);
    await shot('admin_deals_verified.png');

    // 2. Click Collections: x = 80, y = 339
    console.log('Navigating to Collections (80, 339)...');
    await click(80, 339, 2000);
    // Click on the second collection card (Kitchen Appliances) at x = 400, y = 240
    await click(400, 240, 1200);
    await shot('admin_collections_verified.png');

    // 3. Click Stock Management: x = 80, y = 294
    console.log('Navigating to Stock Management (80, 294)...');
    await click(80, 294, 2000);
    await shot('admin_stock_verified.png');

    // 4. Scroll sidebar down to see Marketing (Banners)
    console.log('Scrolling sidebar down...');
    await scroll(80, 400, 400, 1000);
    // Click Banners (after scrolling, Banners is near y = 580)
    console.log('Clicking Banners...');
    await click(80, 580, 2000);
    // Scroll right content down to see Sidebar Promo section
    console.log('Scrolling down to Sidebar Promo section...');
    await scroll(600, 400, 800, 1000);
    await shot('admin_sidebar_promo_verified.png');

    // 5. Scroll sidebar further down to see System & Help
    console.log('Scrolling sidebar down to System & Help...');
    await scroll(80, 400, 500, 1000);
    // Click Help & Support
    console.log('Clicking Help & Support...');
    await click(80, 640, 2000);
    await shot('admin_help_support_verified.png');

    // Search query in Help & Support
    console.log('Searching in Help & Support: "load picture on product uploads"...');
    await click(450, 185, 600); // Focus search field
    await typeText('load picture on product uploads');
    await shot('admin_help_search_verified.png');

    ws.close();
    process.exit(0);
  };
}
main();
