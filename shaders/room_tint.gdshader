// Teinte de salle (mutations de palier 1 : désaturation, virage au jaune, contraste aplati).
// Appliqué aux nœuds Tiles, Props et NPCs, jamais à l'ancre.
shader_type canvas_item;

uniform float desaturate : hint_range(0.0, 1.0) = 0.0;
uniform float yellow_shift : hint_range(0.0, 1.0) = 0.0;
uniform float flatten : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(c.rgb, vec3(l), desaturate);
	vec3 beige = vec3(0.86, 0.78, 0.55) * (0.35 + l);
	col = mix(col, beige, yellow_shift * 0.6);
	col = mix(col, vec3(0.55, 0.5, 0.4), flatten * 0.5);
	COLOR = vec4(col, c.a);
}
