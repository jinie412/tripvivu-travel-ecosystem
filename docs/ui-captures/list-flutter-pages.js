const { chromium } = require('/Users/orotech/playwright-ts/node_modules/playwright');

(async () => {
  const browser = await chromium.connectOverCDP('http://127.0.0.1:51456');
  const pages = browser.contexts().flatMap((context) => context.pages());
  for (let index = 0; index < pages.length; index += 1) {
    process.stdout.write(`${index}: ${await pages[index].title()} | ${pages[index].url()}\n`);
  }
  process.exit(0);
})();
