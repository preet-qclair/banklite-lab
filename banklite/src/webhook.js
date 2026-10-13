// Signs webhook callbacks sent to merchants.
'use strict';

const crypto = require('crypto');

const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET || 'banklite-demo-webhook-secret';

function sign(payload) {
  return crypto.createHmac('sha256', WEBHOOK_SECRET).update(JSON.stringify(payload)).digest('base64');
}

module.exports = { sign };
