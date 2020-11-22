#version 330

uniform vec4 VertexParams[2];

layout (location=0) in vec2 VertPosition;
layout (location=1) in vec2 VertTexCoord;
layout (location=2) in vec4 VertColor;
layout (location=3) in float TextureId;

out vec2 VaryingTexCoord;
out vec4 VaryingColor;
out float VaryingTextureId;

vec4 position(mat3x2 transMat, vec2 localPosition);

void main() {
	VaryingTexCoord = VertTexCoord;
	VaryingColor = VertColor;
	VaryingTextureId = TextureId;
	gl_Position = position(mat3x2(vec2(VertexParams[0].x, VertexParams[0].y), vec2(VertexParams[0].z, VertexParams[0].w), vec2(VertexParams[1].x, VertexParams[1].y)), VertPosition);
}

vec4 position(mat3x2 transMat, vec2 localPosition) {
	return vec4(transMat * vec3(localPosition, 1), 0, 1);
}