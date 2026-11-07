// Post-traitement plein écran. Toutes les intensités sont pilotées par FxManager selon la fidélité.
shader_type canvas_item;

#include "res://shaders/vhs.gdshaderinc"
#include "res://shaders/palette_memory.gdshaderinc"
#include "res://shaders/dither.gdshaderinc"
#include "res://shaders/memory_blur.gdshaderinc"
#include "res://shaders/glitch.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float vhs_strength = 0.2;
uniform float chroma = 1.0;
uniform float scanlines = 1.0;
uniform float tracking = 1.0;      // 0 avec l'option « effets réduits »
uniform float saturation = 1.0;
uniform float palette_amount = 0.0;
uniform int palette_count = 8;
uniform float dither_strength = 0.0;
uniform float blur_strength = 0.0;
uniform float vignette_strength = 0.15;
uniform float band_y = 0.0;
uniform float band_h = 0.0;
uniform float band_offset = 0.0;
uniform float time_offset = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	float t = TIME + time_offset;
	uv = glitch_band(uv, band_y, band_h, band_offset, px);
	vec3 col = vhs_sample(screen_tex, uv, chroma, vhs_strength, t, tracking);
	col = memory_blur(screen_tex, uv, col, blur_strength, px);
	col = vhs_saturation(col, saturation);
	col = palette_remap(col, palette_amount, palette_count);
	col = dither(col, FRAGCOORD.xy, dither_strength);
	col = vhs_post(col, uv, px, vhs_strength, scanlines, t, tracking);
	col = vignette(col, uv, vignette_strength + blur_strength * 0.5);
	COLOR = vec4(col, 1.0);
}
