#version 330
uniform mat3x2 TransformMatrix;

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
	gl_Position = position(TransformMatrix, VertPosition);
}

vec4 position(mat3x2 transMat, vec2 localPosition) {
	return vec4(transMat * vec3(localPosition, 1), 0, 1);
}