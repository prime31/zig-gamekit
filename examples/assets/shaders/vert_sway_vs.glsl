#version 330

uniform vec4 VertexSwayParams[3];
out vec2 uv_out;
layout(location = 1) in vec2 uv_in;
out vec4 color_out;
layout(location = 2) in vec4 color_in;
layout(location = 0) in vec2 pos_in;

void main()
{
    uv_out = uv_in;
    color_out = color_in;
    gl_Position = vec4(mat3x2(vec2(VertexSwayParams[0].x, VertexSwayParams[0].y), vec2(VertexSwayParams[0].z, VertexSwayParams[0].w), vec2(VertexSwayParams[1].x, VertexSwayParams[1].y)) * vec3(pos_in.x + ((sin(VertexSwayParams[2].x) * 20.0) * (1.0 - uv_in.y)), pos_in.y, 1.0), 0.0, 1.0);
}

