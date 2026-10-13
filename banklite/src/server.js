// BankLite payment API: a synthetic system for the "find the crypto" lab.
// Two TLS endpoints: :8443 (TLS 1.3, hybrid post-quantum key exchange)
// and :8444 (legacy TLS 1.2 for an old acquirer integration).
'use strict';

const fs = require('fs');
const path = require('path');
const https = require('https');

const card = require('./card');
const receipt = require('./receipt');
const webhook = require('./webhook');
const vault = require('./legacy/vault');

const ROOT = path.join(__dirname, '..');
const tls = JSON.parse(fs.readFileSync(path.join(ROOT, 'config/tls.json'), 'utf8'));

function handler(req, res) {
  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', () => {
    if (req.method === 'POST' && req.url === '/pay') {
      const p = JSON.parse(body || '{}');
      const token = card.tokenise(p.pan || '4111111111111111');
      const r = receipt.receiptId(token, p.amount || 100);
      const sig = webhook.sign({ token, amount: p.amount, receipt: r });
      vault.store(r, p.pan || '');
      res.writeHead(200, { 'content-type': 'application/json', 'x-banklite-signature': sig });
      return res.end(JSON.stringify({ token, receipt: r }));
    }
    res.writeHead(200, { 'content-type': 'text/plain' });
    res.end('BankLite OK\n');
  });
}

function serve(ep) {
  const opts = {
    key: fs.readFileSync(path.join(ROOT, ep.key)),
    cert: fs.readFileSync(path.join(ROOT, ep.cert)),
    minVersion: ep.minVersion,
    maxVersion: ep.maxVersion,
  };
  if (ep.groups) opts.ecdhCurve = ep.groups;
  if (ep.ciphers) opts.ciphers = ep.ciphers;
  https.createServer(opts, handler).listen(ep.port, () =>
    console.log(`BankLite ${ep.name} listening on :${ep.port}`));
}

tls.endpoints.forEach(serve);
