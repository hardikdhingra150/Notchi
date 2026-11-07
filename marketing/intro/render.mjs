// Renders index.html to numbered JPEG frames with headless Chrome over the
// DevTools protocol (no npm packages: Node's built-in WebSocket).
//   node render.mjs <outDir> [fps=30] [onlyTimes=comma,separated,seconds]
import { spawn } from "node:child_process";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const out = resolve(process.argv[2] ?? join(here, "out/frames"));
const fps = Number(process.argv[3] ?? 30);
const only = process.argv[4]?.split(",").map(Number);
const CHROME = process.env.CHROME ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const PORT = 9333;

mkdirSync(out, { recursive: true });
const profile = mkdtempSync(join(tmpdir(), "notchi-intro-"));
const chrome = spawn(CHROME, [
  "--headless=new", `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`,
  "--window-size=1920,1080", "--hide-scrollbars", "--force-device-scale-factor=1",
  "--disable-gpu-vsync", "--no-first-run", "--no-default-browser-check", "about:blank",
], { stdio: "ignore" });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function json(path, method = "GET") {
  for (let i = 0; i < 50; i++) {
    try { return await (await fetch(`http://127.0.0.1:${PORT}${path}`, { method })).json(); } catch { await sleep(200); }
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
  if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
  else if (msg.method) events.push(msg.method);
});
const send = (method, params = {}) => new Promise((res, rej) => {
  const i = ++id;
  pending.set(i, (msg) => (msg.error ? rej(new Error(`${method}: ${msg.error.message}`)) : res(msg.result)));
  ws.send(JSON.stringify({ id: i, method, params }));
});
const evaluate = async (expression) => {
  const r = await send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true });
  if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description ?? "eval failed");
  return r.result.value;
};

await send("Page.enable");
await send("Runtime.enable");
await send("Emulation.setDeviceMetricsOverride", { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false });
await send("Page.navigate", { url: pathToFileURL(join(here, "index.html")).href });
for (let i = 0; i < 100 && !events.includes("Page.loadEventFired"); i++) await sleep(100);
await evaluate("document.fonts.ready.then(() => document.fonts.size)");
await sleep(300);

const duration = await evaluate("window.DURATION");
const times = only ?? Array.from({ length: Math.round(duration * fps) }, (_, i) => i / fps);
const started = Date.now();
for (let i = 0; i < times.length; i++) {
  await evaluate(`render(${times[i]}); new Promise(r => requestAnimationFrame(() => r(1)))`);
  const { data } = await send("Page.captureScreenshot", { format: "jpeg", quality: 92, captureBeyondViewport: false });
  const name = only ? `t${String(times[i]).replace(".", "_")}.jpg` : `f${String(i).padStart(5, "0")}.jpg`;
  writeFileSync(join(out, name), Buffer.from(data, "base64"));
  if (i % 60 === 0) process.stdout.write(`frame ${i}/${times.length}  ${((Date.now() - started) / 1000).toFixed(0)}s\n`);
}
console.log(`done: ${times.length} frames in ${((Date.now() - started) / 1000).toFixed(1)}s -> ${out}`);
ws.close();
chrome.kill();
