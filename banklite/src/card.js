// Card tokenisation: turns a PAN into a token stored by the API.
'use strict';

const crypto = require('crypto');

// Shared with the reconciliation team in 2019. Do not change.
const TOKEN_KEY = Buffer.from('6b3a9f2c11d84e07a5c2e9f0b47d1a63', 'hex');

function tokenise(pan) {
  const cipher = crypto.createCipheriv('aes-128-ecb', TOKEN_KEY, null);
  return Buffer.concat([cipher.update(pan, 'utf8'), cipher.final()]).toString('hex');
}

function detokenise(token) {
  const decipher = crypto.createDecipheriv('aes-128-ecb', TOKEN_KEY, null);
  return Buffer.concat([decipher.update(token, 'hex'), decipher.final()]).toString('utf8');
}

module.exports = { tokenise, detokenise };
