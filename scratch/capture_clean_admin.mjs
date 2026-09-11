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
  if (!page) {
    console.error('Flutter web page not found!');
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
    console.log(`Saved screenshot: ${filename}`);
  }

  const wait = ms => new Promise(r => setTimeout(r, ms));

  async function clickAt(x, y) {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await wait(50);
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await wait(100);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
    await wait(1500);
  }

  ws.onopen = async () => {
    await send('Page.enable');
    await send('Runtime.enable');
    await send('Input.enable');

    console.log('Step 1: Navigating to Admin Panel...');
    // Click Admin at top right
    await clickAt(1450, 38);
    await wait(2000);
    await shot('admin_entered_live.png');

    console.log('Step 2: Clicking dedicated Product List button at (100, 368)...');
    await clickAt(100, 368);
    await wait(2000);
    await shot('admin_product_list_live.png');

    console.log('Step 3: Clicking Abandoned Carts at (100, 690)...');
    await clickAt(100, 690);
    await wait(2000);
    await shot('admin_abandoned_carts_live.png');

    console.log('Step 4: Scrolling sidebar down to click Banners...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 100, y: 500, deltaX: 0, deltaY: 500 });
    await wait(1000);
    console.log('Clicking Banners at (100, 585)...');
    await clickAt(100, 585);
    await wait(2000);

    console.log('Scrolling down Banners page to show Feature / Trust Badges editor...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 600, y: 500, deltaX: 0, deltaY: 2200 });
    await wait(1500);
    await shot('admin_trust_badges_editor_live.png');

    console.log('Step 5: Scrolling sidebar up to Dashboard...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 100, y: 300, deltaX: 0, deltaY: -800 });
    await wait(1000);
    await clickAt(100, 160);
    await wait(2000);
    console.log('Hovering over Revenue Analytics data line...');
    // Touch/hover over line point
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 250, y: 680 });
    await wait(500);
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 500, y: 550 });
    await wait(500);
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 900, y: 535 });
    await wait(500);
    await shot('admin_dashboard_tooltip_spot.png');

    console.log('All steps completed successfully.');
    ws.close();
    process.exit(0);
  };
}
main();
