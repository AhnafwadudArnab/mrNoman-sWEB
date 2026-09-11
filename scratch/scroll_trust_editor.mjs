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

  function send(m, p = {}) {
    return new Promise(r => {
      const i = id++;
      const timer = setTimeout(() => {
        ws.removeEventListener('message', h);
        r(null);
      }, 500);
      const h = e => {
        try {
          const msg = JSON.parse(e.data);
          if (msg.id === i) {
            clearTimeout(timer);
            ws.removeEventListener('message', h);
            r(msg.result || msg);
          }
        } catch (_) {}
      };
      ws.addEventListener('message', h);
      ws.send(JSON.stringify({ id: i, method: m, params: p }));
    });
  }

  const wait = ms => new Promise(r => setTimeout(r, ms));

  async function shot(filename) {
    const ss = await send('Page.captureScreenshot', { format: 'png' });
    if (ss && ss.data) {
      const targetPath = `C:/Users/ahana/.gemini/antigravity-ide/brain/7bab53eb-7e8e-4858-875c-9b6d9807aa04/${filename}`;
      fs.writeFileSync(targetPath, Buffer.from(ss.data, 'base64'));
      console.log(`Saved screenshot: ${filename}`);
    }
  }

  ws.onopen = async () => {
    await send('Page.enable');

    console.log('Scrolling Banners page down to Feature / Trust Badges editor...');
    await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 600, y: 400, deltaX: 0, deltaY: 1500 });
    await wait(1200);

    await shot('admin_trust_badges_editor_live.png');

    ws.close();
    process.exit(0);
  };
}
main();
