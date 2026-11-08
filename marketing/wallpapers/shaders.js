// Notchi wallpaper library. Every wallpaper is a fragment shader driven by
// T, the loop phase in [0, 1). Anything that moves does a whole number of
// cycles per loop (sin(TAU*T*n), fract(y + T*n), noise sampled around a
// circle), so the rendered video loops with no visible seam.
window.LOOP_SECONDS = 6;

const HEAD = `
precision highp float;
uniform vec2 R;
uniform float T;
#define TAU 6.28318530718
float h21(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p){ vec2 i = floor(p), f = fract(p); vec2 u = f * f * (3. - 2. * f);
  return mix(mix(h21(i), h21(i + vec2(1, 0)), u.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), u.x), u.y); }
float fbm(vec2 p){ float v = 0., a = .5; for (int i = 0; i < 5; i++) { v += a * noise(p); p = p * 2.03 + vec2(1.7, 9.2); a *= .5; } return v; }
vec2 loop(float r){ float a = T * TAU; return vec2(cos(a), sin(a)) * r; }
vec2 rot(vec2 p, float a){ float c = cos(a), s = sin(a); return vec2(c * p.x - s * p.y, s * p.x + c * p.y); }
`;

window.WALLPAPERS = [
  {
    id: "aurora", name: "Aurora", kind: "shader", theme: "Midnight",
    frag: `void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = uv; p.x *= R.x / R.y;
      vec3 col = mix(vec3(.02,.025,.07), vec3(.04,.07,.18), uv.y);
      float tw = .5 + .5 * sin(TAU * T * 2. + h21(floor(gl_FragCoord.xy / 3.)) * 40.);
      col += step(.9975, h21(floor(gl_FragCoord.xy / 3.))) * uv.y * tw;
      for (int i = 0; i < 3; i++) { float fi = float(i);
        float n = fbm(vec2(p.x * .7 + fi * 3.1, fi * 2.) + loop(.5 + fi * .15));
        float y = .42 + .3 * (n - .45) + .05 * sin(p.x * 1.6 + fi * 2. + TAU * T) + fi * .09;
        float rays = .35 + .9 * pow(fbm(vec2(p.x * 16. + fi * 4., fi) + loop(.9)), 2.);
        float d = uv.y - y;
        float band = smoothstep(-.015, .02, d) * exp(-max(d, 0.) * (5. - fi)) * rays;
        col += mix(vec3(.12,1.,.6), vec3(.68,.34,1.), fi / 2.) * band * (.85 - fi * .15); }
      gl_FragColor = vec4(col, 1.); }`,
  },
  {
    id: "ink-tide", name: "Ink Tide", kind: "shader", theme: "Paper",
    frag: `void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = uv; p.x *= R.x / R.y;
      vec3 paper = vec3(.92,.9,.83), ink = vec3(.09,.075,.055), acc = vec3(1.,.42,.24), gold = vec3(1.,.78,.29);
      vec3 col = mix(paper, mix(paper, gold, .35), uv.y);
      float sun = length((p - vec2(1.25, .7)) * vec2(1., 1.)) - .13;
      col = mix(col, acc, smoothstep(.004, 0., sun));
      col = mix(col, ink, smoothstep(.006, 0., abs(sun) - .004));
      for (int i = 0; i < 4; i++) { float fi = float(i);
        float y = .46 - fi * .1 + .035 * sin(p.x * (2. + fi) + TAU * T * (fi + 1.) + fi)
                  + .045 * (fbm(vec2(p.x * 1.4 + fi * 5., fi) + loop(.45)) - .5);
        vec3 layer = mix(paper * .82, ink, .25 + fi * .24);
        float m = smoothstep(.002, -.002, uv.y - y);
        col = mix(col, layer, m);
        col = mix(col, ink, smoothstep(.0045, 0., abs(uv.y - y)) * .9); }
      gl_FragColor = vec4(col, 1.); }`,
  },
  {
    id: "starfield", name: "Starfield", kind: "shader", theme: "Midnight",
    frag: `void main(){
      vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      vec3 col = vec3(.025,.025,.06) + vec3(.06,.04,.14) * (1. - length(p) * .9);
      col += vec3(.25,.12,.45) * .25 * fbm(p * 2.5 + loop(.4));
      for (int i = 0; i < 5; i++) { float fi = float(i);
        float d = fract(fi / 5. + T);
        float sc = mix(16., .8, d); float fade = smoothstep(0., .35, d) * smoothstep(1., .82, d);
        vec2 q = p * sc + fi * 17.3; vec2 id = floor(q); vec2 g = fract(q) - .5;
        float r = h21(id); vec2 o = vec2(h21(id + 1.3), h21(id + 7.1)) - .5;
        float dd = length(g - o * .7);
        float star = (pow(.018 / max(dd, .001), 1.6) * .4) * smoothstep(.42, .0, dd) * step(.55, r);
        col += star * fade * mix(vec3(.7,.78,1.), vec3(1.,.82,.95), r); }
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },
  {
    id: "neon-rain", name: "Neon Rain", kind: "particles", theme: "Neon Rain",
    frag: `void main(){
      vec2 uv = gl_FragCoord.xy / R;
      vec3 col = mix(vec3(.05,.03,.12), vec3(.1,.03,.16), uv.y);
      col += vec3(1.,.25,.85) * .22 * exp(-uv.y * 5.) + vec3(.25,.95,1.) * .08 * exp(-abs(uv.x - .5) * 6.) * exp(-uv.y * 3.);
      for (int L = 0; L < 2; L++) { float fl = float(L);
        float cols = 70. + fl * 60.; float x = uv.x * cols; float id = floor(x); float fx = fract(x) - .5;
        float sp = 1. + floor(h21(vec2(id, 3. + fl)) * 3.); float off = h21(vec2(id, 7. + fl));
        float y = fract(uv.y + T * sp + off);
        float streak = smoothstep(.55, 1., y) * smoothstep(1., .985, y);
        float w = smoothstep(.16 - fl * .06, 0., abs(fx));
        vec3 c = mix(vec3(1.,.25,.85), vec3(.25,.95,1.), step(.5, h21(vec2(id, 11.))));
        col += c * streak * w * (1.1 - fl * .45); }
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },
  {
    id: "petals", name: "Petals", kind: "particles", theme: "Sakura",
    frag: `void main(){
      vec2 uv = gl_FragCoord.xy / R.y;
      vec3 col = mix(vec3(.97,.76,.8), vec3(1.,.9,.88), gl_FragCoord.y / R.y);
      col += vec3(1.,.95,.85) * .25 * exp(-length(gl_FragCoord.xy / R - vec2(.8,.85)) * 3.);
      for (int i = 0; i < 3; i++) { float fi = float(i);
        float sc = 5. + fi * 3.5; float K = 2. + fi;
        vec2 q = uv * sc + vec2(0., T * K);
        vec2 id = floor(q); vec2 hid = vec2(id.x, mod(id.y, K));
        vec2 g = fract(q) - .5;
        g.x += .22 * sin(TAU * T + h21(hid) * 6.28);
        g += (vec2(h21(hid + 2.), h21(hid + 5.)) - .5) * .4;
        g = rot(g, TAU * T * (h21(hid + 9.) > .5 ? 1. : -1.) + h21(hid) * 6.);
        float d = length(g * vec2(1., 1.9));
        float on = step(.35, h21(hid + 4.));
        vec3 pc = mix(vec3(.95,.45,.6), vec3(1.,.72,.8), h21(hid + 3.));
        col = mix(col, pc, smoothstep(.13 - fi * .02, .1 - fi * .02, d) * on * (.75 + fi * .1)); }
      gl_FragColor = vec4(col, 1.); }`,
  },
  {
    id: "leaf-drift", name: "Leaf Drift", kind: "particles", theme: "Matcha",
    frag: `void main(){
      vec2 uv = gl_FragCoord.xy / R.y; vec2 s = gl_FragCoord.xy / R;
      vec3 col = mix(vec3(.31,.52,.25), vec3(.86,.9,.72), s.y);
      col = mix(col, vec3(.95,.86,.55), .25 * exp(-length(s - vec2(.2,.9)) * 2.5));
      for (int i = 0; i < 3; i++) { float fi = float(i);
        float sc = 3. + fi * 2.5;
        vec2 q = uv * sc + loop(.35 + fi * .2) + vec2(0., .25 * sin(TAU * T * 2. + fi));
        vec2 id = floor(q); vec2 hid = id + vec2(fi * 13.);
        vec2 g = fract(q) - .5 + (vec2(h21(hid + 1.), h21(hid + 4.)) - .5) * .5;
        float r = .08 + .14 * h21(hid + 7.);
        float b = smoothstep(r, r * .55, length(g)) * step(.4, h21(hid + 2.));
        vec3 bc = mix(vec3(.98,.92,.6), vec3(.6,.85,.45), h21(hid + 3.));
        col = mix(col, bc, b * (.25 + fi * .12)); }
      gl_FragColor = vec4(col, 1.); }`,
  },
  {
    id: "lava", name: "Lava Lamp", kind: "shader", theme: "Paper",
    frag: `void main(){
      vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      float f = 0.;
      for (int i = 0; i < 7; i++) { float fi = float(i);
        vec2 c = vec2(.65 * sin(TAU * T * (1. + mod(fi, 2.)) + fi * 1.7), .38 * sin(TAU * T * (1. + mod(fi, 3.)) + fi * 2.3));
        float r = .1 + .05 * h21(vec2(fi, 1.));
        f += r * r / dot(p - c, p - c); }
      vec3 bg = mix(vec3(.18,.04,.06), vec3(.42,.08,.1), gl_FragCoord.y / R.y);
      vec3 blob = mix(vec3(1.,.42,.2), vec3(1.,.78,.3), clamp(f - 1., 0., 1.));
      float m = smoothstep(.95, 1.05, f);
      vec3 col = mix(bg, blob, m);
      col += vec3(1.,.45,.2) * .12 * smoothstep(.4, .95, f) * (1. - m);
      gl_FragColor = vec4(col, 1.); }`,
  },
  {
    id: "synthwave", name: "Synthwave", kind: "shader", theme: "Neon Rain",
    frag: `void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      float hz = .38;
      vec3 col = mix(vec3(.98,.35,.55), vec3(.13,.05,.3), smoothstep(hz, 1., uv.y));
      vec2 sp = p - vec2(0., .1); float sun = length(sp) - .26;
      float stripes = step(.5, fract((sp.y + .3) * 14. - T * 2.)) + step(.05, sp.y);
      col = mix(col, mix(vec3(1.,.85,.3), vec3(1.,.3,.6), smoothstep(.25, -.25, sp.y)), smoothstep(.004, 0., sun) * min(stripes, 1.) * step(hz, uv.y));
      float ridge = hz + .06 * fbm(vec2(p.x * 2.2, 3.)) + .04 * fbm(vec2(p.x * 6., 1.));
      col = mix(col, vec3(.2,.05,.3), step(uv.y, ridge) * step(hz, uv.y));
      if (uv.y < hz) {
        float z = .25 / (hz - uv.y + .002);
        float gx = abs(fract(p.x * z * .9) - .5); float gz = abs(fract(z + T * 2.) - .5);
        float line = smoothstep(.05 * z * .12 + .015, 0., min(gx, gz) / z * 3.);
        col = mix(vec3(.08,.02,.16), vec3(.25,.04,.35), uv.y / hz);
        col += vec3(1.,.25,.85) * line * (1. - smoothstep(0., hz, hz - uv.y) * .3) * 1.2;
        col += vec3(1.,.3,.6) * .25 * exp(-(hz - uv.y) * 14.); }
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },
  {
    id: "ocean", name: "Ocean Dusk", kind: "shader", theme: "Paper",
    frag: `void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = uv; p.x *= R.x / R.y;
      vec3 col = mix(vec3(1.,.6,.4), vec3(.36,.42,.74), smoothstep(.45, 1., uv.y));
      float sun = length(p - vec2(.9, .52)) - .09;
      col = mix(col, vec3(1.,.9,.6), smoothstep(.006, 0., sun));
      col += vec3(1.,.75,.5) * .35 * exp(-length(p - vec2(.9, .52)) * 4.);
      for (int i = 0; i < 6; i++) { float fi = float(i);
        float y = .46 - fi * .075 + .012 * sin(p.x * (5. + fi * 2.) + TAU * T * (1. + fi)) + .008 * sin(p.x * 13. - TAU * T * 2.);
        vec3 wc = mix(vec3(.18,.32,.6), vec3(.03,.1,.25), fi / 5.);
        float m = smoothstep(.003, -.003, uv.y - y);
        col = mix(col, wc, m);
        col += vec3(1.,.8,.6) * .35 * smoothstep(.004, 0., abs(uv.y - y)) * exp(-abs(p.x - .9) * 2.5) * (1. - fi / 6.); }
      gl_FragColor = vec4(col, 1.); }`,
  },
  {
    id: "liquid", name: "Liquid Glass", kind: "shader", theme: "Any",
    frag: `void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = uv; p.x *= R.x / R.y;
      vec2 w = p + .25 * vec2(fbm(p * 1.5 + loop(.6)), fbm(p * 1.5 + 4. - loop(.6)));
      vec3 c1 = vec3(1.,.42,.24), c2 = vec3(.56,.49,1.), c3 = vec3(.36,.88,.78), c4 = vec3(1.,.78,.29);
      vec2 a = vec2(.4, .7) + loop(.12), b = vec2(1.4, .3) - loop(.15), c = vec2(1.2, .85) + loop(.1).yx, d = vec2(.5, .2) - loop(.13).yx;
      float wa = exp(-dot(w - a, w - a) * 3.), wb = exp(-dot(w - b, w - b) * 3.), wc = exp(-dot(w - c, w - c) * 3.), wd = exp(-dot(w - d, w - d) * 3.);
      vec3 col = (c1 * wa + c2 * wb + c3 * wc + c4 * wd) / (wa + wb + wc + wd + .001);
      col = mix(col, vec3(1.), .08 * fbm(p * 30.));
      gl_FragColor = vec4(col, 1.); }`,
  },
  {
    id: "fireflies", name: "Fireflies", kind: "particles", theme: "Matcha",
    frag: `void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = uv; p.x *= R.x / R.y;
      vec3 col = mix(vec3(.03,.09,.06), vec3(.08,.2,.18), uv.y);
      float trees = .3 + .18 * fbm(vec2(p.x * 2.5, 1.)) + .12 * fbm(vec2(p.x * 9., 2.));
      col = mix(col, vec3(.01,.025,.02), step(uv.y, trees));
      for (int i = 0; i < 40; i++) { float fi = float(i);
        vec2 base = vec2(h21(vec2(fi, 1.)) * R.x / R.y, .12 + h21(vec2(fi, 2.)) * .75);
        float n1 = 1. + floor(h21(vec2(fi, 3.)) * 2.);
        vec2 pos = base + vec2(.05 * sin(TAU * T * n1 + fi), .04 * sin(TAU * T * n1 * 2. + fi * 2.));
        float blink = pow(.5 + .5 * sin(TAU * T * (1. + mod(fi, 3.)) + fi * 1.3), 3.);
        float d = length(p - pos);
        float glow = .00018 / (d * d + .00018) + .35 * exp(-d * 18.);
        col += vec3(.95,1.,.55) * glow * (.15 + .85 * blink) * .8; }
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },
  {
    id: "dunes", name: "Dunes", kind: "shader", theme: "Paper",
    frag: `void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = uv; p.x *= R.x / R.y;
      vec3 col = mix(vec3(1.,.8,.55), vec3(.98,.55,.4), smoothstep(.4, 1., uv.y));
      float sun = length(p - vec2(.45, .66)) - .11;
      col = mix(col, vec3(1.,.95,.8), smoothstep(.006, 0., sun));
      vec2 sh = .004 * vec2(fbm(p * 8. + loop(2.)), 0.);
      for (int i = 0; i < 4; i++) { float fi = float(i);
        float y = .5 - fi * .11 + .07 * sin((p.x + sh.x) * (1.5 + fi * .6) + fi * 2.) + .03 * fbm(vec2(p.x * 2. + fi * 3., fi));
        vec3 sand = mix(vec3(.93,.6,.38), vec3(.55,.26,.18), fi / 3.);
        float m = smoothstep(.002, -.002, uv.y - y);
        float shade = .5 + .5 * sin((p.x + uv.y) * 4. + fi + TAU * T);
        col = mix(col, sand * (.86 + .14 * shade), m); }
      gl_FragColor = vec4(col, 1.); }`,
  },
  {
    id: "snowfall", name: "Snowfall", kind: "particles", theme: "Midnight",
    frag: `void main(){
      vec2 uv = gl_FragCoord.xy / R.y; vec2 s = gl_FragCoord.xy / R;
      vec3 col = mix(vec3(.05,.08,.18), vec3(.2,.27,.45), s.y);
      vec2 mp = gl_FragCoord.xy / R.y - vec2(R.x / R.y * .78, .78);
      col += vec3(.9,.93,1.) * smoothstep(.07, .065, length(mp)) + vec3(.4,.5,.8) * .25 * exp(-length(mp) * 6.);
      col = mix(col, vec3(.85,.9,1.), smoothstep(.17, .16, s.y + .02 * sin(s.x * 9.)));
      for (int i = 0; i < 4; i++) { float fi = float(i);
        float sc = 6. + fi * 5.; float K = 3. + fi * 2.;
        vec2 q = uv * sc + vec2(0., T * K);
        vec2 id = floor(q); vec2 hid = vec2(id.x, mod(id.y, K));
        vec2 g = fract(q) - .5 + (vec2(h21(hid + 1.), h21(hid + 6.)) - .5) * .6;
        g.x += .15 * sin(TAU * T + h21(hid) * 6.28);
        float r = .05 + .04 * h21(hid + 3.);
        col += vec3(1.) * smoothstep(r, r * .3, length(g)) * step(.3, h21(hid + 2.)) * (.45 + fi * .15); }
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },
  {
    id: "silk", name: "Silk", kind: "shader", theme: "Any",
    frag: `void main(){
      vec2 p = (gl_FragCoord.xy - .5 * R) / R.y * 3.;
      float a = TAU * T;
      float v = sin(p.x * 1.3 + a) + sin(p.y * 1.7 - a) + sin((p.x + p.y) * .9 + a * 2.) + sin(length(p + vec2(sin(a), cos(a))) * 2.5 - a);
      float k = .5 + .5 * sin(v * .8);
      vec3 c1 = vec3(1.,.48,.33), c2 = vec3(.62,.55,1.), c3 = vec3(.45,.9,.8);
      vec3 col = mix(mix(c1, c2, smoothstep(0., .55, k)), c3, smoothstep(.5, 1., k));
      col = mix(col, vec3(1.), .18 * pow(.5 + .5 * sin(v * 2.4 + a), 6.));
      gl_FragColor = vec4(col, 1.); }`,
  },
].map((w) => ({ ...w, frag: HEAD + w.frag }));
