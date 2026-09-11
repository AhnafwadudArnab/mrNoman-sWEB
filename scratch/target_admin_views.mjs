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
  if (!page) process.exit(1);

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
    console.log(`Saved screenshot: ${filename}`);
  }

  const wait = ms => new Promise(r => setTimeout(r, ms));

  async function clickAt(x, y) {
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await wait(80);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
    await wait(1200);
  }

  async function mouseMoveTo(x, y) {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await wait(600);
  }

  ws.onopen = async () => {
    await send('Page.enable');
    await send('Runtime.enable');
    await send('Input.enable');

    console.log('1. Navigating to Admin Panel if on Storefront...');
    // Click Admin at top right (1450, 38)
    await clickAt(1450, 38);
    await wait(2000);

    // 2. Click Product List at (80, 370)
    console.log('2. Clicking Product List at (80, 370)...');
    await clickAt(80, 370);
    await wait(2500);
    await shot('admin_product_list_live.png');

    // 3. Click Abandoned Carts at (80, 690)
    console.log('3. Clicking Abandoned Carts at (80, 690)...');
    await clickAt(80, 690);
    await wait(2500);
    await shot('admin_abandoned_carts_live.png');

    // 4. Scroll sidebar down at (80, 600) to reach Banners
    console.log('4. Scrolling sidebar to reach Banners...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 80, y: 600, deltaX: 0, deltaY: 800 });
    await wait(1000);
    // Find and click Banners (approx y = 720 after scroll)
    console.log('Clicking Banners in sidebar...');
    await clickAt(80, 720);
    await wait(2500);
    console.log('Scrolling down Banners page to Trust Badges editor...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 600, y: 500, deltaX: 0, deltaY: 2000 });
    await wait(1500);
    await shot('admin_trust_badges_editor_live.png');

    // 5. Scroll sidebar back up and click Dashboard at (80, 160)
    console.log('5. Scrolling sidebar back up to Dashboard...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 80, y: 300, deltaX: 0, deltaY: -1000 });
    await wait(1000);
    await clickAt(80, 160);
    await wait(2000);
    // Hover over revenue analytics point at (250, 680)
    console.log('Hovering over Revenue Analytics data spot...');
    await mouseMoveTo(250, 680);
    await wait(800);
    await shot('admin_dashboard_tooltip_spot.png');

    ws.close();
    process.exit(0);
  };
}
main();
