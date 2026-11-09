// Renders every wallpaper in shaders.js to one seamless loop of JPEG frames,
// then encodes a full 1080p MP4, a small preview MP4 and a poster for the site.
//   node render.mjs [outDir=../../web/public/wallpapers] [ids=comma,separated] [--frames-only]
import { execFileSync, spawn } from "node:child_process";
import { mkdirSync, mkdtempSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const outDir = resolve(process.argv[2] ?? join(here, "../../web/public/wallpapers"));
const only = process.argv[3] && !process.argv[3].startsWith("--") ? process.argv[3].split(",") : null;
const framesOnly = process.argv.includes("--frames-only");
const FPS = 30;
const CHROME = process.env.CHROME ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const PORT = 9334;

mkdirSync(outDir, { recursive: true });
const work = mkdtempSync(join(tmpdir(), "notchi-wp-"));
const chrome = spawn(CHROME, [
  "--headless=new", `--remote-debugging-port=${PORT}`, `--user-data-dir=${join(work, "profile")}`,
  "--window-size=1920,1080", "--hide-scrollbars", "--force-device-scale-factor=1",
  "--use-angle=metal", "--enable-gpu", "--ignore-gpu-blocklist", "--no-first-run", "about:blank",
], { stdio: "ignore" });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function json(path) {
  for (let i = 0; i < 150; i++) {
    try { return await (await fetch(`http://127.0.0.1:${PORT}${path}`)).json(); } catch { await sleep(200); }
  }
  throw new Error("Chrome didn't start");
}

const target = (await json("/json/list")).find((t) => t.type === "page");
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener("open", r, { once: true }));
let id = 0;
const pending = new Map();
const events = [];
ws.addEventListener("message", (m) => {
  const msg = JSON.parse(m.data);
  if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); } else if (msg.method) events.push(msg.method);
});
const send = (method, params = {}) => new Promise((res, rej) => {
  const i = ++id;
  pending.set(i, (msg) => (msg.error ? rej(new Error(`${method}: ${msg.error.message}`)) : res(msg.result)));
  ws.send(JSON.stringify({ id: i, method, params }));
});
const evaluate = async (expression) => {
  const r = await send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true });
  if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description ?? r.exceptionDetails.text);
  return r.result.value;
};

await send("Page.enable");
await send("Runtime.enable");
await send("Emulation.setDeviceMetricsOverride", { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false });

// list of wallpapers comes from the page itself
await send("Page.navigate", { url: pathToFileURL(join(here, "index.html")).href });
await sleep(800);
const all = await evaluate("WALLPAPERS.map(w => ({ id: w.id, name: w.name, kind: w.kind, theme: w.theme }))");
const list = only ? all.filter((w) => only.includes(w.id)) : all;
const encoder = join(here, "../intro/encode.swift");

for (const w of list) {
  events.length = 0;
  await send("Page.navigate", { url: `${pathToFileURL(join(here, "index.html")).href}?w=${w.id}` });
  for (let i = 0; i < 100 && !events.includes("Page.loadEventFired"); i++) await sleep(50);
  const { loop } = await evaluate("window.WALLPAPER");
  const n = loop * FPS;
  const frames = join(work, w.id);
  rmSync(frames, { recursive: true, force: true });
  mkdirSync(frames, { recursive: true });
  const t0 = Date.now();
  for (let i = 0; i < n; i++) {
    await evaluate(`render(${i / n}); 1`);
    const { data } = await send("Page.captureScreenshot", { format: "jpeg", quality: 94 });
    writeFileSync(join(frames, `f${String(i).padStart(5, "0")}.jpg`), Buffer.from(data, "base64"));
  }
  console.log(`${w.id}: ${n} frames in ${((Date.now() - t0) / 1000).toFixed(1)}s`);
  if (framesOnly) { console.log(`  frames: ${frames}`); continue; }
  execFileSync("swift", [encoder, frames, join(outDir, `${w.id}.mp4`), String(FPS), "4500000"], { stdio: "inherit" });
  execFileSync("swift", [encoder, frames, join(outDir, `${w.id}-preview.mp4`), String(FPS), "900000", "640"], { stdio: "inherit" });
  const first = readdirSync(frames).sort()[0];
  execFileSync("sips", ["-Z", "960", join(frames, first), "--out", join(outDir, `${w.id}.jpg`)], { stdio: "ignore" });
  rmSync(frames, { recursive: true, force: true });
}
ws.close();
chrome.kill();
await new Promise((r) => chrome.once("exit", r));
if (!framesOnly) rmSync(work, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
