#version 330

layout(location = 0) out vec4 frag_color_0;
in vec2 uv_out;
layout(location = 1) out vec4 frag_color_1;
in vec4 color_out;

void main()
{
    frag_color_0 = vec4(1.0, 0.0, 0.0, 1.0);
    frag_color_1 = color_out;
}

