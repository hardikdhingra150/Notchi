// Notchi's detailed wallpaper collections. Original art in the spirit of
// popular aesthetics (magic school, deep space, neon city, cozy nights);
// no characters, logos or names from anyone else's films or books.
// Same rule as shaders.js: everything moving completes whole cycles per loop.

const EXTRA = `
float h11(float n){ return fract(sin(n * 127.1) * 43758.5453); }
vec3 sky(float y, vec3 a, vec3 b, vec3 c){ return y < .5 ? mix(a, b, y * 2.) : mix(b, c, y * 2. - 1.); }
float stars(vec2 px, float dens, float tw){
  vec2 id = floor(px / 3.); float r = h21(id);
  float on = step(1. - dens, r);
  float blink = .55 + .45 * sin(TAU * T * (1. + floor(h21(id + 3.) * 3.)) + r * 40.);
  return on * mix(1., blink, tw) * (.4 + .6 * h21(id + 9.)); }
`;

const PREMIUM = [
  // ───────────────────────── Spellbound ─────────────────────────
  {
    id: "floating-candles", name: "Floating Candles", collection: "Spellbound", kind: "shader", theme: "Midnight",
    line: "Hundreds of candles drifting under an enchanted night ceiling.",
    frag: `
    vec3 candle(vec2 p, vec2 pos, float s, float seed, inout float glowSum){
      vec2 q = (p - pos) / s;
      vec3 c = vec3(0.); float a = 0.;
      // wax body with a slightly uneven, dripping top
      float top = .02 * sin(q.x * 90. + seed * 6.) * step(abs(q.x), .05);
      float body = step(abs(q.x), .05) * step(-.42, q.y) * step(q.y, -.02 + top);
      float shade = .78 + .22 * smoothstep(.05, -.05, q.x);
      vec3 wax = vec3(.96,.92,.82) * shade;
      // flame flickers at whole-number rates
      float fl = 1. + .12 * sin(TAU * T * (3. + mod(seed * 7., 3.)) + seed * 9.) + .06 * sin(TAU * T * 7. + seed);
      vec2 f = q - vec2(.004 * sin(TAU * T * 2. + seed * 5.), .07);
      f.y /= fl;
      float fd = length(vec2(f.x * 2.1, f.y < 0. ? f.y * 1.5 : f.y * .62));
      float flame = smoothstep(.05, .025, fd);
      float core = smoothstep(.028, .008, fd);
      float halo = exp(-length(q - vec2(0., .07)) * 7.) * .55 * fl;
      glowSum += halo * s;
      c = mix(c, wax, body);
      a = max(a, body);
      c = mix(c, vec3(1.,.62,.18), flame); a = max(a, flame);
      c = mix(c, vec3(1.,.97,.82), core);
      return c + vec3(1.,.72,.35) * halo * (1. - body); }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      // enchanted ceiling: deep night sky with drifting clouds and stars
      vec3 col = sky(uv.y, vec3(.03,.025,.06), vec3(.06,.05,.14), vec3(.1,.08,.22));
      float cl = fbm(p * 1.6 + loop(.35)) * fbm(p * 3.1 - loop(.25) + 4.);
      col += vec3(.3,.28,.5) * cl * .55 * smoothstep(.1, 1., uv.y);
      col += vec3(.95,.92,1.) * stars(gl_FragCoord.xy, .006, 1.) * smoothstep(.2, .9, uv.y);
      float glow = 0.;
      vec3 acc = vec3(0.);
      for (int layer = 0; layer < 3; layer++) {
        float fl = float(layer);
        float s = .55 + fl * .38;
        for (int i = 0; i < 18; i++) {
          float fi = float(i) + fl * 31.;
          vec2 pos = vec2((h11(fi) - .5) * 1.95, (h11(fi + 4.1) - .5) * 1.08);
          pos.y += .018 * sin(TAU * T + fi * 1.7) * s;
          pos.x += .006 * sin(TAU * T * 2. + fi) * s;
          vec2 q = (p - pos) / (s * .16);
          if (abs(q.x) < .8 && abs(q.y) < .8) acc += candle(p, pos, s * .16, fi, glow) * (.55 + fl * .25);
          else glow += exp(-length(q - vec2(0., .07)) * 7.) * .55 * s * .16;
        }
      }
      col = col * (1. - min(length(acc), 1.) * .9) + acc;
      col += vec3(1.,.66,.3) * glow * .42;
      col += vec3(.55,.32,.14) * .16 * pow(1. - uv.y, 2.);
      gl_FragColor = vec4(pow(min(col, 1.), vec3(.95)), 1.); }`,
  },
  {
    id: "moonlit-castle", name: "Moonlit Castle", collection: "Spellbound", kind: "shader", theme: "Midnight",
    line: "Towers on a cliff, lit windows and a full moon over the lake.",
    frag: `
    // returns the silhouette height at x; body = height of tower/wall bodies (no roofs)
    float castle(float x, out float body){
      float h = 0.; body = 0.;
      for (int i = 0; i < 9; i++) {
        float fi = float(i);
        float cx = -.56 + fi * .14 + (h11(fi + 2.) - .5) * .04;
        float w = .03 + h11(fi + 7.) * .025 + (fi == 4. ? .02 : 0.);
        float top = .22 + h11(fi + 11.) * .16 + (fi == 4. ? .2 : 0.) + (fi == 2. || fi == 6. ? .08 : 0.);
        float dx = abs(x - cx);
        float roofH = w * (1.6 + h11(fi + 5.) * .9);
        if (dx < w) { body = max(body, top); h = max(h, top); }
        if (dx < w * 1.18) h = max(h, top + (w * 1.18 - dx) / (w * 1.18) * roofH);
      }
      // curtain walls with battlements
      float crenel = step(.5, fract(x * 55.)) * .012;
      float wall = abs(x) < .62 ? .17 + crenel : 0.;
      body = max(body, abs(x) < .62 ? .17 : 0.);
      return max(h, wall); }
    vec3 scene(vec2 p, vec2 uv){
      vec3 col = sky(uv.y, vec3(.06,.05,.16), vec3(.12,.12,.32), vec3(.03,.04,.12));
      col += vec3(.95,.95,1.) * stars(gl_FragCoord.xy, .005, 1.) * smoothstep(.45, 1., uv.y);
      vec2 mp = p - vec2(.55, .26);
      float md = length(mp);
      float crater = fbm(mp * 22.) * .35 + fbm(mp * 7.) * .25;
      vec3 moon = vec3(1.,.97,.88) * (.82 + .3 * crater);
      col += vec3(.6,.65,1.) * .35 * exp(-md * 3.5) + vec3(.8,.85,1.) * .25 * exp(-md * 12.);
      col = mix(col, moon, smoothstep(.13, .125, md));
      // clouds sliding across the moon
      float cl = smoothstep(.45, .8, fbm(vec2(p.x * 1.8, p.y * 3.) + loop(.5) + vec2(3.)));
      col = mix(col, vec3(.16,.16,.3) + vec3(.5,.5,.6) * exp(-md * 4.) * .6, cl * .75 * smoothstep(-.05, .3, p.y));
      // cliff + castle silhouette
      float bodyTop; float ch = castle(p.x, bodyTop) - .34; bodyTop -= .34;
      float cliff = -.18 + .1 * fbm(vec2(p.x * 3., 2.)) - .12 * smoothstep(.3, 1.2, abs(p.x + .1));
      float top = max(cliff, (abs(p.x) < .7 ? ch : -1.));
      if (p.y < top) {
        col = vec3(.025,.025,.06);
        col += vec3(.25,.25,.5) * .15 * smoothstep(top - .2, top, p.y);
        // lit windows in the towers and keep
        vec2 wg = vec2(p.x * 95., p.y * 60.);
        vec2 wid = floor(wg); vec2 wf = fract(wg);
        float lit = step(.88, h21(wid)) * step(wf.x, .42) * step(wf.y, .55) * step(cliff + .02, p.y) * step(p.y, bodyTop - .015);
        float flick = .75 + .25 * sin(TAU * T * (1. + mod(wid.x, 3.)) + h21(wid) * 20.);
        col += vec3(1.,.72,.32) * lit * flick;
      }
      return col; }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      float water = -.3;
      vec3 col;
      if (p.y > water) col = scene(p, uv);
      else {
        // lake: mirrored scene with ripples
        vec2 rp = vec2(p.x + .006 * sin(p.y * 80. + TAU * T * 2.) + .004 * sin(p.x * 30. - TAU * T), 2. * water - p.y);
        col = scene(rp, vec2(uv.x, (rp.y + .5)));
        col *= vec3(.55,.6,.8);
        col += vec3(.7,.75,1.) * .08 * smoothstep(.002, 0., abs(sin(p.y * 180. + TAU * T * 3.) * .01)) * exp(-abs(p.x - .55) * 6.);
      }
      col *= 1. - .35 * length(uv - .5);
      gl_FragColor = vec4(col, 1.); }`,
  },
  {
    id: "spell-trails", name: "Spell Trails", collection: "Spellbound", kind: "particles", theme: "Midnight",
    line: "Ribbons of light spiralling through the dark like a duel of spells.",
    frag: `
    vec2 path(float t, float k){
      float a = TAU * t;
      return vec2(.75 * sin(a * (1. + k) + k * 2.), .36 * sin(a * (2. + k) + k)) + vec2(.06 * sin(a * 5. + k), .05 * cos(a * 4. + k)); }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      vec3 col = vec3(.02,.015,.04) + vec3(.08,.04,.14) * (1. - length(p) * .8);
      col += vec3(.18,.08,.32) * .35 * fbm(p * 2. + loop(.4)) * (1. - length(p) * .6);
      vec3 cs[3]; cs[0] = vec3(1.,.78,.32); cs[1] = vec3(.65,.4,1.); cs[2] = vec3(.3,.95,.85);
      for (int k = 0; k < 3; k++) {
        float fk = float(k);
        vec2 prev = path(T, fk);
        for (int i = 1; i < 110; i++) {
          float fi = float(i);
          vec2 q = path(T - fi * .002, fk);
          vec2 ab = q - prev; vec2 ap = p - prev;
          float h = clamp(dot(ap, ab) / dot(ab, ab), 0., 1.);
          float d = length(ap - ab * h);
          float fade = pow(1. - fi / 110., 1.4);
          float w = .0012 + .0055 * fade;
          col += cs[k] * smoothstep(w * 2.5, 0., d) * fade * .38 + cs[k] * exp(-d * 60.) * fade * .035;
          prev = q;
        }
        vec2 head = path(T, fk);
        col += cs[k] * .03 / (length(p - head) + .02);
      }
      // floating sparks
      for (int i = 0; i < 30; i++) {
        float fi = float(i);
        vec2 sp = vec2((h11(fi) - .5) * 1.9, (h11(fi + 3.) - .5) * 1.);
        sp += vec2(.03 * sin(TAU * T + fi), .05 * sin(TAU * T * 2. + fi * 2.));
        float tw = pow(.5 + .5 * sin(TAU * T * (1. + mod(fi, 3.)) + fi), 4.);
        float sd = length(p - sp);
        col += vec3(1.,.85,.6) * (smoothstep(.006, 0., sd) + exp(-sd * 90.) * .4) * tw;
      }
      col = 1. - exp(-col * 1.3);
      gl_FragColor = vec4(col, 1.); }`,
  },

  // ───────────────────────── Deep Space ─────────────────────────
  {
    id: "black-hole", name: "Black Hole", collection: "Deep Space", kind: "shader", theme: "Midnight",
    line: "A glowing disc of fire bending around a black hole.",
    frag: `
    vec3 starsAt(vec2 q){
      vec2 g = q * 160.; vec2 id = floor(g); vec2 f = fract(g) - .5;
      float r = h21(id); vec2 o = vec2(h21(id + 1.), h21(id + 2.)) - .5;
      float s = step(.985, r) * smoothstep(.12, 0., length(f - o * .6));
      return vec3(.85,.88,1.) * s * (.5 + .5 * h21(id + 5.)); }
    void main(){
      vec2 p = (gl_FragCoord.xy - .5 * R) / R.y * .78;
      float rs = .13;
      float d2 = dot(p, p);
      // background, bent by gravity near the shadow
      vec2 pl = p * (1. + rs * rs * 2.2 / max(d2, .0005));
      vec3 col = starsAt(pl) + vec3(.03,.02,.06) + vec3(.12,.06,.2) * .35 * fbm(pl * 2.5 + 3.);
      // accretion disc, seen from slightly above
      float k = .2;
      vec2 dp = vec2(p.x, p.y / k);
      float r = length(dp), a = atan(dp.y, dp.x);
      float spin = a + TAU * T + log(r + .001) * 2.6;
      float tex = fbm(vec2(r * 5., 0.) + vec2(cos(spin), sin(spin)) * 1.8);
      float tex2 = fbm(vec2(r * 14., 3.) + vec2(cos(spin * 2.), sin(spin * 2.)) * 1.2);
      float streak = .6 + .7 * tex2;
      float band = smoothstep(.17, .2, r) * smoothstep(.62, .3, r);
      float doppler = 1. + .75 * cos(a);
      vec3 hot = mix(vec3(1.,.55,.2), vec3(1.,.95,.82), smoothstep(.5, .2, r));
      vec3 disk = hot * band * pow(.25 + 1.2 * tex * streak, 1.6) * doppler * 1.5;
      // the far side of the disc, lensed into an arc over and under the shadow
      float pr = sqrt(d2);
      float pa = atan(p.y, p.x);
      float sp2 = pa + TAU * T + pr * 9.;
      float arc = smoothstep(rs * 1.0, rs * 1.12, pr) * smoothstep(rs * 2.4, rs * 1.3, pr);
      float arcTex = .5 + .9 * fbm(vec2(pr * 30., 0.) + vec2(cos(sp2), sin(sp2)) * 2.);
      float upper = mix(.45, 1., smoothstep(-.02, .06, p.y));
      vec3 lensed = mix(vec3(1.,.6,.25), vec3(1.,.95,.85), smoothstep(rs * 1.9, rs * 1.1, pr)) * arc * arcTex * upper * (1. + .5 * cos(pa)) * 1.3;
      float shadow = smoothstep(rs * 1.0, rs * .96, pr);
      float ring = exp(-abs(pr - rs * 1.03) * 220.);
      col += lensed;
      float fr = smoothstep(.004, -.004, p.y);
      vec3 frontCol = col * (1. - band * .9) + disk;
      vec3 backCol = col + disk * (1. - smoothstep(rs * 1.08, rs * .98, pr));
      col = mix(backCol, frontCol, fr);
      col = mix(col, vec3(0.), shadow * mix(1., 1. - band, fr));
      col += vec3(1.,.85,.6) * ring * 1.4;
      col += vec3(1.,.55,.25) * .16 * exp(-pr * 4.5) * (1. - shadow);
      col = 1. - exp(-col * 1.25);
      gl_FragColor = vec4(pow(col, vec3(.95)), 1.); }`,
  },
  {
    id: "nebula", name: "Nebula", collection: "Deep Space", kind: "shader", theme: "Neon Rain",
    line: "Clouds of pink and teal gas lit by newborn stars.",
    frag: `
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      vec2 q = p * 1.6;
      vec2 w = vec2(fbm(q + loop(.25)), fbm(q + 5.2 - loop(.25)));
      vec2 w2 = vec2(fbm(q + 2. * w + 1.7), fbm(q + 2. * w + 9.2));
      float n = fbm(q + 2.4 * w2);
      vec3 col = vec3(.01,.01,.03);
      col = mix(col, vec3(.62,.1,.52), smoothstep(.2, .62, n));
      col = mix(col, vec3(.12,.62,.78), smoothstep(.35, .75, w2.x) * .75);
      col = mix(col, vec3(1.,.66,.45), smoothstep(.55, .85, n) * .7);
      col *= .3 + 1.6 * smoothstep(.1, .75, n);
      float dust = smoothstep(.5, .75, fbm(q * 2.4 - w * 1.5 + 11.));
      col *= 1. - dust * .55;
      // stars, a few big ones with diffraction spikes
      vec2 g = gl_FragCoord.xy / 4.; vec2 id = floor(g);
      col += vec3(.9,.92,1.) * step(.992, h21(id)) * (.45 + .55 * h21(id + 2.));
      for (int i = 0; i < 9; i++) {
        float fi = float(i);
        vec2 sp = vec2((h11(fi * 3.1) - .5) * 1.7, (h11(fi * 7.3) - .5) * .95);
        vec2 d = p - sp;
        float tw = .8 + .2 * sin(TAU * T * (1. + mod(fi, 2.)) + fi);
        float core = exp(-length(d) * 160.) * 1.6 + exp(-length(d) * 30.) * .35;
        float spike = (exp(-abs(d.x) * 900.) * exp(-abs(d.y) * 30.) + exp(-abs(d.y) * 900.) * exp(-abs(d.x) * 30.)) * .6;
        col += mix(vec3(.75,.85,1.), vec3(1.,.8,.95), h11(fi)) * (core + spike) * tw;
      }
      col = 1. - exp(-col * 1.4);
      col *= 1. - .3 * length(uv - .5);
      gl_FragColor = vec4(col, 1.); }`,
  },
  {
    id: "ringed-planet", name: "Ringed Planet", collection: "Deep Space", kind: "shader", theme: "Paper",
    line: "A giant ringed world rising over the edge of space.",
    frag: `
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      vec3 col = vec3(.01,.012,.03) + vec3(.05,.04,.1) * (1. - uv.y);
      vec2 g = gl_FragCoord.xy / 3.; vec2 id = floor(g);
      col += vec3(1.) * step(.9965, h21(id)) * (.4 + .6 * h21(id + 1.)) * (.7 + .3 * sin(TAU * T + h21(id) * 30.));
      vec2 c = vec2(.15, -.2); float PR = .3;
      vec2 d = p - c; float dl = length(d);
      // rings: an ellipse around the planet, tilted
      float tilt = .28;
      vec2 rd = rot(d, -.32);
      vec2 rr = vec2(rd.x, rd.y / tilt);
      float ringR = length(rr) / PR;
      float ringBand = smoothstep(1.22, 1.26, ringR) * smoothstep(2.05, 1.98, ringR);
      float gaps = .55 + .45 * sin(ringR * 70.) * sin(ringR * 23. + 1.);
      gaps *= smoothstep(1.58, 1.62, ringR) + smoothstep(1.66, 1.62, ringR);
      vec3 ringCol = mix(vec3(.95,.82,.62), vec3(.7,.55,.45), smoothstep(1.3, 2., ringR)) * ringBand * gaps * (.75 + .25 * sin(TAU * T + ringR * 9.));
      bool ringFront = rd.y < 0.;
      vec3 ringLit = mix(vec3(1.,.88,.7), vec3(.78,.62,.5), smoothstep(1.3, 2., ringR)) * (.8 + .2 * sin(TAU * T + ringR * 9.));
      // planet body with bands, lit from the upper left
      if (dl < PR) {
        vec3 n = vec3(d / PR, sqrt(1. - dot(d, d) / (PR * PR)));
        float lat = asin(clamp(n.y, -1., 1.));
        float bands = fbm(vec2(lat * 9., n.x * 1.5) + loop(.18)) * .6 + .5 * sin(lat * 26. + fbm(vec2(n.x * 3., lat * 4.)) * 3.);
        vec3 surf = mix(vec3(.82,.55,.35), vec3(.98,.86,.64), .5 + .5 * bands);
        surf = mix(surf, vec3(.6,.36,.25), smoothstep(.6, .9, fbm(vec2(lat * 30., n.x * 4.) - loop(.2))) * .4);
        float light = clamp(dot(n, normalize(vec3(-.55,.6,.6))), 0., 1.);
        col = surf * (.06 + light * 1.05);
        col += vec3(.45,.65,1.) * pow(1. - n.z, 3.) * .5 * (.3 + light);
        // ring shadow on the planet
        col *= 1. - ringBand * .5 * step(0., rd.y) * .0;
        if (!ringFront) col = col; 
      } else {
        col += vec3(.35,.55,1.) * .5 * exp(-(dl - PR) * 18.);
        col += ringLit * ringBand * (.35 + .65 * gaps);
      }
      if (ringFront && dl < PR) col = mix(col, ringLit, min(ringBand * (.35 + .65 * gaps), .92));
      // the ring's shadow falls across the planet just above it
      if (dl < PR) { vec2 sd = rot(d + vec2(.0, .03), -.32); float sR = length(vec2(sd.x, sd.y / tilt)) / PR;
        col *= 1. - .45 * smoothstep(1.22, 1.3, sR) * smoothstep(2.05, 1.95, sR) * step(0., sd.y); }
      // a small moon
      vec2 m = p - vec2(-.62, .28); float md = length(m);
      vec3 mn = vec3(m / .055, sqrt(max(0., 1. - dot(m, m) / (.055 * .055))));
      if (md < .055) col = vec3(.75,.75,.8) * (.08 + clamp(dot(mn, normalize(vec3(.5,.3,.8))), 0., 1.)) * (.8 + .3 * fbm(m * 60.));
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },

  // ───────────────────────── Neon City ─────────────────────────
  {
    id: "cyber-city", name: "Cyberpunk Skyline", collection: "Neon City", kind: "shader", theme: "Neon Rain",
    line: "Rain, neon signs and flying cars over a city that never sleeps.",
    frag: `
    vec3 city(vec2 p, vec2 uv, float hz){
      vec3 col = sky(clamp((p.y - hz) * 1.6, 0., 1.), vec3(.55,.08,.35), vec3(.16,.04,.24), vec3(.03,.02,.08));
      col += vec3(1.,.25,.6) * .35 * exp(-max(p.y - hz, 0.) * 5.);
      for (int L = 0; L < 3; L++) {
        float fl = float(L);
        float bw = .055 + fl * .035;
        float xs = p.x + fl * 1.37 + 10.;
        float id = floor(xs / bw); float fx = fract(xs / bw);
        float bh = hz + .06 + h11(id + fl * 50.) * (.42 + fl * .06) + (h11(id * 3.1 + fl) > .85 ? .18 : 0.);
        float gap = step(.06, fx) * step(fx, .94);
        if (p.y < bh && gap > 0.) {
          vec3 b = mix(vec3(.16,.08,.28), vec3(.02,.015,.05), fl / 2.);
          vec2 wg = vec2(fx * (5. + fl * 2.), (p.y - hz) * (55. - fl * 12.));
          vec2 wid = floor(wg); vec2 wf = fract(wg);
          float lit = step(.58, h21(wid + id * 7.)) * step(.25, wf.x) * step(wf.x, .8) * step(.3, wf.y) * step(wf.y, .78);
          float fl2 = .7 + .3 * step(.5, fract(T * (2. + mod(id, 3.)) + h21(wid)));
          vec3 wc = mix(vec3(.3,.9,1.), vec3(1.,.55,.85), step(.5, h21(wid + 3.))) * mix(1., .6, fl / 2.);
          b += wc * lit * fl2 * (.55 + fl * .2);
          // a neon sign near the top of some buildings
          float hasSign = step(.55, h11(id * 5.7 + fl));
          float sy = bh - .07 - h11(id + 9.) * .1;
          float sign = hasSign * step(abs(fx - .5), .16) * step(abs(p.y - sy), .035 + fl * .01);
          float buzz = .75 + .25 * step(.12, fract(T * (4. + mod(id, 4.)) + h11(id)));
          vec3 sc = h11(id + 2.) > .5 ? vec3(1.,.2,.65) : vec3(.2,.95,1.);
          b = mix(b, sc * 1.4 * buzz, sign);
          col = mix(col, b, 1.);
          col = mix(col, vec3(.45,.12,.4), (1. - fl / 2.) * .35 * (1. - smoothstep(hz, hz + .5, p.y)));
        }
        // glow spilling from signs
      }
      // flying cars crossing at a few heights
      for (int i = 0; i < 8; i++) {
        float fi = float(i);
        float dir = h11(fi) > .5 ? 1. : -1.;
        float x = (fract(h11(fi + 3.) + T * (1. + floor(h11(fi + 6.) * 2.)) * dir) - .5) * 2.4;
        vec2 c = vec2(x, hz + .25 + h11(fi + 9.) * .4);
        vec2 d = p - c;
        float trail = exp(-abs(d.y) * 900.) * smoothstep(0., .12, -d.x * dir) * smoothstep(.25, .0, -d.x * dir);
        col += (dir > 0. ? vec3(1.,.4,.3) : vec3(1.,.95,.85)) * (exp(-length(d) * 140.) * 1.6 + trail * .5);
      }
      return col; }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      float hz = -.3;
      vec3 col;
      if (p.y > hz) col = city(p, uv, hz);
      else {
        float rip = .004 * sin(p.y * 260. + TAU * T * 3.) + .003 * sin(p.x * 40. + TAU * T * 2.);
        vec2 rq = vec2(p.x + rip, 2. * hz - p.y);
        col = (city(rq, uv, hz) + city(rq + vec2(.004, .006), uv, hz) + city(rq - vec2(.004, .01), uv, hz)) / 3. * .42 * vec3(.85,.8,1.);
        col *= smoothstep(-.75, hz, p.y) * .6 + .4;
        col += vec3(.05,.03,.08);
      }
      // rain
      float cols = 160.; float x = uv.x * cols; float cid = floor(x); float fx = fract(x) - .5;
      float sp = 2. + floor(h11(cid) * 3.); float y = fract(uv.y * 1.5 + T * sp + h11(cid + 4.));
      col += vec3(.7,.75,1.) * smoothstep(.85, 1., y) * smoothstep(.2, 0., abs(fx)) * .35;
      col *= 1. - .3 * length(uv - .5);
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },
  {
    id: "code-rain", name: "Code Rain", collection: "Neon City", kind: "particles", theme: "Matcha",
    line: "Columns of glowing glyphs pouring down the screen.",
    frag: `
    void main(){
      vec2 uv = gl_FragCoord.xy / R;
      vec2 cell = vec2(20., 26.);
      vec2 g = gl_FragCoord.xy / cell; vec2 id = floor(g); vec2 f = fract(g);
      float rows = R.y / cell.y + 2.;
      float k = 1. + floor(h11(id.x) * 3.);
      float head = fract(h11(id.x + 7.) - T * k) * rows * 1.4;
      float row = rows - id.y;
      float dist = head - row;
      float len = 10. + h11(id.x + 2.) * 22.;
      float trail = dist > 0. && dist < len ? 1. - dist / len : 0.;
      float change = floor(T * (24. + 24. * step(.5, h11(id.x + 5.))));
      float seed = h21(id + change * .37 * step(.7, h21(id + 1.)));
      vec2 gp = floor(vec2((f.x - .12) / .76 * 5., (f.y - .1) / .8 * 7.));
      float inGlyph = step(0., gp.x) * step(gp.x, 4.) * step(0., gp.y) * step(gp.y, 6.);
      float bit = step(.48, h21(vec2(min(gp.x, 4. - gp.x), gp.y) + seed * 31.)) * inGlyph;
      vec3 col = vec3(.0,.025,.01);
      col += vec3(.15,1.,.4) * bit * pow(trail, 1.5) * 1.1;
      float isHead = step(abs(dist), .6);
      col += vec3(.75,1.,.8) * bit * isHead * 1.2;
      col += vec3(.1,.6,.25) * .06 * pow(trail, 3.);
      col *= .85 + .15 * sin(gl_FragCoord.y * 3.14159);
      col *= 1. - .45 * length(uv - .5);
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },
  // ───────────────────────── Cozy Nights ─────────────────────────
  {
    id: "rainy-window", name: "Rainy Window", collection: "Cozy Nights", kind: "particles", theme: "Midnight",
    line: "Raindrops sliding down the glass, city lights blurred behind.",
    frag: `
    vec3 bokeh(vec2 p, float sharp){
      vec3 col = sky(clamp(p.y + .5, 0., 1.), vec3(.12,.06,.05), vec3(.07,.07,.12), vec3(.03,.04,.08));
      for (int i = 0; i < 46; i++) {
        float fi = float(i);
        vec2 c = vec2((h11(fi) - .5) * 2.1, (h11(fi + 2.) - .6) * 1.05);
        float r = .035 + h11(fi + 4.) * .07;
        vec3 lc = h11(fi + 6.) > .7 ? vec3(.3,.8,.9) : h11(fi + 6.) > .35 ? vec3(1.,.55,.2) : vec3(1.,.25,.2);
        if (h11(fi + 8.) > .85) lc = vec3(1.,.95,.85);
        float tw = .8 + .2 * sin(TAU * T * (1. + mod(fi, 2.)) + fi);
        float d = length(p - c);
        float soft = mix(.85, .25, sharp);
        col += lc * smoothstep(r, r * (1. - soft), d) * .95 * tw;
      }
      return col; }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      vec2 n = vec2(0.); float wet = 0.;
      // small drops stuck to the glass
      vec2 g = p * 26.; vec2 id = floor(g); vec2 f = fract(g) - .5;
      vec2 o = (vec2(h21(id), h21(id + 3.)) - .5) * .6;
      float rr = .12 + .18 * h21(id + 5.);
      vec2 dd = f - o; float dl = length(dd);
      float drop = smoothstep(rr, rr * .7, dl) * step(.45, h21(id + 7.));
      n += dd / rr * drop; wet = max(wet, drop);
      // big drops sliding down, leaving a trail
      float cols = 14.;
      float cx = (p.x + 1.) * cols; float cid = floor(cx); float fx = fract(cx) - .5;
      float k = 1. + floor(h11(cid) * 2.);
      float yy = fract(h11(cid + 3.) - T * k);
      float dy = (p.y + .5) - yy;
      float wob = .12 * sin(dy * 30. + h11(cid) * 6.);
      vec2 bd = vec2((fx - wob * .3) * 1.8, dy * 9.);
      float big = smoothstep(.32, .22, length(vec2(bd.x, bd.y < 0. ? bd.y * .7 : bd.y * 1.3)));
      float trail = smoothstep(.12, .02, abs(fx - wob * .3)) * smoothstep(0., .02, dy) * smoothstep(.35, .05, dy);
      n += vec2(bd.x, bd.y) * big * .9; wet = max(wet, max(big, trail * .6));
      vec3 blurred = bokeh(p, 0.);
      vec3 sharp = bokeh(p - n * .09, 1.) * 1.15;
      vec3 col = mix(blurred * .8 + vec3(.06,.065,.08), sharp, wet);
      // a bright rim and highlight on each drop
      col += vec3(1.) * .35 * smoothstep(.55, .95, length(n)) * wet;
      col += vec3(1.) * .5 * smoothstep(.75, .95, dot(normalize(n + vec2(.0001)), normalize(vec2(-.5, .7)))) * smoothstep(.2, .8, length(n)) * wet;
      col *= 1. - .35 * length(uv - .5);
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },
  {
    id: "sky-lanterns", name: "Sky Lanterns", collection: "Cozy Nights", kind: "particles", theme: "Paper", loop: 12,
    line: "Paper lanterns rising slowly from a lake at dusk.",
    frag: `
    vec3 lanterns(vec2 p, float hz, float refl){
      vec3 acc = vec3(0.);
      for (int L = 0; L < 3; L++) {
        float fl = float(L); float s = .45 + fl * .45;
        for (int i = 0; i < 18; i++) {
          float fi = float(i) + fl * 40.;
          float ph = fract(h11(fi) + T);
          vec2 c = vec2((h11(fi + 2.) - .5) * 2.0, hz + .02 + ph * (.9 - fl * .1));
          c.x += .03 * sin(TAU * T * 2. + fi) * s;
          float fade = smoothstep(0., .12, ph) * smoothstep(1., .75, ph);
          vec2 d = (p - c) / (s * .028);
          float body = smoothstep(1.05, .95, max(abs(d.x) * 1.15, abs(d.y + .1) * .85 + abs(d.x) * .2));
          float flame = exp(-length(d - vec2(0., -.7)) * 3.);
          vec3 lc = mix(vec3(1.,.42,.15), vec3(1.,.82,.45), smoothstep(.8, -.8, d.y));
          float glow = exp(-length(d) * .9) * .25;
          acc += (lc * body * (.8 + .4 * flame) + vec3(1.,.6,.25) * glow) * fade * mix(.55, 1., fl / 2.) * refl;
        }
      }
      return acc; }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      float hz = -.18;
      vec3 col;
      if (p.y > hz) {
        float y = (p.y - hz) / .7;
        col = sky(clamp(y, 0., 1.), vec3(1.,.55,.3), vec3(.42,.2,.38), vec3(.07,.06,.18));
        col += vec3(.95,.95,1.) * stars(gl_FragCoord.xy, .004, 1.) * smoothstep(.4, 1., y);
        float hills = hz + .05 + .05 * fbm(vec2(p.x * 2.5, 1.)) + .02 * fbm(vec2(p.x * 9., 3.));
        col = mix(col, vec3(.08,.05,.12), step(p.y, hills));
        col += lanterns(p, hz, 1.);
      } else {
        vec2 rp = vec2(p.x + .0028 * sin(p.y * 90. + TAU * T * 4.), 2. * hz - p.y);
        float y = (rp.y - hz) / .7;
        col = sky(clamp(y, 0., 1.), vec3(1.,.55,.3), vec3(.42,.2,.38), vec3(.07,.06,.18)) * .45;
        col += lanterns(rp, hz, .55);
        col = mix(col, vec3(.04,.03,.08), .35);
      }
      col *= 1. - .3 * length(uv - .5);
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },
  {
    id: "koi-pond", name: "Koi Pond", collection: "Cozy Nights", kind: "particles", theme: "Matcha",
    line: "Koi circling under lily pads, light dancing on the water.",
    frag: `
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      vec3 col = mix(vec3(.04,.22,.22), vec3(.1,.36,.32), uv.y);
      float cau = pow(1. - abs(fbm(p * 5. + loop(.35)) * 2. - 1.), 9.) + .6 * pow(1. - abs(fbm(p * 9. - loop(.25) + 4.) * 2. - 1.), 12.);
      col += vec3(.45,.8,.7) * cau * .2;
      // koi
      for (int i = 0; i < 6; i++) {
        float fi = float(i);
        vec2 cen = vec2(-.62 + mod(fi, 3.) * .62, fi < 3. ? .16 : -.2);
        float rad = .14 + h11(fi + 4.) * .06;
        float dir = h11(fi + 6.) > .5 ? 1. : -1.;
        float th = TAU * T * dir + fi * 1.9;
        vec2 pos = cen + vec2(cos(th), sin(th) * .62) * rad;
        vec2 tang = normalize(vec2(-sin(th), cos(th) * .62) * dir);
        vec2 d = p - pos;
        vec2 q = vec2(dot(d, tang), dot(d, vec2(-tang.y, tang.x)));
        float L = .1;
        float x = q.x / L;
        q.y -= .012 * sin(TAU * T * 6. - x * 6. + fi) * smoothstep(.5, -1., x);
        float w = .038 * pow(max(0., 1. - pow(x * 1.05 + .15, 2.)), .55) * smoothstep(-1.05, -.55, x);
        float body = smoothstep(w, w * .6, abs(q.y)) * step(-1.05, x) * step(x, 1.);
        float tail = smoothstep(.006, .0, abs(q.y) - (-x - .85) * .09) * step(x, -.85) * step(-1.3, x);
        float fish = max(body, tail);
        // shadow on the pond floor
        vec2 sq = q + vec2(.015, -.02);
        float sw = .03 * pow(max(0., 1. - pow(sq.x / L, 2.)), .7);
        col *= 1. - .35 * smoothstep(sw, sw * .2, abs(sq.y)) * step(abs(sq.x / L), 1.);
        float spots = smoothstep(.45, .6, noise(q * 60. + fi * 7.));
        vec3 skin = h11(fi + 8.) > .5 ? mix(vec3(1.,.42,.1), vec3(1.,.97,.92), spots) : mix(vec3(1.,.97,.92), vec3(1.,.35,.08), spots);
        if (h11(fi + 10.) > .8) skin = mix(skin, vec3(.08), smoothstep(.55, .7, noise(q * 45. + 3.)));
        col = mix(col, skin * (.85 + .25 * smoothstep(0., w, -q.y)), fish * .96);
      }
      // ripples
      for (int i = 0; i < 4; i++) {
        float fi = float(i);
        vec2 c = vec2((h11(fi + 20.) - .5) * 1.6, (h11(fi + 22.) - .5) * .8);
        float ph = fract(T * 2. + h11(fi + 24.));
        float rr = ph * .35;
        col += vec3(.8,1.,.95) * exp(-abs(length(p - c) - rr) * 140.) * (1. - ph) * .25;
      }
      // lily pads floating on top
      for (int i = 0; i < 6; i++) {
        float fi = float(i);
        vec2 c = vec2((h11(fi + 30.) - .5) * 1.7, (h11(fi + 33.) - .5) * .9) + loop(.006) * (fi + 1.);
        float r = .07 + h11(fi + 35.) * .07;
        vec2 d = p - c;
        float ang = atan(d.y, d.x) - h11(fi + 37.) * 6.28;
        float notch = smoothstep(.0, .05, abs(mod(ang + 3.14159, 6.28318) - 3.14159) - .0) ;
        float pad = smoothstep(r, r * .96, length(d)) * smoothstep(.0, .25, abs(sin(ang * .5)));
        vec3 pc = mix(vec3(.15,.42,.15), vec3(.32,.62,.25), .5 + .5 * sin(ang * 14.) * .3 + length(d) / r * .4);
        col = mix(col, col * .65, smoothstep(r * 1.2, r, length(d - vec2(.012, -.014))));
        col = mix(col, pc, pad);
        if (i == 2) col = mix(col, vec3(1.,.75,.85), smoothstep(.028, .02, length(d - vec2(r * .25, r * .2))));
      }
      col *= 1. - .35 * length(uv - .5);
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },
  {
    id: "aurora-peaks", name: "Aurora Peaks", collection: "Cozy Nights", kind: "shader", theme: "Midnight",
    line: "Northern lights over snowy mountains and a mirror lake.",
    frag: `
    vec3 skyAt(vec2 p, vec2 uv){
      vec3 col = mix(vec3(.02,.03,.07), vec3(.03,.06,.14), uv.y);
      col += vec3(.95,.95,1.) * stars(gl_FragCoord.xy, .004, 1.) * smoothstep(.3, .9, uv.y);
      for (int i = 0; i < 3; i++) { float fi = float(i);
        float n = fbm(vec2(p.x * .7 + fi * 3.1, fi * 2.) + loop(.5 + fi * .15));
        float y = .1 + .28 * (n - .45) + .05 * sin(p.x * 1.6 + fi * 2. + TAU * T) + fi * .07;
        float rays = .35 + .9 * pow(fbm(vec2(p.x * 16. + fi * 4., fi) + loop(.9)), 2.);
        float d = p.y - y;
        float band = smoothstep(-.015, .02, d) * exp(-max(d, 0.) * (5. - fi)) * rays;
        col += mix(vec3(.12,1.,.6), vec3(.68,.34,1.), fi / 2.) * band * (.8 - fi * .15); }
      return col; }
    float ridge(float x, float k){
      float h = 0., a = .5, f = 1.;
      for (int i = 0; i < 5; i++) { h += a * (1. - abs(noise(vec2(x * f * 1.6 + k * 7., k + float(i))) * 2. - 1.)); a *= .45; f *= 2.1; }
      return h * .32; }
    vec3 scene(vec2 p, vec2 uv){
      vec3 col = skyAt(p, uv);
      for (int L = 0; L < 2; L++) {
        float fl = float(L);
        float h = -.26 + ridge(p.x, fl * 4. + 1.) * (1.1 - fl * .35) + (fl == 0. ? .06 : -.04);
        if (p.y < h) {
          float snowline = (fl == 0. ? -.06 : -.13) + .05 * fbm(vec2(p.x * 6., fl));
          float cap = smoothstep(snowline, snowline + .03, p.y) * smoothstep(h - .2, h - .02, p.y) * (.55 + .45 * fbm(vec2(p.x * 40., p.y * 25.)));
          vec3 rock = fl == 0. ? vec3(.09,.12,.2) : vec3(.025,.035,.07);
          vec3 snowC = (fl == 0. ? vec3(.55,.68,.82) : vec3(.75,.88,.96)) + vec3(.05,.25,.15) * .3;
          col = mix(rock + vec3(.03,.05,.08) * smoothstep(h - .3, h, p.y), snowC, cap);
          col += vec3(.1,.5,.35) * .1 * (1. - fl);
        }
      }
      return col; }
    void main(){
      vec2 uv = gl_FragCoord.xy / R; vec2 p = (gl_FragCoord.xy - .5 * R) / R.y;
      float wl = -.3;
      vec3 col;
      if (p.y > wl) col = scene(p, uv);
      else {
        vec2 rp = vec2(p.x + .003 * sin(p.y * 200. + TAU * T * 2.), 2. * wl - p.y);
        col = scene(rp, vec2(uv.x, rp.y + .5)) * vec3(.55,.65,.75);
      }
      col *= 1. - .3 * length(uv - .5);
      gl_FragColor = vec4(min(col, 1.), 1.); }`,
  },
];

window.WALLPAPERS.push(...PREMIUM.map((w) => ({ ...w, frag: window.WP_HEAD + EXTRA + w.frag })));
