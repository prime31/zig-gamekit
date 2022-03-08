#version 330

uniform sampler2D main_tex;

layout(location = 0) out vec4 frag_color_0;
in vec2 uv_out;
layout(location = 1) out vec4 frag_color_1;
in vec4 color_out;

void main()
{
    frag_color_0 = texture(main_tex, uv_out);
    frag_color_1 = texture(main_tex, uv_out) * color_out;
}

