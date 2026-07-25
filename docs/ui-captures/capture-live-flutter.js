const { chromium } = require('/Users/orotech/playwright-ts/node_modules/playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();
  await page.goto('http://127.0.0.1:53241', { waitUntil: 'networkidle' });
  await page.waitForTimeout(5000);
  await page.screenshot({
    path: path.resolve(__dirname, 'flutter-live-current.png'),
  });
  const text = await page.locator('body').innerText().catch(() => '');
  process.stdout.write(text.slice(0, 5000));
  await browser.close();
})();
