const fs = require('fs');
const path = require('path');

const targetDir = 'd:/DATN/Travel-Graduation-Workspace/travel-advisor-web/src/pages/admin';

function processDir(dir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory()) {
      processDir(fullPath);
    } else if (fullPath.endsWith('.tsx')) {
      let content = fs.readFileSync(fullPath, 'utf8');
      
      // If it has NotificationBell component but not the import
      if (content.includes('<NotificationBell />') && !content.includes('import { NotificationBell }')) {
        let depth = fullPath.split(path.sep).length - targetDir.split('/').length;
        let prefix = '../'.repeat(depth + 1);
        if (fullPath.includes('UserDetail/components')) {
            prefix = '../../../../';
        } else if (fullPath.includes('UserDetail')) {
            prefix = '../../../';
        } else {
            prefix = '../../../';
        }

        const importStr = `\nimport { NotificationBell } from '${prefix}components/NotificationBell';`;

        content = content.replace(
            /(import\s*{\s*AdminHeaderProfile\s*}\s*from\s*'.*?';)/,
            `$1${importStr}`
        );
        
        fs.writeFileSync(fullPath, content);
        console.log('Added import to', fullPath);
      }
    }
  }
}

processDir(targetDir);
