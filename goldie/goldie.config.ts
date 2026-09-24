// App Store (iPhone 6.9"). Demo build: goldie/README in the repo root's
// goldie section; build with --dart-define=DEMO_DATA=true.
import { APP_ROOT, base } from "./shared.ts";

const config = {
  ...base,
  appPath: `${APP_ROOT}/goldie/builds/Runner.app`,
  bundleId: "dev.davidmenendez.timeregister",
  devices: ["iphone-6.9"],
  flowsDir: `${APP_ROOT}/.argent/flows/ios`,
};

export default config;
