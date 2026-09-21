const fs = require('fs');
let content = fs.readFileSync('functions/index.js', 'binary');
content = content.replace(/topic: "annonces"/g, 'android: { priority: "high" }, apns: { payload: { aps: { contentAvailable: true } } }, topic: "annonces"');
content = content.replace(/topic: "live"/g, 'android: { priority: "high" }, apns: { payload: { aps: { contentAvailable: true } } }, topic: "live"');
content = content.replace(/topic: "tournois"/g, 'android: { priority: "high" }, apns: { payload: { aps: { contentAvailable: true } } }, topic: "tournois"');
fs.writeFileSync('functions/index.js', content, 'binary');
