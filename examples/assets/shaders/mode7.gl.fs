#version 330

uniform float mapw;
uniform float maph;
uniform float x;
uniform float y;
uniform float zoom;
uniform float fov;
uniform float offset;
uniform float wrap;
uniform float x1, x2, y1, y2;

uniform sampler2D main_tex;
uniform sampler2D map_tex;

in vec2 uv_out;
in vec4 color_out;

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color);

layout (location=0) out vec4 frag_color;

void main() {
	frag_color = effect(main_tex, uv_out.st, color_out);
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {
	mat2 rotation = mat2(x1, y1, x2, y2);
	vec2 uv = vec2(
		(0.5 - tex_coord.x) * zoom,
		(offset - tex_coord.y) * (zoom / fov)
	) * rotation;
	vec2 uv2 = vec2(
		(uv.x / tex_coord.y + x) / mapw,
		(uv.y / tex_coord.y + y) / maph
	);

	if (wrap == 0 && (uv2.x < 0.0 || uv2.x > 1.0 || uv2.y < 0.0 || uv2.y > 1.0)) {
		return vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		return (texture(map_tex, mod(uv2, 1.0) ) * vert_color);
	}
}