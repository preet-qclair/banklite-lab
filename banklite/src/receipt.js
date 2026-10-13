// Receipt identifiers printed on customer slips.
'use strict';

const crypto = require('crypto');

function receiptId(token, amount) {
  return crypto.createHash('sha1').update(`${token}:${amount}:${Date.now()}`).digest('hex').slice(0, 16);
}

module.exports = { receiptId };
