/** Change these once, and every link on the site follows. */
export const REPO = "hardikdhingra150/notchi";
export const REPO_URL = `https://github.com/${REPO}`;
export const RELEASES_URL = `${REPO_URL}/releases`;
/** Homebrew 7 asks before it loads a cask from a third-party tap, hence the trust step. */
export const BREW = "brew trust --cask hardikdhingra150/tap/notchi && brew install --cask hardikdhingra150/tap/notchi";

/** The current public build. Update both when a new version is released. */
export const APP_VERSION = "0.5.0-beta.5";
export const DOWNLOAD_URL = `${REPO_URL}/releases/download/v${APP_VERSION}/Notchi-${APP_VERSION}.dmg`;
export const SITE_URL = "https://notchi-plum.vercel.app";

/** Website version, shown in the footer. Keep in step with package.json and the changelog. */
export const SITE_VERSION = "v9";
