// Light-mode CRT shader for Ghostty — Mac 90's inspired
// Warm cream background, dark text, subtle retro CRT texture.
// Companion to crt.glsl (dark/amber mode). Toggle with toggle-theme.sh.

// Warm tint — shifts whites toward cream/parchment.
const float WARMTH = 0.30;
const vec3 WARM_TINT = vec3(1.0, 0.96, 0.90);

// Bloom — subtle glow around text.
const float BLOOM = 0.04;
const float BLOOM_RADIUS = 1.4;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    vec3 col = texture(iChannel0, uv).rgb;

    // Soft bloom
    vec3 bloom = vec3(0.0);
    vec2 bs = vec2(BLOOM_RADIUS) / iResolution.xy;
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            bloom += texture(iChannel0, uv + vec2(float(x), float(y)) * bs).rgb;
        }
    }
    bloom /= 25.0;
    // Only bloom dark areas (text glow), not the bright background
    float bloomMask = 1.0 - luma(col);
    col += (bloom - col) * BLOOM * bloomMask;

    // Warm tint — shift toward cream
    col = mix(col, col * WARM_TINT, WARMTH);

    // Faint scanlines
    float scan = sin(uv.y * 3.14159 * 480.0) * 0.5 + 0.5;
    col *= 0.97 + 0.03 * scan;

    fragColor = vec4(col, 1.0);
}
