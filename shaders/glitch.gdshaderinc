// Hors-champ (palier 6) : une bande de l'image se décale de quelques pixels, comme une erreur de lecture.
vec2 glitch_band(vec2 uv, float band_y, float band_h, float offset_px, vec2 px) {
	if (band_h > 0.0 && uv.y > band_y && uv.y < band_y + band_h) {
		uv.x += offset_px * px.x;
	}
	return uv;
}
