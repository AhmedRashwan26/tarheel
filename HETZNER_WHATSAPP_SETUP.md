# 🚀 دليل تشغيل بوابة Evolution API على سيرفر Hetzner لمنصة ترحيل

هذا الدليل يوضح كيفية تشغيل بوابة واتساب سحابية دائمة 24/7 على سيرفر **Hetzner** الخاص بك خلال دقيقتين فقط، وبدون أي تكلفة إضافية (0$).

---

## 📋 الخطوات على سيرفر Hetzner (3 أوامر فقط في الطرفية):

### 1. ادخل إلى سيرفر Hetzner عبر SSH:
افتح موجه الأوامر (Terminal أو PowerShell أو PuTTY) لديك واكتب:
```bash
ssh root@YOUR_HETZNER_IP
```
*(استبدل `YOUR_HETZNER_IP` بعنوان IP الخاص بسيرفرك على هيتزنر).*

---

### 2. سحب مجلد الإعداد أو نسخ الملفات:
قم بإنشاء مجلد البوابة في السيرفر:
```bash
mkdir -p /root/tarheel-evolution && cd /root/tarheel-evolution
```

قم بإنشاء ملف `docker-compose.yml` داخل هذا المجلد:
```bash
cat << 'EOF' > docker-compose.yml
version: '3.8'

services:
  evolution_postgres:
    image: postgres:16-alpine
    container_name: evolution_postgres
    restart: always
    environment:
      POSTGRES_USER: evolution
      POSTGRES_PASSWORD: tarheel_evo_secret_2026
      POSTGRES_DB: evolution_db
    volumes:
      - evolution_pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U evolution -d evolution_db"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - evolution_network

  evolution_redis:
    image: redis:7-alpine
    container_name: evolution_redis
    restart: always
    command: redis-server --appendonly yes
    volumes:
      - evolution_redisdata:/data
    networks:
      - evolution_network

  evolution_api:
    image: atendai/evolution-api:v2.2.3
    container_name: evolution_api
    restart: always
    ports:
      - "8080:8080"
    environment:
      SERVER_URL: http://localhost:8080
      SERVER_PORT: 8080
      SERVER_TYPE: http
      AUTHENTICATION_TYPE: apikey
      AUTHENTICATION_API_KEY: Tarheel_Secure_Evolution_Key_2026
      AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES: "true"
      DATABASE_ENABLED: "true"
      DATABASE_PROVIDER: postgresql
      DATABASE_CONNECTION_URI: postgresql://evolution:tarheel_evo_secret_2026@evolution_postgres:5432/evolution_db?schema=public
      DATABASE_SAVE_DATA_INSTANCE: "true"
      CACHE_REDIS_ENABLED: "true"
      CACHE_REDIS_URI: redis://evolution_redis:6379/1
      CACHE_REDIS_PREFIX_KEY: evolution
      CACHE_REDIS_SAVE_INSTANCES: "true"
      DEL_INSTANCE: "false"
      CONFIG_SESSION_PHONE_CLIENT: "Tarheel Platform"
      CONFIG_SESSION_PHONE_NAME: "Chrome (Linux)"
    depends_on:
      evolution_postgres:
        condition: service_healthy
      evolution_redis:
        condition: service_started
    volumes:
      - evolution_instances:/evolution/instances
    networks:
      - evolution_network

networks:
  evolution_network:
    driver: bridge

volumes:
  evolution_pgdata:
  evolution_redisdata:
  evolution_instances:
EOF
```

---

### 3. تشغيل الحاويات وإنشاء الاتصال (Run):
نفّذ الأمر التالي لتشغيل المحرك وقاعدة البيانات في الخلفية:
```bash
docker compose up -d
```
*(إذا لم يكن docker compose مثبتاً: `apt update && apt install -y docker.io docker-compose-plugin && docker compose up -d`)*

انتظر 10 ثوانٍ، ثم قم بإنشاء جلسة ترحيل بأمر واحد:
```bash
curl -X POST "http://localhost:8080/instance/create" \
  -H "Content-Type: application/json" \
  -H "apikey: Tarheel_Secure_Evolution_Key_2026" \
  -d '{
    "instanceName": "tarheel",
    "token": "tarheel_token_2026",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }'
```

---

## 📲 4. مسح رمز الـ QR Code وربط الرقم:
افتح متصفحك على الرابط التالي:
👉 **`http://YOUR_HETZNER_IP:8080/instance/connect/tarheel`**

- سيظهر لك رمز الـ **QR Code** الخاص بسيرفر هيتزنر.
- امسحه من تطبيق واتساب في هاتفك.
- ستتحول الحالة فوراً إلى **Connected**.
- **ملاحظة أمنية قوية:** الجلسة تُحفظ في قاعدة بيانات PostgreSQL على هيتزنر، ولن تفصل أبداً حتى لو أعدت تشغيل السيرفر!

---

## 🔗 5. ربط منصة ترحيل مع السيرفر:
في ملف `.env` لمنصة ترحيل على جهازك أو السيرفر، أضف السطرين التاليين:
```env
EVOLUTION_API_URL="http://YOUR_HETZNER_IP:8080"
EVOLUTION_API_KEY="Tarheel_Secure_Evolution_Key_2026"
EVOLUTION_INSTANCE="tarheel"
```
وستبدأ منصة ترحيل بإرسال كافة رموز الـ OTP والإشعارات عبر سيرفر Hetzner فائق السرعة تلقائياً! 🚀
