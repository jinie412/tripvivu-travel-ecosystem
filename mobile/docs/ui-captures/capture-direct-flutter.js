const { chromium } = require('/Users/orotech/playwright-ts/node_modules/playwright');
const path = require('path');

(async () => {
  const browser = await chromium.connectOverCDP('http://127.0.0.1:51456');
  const page = browser.contexts()[0].pages()[0];
  await page.setViewportSize({ width: 922, height: 2048 });
  await page.waitForTimeout(800);

  const action = process.argv[2];
  if (action === 'create') {
    await page.mouse.click(195, 780);
    await page.waitForTimeout(1400);
    await page.screenshot({
      path: path.resolve(__dirname, 'flutter-direct-create.png'),
    });
  } else if (action === 'create-from-home') {
    await page.mouse.click(460, 1990);
    await page.waitForTimeout(1800);
    await page.screenshot({
      path: path.resolve(__dirname, 'flutter-direct-create-gradient.png'),
    });
  } else if (action === 'save-create') {
    await page.screenshot({
      path: path.resolve(__dirname, 'flutter-direct-create.png'),
    });
  } else if (action === 'back') {
    await page.mouse.click(36, 29);
    await page.waitForTimeout(1200);
    await page.screenshot({
      path: path.resolve(__dirname, 'flutter-direct-after-back.png'),
    });
  } else if (action === 'summary') {
    await page.mouse.click(400, 1260);
    await page.waitForTimeout(2400);
    await page.screenshot({
      path: path.resolve(__dirname, 'flutter-direct-summary.png'),
    });
  } else if (action === 'save-summary') {
    await page.screenshot({
      path: path.resolve(__dirname, 'flutter-direct-summary.png'),
    });
  } else if (action === 'summary-bottom') {
    for (let index = 0; index < 4; index += 1) {
      await page.mouse.move(460, 1750);
      await page.mouse.down();
      await page.mouse.move(460, 320, { steps: 18 });
      await page.mouse.up();
      await page.waitForTimeout(350);
    }
    await page.screenshot({
      path: path.resolve(__dirname, 'flutter-direct-summary-bottom.png'),
    });
  } else if (action === 'detail') {
    await page.mouse.click(460, 2010);
    await page.waitForTimeout(3500);
    await page.screenshot({
      path: path.resolve(__dirname, 'flutter-direct-detail.png'),
    });
  } else if (action === 'expand-detail') {
    await page.mouse.move(460, 500);
    await page.mouse.down();
    await page.mouse.move(460, 110, { steps: 20 });
    await page.mouse.up();
    await page.waitForTimeout(1400);
    await page.screenshot({
      path: path.resolve(__dirname, 'flutter-direct-detail.png'),
    });
  } else if (action === 'current') {
    await page.screenshot({
      path: path.resolve(__dirname, 'flutter-direct-current.png'),
    });
  }
  const metrics = await page.evaluate(() => ({
    innerWidth,
    innerHeight,
    devicePixelRatio,
  }));
  process.stdout.write(
    `${await page.title()} | ${page.url()} | ${JSON.stringify(metrics)}\n`,
  );
  process.exit(0);
})();
