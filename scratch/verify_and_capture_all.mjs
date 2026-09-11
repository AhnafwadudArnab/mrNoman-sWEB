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
      await new Promise(r => setTimeout(r, 40));
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

    // Save storefront view first!
    await shot('live_storefront_verified.png');

    // Click Admin in header (x: 930, y: 38)
    console.log('Clicking Admin button in header...');
    await click(930, 38, 2000);

    // Verify Admin Dashboard is open
    await shot('admin_navigated_dashboard.png');

    // 1. Deals: In Admin sidebar, Deals is under SALES.
    // In verified_current_view.png:
    // Products: y: 110
    // Stock Management: y: 168
    // Collections: y: 222
    // Brands: y: 280
    // SALES: y: 340
    // Orders: y: 375
    // Abandoned Carts: y: 430
    // Payments: y: 485
    // Discounts: y: 540
    // Deals: y: 598
    // Promotions: y: 655
    console.log('Clicking Deals in Admin sidebar (80, 598)...');
    await click(80, 598, 2000);
    await shot('admin_deals_page.png');

    // 2. Collections: (80, 222)
    console.log('Clicking Collections in Admin sidebar (80, 222)...');
    await click(80, 222, 2000);
    // Click on Kitchen Appliances card to show its linked products (card ~ x: 450, y: 230)
    await click(450, 230, 1000);
    await shot('admin_collections_page.png');

    // 3. Stock Management: (80, 168)
    console.log('Clicking Stock Management (80, 168)...');
    await click(80, 168, 2000);
    await shot('admin_stock_page.png');

    // 4. Banners:
    // Scroll sidebar slightly or click Banners at y ~ 750
    console.log('Clicking Banners (80, 750)...');
    await click(80, 750, 2000);
    // Scroll down main area to see Sidebar Promo
    await scroll(600, 500, 1000, 1000);
    await shot('admin_banners_sidebar_promo.png');

    // 5. Help & Support:
    // Scroll sidebar down to see SYSTEM & HELP
    await scroll(80, 500, 800, 1000);
    // Click Help & Support at y ~ 810
    console.log('Clicking Help & Support...');
    await click(80, 810, 2000);
    await shot('admin_help_support_page.png');

    // Search query in Help & Support
    console.log('Searching in Help & Support...');
    await click(450, 235, 500);
    await typeText('load picture on product uploads');
    await shot('admin_help_search_matched.png');

    ws.close();
    process.exit(0);
  };
}
main();
