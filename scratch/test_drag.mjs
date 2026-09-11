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

  const wait = ms => new Promise(r => setTimeout(r, ms));

  async function shot(filename) {
    const ss = await send('Page.captureScreenshot', { format: 'png' });
    const targetPath = `C:/Users/ahana/.gemini/antigravity-ide/brain/7bab53eb-7e8e-4858-875c-9b6d9807aa04/${filename}`;
    fs.writeFileSync(targetPath, Buffer.from(ss.data, 'base64'));
    console.log(`Saved screenshot: ${filename}`);
  }

  ws.onopen = async () => {
    await send('Page.enable');
    await send('Input.enable');

    console.log('Testing drag/scroll on right side...');
    // Click on the right pane to focus it
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 600, y: 500, button: 'left', buttons: 1, clickCount: 1 });
    await wait(50);
    for (let y = 500; y >= 100; y -= 40) {
      await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 600, y, buttons: 1 });
      await wait(30);
    }
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: 600, y: 100, button: 'left', buttons: 0, clickCount: 1 });
    await wait(1000);

    // Also send PageDown key
    await send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'PageDown', code: 'PageDown', windowsVirtualKeyCode: 34 });
    await send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'PageDown', code: 'PageDown', windowsVirtualKeyCode: 34 });
    await wait(1000);

    await shot('test_drag_result.png');

    ws.close();
    process.exit(0);
  };
}
main();
