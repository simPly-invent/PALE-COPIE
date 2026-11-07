// VHS : aberration chromatique, lignes de balayage, bruit de tracking qui défile, saturation réduite.
float vhs_rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 vhs_sample(sampler2D tex, vec2 uv, float chroma, float strength, float t, float tracking) {
	// ondulation horizontale (tracking)
	float band = smoothstep(0.0, 0.06, abs(fract(uv.y * 0.5 - t * 0.07 * tracking) - 0.5) - 0.44);
	float wobble = (vhs_rand(vec2(floor(uv.y * 240.0), floor(t * 24.0))) - 0.5) * 0.004 * strength * tracking;
	uv.x += wobble + band * 0.006 * strength * tracking;
	float off = chroma * strength * 0.004;
	float r = texture(tex, uv + vec2(off, 0.0)).r;
	float g = texture(tex, uv).g;
	float b = texture(tex, uv - vec2(off, 0.0)).b;
	return vec3(r, g, b);
}

vec3 vhs_post(vec3 col, vec2 uv, vec2 px, float strength, float scan, float t, float tracking) {
	float line = mod(floor(uv.y / px.y), 2.0);
	col *= 1.0 - scan * strength * 0.18 * line;
	float noise = vhs_rand(uv * vec2(640.0, 480.0) + vec2(t * 13.0, t * 7.0)) - 0.5;
	col += noise * 0.06 * strength;
	// bande de bruit qui défile
	float roll = fract(t * 0.05 * tracking);
	float d = abs(uv.y - roll);
	col += (1.0 - smoothstep(0.0, 0.015, d)) * 0.12 * strength * tracking * vhs_rand(vec2(uv.x * 80.0, t));
	return col;
}

vec3 vhs_saturation(vec3 col, float sat) {
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	return mix(vec3(l), col, sat);
}
