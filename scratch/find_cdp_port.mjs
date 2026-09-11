import http from 'http';

const ports = [51338, 55138, 55140, 56343, 56344, 59150, 63267, 63269, 63807, 44456, 49687];

async function checkPort(port) {
  return new Promise(resolve => {
    const req = http.get(`http://127.0.0.1:${port}/json/version`, { timeout: 400 }, res => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({ port, json });
        } catch (_) { resolve(null); }
      });
    });
    req.on('error', () => resolve(null));
    req.on('timeout', () => { req.destroy(); resolve(null); });
  });
}

async function main() {
  for (const p of ports) {
    const r = await checkPort(p);
    if (r) {
      console.log(`FOUND CDP on port ${r.port}: ${r.json.Browser}`);
    }
  }
}
main();
