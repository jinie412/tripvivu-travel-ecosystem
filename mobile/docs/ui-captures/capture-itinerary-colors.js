const { chromium } = require('/Users/orotech/playwright-ts/node_modules/playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: { width: 1300, height: 910 },
    deviceScaleFactor: 1,
  });
  await page.goto(
    `file://${path.resolve(__dirname, 'itinerary-color-sync-preview.html')}`,
  );
  const captures = {
    'itinerary-create-color-sync.png': '#create',
    'itinerary-summary-color-sync.png': '#summary',
    'itinerary-detail-color-sync.png': '#detail',
  };
  for (const [file, selector] of Object.entries(captures)) {
    await page.locator(selector).screenshot({
      path: path.resolve(__dirname, file),
    });
  }
  await browser.close();
})();
