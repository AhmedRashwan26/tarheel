const express = require('express');
const { default: makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion, proto, generateWAMessageFromContent } = require('@whiskeysockets/baileys');
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
const recentLogs = [];

function logEvent(msg) {
  const time = new Date().toLocaleTimeString('ar-SA', { hour12: false });
  const entry = `[${time}] ${msg}`;
  console.log(entry);
  recentLogs.unshift(entry);
  if (recentLogs.length > 40) recentLogs.pop();
}

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

function normalizePhoneForWhatsApp(phone) {
  let clean = phone.toString().replace(/[^0-9]/g, '');
  if (clean.startsWith('00')) {
    clean = clean.substring(2);
  }
  // Saudi Arabia: 05XXXXXXXX (10 digits) -> 9665XXXXXXXX
  if (clean.startsWith('05') && clean.length === 10) {
    clean = '966' + clean.substring(1);
  }
  // Saudi Arabia: 5XXXXXXXX (9 digits) -> 9665XXXXXXXX
  else if (clean.startsWith('5') && clean.length === 9) {
    clean = '966' + clean;
  }
  // Egypt: 01XXXXXXXXX (11 digits) -> 201XXXXXXXXX
  else if (clean.startsWith('01') && clean.length === 11) {
    clean = '20' + clean.substring(1);
  }
  return clean;
}

app.get('/logs', (req, res) => {
  res.json({
    connected: isConnected,
    phone: connectedUser,
    logs: recentLogs,
  });
});

app.post('/send', async (req, res) => {
  const { to, message, code } = req.body;

  if (!to || !message) {
    return res.status(400).json({ success: false, error: 'Missing "to" or "message" in request body' });
  }

  if (!isConnected || !sock) {
    return res.status(503).json({ success: false, error: 'WhatsApp is not connected yet. Please scan the QR code first.' });
  }

  try {
    const cleanPhone = normalizePhoneForWhatsApp(to);
    const jid = `${cleanPhone}@s.whatsapp.net`;
    const otpCode = code || (message.match(/\b\d{6}\b/) ? message.match(/\b\d{6}\b/)[0] : null);

    let messageId = null;

    if (otpCode) {
      try {
        logEvent(`📤 جاري إرسال رمز OTP [${otpCode}] مع زر "نسخ الرمز" إلى ${cleanPhone}...`);

        const interactiveMsg = {
          viewOnceMessage: {
            message: {
              messageContextInfo: {
                deviceListMetadata: {},
                deviceListMetadataVersion: 2
              },
              interactiveMessage: proto.Message.InteractiveMessage.fromObject({
                body: proto.Message.InteractiveMessage.Body.fromObject({
                  text: message
                }),
                footer: proto.Message.InteractiveMessage.Footer.fromObject({
                  text: 'منصة ترحيل لخدمات النقل والمشاوير'
                }),
                header: proto.Message.InteractiveMessage.Header.fromObject({
                  title: 'منصة تـرحـيـل (Tarheel)',
                  hasMediaAttachment: false
                }),
                nativeFlowMessage: proto.Message.InteractiveMessage.NativeFlowMessage.fromObject({
                  buttons: [
                    {
                      name: 'cta_copy',
                      buttonParamsJson: JSON.stringify({
                        display_text: '📋 نسخ رمز التحقق',
                        id: 'copy_otp_code',
                        copy_code: otpCode
                      })
                    }
                  ]
                })
              })
            }
          }
        };

        const waMsg = generateWAMessageFromContent(jid, interactiveMsg, { userJid: sock.user?.id || jid });
        const sendPromise = sock.relayMessage(jid, waMsg.message, { messageId: waMsg.key.id });
        const timeoutPromise = new Promise((_, reject) => 
          setTimeout(() => reject(new Error('مهلة إرسال رسالة الواتساب انتهت (10 ثوانٍ)')), 10000)
        );
        await Promise.race([sendPromise, timeoutPromise]);
        messageId = waMsg.key.id;
        logEvent(`✅ تم تسليم رسالة OTP مع زر النسخ بنجاح إلى ${cleanPhone} (معرف: ${messageId})`);
      } catch (interactiveErr) {
        logEvent(`⚠️ تعذر إرسال الرسالة التفاعلية، جاري التراجع للرسالة النصية: ${interactiveErr.message}`);
        const sendPromise = sock.sendMessage(jid, { text: message });
        const timeoutPromise = new Promise((_, reject) => 
          setTimeout(() => reject(new Error('مهلة إرسال رسالة الواتساب انتهت (10 ثوانٍ)')), 10000)
        );
        const result = await Promise.race([sendPromise, timeoutPromise]);
        messageId = result?.key?.id;
        logEvent(`✅ تم تسليم الرسالة النصية بنجاح إلى واتساب ${cleanPhone} (معرف: ${messageId})`);
      }
    } else {
      logEvent(`📤 جاري إرسال رسالة نصية إلى ${cleanPhone}...`);
      const sendPromise = sock.sendMessage(jid, { text: message });
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('مهلة إرسال رسالة الواتساب انتهت (10 ثوانٍ)')), 10000)
      );
      const result = await Promise.race([sendPromise, timeoutPromise]);
      messageId = result?.key?.id;
      logEvent(`✅ تم تسليم الرسالة بنجاح إلى واتساب ${cleanPhone} (معرف: ${messageId})`);
    }

    res.json({
      success: true,
      messageId,
      to: cleanPhone,
    });
  } catch (error) {
    logEvent(`❌ فشل إرسال الرسالة إلى ${to}: ${error.message}`);
    console.error('Error sending WhatsApp message:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/logout', async (req, res) => {
  try {
    if (sock) {
      await sock.logout();
    }
    fs.rmSync(AUTH_DIR, { recursive: true, force: true });
    isConnected = false;
    connectedUser = null;
    latestQr = null;
    setTimeout(startWhatsApp, 1000);
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
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
    .btn-logout {
      background: rgba(239, 68, 68, 0.2);
      color: #f87171;
      border: 1px solid rgba(239, 68, 68, 0.3);
      padding: 10px 20px;
      border-radius: 8px;
      cursor: pointer;
      font-weight: 700;
      margin-top: 15px;
      transition: all 0.2s;
    }
    .btn-logout:hover { background: rgba(239, 68, 68, 0.3); }
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
      <button class="btn-logout" onclick="logoutNumber()">🔄 تغيير الرقم / تسجيل الخروج</button>
    </div>
  </div>

  <script>
    const baseUrl = window.location.pathname.replace(/\\/$/, '');

    async function updateStatus() {
      try {
        const res = await fetch(baseUrl + '/status');
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

          const qrRes = await fetch(baseUrl + '/qr');
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

    async function logoutNumber() {
      if (confirm('هل تريد فصل الرقم الحالي وربط رقم جديد؟')) {
        try {
          await fetch(baseUrl + '/logout', { method: 'POST' });
          updateStatus();
        } catch (e) {
          alert('حدث خطأ أثناء تسجيل الخروج');
        }
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
