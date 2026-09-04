const express = require('express');
const { default: makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } = require('@whiskeysockets/baileys');
const pino = require('pino');
const QRCode = require('qrcode');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3001;
const AUTH_DIR = process.env.AUTH_DIR || path.join(__dirname, 'auth_info');

let sock = null;
let latestQr = null;
let isConnected = false;
let connectedUser = null;

async function startWhatsApp() {
  if (!fs.existsSync(AUTH_DIR)) {
    fs.mkdirSync(AUTH_DIR, { recursive: true });
  }

  const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR);
  const { version, isLatest } = await fetchLatestBaileysVersion();
  console.log(`Using WhatsApp Web v${version.join('.')}, isLatest: ${isLatest}`);

  sock = makeWASocket({
    version,
    auth: state,
    logger: pino({ level: 'silent' }),
    printQRInTerminal: true,
    browser: ['Tarheel Platform', 'Chrome', '120.0.0'],
    syncFullHistory: false,
  });

  sock.ev.on('creds.update', saveCreds);

  sock.ev.on('connection.update', async (update) => {
    const { connection, lastDisconnect, qr } = update;

    if (qr) {
      console.log('Generating QR code data URL...');
      try {
        latestQr = await QRCode.toDataURL(qr);
      } catch (err) {
        console.error('Failed to generate QR Data URL:', err);
      }
    }

    if (connection === 'close') {
      isConnected = false;
      connectedUser = null;
      const statusCode = lastDisconnect?.error?.output?.statusCode;
      const shouldReconnect = statusCode !== DisconnectReason.loggedOut;
      console.log(`WhatsApp connection closed (statusCode: ${statusCode}). Reconnecting: ${shouldReconnect}`);
      
      if (statusCode === DisconnectReason.loggedOut) {
        console.log('User logged out. Clearing auth directory for a fresh QR code.');
        try {
          fs.rmSync(AUTH_DIR, { recursive: true, force: true });
        } catch (e) {}
      }

      if (shouldReconnect) {
        setTimeout(startWhatsApp, 3000);
      } else {
        setTimeout(startWhatsApp, 5000);
      }
    } else if (connection === 'open') {
      isConnected = true;
      latestQr = null;
      connectedUser = sock.user?.id ? sock.user.id.split(':')[0] : 'Connected';
      console.log(`🎉 WhatsApp connected successfully! Number: +${connectedUser}`);
    }
  });
}

// REST Endpoints
app.get('/status', (req, res) => {
  res.json({
    connected: isConnected,
    phone: connectedUser,
    hasQr: !!latestQr,
  });
});

app.get('/qr', (req, res) => {
  res.json({
    connected: isConnected,
    phone: connectedUser,
    qr: latestQr,
  });
});

app.post('/send', async (req, res) => {
  const { to, message } = req.body;

  if (!to || !message) {
    return res.status(400).json({ success: false, error: 'Missing "to" or "message" in request body' });
  }

  if (!isConnected || !sock) {
    return res.status(503).json({ success: false, error: 'WhatsApp is not connected yet. Please scan the QR code first.' });
  }

  try {
    let cleanPhone = to.toString().replace(/[^0-9]/g, '');
    if (cleanPhone.startsWith('00')) {
      cleanPhone = cleanPhone.substring(2);
    }
    const jid = `${cleanPhone}@s.whatsapp.net`;

    console.log(`Sending WhatsApp message to ${jid}: ${message}`);
    const result = await sock.sendMessage(jid, { text: message });

    res.json({
      success: true,
      messageId: result?.key?.id,
      to: cleanPhone,
    });
  } catch (error) {
    console.error('Error sending WhatsApp message:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Beautiful Web Dashboard for QR Code Scanning
app.get('/', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>بوابة واتساب ترحيل - Tarheel WhatsApp Gateway</title>
  <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;900&display=swap" rel="stylesheet">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Tajawal', sans-serif; }
    body {
      background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
      color: #f8fafc;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: rgba(30, 41, 59, 0.85);
      border: 1px solid rgba(255, 255, 255, 0.1);
      backdrop-filter: blur(12px);
      border-radius: 20px;
      padding: 40px;
      max-width: 480px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 40px rgba(0,0,0,0.4);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 6px 16px;
      border-radius: 9999px;
      font-size: 14px;
      font-weight: 700;
      margin-bottom: 20px;
    }
    .badge-connected { background: rgba(16, 185, 129, 0.2); color: #34d399; border: 1px solid rgba(16, 185, 129, 0.3); }
    .badge-disconnected { background: rgba(245, 158, 11, 0.2); color: #fbbf24; border: 1px solid rgba(245, 158, 11, 0.3); }
    .qr-container {
      background: #ffffff;
      padding: 16px;
      border-radius: 16px;
      display: inline-block;
      margin: 20px 0;
      box-shadow: 0 10px 25px rgba(0,0,0,0.3);
      min-width: 250px;
      min-height: 250px;
    }
    .qr-container img { width: 250px; height: 250px; display: block; }
    .steps {
      text-align: right;
      background: rgba(15, 23, 42, 0.6);
      border-radius: 12px;
      padding: 16px;
      margin-top: 20px;
      font-size: 14px;
      line-height: 1.8;
      color: #cbd5e1;
    }
    .steps ol { padding-right: 20px; }
  </style>
</head>
<body>
  <div class="card">
    <div style="font-size: 40px; margin-bottom: 10px;">🚗 💬</div>
    <h1 style="font-size: 24px; font-weight: 900; margin-bottom: 5px;">بوابة واتساب تـرحـيـل</h1>
    <p style="color: #94a3b8; font-size: 14px; margin-bottom: 20px;">خادم الرسائل المفتوح المصدر المجاني للتحقق من الهوية</p>

    <div id="statusBadge" class="badge badge-disconnected">
      <span style="display:inline-block; width:8px; height:8px; border-radius:50%; background:currentColor;"></span>
      <span>جاري فحص الاتصال...</span>
    </div>

    <div id="qrBox">
      <div class="qr-container">
        <img id="qrImg" src="" alt="QR Code" style="display: none;" />
        <div id="qrLoading" style="padding: 100px 0; color: #64748b; font-size: 14px;">جاري تحميل الباركود...</div>
      </div>
      <div class="steps">
        <strong>طريقة الربط من جوالك:</strong>
        <ol>
          <li>افتح تطبيق <strong>الواتساب</strong> على جوالك.</li>
          <li>اذهب إلى <strong>الإعدادات</strong> ⬅️ <strong>الأجهزة المرتبطة</strong>.</li>
          <li>اضغط على <strong>ربط جهاز</strong> وامسح الباركود أعلاه.</li>
        </ol>
      </div>
    </div>

    <div id="connectedBox" style="display: none; padding: 20px 0;">
      <div style="font-size: 60px; margin-bottom: 10px;">✅</div>
      <h2 style="color: #34d399; font-size: 20px; font-weight: 700;">تم الاتصال بنجاح!</h2>
      <p id="connectedPhone" style="color: #94a3b8; margin-top: 5px; font-size: 15px;"></p>
      <p style="color: #64748b; font-size: 13px; margin-top: 15px;">المنصة الآن ترسل رسائل OTP مباشرة ومجاناً عبر هذا الرقم.</p>
    </div>
  </div>

  <script>
    async function updateStatus() {
      try {
        const res = await fetch('/status');
        const data = await res.json();
        
        const badge = document.getElementById('statusBadge');
        const qrBox = document.getElementById('qrBox');
        const connectedBox = document.getElementById('connectedBox');
        const qrImg = document.getElementById('qrImg');
        const qrLoading = document.getElementById('qrLoading');
        const connectedPhone = document.getElementById('connectedPhone');

        if (data.connected) {
          badge.className = 'badge badge-connected';
          badge.innerHTML = '● متصل ونشط';
          qrBox.style.display = 'none';
          connectedBox.style.display = 'block';
          connectedPhone.innerText = 'الرقم المرتبط: +' + (data.phone || '');
        } else {
          badge.className = 'badge badge-disconnected';
          badge.innerHTML = '● غير متصل - يرجى المسح';
          qrBox.style.display = 'block';
          connectedBox.style.display = 'none';

          const qrRes = await fetch('/qr');
          const qrData = await qrRes.json();
          if (qrData.qr) {
            qrImg.src = qrData.qr;
            qrImg.style.display = 'block';
            qrLoading.style.display = 'none';
          }
        }
      } catch (err) {
        console.error('Error fetching status:', err);
      }
    }

    setInterval(updateStatus, 3000);
    updateStatus();
  </script>
</body>
</html>
  `);
});

// Start Express server and WhatsApp client
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Tarheel WhatsApp Gateway running on http://0.0.0.0:${PORT}`);
  startWhatsApp();
});
