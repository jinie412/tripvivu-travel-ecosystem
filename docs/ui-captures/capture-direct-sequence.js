const { chromium } = require('/Users/orotech/playwright-ts/node_modules/playwright');
const path = require('path');

(async () => {
  const browser = await chromium.connectOverCDP('http://127.0.0.1:51456');
  const pages = browser.contexts().flatMap((context) => context.pages());
  const page = pages.find((candidate) =>
    candidate.url().startsWith('http://localhost:53241'),
  );
  if (!page) throw new Error('Không tìm thấy tab Flutter đang chạy.');
  await page.setViewportSize({ width: 922, height: 2048 });
  await page.waitForTimeout(2500);

  await page.mouse.click(460, 280);
  await page.waitForTimeout(3500);
  await page.screenshot({
    path: path.resolve(__dirname, 'flutter-direct-summary.png'),
  });

  await page.mouse.click(460, 2010);
  await page.waitForTimeout(4500);
  await page.screenshot({
    path: path.resolve(__dirname, 'flutter-direct-detail-collapsed.png'),
  });

  await page.mouse.move(460, 500);
  await page.mouse.down();
  await page.mouse.move(460, 120, { steps: 24 });
  await page.mouse.up();
  await page.waitForTimeout(2200);
  await page.screenshot({
    path: path.resolve(__dirname, 'flutter-direct-detail.png'),
  });

  process.stdout.write(`${await page.title()} | ${page.url()}\n`);
  process.exit(0);
})();
