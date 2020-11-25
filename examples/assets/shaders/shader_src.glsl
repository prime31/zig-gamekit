@vs sprite_vs
uniform VertexParams {
	vec4 transform_matrix[2];
};

layout(location = 0) in vec2 pos_in;
layout(location = 1) in vec2 uv_in;
layout(location = 2) in vec4 color_in;

out vec2 uv_out;
out vec4 color_out;

void main() {
	uv_out = uv_in;
	color_out = color_in;
	mat3x2 transMat = mat3x2(transform_matrix[0].x, transform_matrix[0].y, transform_matrix[0].z, transform_matrix[0].w, transform_matrix[1].x, transform_matrix[1].y);

	gl_Position = vec4(transMat * vec3(pos_in, 1), 0, 1);
}
@end


@block sprite_fs_main
uniform sampler2D main_tex;

in vec2 uv_out;
in vec4 color_out;
out vec4 frag_color;

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color);

void main() {
	frag_color = effect(main_tex, uv_out.st, color_out);
}
@end


@fs sprite_fs
@include_block sprite_fs_main
vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {
	return texture(tex, tex_coord) * vert_color;
}
@end

@program sprite sprite_vs sprite_fs

@fs mode7_fs
@include_block sprite_fs_main
uniform Mode7Params {
	float mapw;
	float maph;
	float x;
	float y;
	float zoom;
	float fov;
	float offset;
	float wrap;
	float x1, x2, y1, y2;
};
uniform sampler2D map_tex;

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
@end

@program mode7 sprite_vs mode7_fs

#@include example_include_commented_out.glsl