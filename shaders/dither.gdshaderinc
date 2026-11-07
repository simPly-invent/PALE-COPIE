// Tramage ordonné Bayer 4x4 : remplace progressivement les dégradés et les ombres.
float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[i] / 16.0 - 0.5;
}

vec3 dither(vec3 col, vec2 pixel, float strength) {
	if (strength <= 0.0) {
		return col;
	}
	float levels = mix(32.0, 4.0, strength);
	vec3 d = col + bayer4(pixel) / levels;
	return mix(col, floor(d * levels + 0.5) / levels, clamp(strength * 1.5, 0.0, 1.0));
}
