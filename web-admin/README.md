# 🌍 Travel Advisor Web

Frontend React + TypeScript cho Admin và Local Service Provider portal.

---

## 📦 Yêu cầu

- **Node.js** >= 18.x và npm
- **Git**

Kiểm tra version:
```bash
node --version && npm --version
```

---

## ⚡ Cài đặt lần đầu

### 1. Clone repository
```bash
git clone <repo-url>
cd travel-advisor-web
```

### 2. Cài dependencies
```bash
npm install
```

### 3. Chạy dev server
```bash
npm run dev
```
→ App tự động mở tại: **http://localhost:3000**

---

## 🔄 Quy trình làm việc hằng ngày

```bash
# 1. Update code mới nhất
git checkout develop
git pull origin develop

# 2. Start dev server
npm run dev
```

### Làm việc với Git

#### Bắt đầu feature/task mới
```bash
git checkout develop
git pull origin develop
git checkout -b feature/ten-feature    # hoặc fix/ten-bug
```

#### Commit thường xuyên
```bash
git status                             # Xem file thay đổi
git add .                              # Stage tất cả
git commit -m "feat: mô tả ngắn gọn"  # Commit
```

**Convention commit messages:**
- `feat:` - Tính năng mới
- `fix:` - Sửa bug  
- `docs:` - Thay đổi docs
- `style:` - CSS/UI styling
- `refactor:` - Refactor code
- `test:` - Thêm tests

#### Push và tạo PR
```bash
git push origin feature/ten-feature
# Sau đó tạo Pull Request trên GitHub
```

#### Sau khi merge
```bash
git checkout develop
git pull origin develop
git branch -d feature/ten-feature      # Xóa branch local
```

---

## 🧪 Testing & Debugging

### Debug trong Browser
- Mở DevTools: `F12` hoặc `Ctrl+Shift+I`
- React DevTools extension (recommended)
- Console logs: `console.log()`, `console.table()`

### Debug với VSCode
Tạo `.vscode/launch.json`:
```json
{
  "type": "chrome",
  "request": "launch",
  "name": "Debug React",
  "url": "http://localhost:3000",
  "webRoot": "${workspaceFolder}/src"
}
```

### Check build errors
```bash
npm run build        # Xem lỗi compile TypeScript
```

---

**Happy Coding! 🚀**

*Last updated: February 2026*
