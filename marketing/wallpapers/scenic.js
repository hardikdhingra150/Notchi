// Golden Hour: painted landscapes made to sit behind a real desktop.
// Rules every scene here follows so icons and folders stay easy to read:
//   - the upper sky is a smooth, mid-tone gradient (white labels read on it)
//   - the busy detail lives on the horizon and lower half, never top right,
//     where macOS lines up desktop icons
//   - the bottom strip is calm and darker for the Dock
//   - motion is slow: grass, mist, water and birds, nothing that flashes
// Same loop rule as shaders.js: everything moving completes whole cycles per loop.

const SC = `
float hs(float n){ return fract(sin(n * 127.1) * 43758.5453); }
float n1(float x){ float i = floor(x), f = fract(x); return mix(hs(i), hs(i + 1.), f * f * (3. - 2. * f)); }
float f1(float x){ float v = 0., a = .5; for (int i = 0; i < 5; i++) { v += a * n1(x); x = x * 2.07 + 3.1; a *= .5; } return v; }
float seg(vec2 p, vec2 a, vec2 b){ vec2 pa = p - a, ba = b - a; float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.); return length(pa - ba * h); }
float below(float y, float h, float px){ return smoothstep(px, -px, y - h); }
vec3 grad4(float t, vec3 a, vec3 b, vec3 c, vec3 d){
  vec3 col = mix(a, b, smoothstep(0., .28, t));
  col = mix(col, c, smoothstep(.22, .62, t));
  return mix(col, d, smoothstep(.55, 1., t)); }
vec3 grade(vec3 col, vec2 uv){
  col *= mix(.8, 1., smoothstep(1.2, .4, length((uv - .5) * vec2(1.2, 1.))));
  col *= mix(.8, 1., smoothstep(0., .13, uv.y));
  return col + (h21(gl_FragCoord.xy * .713 + 7.) - .5) * (3. / 255.); }
// a row of pointed conifers on a ridge
float pines(float x, float seed, float n, float th){
  float best = 0.;
  for (int k = -1; k <= 1; k++) {
    float c = floor(x * n) + float(k);
    float cx = c + .5 + .35 * (hs(c + seed * 5.) - .5);
    float hw = .38 + .3 * hs(c + seed * 7.);
    float hgt = th * (.35 + .65 * hs(c + seed)) * step(.12, hs(c + seed * 3.));
    float tri = max(0., 1. - abs(x * n - cx) / hw);
    best = max(best, hgt * tri * (.92 + .08 * sin(tri * 30.))); }
  return best; }
// round, cloud-like bumps: overlapping circles along a line
float puffs(float x, float n, float seed, float mv){
  float c0 = floor(x * n), best = 0.;
  for (int k = -1; k <= 1; k++) { float c = c0 + float(k);
    float cx = (c + .5 + .35 * (hs(c + seed) - .5) + mv * sin(TAU * T + c * 1.7)) / n;
    float r = (.55 + .5 * hs(c * 1.3 + seed)) / n;
    float d = x - cx;
    best = max(best, sqrt(max(r * r - d * d, 0.))); }
  return best; }
// grass or flower blades leaning in the wind; returns (mask, tip height)
vec2 blades(vec2 p, float base, float amp, float n, float seed, float px, float wind){
  float sway = sin(TAU * T * wind + p.x * 2.5 + seed);
  float x = p.x - max(p.y - base, 0.) * (.35 * sway);
  float c = floor(x * n), f = fract(x * n);
  float h = base + amp * (.3 + .7 * hs(c + seed)) * pow(1. - abs(f - .5) * 2., 1.6) + .025 * f1(p.x * 3. + seed);
  return vec2(below(p.y, h, px), h); }
float birds(vec2 p, vec2 at, float px, float flaps){
  float m = 0.;
  for (int i = 0; i < 6; i++) { float fi = float(i);
    vec2 q = p - at - vec2(-abs(fi - 2.) * .032 - hs(fi) * .02, (fi - 2.) * .011 + hs(fi + 4.) * .012);
    float flap = sin(TAU * T * flaps + fi * 1.9);
    float d = abs(q.y - abs(q.x) * (.12 + .5 * flap));
    m = max(m, smoothstep(px * 1.4, 0., d - .0012) * step(abs(q.x), .011)); }
  return m; }
`;

const SCENIC = [
  {
    id: "savanna", name: "Savanna Sunset", kind: "shader", theme: "Paper", loop: 12,
    line: "Acacias and a giraffe against a low sun, grass moving in the warm wind.",
    frag: `
    float acacia(vec2 p, vec2 base, float s, float seed, float px){
      vec2 q = (p - base) / s; float qp = px / s;
      float d = seg(q, vec2(0.), vec2(.015, .3)) - .02;
      d = min(d, seg(q, vec2(.015, .28), vec2(-.17, .5)) - .012);
      d = min(d, seg(q, vec2(.015, .28), vec2(.21, .51)) - .012);
      d = min(d, seg(q, vec2(.03, .34), vec2(.05, .54)) - .009);
      float cr = 1e3;
      for (int k = 0; k < 9; k++) { float fk = float(k);
        vec2 c = vec2(-.42 + fk * .105 + (hs(fk + seed) - .5) * .05, .55 + .035 * hs(fk * 2. + seed) - abs(fk - 4.) * .006);
        float r = .085 + .04 * hs(fk * 3. + seed);
        cr = min(cr, (length((q - c) * vec2(1., 2.1)) - r) / 2.1); }
      d = min(d, cr + (noise(q * 40. + seed) - .5) * .012);
      return smoothstep(qp, -qp, d); }
    float giraffe(vec2 p, vec2 base, float s, float px){
      vec2 q = (p - base) / s; float qp = px / s;
      float bob = .012 * sin(TAU * T * 2.);
      float d = (length(vec2(q.x / .17, (q.y - .43) / .075)) - 1.) * .075;
      d = min(d, seg(q, vec2(-.12, .42), vec2(-.13, 0.)) - .014);
      d = min(d, seg(q, vec2(-.07, .4), vec2(-.06, 0.)) - .014);
      d = min(d, seg(q, vec2(.08, .4), vec2(.1, 0.)) - .014);
      d = min(d, seg(q, vec2(.13, .42), vec2(.15, 0.)) - .014);
      vec2 head = vec2(.29, .88 + bob);
      d = min(d, seg(q, vec2(.12, .46), head) - mix(.035, .018, clamp((q.y - .46) / .42, 0., 1.)));
      d = min(d, seg(q, head, head + vec2(.08, -.04)) - .02);
      d = min(d, seg(q, head + vec2(-.01, .01), head + vec2(-.01, .06)) - .006);
      d = min(d, seg(q, vec2(-.17, .45), vec2(-.21, .28)) - .005);
      return smoothstep(qp, -qp, d); }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y; float px = 1.2 / R.y;
      float hz = -.1;
      vec3 hor = vec3(1., .74, .42);
      vec3 col = grad4(clamp((p.y - hz) / (.5 - hz), 0., 1.), hor, vec3(.95, .45, .3), vec3(.6, .22, .32), vec3(.26, .09, .2));
      vec2 sp = vec2(-.3, hz + .12);
      float sd = length(p - sp);
      col += vec3(1., .55, .25) * exp(-sd * 3.5) * .4 * (1. + .04 * sin(TAU * T * 2.));
      col += vec3(1., .85, .55) * exp(-sd * 16.) * .4;
      float cs = fbm(vec2(p.x * 1.1, p.y * 9.) + loop(.2) + 2.);
      float streak = smoothstep(.55, .78, cs) * smoothstep(hz + .04, hz + .14, p.y) * smoothstep(.34, .12, p.y);
      col = mix(col, mix(vec3(.62, .25, .32), vec3(1., .72, .45), exp(-sd * 2.5)), streak * .55);
      col = mix(col, vec3(1., .93, .72), smoothstep(.1 + px, .1 - px, sd));
      col = mix(col, vec3(.22, .07, .12), birds(p, vec2(-1.15 + fract(T) * 2.4, .17), px, 30.));
      // far hills that hide the bottom of the sun
      col = mix(col, mix(hor, vec3(.62, .26, .3), .55), below(p.y, hz + .02 + .045 * f1(p.x * 1.8 + 4.), px));
      // the plain, darkening toward you
      float g = clamp((hz - p.y) / (hz + .5), 0., 1.);
      vec3 ground = mix(mix(vec3(.55, .22, .25), hor, .3), vec3(.15, .05, .08), smoothstep(0., .75, g));
      col = mix(col, ground, below(p.y, hz + .004 * f1(p.x * 9.), px));
      float far = 0.;
      for (int i = 0; i < 5; i++) { float fi = float(i);
        far = max(far, acacia(p, vec2(-.82 + fi * .4 + hs(fi) * .16, hz - .004), .06 + .05 * hs(fi + 2.), fi, px)); }
      col = mix(col, vec3(.4, .14, .19), far);
      col = mix(col, vec3(.2, .06, .1), max(acacia(p, vec2(-.66, -.19), .22, 9., px), giraffe(p, vec2(-.4, -.17), .2, px)));
      col = mix(col, vec3(.1, .03, .06), acacia(p, vec2(.5, -.4), .62, 4., px));
      vec2 b1 = blades(p, -.37, .05, 140., 1., px, 2.);
      col = mix(col, vec3(.2, .07, .1), b1.x);
      col += vec3(1., .6, .3) * exp(-(b1.y - p.y) * 70.) * b1.x * .25;
      vec2 b2 = blades(p, -.45, .07, 95., 5., px, 2.);
      col = mix(col, vec3(.08, .025, .05), b2.x);
      col += vec3(1., .55, .25) * exp(-(b2.y - p.y) * 60.) * b2.x * .18;
      gl_FragColor = vec4(grade(col, uv), 1.); }`,
  },
  {
    id: "desert-mesa", name: "Desert Mesa", kind: "shader", theme: "Paper",
    line: "Buttes and saguaros just after sunset, the first stars over the dunes.",
    frag: `
    float mesa(float x, float c, float w, float h, float sl){ return h * smoothstep(w + sl, w, abs(x - c)); }
    float saguaro(vec2 p, vec2 b, float s, float px){
      vec2 q = (p - b) / s; float qp = px / s;
      float d = seg(q, vec2(0.), vec2(0., .62)) - .045;
      d = min(d, seg(q, vec2(0., .26), vec2(-.15, .26)) - .035);
      d = min(d, seg(q, vec2(-.15, .26), vec2(-.15, .46)) - .035);
      d = min(d, seg(q, vec2(0., .34), vec2(.13, .34)) - .033);
      d = min(d, seg(q, vec2(.13, .34), vec2(.13, .52)) - .033);
      return smoothstep(qp, -qp, d); }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y; float px = 1.2 / R.y;
      float hz = -.06;
      vec3 hor = vec3(1., .62, .36);
      vec3 col = grad4(clamp((p.y - hz) / (.5 - hz), 0., 1.), hor, vec3(.9, .4, .38), vec3(.42, .2, .42), vec3(.11, .08, .23));
      vec2 id = floor(gl_FragCoord.xy / 3.); float r = h21(id);
      col += step(.9965, r) * (.55 + .45 * sin(TAU * T * 2. + r * 50.)) * smoothstep(.12, .45, p.y) * .75;
      col += vec3(1., .5, .3) * exp(-length((p - vec2(.15, hz)) * vec2(.55, 1.6)) * 3.) * .45;
      float cs = fbm(vec2(p.x * 1.3, p.y * 10.) + loop(.2) + 6.);
      col = mix(col, vec3(.98, .58, .5), smoothstep(.58, .8, cs) * smoothstep(hz + .03, hz + .1, p.y) * smoothstep(.28, .1, p.y) * .5);
      // a thin crescent moon, top left
      vec2 mp = p - vec2(-.62, .32);
      float moon = smoothstep(.03 + px, .03 - px, length(mp)) * smoothstep(.026 - px, .026 + px, length(mp - vec2(.012, .008)));
      col = mix(col, vec3(1., .95, .85), moon);
      col += vec3(1., .9, .8) * exp(-length(mp) * 30.) * .08;
      float xs = p.x + .0015 * sin(TAU * T * 3. + p.y * 260.);
      float h1 = hz + .01 * f1(xs * 6.) + mesa(xs, -.55, .12, .12, .03) + mesa(xs, -.33, .05, .08, .02)
               + mesa(xs, .45, .2, .1, .04) + mesa(xs, .8, .06, .15, .015) + .004 * f1(xs * 40.);
      col = mix(col, mix(hor, vec3(.55, .27, .42), .62), below(p.y, h1, px));
      float h2 = hz - .04 + mesa(p.x, -.05, .09, .16, .035) + mesa(p.x, .25, .04, .11, .02) + .015 * f1(p.x * 5. + 2.) + .004 * f1(p.x * 50.);
      float m2 = below(p.y, h2, px);
      col = mix(col, mix(vec3(.36, .14, .2), vec3(.6, .25, .25), smoothstep(-.02, 0., p.y - h2 + .02) * .5), m2);
      float d1 = -.17 + .03 * sin(p.x * 3. + 1.) + .02 * f1(p.x * 2.);
      float md1 = below(p.y, d1, px);
      col = mix(col, vec3(.24, .1, .13) + .015 * sin(p.y * 260. + p.x * 14. + f1(p.x * 6.) * 8.), md1);
      col += vec3(1., .55, .35) * exp(-(d1 - p.y) * 90.) * md1 * .22;
      col = mix(col, vec3(.13, .05, .08), saguaro(p, vec2(.62, d1 - .012), .17, px));
      float d2 = -.33 + .05 * sin(p.x * 2.2 - .8) + .01 * f1(p.x * 6.);
      float md2 = below(p.y, d2, px);
      col = mix(col, vec3(.11, .045, .07), md2);
      col += vec3(1., .5, .3) * exp(-(d2 - p.y) * 80.) * md2 * .15;
      col = mix(col, vec3(.06, .02, .04), saguaro(p, vec2(-.6, -.41), .33, px));
      gl_FragColor = vec4(grade(col, uv), 1.); }`,
  },
  {
    id: "misty-pines", name: "Misty Pines", kind: "shader", theme: "Midnight",
    line: "Ridge after ridge of pines in morning mist, mirrored in a still lake.",
    frag: `
    vec3 scene(vec2 p, float px){
      float hz = -.15;
      vec3 col = grad4(clamp((p.y - hz) / (.5 - hz), 0., 1.), vec3(1., .82, .68), vec3(.82, .72, .74), vec3(.5, .56, .68), vec3(.26, .34, .48));
      vec2 sp = vec2(.05, hz + .14);
      float sd = length(p - sp);
      col += vec3(1., .8, .6) * exp(-sd * 3.) * .35;
      col = mix(col, vec3(1., .94, .82), smoothstep(.055, .045, sd) * .55);
      float a = atan(p.y - sp.y, p.x - sp.x);
      col += vec3(1., .85, .65) * smoothstep(.55, .8, fbm(vec2(a * 5., 1.) + loop(.25))) * exp(-sd * 2.2) * .045;
      for (int i = 0; i < 5; i++) { float fi = float(i);
        float base = hz + .2 - fi * .075;
        float h = base + .06 * (f1(p.x * (1.5 + fi * .6) + fi * 7.) - .5) + pines(p.x + fi * .37, fi * 11., 14. + fi * 8., .03 + fi * .013) * step(.5, fi);
        col = mix(col, mix(vec3(.66, .66, .72), vec3(.04, .1, .1), (fi + 1.) / 5.), below(p.y, h, px));
        float fog = fbm(vec2(p.x * 1.4 - fi * 2., p.y * 5.) + loop(.3 + fi * .05) + fi * 3.);
        col = mix(col, vec3(.88, .84, .84), smoothstep(.06, 0., abs(p.y - base + .045)) * smoothstep(.3, .75, fog) * (.7 - fi * .1)); }
      return col; }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y; float px = 1.2 / R.y;
      float lake = -.3;
      vec3 col;
      if (p.y > lake) col = scene(p, px);
      else {
        float dd = lake - p.y;
        float rip = .004 * sin(p.y * 240. / (dd + .3) + TAU * T * 2.) * smoothstep(0., .1, dd) + .002 * (noise(vec2(p.x * 8., p.y * 60.) + loop(.6)) - .5);
        col = scene(vec2(p.x + rip, 2. * lake - p.y), px) * vec3(.72, .8, .86);
        col += vec3(1., .9, .8) * smoothstep(.72, .95, noise(vec2(p.x * 4., p.y * 140.) + loop(.8))) * .05;
        col = mix(col, vec3(.04, .07, .09), smoothstep(.02, .2, dd) * .45);
      }
      col = mix(col, vec3(.03, .05, .06), smoothstep(.006, 0., abs(p.y - lake + .002)) * .8);
      // a small boat, rocking
      vec2 bq = p - vec2(-.36, -.385);
      bq = rot(bq, .03 * sin(TAU * T));
      float hull = step(abs(bq.x), .05 - bq.y * .6) * step(-.012, bq.y) * step(bq.y, 0.);
      float man = smoothstep(.009, .007, length(bq - vec2(.005, .02))) + step(abs(bq.x - .005), .006) * step(0., bq.y) * step(bq.y, .016);
      col = mix(col, vec3(.03, .04, .05), max(hull, man));
      gl_FragColor = vec4(grade(col, uv), 1.); }`,
  },
  {
    id: "lavender-fields", name: "Lavender Fields", kind: "shader", theme: "Sakura",
    line: "Rows of lavender running toward a lone tree and a setting sun.",
    frag: `
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y; float px = 1.2 / R.y;
      float hz = -.02;
      vec3 hor = vec3(1., .78, .52);
      vec3 col = grad4(clamp((p.y - hz) / (.5 - hz), 0., 1.), hor, vec3(.95, .56, .55), vec3(.6, .45, .7), vec3(.3, .25, .5));
      vec2 sp = vec2(.22, hz + .07);
      float sd = length(p - sp);
      col += vec3(1., .65, .4) * exp(-sd * 3.2) * .4;
      col = mix(col, vec3(1., .95, .78), smoothstep(.06 + px, .06 - px, sd));
      float cl = fbm(p * vec2(1.6, 4.) + loop(.2) + 1.);
      float cm = smoothstep(.55, .72, cl) * smoothstep(hz + .08, hz + .18, p.y) * smoothstep(.36, .16, p.y) * smoothstep(.75, .3, p.x);
      col = mix(col, mix(vec3(.75, .48, .62), vec3(1., .78, .6), exp(-sd * 2.)), cm * .6);
      col = mix(col, mix(hor, vec3(.52, .42, .62), .6), below(p.y, hz + .03 + .04 * f1(p.x * 1.3 + 2.), px));
      float hm = hz + .016 + .014 * sin(p.x * 2.4 + .5) + .008 * f1(p.x * 4.);
      col = mix(col, mix(vec3(.46, .36, .5), vec3(.36, .27, .42), smoothstep(hm, hz - .01, p.y)), below(p.y, hm, px));
      // the lone tree on the hill
      float tx = -.42;
      vec2 tq = p - vec2(tx, hz + .016 + .014 * sin(tx * 2.4 + .5) + .008 * f1(tx * 4.) - .003);
      float crown = 1e3;
      for (int k = 0; k < 6; k++) { float fk = float(k);
        crown = min(crown, length(tq - vec2(-.035 + fk * .014, .06 + .012 * sin(fk * 2.3) + .01 * (1. - abs(fk - 2.5) / 2.5))) - .024 - .006 * hs(fk)); }
      float tree = max(smoothstep(px, -px, crown), smoothstep(px, -px, seg(tq, vec2(0.), vec2(0., .055)) - .004));
      col = mix(col, vec3(.22, .14, .24), tree);
      float fieldTop = hz - .008;
      if (p.y < fieldTop) {
        float dz = max(hz - p.y, .0005);
        float z = 1. / dz;
        float u = (p.x - sp.x) * z * 1.3;
        float f = abs(fract(u) - .5) * 2.;
        float aa = 2. * z * 1.3 / R.y * 1.5;
        float row = smoothstep(.62 + aa, .62 - aa, f);
        row = mix(row, .62, smoothstep(.05, .22, aa));
        float tex = noise(vec2(u * 2., z * 7.) + loop(.3));
        row *= .75 + .25 * smoothstep(.2, .7, noise(vec2(u * 4., z * 14.)));
        vec3 bloom = mix(vec3(.42, .26, .66), vec3(.66, .45, .86), tex) * mix(1., 1.25, exp(-dz * 6.));
        vec3 gap = vec3(.17, .15, .13);
        vec3 field = mix(gap, bloom, row);
        field = mix(field, mix(hor, vec3(.62, .48, .72), .55), exp(-dz * 14.) * .85);
        field *= mix(1., .55, smoothstep(.05, .5, dz));
        col = mix(col, field, below(p.y, fieldTop, px));
      }
      vec2 b = blades(p, -.44, .08, 120., 3., px, 1.);
      col = mix(col, vec3(.16, .09, .2), b.x);
      col = mix(col, vec3(.5, .32, .72), b.x * smoothstep(.03, 0., b.y - p.y) * .7);
      gl_FragColor = vec4(grade(col, uv), 1.); }`,
  },
  {
    id: "palm-beach", name: "Palm Beach", kind: "shader", theme: "Neon Rain",
    line: "Palms over a glittering sea at sunset, waves washing up the sand.",
    frag: `
    float palm(vec2 p, vec2 b, float s, float lean, float seed, float px){
      vec2 q = (p - b) / s; float qp = px / s;
      vec2 top = vec2(lean, 1.), ctl = vec2(lean * .15, .55);
      float d = 1e3; vec2 prev = vec2(0.);
      for (int i = 1; i <= 10; i++) { float t = float(i) / 10.;
        vec2 pt = mix(mix(vec2(0.), ctl, t), mix(ctl, top, t), t);
        d = min(d, seg(q, prev, pt) - mix(.034, .02, t) * (.85 + .15 * sin(t * 60.))); prev = pt; }
      for (int k = 0; k < 7; k++) { float fk = float(k);
        float a = 3.35 - fk * .6 + .05 * sin(TAU * T + fk * .8 + seed);
        vec2 dir = vec2(cos(a), sin(a));
        float L = .42 + .08 * hs(fk + seed), droop = .16 + .22 * (1. - abs(dir.y));
        vec2 pv = top; float dm = 1e3, tg = 0.;
        for (int j = 1; j <= 8; j++) { float t = float(j) / 8.;
          vec2 pt = top + dir * L * t - vec2(0., (droop + .12) * t * t);
          vec2 pa = q - pv, ba = pt - pv; float hh = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
          float dd = length(pa - ba * hh);
          if (dd < dm) { dm = dd; tg = (float(j) - 1. + hh) / 8.; }
          pv = pt; }
        float w = .095 * sin(3.1416 * pow(tg, .7)) + .004;
        float comb = smoothstep(.12, .3, fract(tg * 17. - dm * 13.));
        d = min(d, min(dm - .006, mix(1e3, dm - w, comb * step(dm, w)))); }
      d = min(d, length(q - top - vec2(0., -.03)) - .04);
      return smoothstep(qp, -qp, d); }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y; float px = 1.2 / R.y;
      float hz = -.08;
      vec3 hor = vec3(1., .62, .36);
      vec3 col = grad4(clamp((p.y - hz) / (.5 - hz), 0., 1.), hor, vec3(.97, .44, .42), vec3(.55, .3, .52), vec3(.16, .17, .37));
      vec2 sp = vec2(.12, hz + .035);
      float sd = length(p - sp);
      col += vec3(1., .5, .3) * exp(-sd * 3.) * .45;
      float cs = fbm(vec2(p.x * 1.2, p.y * 9.) + loop(.2) + 9.);
      col = mix(col, mix(vec3(.75, .32, .45), vec3(1., .75, .5), exp(-sd * 2.)), smoothstep(.56, .78, cs) * smoothstep(hz + .05, hz + .14, p.y) * smoothstep(.3, .12, p.y) * .55);
      col = mix(col, vec3(1., .92, .7), smoothstep(.075 + px, .075 - px, sd));
      // a sailboat on the horizon
      vec2 bq = p - vec2(.52, hz + .002 + .0015 * sin(TAU * T * 2.));
      float boat = max(step(abs(bq.x), .022 - bq.y) * step(-.006, bq.y) * step(bq.y, 0.),
                       step(0., bq.y) * step(bq.y, .05) * step(-.001, bq.x) * step(bq.x, .028 * (1. - bq.y / .05)));
      if (p.y < hz) {
        float dd = hz - p.y, z = 1. / (dd + .02);
        vec3 sea = mix(vec3(.62, .3, .38), vec3(.05, .08, .16), smoothstep(0., .3, dd));
        float wv = noise(vec2(p.x * z * 2.5, z * 1.8) + loop(.7));
        sea *= .85 + .3 * wv;
        float w = .03 + dd * .55;
        float g = smoothstep(.6, .88, noise(vec2(p.x * 70., z * 22.) + loop(2.)));
        sea += vec3(1., .72, .45) * smoothstep(w, 0., abs(p.x - sp.x)) * (.25 + g * 1.1) * exp(-dd * 2.5);
        col = sea;
      }
      col = mix(col, vec3(.1, .05, .1), boat);
      float shore = -.33 + .022 * sin(TAU * T) + .01 * sin(p.x * 5.) + .004 * f1(p.x * 20.);
      float foam = smoothstep(.007, 0., abs(p.y - shore)) * (.5 + .5 * noise(vec2(p.x * 30., 0.) + loop(.5)));
      float sand = below(p.y, shore, px);
      vec3 sandc = mix(vec3(.34, .18, .22), vec3(.14, .07, .1), smoothstep(-.33, -.48, p.y));
      col = mix(col, sandc + vec3(.3, .15, .12) * smoothstep(.04, 0., shore - p.y) * .4, sand);
      col = mix(col, vec3(1., .85, .75), foam * .7);
      float pm = max(max(palm(p, vec2(-.72, -.5), .72, .26, 1., px), palm(p, vec2(-.5, -.48), .46, .36, 4., px)), palm(p, vec2(.74, -.47), .34, -.22, 7., px));
      col = mix(col, vec3(.07, .03, .07), pm);
      gl_FragColor = vec4(grade(col, uv), 1.); }`,
  },
  {
    id: "golden-hills", name: "Golden Hills", kind: "shader", theme: "Paper",
    line: "Rolling hills, cypress lanes and a farmhouse in late golden light.",
    frag: `
    float hill(float x, float fi){ return .02 - fi * .09 + .05 * sin(x * (1.6 + fi * .4) + fi * 2.1) + .03 * (f1(x * 2. + fi * 5.) - .5); }
    float cypress(vec2 p, vec2 b, float h, float px){
      vec2 q = p - b; float y = q.y / h;
      q.x -= .012 * h * y * y * sin(TAU * T + b.x * 10.);
      float w = h * .12 * sin(3.1416 * pow(clamp(y, 0., 1.), .62)) + .0015;
      return step(0., y) * step(y, 1.) * smoothstep(px, -px, abs(q.x) - w); }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y; float px = 1.2 / R.y;
      float hz = 0.;
      vec3 hor = vec3(1., .84, .56);
      vec3 col = grad4(clamp((p.y - hz) / .5, 0., 1.), hor, vec3(.98, .66, .45), vec3(.6, .5, .62), vec3(.3, .33, .52));
      vec2 sp = vec2(-.35, hz + .17);
      float sd = length(p - sp);
      col += vec3(1., .75, .45) * exp(-sd * 2.6) * .4;
      col = mix(col, vec3(1., .96, .82), smoothstep(.05 + px * 3., .05 - px * 3., sd));
      float a = atan(p.y - sp.y, p.x - sp.x);
      col += vec3(1., .85, .6) * smoothstep(.5, .8, fbm(vec2(a * 6., 3.) + loop(.25))) * exp(-sd * 2.2) * .05;
      vec3 haze = vec3(.95, .8, .66);
      for (int i = 0; i < 5; i++) { float fi = float(i);
        float h = hill(p.x, fi);
        float m = below(p.y, h, px);
        vec3 lc = mix(vec3(.78, .64, .58), vec3(.24, .2, .09), fi / 4.);
        float stripe = smoothstep(.4, .6, fract((p.x * 2.2 + p.y * 6.) * (3. + fi)));
        lc *= 1. + .045 * (stripe - .5) * step(1.5, fi);
        lc += vec3(1., .7, .35) * exp(-(h - p.y) * 55.) * .22 * (1. - fi * .15);
        col = mix(col, lc, m);
        if (i == 1 || i == 3) {
          float cm = 0.;
          for (int j = 0; j < 9; j++) { float fj = float(j);
            float x = (i == 1 ? .15 : -.75) + fj * (i == 1 ? .045 : .07);
            cm = max(cm, cypress(p, vec2(x, hill(x, fi) - .004), (i == 1 ? .07 : .15) * (.8 + .4 * hs(fj + fi)), px)); }
          col = mix(col, mix(vec3(.4, .3, .28), vec3(.08, .07, .03), fi / 3.), cm);
        }
        if (i == 2) {
          float hx = .38; vec2 hq = p - vec2(hx, hill(hx, fi) - .006);
          float house = step(abs(hq.x), .035) * step(0., hq.y) * step(hq.y, .03);
          float roof = step(.03, hq.y) * step(hq.y, .045 - abs(hq.x) * .4) * step(abs(hq.x), .042);
          col = mix(col, vec3(.42, .3, .24), house);
          col = mix(col, vec3(.5, .24, .16), roof);
          col = mix(col, vec3(1., .78, .4), step(abs(hq.x - .012), .005) * step(abs(hq.y - .014), .006) * (.8 + .2 * sin(TAU * T * 2.)));
        }
        float fog = fbm(vec2(p.x * 1.6 - fi, p.y * 6.) + loop(.25 + fi * .04) + fi * 5.);
        col = mix(col, haze, smoothstep(.05, 0., abs(p.y - h + .03)) * smoothstep(.35, .75, fog) * (.45 - fi * .08));
      }
      gl_FragColor = vec4(grade(col, uv), 1.); }`,
  },
  {
    id: "autumn-lake", name: "Autumn Lake", kind: "shader", theme: "Paper", loop: 12,
    line: "A red and gold forest around a mirror lake, leaves drifting down.",
    frag: `
    vec3 scene(vec2 p, float px){
      float hz = -.05;
      vec3 col = grad4(clamp((p.y - hz) / (.5 - hz), 0., 1.), vec3(1., .86, .66), vec3(.95, .72, .6), vec3(.6, .6, .72), vec3(.32, .4, .58));
      vec2 sp = vec2(.3, hz + .1);
      col += vec3(1., .8, .55) * exp(-length(p - sp) * 3.) * .35;
      float cl = fbm(p * vec2(1.4, 3.5) + loop(.18) + 4.);
      col = mix(col, vec3(1., .9, .82), smoothstep(.55, .75, cl) * smoothstep(.0, .12, p.y) * smoothstep(.38, .18, p.y) * smoothstep(.65, .2, p.x) * .5);
      float mt = hz + .02 + .16 * pow(max(0., 1. - abs(p.x + .35) / .45), 1.3) + .1 * pow(max(0., 1. - abs(p.x - .1) / .35), 1.4) + .015 * f1(p.x * 10.);
      float mm = below(p.y, mt, px);
      col = mix(col, mix(vec3(.55, .58, .72), vec3(.95, .92, .95), smoothstep(mt - .045, mt - .012, p.y) * smoothstep(hz + .07, hz + .13, mt)), mm);
      for (int i = 0; i < 5; i++) { float fi = float(i) * .5;
        float base = hz - .005 - fi * .055 + .015 * (f1(p.x * 2. + fi * 4.) - .5);
        float n = 26. + fi * 8.;
        float c = floor((p.x + fi * .3) * n), f = fract((p.x + fi * .3) * n);
        float th = (.03 + fi * .015) * (.5 + .5 * hs(c + fi * 9.));
        float h = base + th * (.55 + .45 * sqrt(max(0., 1. - (2. * f - 1.) * (2. * f - 1.)))) + .006 * noise(vec2(p.x * 90., fi));
        float r = hs(c * 1.7 + fi);
        vec3 leaf = r < .33 ? vec3(.85, .3, .12) : r < .66 ? vec3(.95, .6, .15) : vec3(.62, .16, .12);
        if (hs(c + 40. + fi) < .12) leaf = vec3(.18, .3, .2);
        leaf *= mix(.95, .6, fi / 2.) * (.9 + .2 * noise(p * vec2(160., 120.)));
        leaf = mix(mix(vec3(.3, .12, .08), vec3(.6, .5, .55), .35 - fi * .15), leaf, smoothstep(h - .05, h - .005, p.y));
        leaf = mix(leaf, vec3(.85, .78, .78), .45 - fi * .2);
        col = mix(col, leaf, below(p.y, h, px)); }
      return col; }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y; float px = 1.2 / R.y;
      float lake = -.19;
      vec3 col;
      if (p.y > lake) col = scene(p, px);
      else {
        float dd = lake - p.y;
        float rip = .003 * sin(p.y * 200. / (dd + .3) + TAU * T * 3.) * smoothstep(0., .08, dd) + .002 * (noise(vec2(p.x * 8., p.y * 50.) + loop(.6)) - .5);
        col = scene(vec2(p.x + rip, 2. * lake - p.y), px) * vec3(.72, .78, .84);
        col += vec3(1., .92, .8) * smoothstep(.75, .95, noise(vec2(p.x * 4., p.y * 140.) + loop(.8))) * .05;
        col = mix(col, vec3(.06, .08, .1), smoothstep(.03, .3, dd) * .5);
      }
      col = mix(col, vec3(.08, .06, .05), smoothstep(.005, 0., abs(p.y - lake + .002)) * .7);
      // near shore with grass at the bottom
      vec2 b = blades(p, -.44, .05, 130., 2., px, 2.);
      col = mix(col, vec3(.16, .08, .05), b.x);
      col += vec3(1., .6, .25) * exp(-(b.y - p.y) * 70.) * b.x * .2;
      // falling leaves
      for (int i = 0; i < 9; i++) { float fi = float(i);
        float y = .55 - fract(T + hs(fi)) * 1.1;
        float x = -.8 + hs(fi + 3.) * 1.6 + .04 * sin(TAU * T * 2. + fi * 2.);
        vec2 q = rot(p - vec2(x, y), TAU * T * 2. + fi);
        q.x *= .6 + .4 * abs(sin(TAU * T * 3. + fi));
        float lf = smoothstep(.009 + px, .009 - px, length(q * vec2(1., 1.9)));
        col = mix(col, mix(vec3(.9, .35, .1), vec3(1., .65, .2), hs(fi + 8.)), lf * smoothstep(-.5, -.3, y) * .95); }
      gl_FragColor = vec4(grade(col, uv), 1.); }`,
  },
  {
    id: "cloud-sea", name: "Above the Clouds", kind: "shader", theme: "Midnight", loop: 12,
    line: "Snowy peaks rising out of a sea of clouds as the sun comes up.",
    frag: `
    float peaksSmooth(float x){
      return .26 * pow(max(0., 1. - abs(x + .48) / .4), 1.4) + .17 * pow(max(0., 1. - abs(x - .05) / .3), 1.5) + .1 * pow(max(0., 1. - abs(x - .5) / .28), 1.3); }
    float peaks(float x){
      return -.02 + .26 * pow(max(0., 1. - abs(x + .48) / .4), 1.4) + .17 * pow(max(0., 1. - abs(x - .05) / .3), 1.5)
           + .1 * pow(max(0., 1. - abs(x - .5) / .28), 1.3) + .03 * (f1(x * 7.) - .5) + .008 * f1(x * 40.); }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y; float px = 1.2 / R.y;
      float hz = 0.;
      vec3 col = grad4(clamp((p.y - hz) / .5, 0., 1.), vec3(1., .85, .62), vec3(.98, .68, .56), vec3(.44, .42, .62), vec3(.12, .16, .33));
      vec2 sp = vec2(-.22, hz + .05);
      float sd = length(p - sp);
      col += vec3(1., .7, .45) * exp(-sd * 3.) * .5;
      col = mix(col, vec3(1., .97, .86), smoothstep(.045 + px, .045 - px, sd));
      float h = peaks(p.x);
      float sx = p.x + .02 * (f1(p.y * 30.) - .5);
      float lit = smoothstep(-.004, .006, peaksSmooth(sx + .01) - peaksSmooth(sx - .01));
      vec3 rock = mix(vec3(.28, .27, .42), vec3(.85, .55, .5), lit * .8);
      float snow = smoothstep(.07, .12, p.y) * smoothstep(h - .06, h - .02, p.y);
      rock = mix(rock, mix(vec3(.62, .62, .8), vec3(1., .85, .78), lit), snow);
      col = mix(col, rock, below(p.y, h, px));
      for (int k = 0; k < 4; k++) { float fk = float(k);
        float base = -.02 - fk * .11;
        float n = 7. - fk * 1.3;
        float top = base + .03 * (fbm(vec2(p.x * 1.5 + fk * 3., fk * 2.) + loop(.12)) - .5) + puffs(p.x, n, fk * 13., .06) * .75 + .5 * puffs(p.x + .3, n * 1.9, fk * 7. + 3., .08) * .75;
        float m = below(p.y, top, px * 2.);
        float dd = top - p.y;
        vec3 body = mix(vec3(.94, .78, .76), vec3(.4, .4, .62), smoothstep(base + .05, base - .09, p.y));
        body = mix(body, vec3(.62, .55, .72), smoothstep(.01, .05, dd) * .25);
        vec3 rim = mix(vec3(1., .88, .74), vec3(1., .97, .9), exp(-abs(p.x - sp.x) * 2.));
        vec3 cc = mix(rim, body, smoothstep(0., .016, dd));
        cc = mix(cc, vec3(.4, .38, .62), fk / 3. * .4);
        cc += .04 * (fbm(p * 8. + loop(.3) + fk) - .5);
        col = mix(col, cc, m); }
      gl_FragColor = vec4(grade(col, uv), 1.); }`,
  },
];

window.WALLPAPERS.push(...SCENIC.map((w) => ({ collection: "Golden Hour", ...w, frag: window.WP_HEAD + SC + w.frag })));
