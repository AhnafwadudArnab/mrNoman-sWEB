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
    await wait(800);
  }

  async function mouseMoveTo(x, y) {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await wait(400);
  }

  ws.onopen = async () => {
    await send('Page.enable');
    await send('Runtime.enable');
    await send('Input.enable');

    console.log('Clicking Admin at top right (1450, 38)...');
    await clickAt(1450, 38);
    await wait(2500);
    await shot('admin_entered_live.png');

    // In Admin Panel:
    // Catalogue -> Products is around (80, 135), Product List is around (80, 175)
    console.log('Clicking Product List in sidebar (80, 175)...');
    await clickAt(80, 175);
    await wait(2000);
    await shot('admin_product_list_live.png');

    // Click Banners (around 80, 715)
    console.log('Clicking Banners in sidebar (80, 715)...');
    await clickAt(80, 715);
    await wait(2000);
    console.log('Scrolling down to Trust Badges editor...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 600, y: 500, deltaX: 0, deltaY: 1500 });
    await wait(1200);
    await shot('admin_trust_badges_editor_live.png');

    // Click Dashboard (80, 70)
    console.log('Clicking Dashboard (80, 70)...');
    await clickAt(80, 70);
    await wait(2000);
    // Move mouse over revenue analytics chart spot (approx 450, 470)
    await mouseMoveTo(450, 470);
    await wait(600);
    await shot('admin_dashboard_tooltip_spot.png');

    ws.close();
    process.exit(0);
  };
}
main();
