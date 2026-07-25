const { chromium } = require('/Users/orotech/playwright-ts/node_modules/playwright');
const path = require('path');

(async () => {
  const browser = await chromium.connectOverCDP('http://127.0.0.1:51456');
  const pages = browser.contexts().flatMap((context) => context.pages());
  for (let index = 0; index < pages.length; index += 1) {
    const page = pages[index];
    await page.setViewportSize({ width: 390, height: 844 });
    await page.waitForTimeout(1500);
    process.stdout.write(`${index}: ${await page.title()} | ${page.url()}\n`);
    const semantics = await page.locator('flt-semantics').allTextContents();
    process.stdout.write(`Semantics: ${semantics.slice(0, 80).join(' | ')}\n`);
    await page.screenshot({
      path: path.resolve(__dirname, `flutter-direct-page-${index}.png`),
    });
  }
  await browser.close();
})();
