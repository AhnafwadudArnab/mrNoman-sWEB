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
    await wait(80);
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await wait(120);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
    await wait(1500);
  }

  ws.onopen = async () => {
    await send('Page.enable');
    await send('Runtime.enable');
    await send('Input.enable');

    console.log('1. Clicking Admin at top right (1450, 38)...');
    await clickAt(1450, 38);
    await wait(1500);

    console.log('2. Clicking Product List at (130, 311)...');
    await clickAt(130, 311);
    await wait(2000);
    await shot('admin_product_list_live.png');

    console.log('3. Clicking Abandoned Carts at (130, 571)...');
    await clickAt(130, 571);
    await wait(2000);
    await shot('admin_abandoned_carts_live.png');

    console.log('4. Scrolling sidebar to click Banners...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 130, y: 500, deltaX: 0, deltaY: 450 });
    await wait(1000);
    // After 450 scroll down, Banners is around y = 585
    console.log('Clicking Banners in sidebar at (130, 585)...');
    await clickAt(130, 585);
    await wait(2000);
    console.log('Scrolling main page down to Trust Badges...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 700, y: 500, deltaX: 0, deltaY: 2500 });
    await wait(1500);
    await shot('admin_trust_badges_editor_live.png');

    console.log('5. Scrolling sidebar back up to Dashboard...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 130, y: 300, deltaX: 0, deltaY: -800 });
    await wait(1000);
    await clickAt(130, 130);
    await wait(2000);
    console.log('Hovering over Revenue Analytics data line point...');
    // Line in revenue analytics chart: move around D1 point (approx x=250, y=680)
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 250, y: 680 });
    await wait(800);
    await shot('admin_dashboard_tooltip_spot.png');

    console.log('Finished capturing all Admin Panel screenshots.');
    ws.close();
    process.exit(0);
  };
}
main();
