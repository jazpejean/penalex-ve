#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform vec3 uGold;
uniform vec3 uNavy;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec2 p = uv * 3.0;
  float t = uTime * 0.12;

  float n = noise(p + t) * 0.5
          + noise(p * 2.0 - t * 0.7) * 0.3
          + noise(p * 4.0 + t * 0.3) * 0.2;

  vec3 base = mix(uNavy * 0.5, uNavy * 1.3, n);
  float gold = smoothstep(0.6, 0.8, n) * 0.35;
  vec3 color = base + uGold * gold;

  float vig = 1.0 - length(uv - 0.5) * 0.7;
  color *= vig;

  fragColor = vec4(color, 1.0);
}