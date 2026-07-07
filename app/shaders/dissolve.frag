#version 460 core

// Hiệu ứng "tan biến" sau khi bé chụp: NỀN ảnh vỡ thành hạt cát rồi biến mất,
// CHỦ THỂ (mask tách nền) giữ nguyên và được VẼ VIỀN dần theo một vòng quét.
//
// Thứ tự khai báo uniform = thứ tự index khi setFloat ở Dart (vec2 = 2 float):
//   uSize    -> 0,1     uTexSize -> 2,3    uProgress -> 4
//   uBorder  -> 5       uCenter  -> 6,7
// Sampler tính index riêng: uFrame -> 0, uMask -> 1.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // kích thước widget (px)
uniform vec2 uTexSize;   // kích thước ảnh nguồn (px)
uniform float uProgress; // 0..1 mức tan biến nền
uniform float uBorder;   // 0..1 mức vẽ viền
uniform vec2 uCenter;    // tâm chủ thể (toạ độ chuẩn hoá 0..1)
uniform float uSpin;     // 0..1 góc vệt sáng chạy quanh viền (lúc đang tải)
uniform float uSpinOn;   // 1 = bật vệt sáng chạy, 0 = tắt
uniform sampler2D uFrame; // ảnh gốc vừa chụp
uniform sampler2D uMask;  // foreground: alpha = chủ thể

out vec4 fragColor;

const float TAU = 6.28318530718;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 345.45));
  p += dot(p, p + 34.345);
  return fract(p.x * p.y);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// fBm 3 tầng, chuẩn hoá về ~0..1.
float fbm(vec2 p) {
  float s = 0.0;
  float amp = 0.5;
  for (int i = 0; i < 3; i++) {
    s += amp * vnoise(p);
    p *= 2.0;
    amp *= 0.5;
  }
  return s / 0.875;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;

  // Cover-fit: lấy mẫu một vùng con canh giữa của ảnh để phủ kín widget (khớp
  // với preview camera đang cover, để chủ thể không "nhảy" lúc chuyển cảnh).
  float widgetAspect = uSize.x / uSize.y;
  float texAspect = uTexSize.x / uTexSize.y;
  vec2 s = uv;
  if (texAspect > widgetAspect) {
    s.x = (uv.x - 0.5) * (widgetAspect / texAspect) + 0.5;
  } else {
    s.y = (uv.y - 0.5) * (texAspect / widgetAspect) + 0.5;
  }

  vec4 frame = texture(uFrame, s);
  float m = texture(uMask, s).a; // 1 = chủ thể, 0 = nền

  // --- Tan biến nền -----------------------------------------------------------
  float wave = fbm(s * 3.2 + uCenter);
  float grain = hash(floor(FlutterFragCoord().xy * 0.9));
  float n = clamp(wave * 0.8 + grain * 0.2, 0.0, 1.0);
  float edge = 0.14;
  float bgVisible = smoothstep(uProgress - edge, uProgress + edge, n);

  float bg = bgVisible * (1.0 - m);
  float alpha = clamp(m + bg, 0.0, 1.0);
  vec3 color = frame.rgb;

  // Ánh sáng "hạt cát" ấm ngay tại làn sóng đang tan (chỉ trên nền).
  float band = 1.0 - smoothstep(0.0, edge, abs(n - uProgress));
  float burn = band * (1.0 - m) * step(0.02, uProgress) * (1.0 - step(0.99, uProgress));
  color += vec3(0.98, 0.86, 0.62) * burn * 1.15;

  // --- Viền chủ thể được vẽ dần theo vòng quét --------------------------------
  vec2 px = 1.6 / uTexSize;
  float ax = texture(uMask, s + vec2(px.x, 0.0)).a;
  float axn = texture(uMask, s - vec2(px.x, 0.0)).a;
  float ay = texture(uMask, s + vec2(0.0, px.y)).a;
  float ayn = texture(uMask, s - vec2(0.0, px.y)).a;
  float grad = abs(ax - axn) + abs(ay - ayn);
  float line = smoothstep(0.10, 0.70, grad);

  vec2 rel = s - uCenter;
  rel.x *= texAspect; // canh tỉ lệ để vòng quét đều
  float angN = atan(rel.y, rel.x) / TAU + 0.5; // 0..1 quanh tâm
  float drawn = step(angN, uBorder);
  float tip = smoothstep(0.035, 0.0, abs(angN - uBorder)) * (1.0 - step(1.0, uBorder));

  // Đang tải: CHÍNH VIỀN TRẮNG tự vẽ chạy vòng quanh — một cung viền được vẽ,
  // đuôi mờ dần, đầu bút quay liên tục (không phải vệt sáng chạy trên viền tĩnh).
  // Ngoài lúc tải (intro/xong): viền vẽ theo uBorder rồi đứng yên.
  float drel = fract(uSpin - angN);            // 0 ở đầu bút, tăng dần về đuôi
  float comet = smoothstep(0.55, 0.0, drel);   // cung viền đang vẽ, đuôi nhạt
  float headTip = smoothstep(0.05, 0.0, drel); // đầu bút sáng hơn
  float outlineAmt = mix(drawn, comet, uSpinOn);
  float outline = line * outlineAmt;
  float lead = line * tip;                    // đầu bút lúc intro
  float loadHead = line * headTip * uSpinOn;  // đầu bút lúc đang vẽ vòng lặp

  color += vec3(1.0) * (outline * 0.95 + lead * 1.6 + loadHead * 0.9);
  alpha = max(alpha, max(max(outline, lead), loadHead));

  // Flutter fragment shader trả màu ĐÃ nhân alpha (premultiplied).
  fragColor = vec4(color * alpha, alpha);
}
