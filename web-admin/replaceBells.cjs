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
      
      let modified = false;
      
      const bellButtonRegex1 = /<button className="icon-btn">\s*<Bell size=\{20\} \/>\s*<\/button>/g;
      const bellButtonRegex2 = /<button className="icon-btn"\s*>\s*<Bell size=\{20\} \/>\s*<\/button>/g;
      
      if (bellButtonRegex1.test(content) || bellButtonRegex2.test(content)) {
        content = content.replace(bellButtonRegex1, '<NotificationBell />');
        content = content.replace(bellButtonRegex2, '<NotificationBell />');
        modified = true;
      }
      
      if (modified) {
        let depth = fullPath.split(path.sep).length - targetDir.split('/').length;
        // UserManagement/index.tsx depth is 2 relative to admin
        let prefix = '../'.repeat(depth + 1); // up to admin, up to pages, up to src
        if (fullPath.includes('UserDetail/components')) {
            prefix = '../../../../';
        } else if (fullPath.includes('UserDetail')) {
            prefix = '../../../';
        } else {
            prefix = '../../../';
        }

        const importStr = `\nimport { NotificationBell } from '${prefix}components/NotificationBell';`;

        if (!content.includes('NotificationBell')) {
            content = content.replace(
                /(import\s*{\s*AdminHeaderProfile\s*}\s*from\s*'.*?';)/,
                `$1${importStr}`
            );
        }
        
        fs.writeFileSync(fullPath, content);
        console.log('Updated', fullPath);
      }
    }
  }
}

processDir(targetDir);
