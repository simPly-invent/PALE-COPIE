// Flou de souvenir : les bords de l'écran se brouillent, avec une vignette (palier 5+).
vec3 memory_blur(sampler2D tex, vec2 uv, vec3 col, float strength, vec2 px) {
	if (strength <= 0.0) {
		return col;
	}
	float d = length((uv - 0.5) * vec2(1.25, 1.0));
	float edge = smoothstep(0.3, 0.75, d) * strength;
	vec3 acc = vec3(0.0);
	float r = 3.0 * edge;
	acc += texture(tex, uv + vec2(r, 0.0) * px).rgb;
	acc += texture(tex, uv - vec2(r, 0.0) * px).rgb;
	acc += texture(tex, uv + vec2(0.0, r) * px).rgb;
	acc += texture(tex, uv - vec2(0.0, r) * px).rgb;
	acc += texture(tex, uv + vec2(r, r) * px * 0.7).rgb;
	acc += texture(tex, uv - vec2(r, r) * px * 0.7).rgb;
	col = mix(col, acc / 6.0, edge);
	return col;
}

vec3 vignette(vec3 col, vec2 uv, float strength) {
	float d = length((uv - 0.5) * vec2(1.1, 1.0));
	return col * (1.0 - smoothstep(0.35, 0.85, d) * strength);
}
