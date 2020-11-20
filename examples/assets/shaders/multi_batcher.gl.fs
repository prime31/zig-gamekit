#version 330
uniform sampler2D Textures[8];

in vec2 VaryingTexCoord;
in vec4 VaryingColor;
in float VaryingTextureId;

vec4 effect(vec4 vcolor, sampler2D tex, vec2 texcoord);

layout (location=0) out vec4 frag_color;
void main() {
	int tid = int(VaryingTextureId + 0.1);
	frag_color = effect(VaryingColor, Textures[tid], VaryingTexCoord.st);
}

vec4 effect(vec4 vcolor, sampler2D tex, vec2 texcoord) {
	return texture(tex, texcoord) * vcolor;
}