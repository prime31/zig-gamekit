#version 330
uniform sampler2D MainTex;
uniform vec4 via_ScreenSize;

in vec2 VaryingTexCoord;
in vec4 VaryingColor;

#define via_PixelCoord (vec2(gl_FragCoord.x, (gl_FragCoord.y * via_ScreenSize.z) + via_ScreenSize.w))
vec4 effect(vec4 vcolor, sampler2D tex, vec2 texcoord);

layout (location=0) out vec4 frag_color;
void main() {
	frag_color = effect(VaryingColor, MainTex, VaryingTexCoord.st);
}

vec4 effect(vec4 vcolor, sampler2D tex, vec2 texcoord) {
	return texture(tex, texcoord) * vcolor;
}