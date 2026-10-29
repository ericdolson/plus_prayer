#version 460 core
// One layer of a scroll edge (components/scroll_edge.dart). Runs over a
// blurred copy of the backdrop and is laid over the backdrop itself. t runs
// from the screen's edge (0) to the edge's inner end (1): the blur shows
// fully before u_blur.x and eases out by u_blur.y; the dim, if any, eases out
// over the whole height. Both follow one
// curve, flat at both ends so neither has a visible start or end; u_curve > 1
// bows it so they build sooner from the inner end.

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;    // the backdrop, in physical pixels (set by the engine)
uniform float u_height; // the edge's height, from the top or bottom of the screen
uniform vec4 u_ground;  // the screen's ground; alpha = dim at the screen's edge
uniform float u_curve;  // the falloff's bow: 1 = plain smoothstep
uniform vec2 u_blur;    // the blur eases out from x to y (0-1)
uniform float u_bottom; // 1 = the bottom edge
uniform sampler2D u_texture;

out vec4 frag_color;

// 1 before [from], 0 after [to].
float fade(float from, float to, float t) {
  return 1.0 - pow(smoothstep(from, to, t), u_curve);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 uv = p / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  float t = clamp((u_bottom > 0.5 ? u_size.y - p.y : p.y) / u_height, 0.0, 1.0);
  float blur = fade(u_blur.x, u_blur.y, t);
  float dim = u_ground.a * fade(0.0, 1.0, t);
  vec4 blurred = texture(u_texture, uv);
  // Laid over the sharp backdrop S, this gives (1 - dim) * mix(S, blurred,
  // blur) + dim * ground: the dim covers the sharp part too.
  vec3 color = (1.0 - dim) * blur * blurred.rgb + dim * u_ground.rgb * blurred.a;
  float alpha = blur + dim - blur * dim;
  // Half a step of noise, so dark gradients don't band.
  float noise = (fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) / 255.0;
  frag_color = vec4(color + noise * alpha, alpha * blurred.a);
}
