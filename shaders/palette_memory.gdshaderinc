// Palette de mémoire : les couleurs glissent vers une palette jaune-beige à 8 teintes.
// palette_count descend jusqu'à 3 teintes à F = 5.
uniform vec3 mem_palette[8];

vec3 palette_remap(vec3 col, float amount, int count) {
	if (amount <= 0.0) {
		return col;
	}
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	// la luminance choisit une teinte parmi les `count` premières (rangées du sombre au clair)
	float idx = clamp(floor(l * float(count)), 0.0, float(count - 1));
	vec3 target = mem_palette[0];
	for (int i = 0; i < 8; i++) {
		if (i == int(idx)) {
			target = mem_palette[i];
		}
	}
	return mix(col, target, amount);
}
