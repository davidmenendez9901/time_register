// Google Play (Pixel 10 Pro). Renders into goldie/android/out.
import { APP_ROOT, base } from "../shared.ts";

const config = {
  ...base,
  // goldie requires the iOS fields even for an android-only config.
  appPath: `${APP_ROOT}/goldie/builds/Runner.app`,
  bundleId: "dev.davidmenendez.timeregister",
  android: {
    appPath: `${APP_ROOT}/goldie/builds/time_register-demo.apk`,
    applicationId: "time_register.davidmenendez.dev",
  },
  devices: ["pixel-10-pro"],
  flowsDir: `${APP_ROOT}/.argent/flows/android`,
};

export default config;
