// Color CRT / VHS shader for Ghostty
// Preserves the terminal's syntax colors, warms them toward amber, and layers on
// CRT texture: chromatic aberration + bloom + soft scanlines.
// Dark backgrounds crush to true black (hue-preserving), so empty space stays black.
// Shadertoy-format GLSL. iChannel0 = terminal screen, iResolution provided by Ghostty.

// How warm/amber the whole image reads. 0 = true theme colors, 1 = heavily amber.
const float WARMTH = 0.92;
// Warm grade at full WARMTH (cuts green/blue to tilt everything toward amber, not beige).
const vec3 WARM_TINT = vec3(1.0, 0.66, 0.18);

// Black-point: screen areas dimmer than this crush to true black (kills bg glow).
// Raise if backgrounds still glow; lower if dim text disappears.
const float BLACK_POINT = 0.18;
// Gamma < 1 lifts dim-but-real text (comments, line numbers) toward readable.
const float TEXT_GAMMA = 0.7;

// Text thickening: fatten glyph strokes by this many pixels. 0 = off.
// Font already carries the weight, so keep this off to avoid softening edges.
const float THICKNESS = 0.0;
// VHS RGB channel split, in pixels. 0 = off. Higher = more analog/blurry.
const float ABERRATION = 0.0;
// Bloom (glow) amount and radius.
const float BLOOM = 0.06;
const float BLOOM_RADIUS = 1.6;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

// Crush dark areas toward black by luminance, but keep the original hue
// (rescale chromaticity to the new, black-pointed luminance).
vec3 crush(vec3 c) {
    float l = luma(c);
    float k = clamp((l - BLACK_POINT) / (1.0 - BLACK_POINT), 0.0, 1.0);
    k = pow(k, TEXT_GAMMA);
    return c * (k / max(l, 1e-4));
}

// Sample the screen with chromatic aberration, then crush.
vec3 sampleScreen(vec2 uv) {
    vec2 off = vec2(ABERRATION / iResolution.x, 0.0);
    float r = texture(iChannel0, uv + off).r;
    float g = texture(iChannel0, uv).g;
    float b = texture(iChannel0, uv - off).b;
    return crush(vec3(r, g, b));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    // Thicken text: dilate by keeping the brightest color in a tiny neighborhood
    // (fattens glyph strokes while preserving their hue).
    vec3 col = sampleScreen(uv);
    float best = luma(col);
    float ds = THICKNESS / iResolution.y;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec3 s = sampleScreen(uv + vec2(float(x), float(y)) * ds);
            float sl = luma(s);
            if (sl > best) { best = sl; col = s; }
        }
    }

    // Colored bloom: average the crushed color over a small neighborhood.
    vec3 bloom = vec3(0.0);
    vec2 bs = vec2(BLOOM_RADIUS) / iResolution.xy;
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            bloom += crush(texture(iChannel0, uv + vec2(float(x), float(y)) * bs).rgb);
        }
    }
    bloom /= 25.0;
    col += bloom * BLOOM;

    // Warm grade: tilt everything toward amber while keeping hue differences.
    col = mix(col, col * WARM_TINT, WARMTH);

    // Soft scanlines (~240 lines across the screen).
    float scan = sin(uv.y * 3.14159 * 480.0) * 0.5 + 0.5;
    col *= 0.96 + 0.04 * scan;

    fragColor = vec4(col, 1.0);
}
