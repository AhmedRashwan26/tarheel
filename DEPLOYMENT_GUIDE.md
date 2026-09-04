# دليل تشغيل ونشر منصة "تـرحـيـل" على سيرفر Hetzner و GitHub 🚀

دليل إرشادي شامل خطوة بخطوة لنشر وإطلاق منصة **تـرحـيـل (Tarheel)** بالكامل في بيئة الإنتاج الحية (Production).

---

## 📋 المتطلبات المسبقة على سيرفر Hetzner
- سيرفر **Hetzner Cloud VPS** بنظام تشغيل **Ubuntu 22.04 أو 24.04 LTS** (المواصفات الموصى بها: خطة CPX21 أو CX22 فما فوق: 2 vCPU و 4GB RAM).
- حساب على **GitHub** لرفع الكود وسحبه على السيرفر.
- (اختياري) اسم نطاق (Domain) مرتبط بعنوان IP الخاص بسيرفرك لتفعيل شهادة SSL المجانية (HTTPS).

---

## الخطوة 1: رفع المشروع من جهازك إلى GitHub 💻

1. افتح موجه الأوامر (Terminal / PowerShell) في مجلد المشروع `Tarheel`.
2. قم بعمل Commit لجميع الملفات:
```bash
git add .
git commit -m "feat: complete production readiness with schedule, avatar uploads, and clean UI"
```
3. اربط المشروع بمستودع GitHub وادفع الكود (استبدل الرابط برابط مستودعك):
```bash
git branch -M main
git remote add origin https://github.com/<USERNAME>/<REPO_NAME>.git
git push -u origin main
```

---

## الخطوة 2: تجهيز وتأمين سيرفر Hetzner 🔒

اتصل بالسيرفر عبر SSH:
```bash
ssh root@<YOUR_SERVER_IP>
```

قم بتحديث النظام وتثبيت الحزم الأساسية (Docker + Docker Compose + Git + UFW):
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose git ufw curl certbot python3-certbot-nginx

# تفعيل خدمة الدوكر
sudo systemctl enable docker
sudo systemctl start docker

# تفعيل جدار الحماية وتأمين المنافذ
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

---

## الخطوة 3: سحب الكود وتشغيل المشروع 🐳

1. استنسخ المستودع من GitHub:
```bash
cd /var/www
git clone https://github.com/<USERNAME>/<REPO_NAME>.git tarheel
cd tarheel
```

2. أعطِ صلاحيات التنفيذ لسكريبت النشر:
```bash
chmod +x deploy.sh
```

3. شغّل سكريبت النشر التلقائي:
```bash
./deploy.sh
```

> **ملاحظة**: يقوم السكريبت ببناء حاويات Docker (الباك إند NestJS، قاعدة بيانات PostgreSQL، كاش Redis، وخادم Nginx لخدمة واجهة الويب) وإنشاء جداول قاعدة البيانات تلقائياً عبر Prisma.

---

## الخطوة 4: تفعيل شهادة SSL (HTTPS) المجانية 🔐 (عند توفر Domain)

إذا قمت بتوجيه اسم نطاق (مثلاً `tarheel.sa` أو `app.tarheel.sa`) إلى IP السيرفر:

```bash
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com
```

ثم انسخ الشهادات إلى مجلد `nginx/ssl` وأعد تشغيل خادم Nginx:
```bash
mkdir -p nginx/ssl
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/ssl/
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/ssl/
docker-compose -f docker-compose.prod.yml restart web
```

---

## 🛠️ أوامر الصيانة والإدارة اليومية

### التحقق من حالة الخدمات:
```bash
docker-compose -f docker-compose.prod.yml ps
```

### عرض سجلات الباك إند (Live Logs):
```bash
docker-compose -f docker-compose.prod.yml logs -f api
```

### سحب آخر التحديثات وإعادة النشر:
```bash
cd /var/www/tarheel
git pull origin main
./deploy.sh
```

### أخذ نسخة احتياطية من قاعدة البيانات (Backup):
```bash
docker exec -t tarheel_postgres_prod pg_dumpall -c -U tarheel > "tarheel_backup_$(date +%Y%m%d).sql"
```

---

## 🌐 الروابط بعد التشغيل:
- **تطبيق الويب (الواجهة الرئيسية)**: `http://<SERVER_IP>` أو `https://<DOMAIN>`
- **توثيق الواجهات البرمجية (Swagger API)**: `http://<SERVER_IP>/api/docs`
- **فحص الصحة (Health Check)**: `http://<SERVER_IP>/api/health`
