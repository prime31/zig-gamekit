#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct fs_params
{
    float mapw;
    float maph;
    float x;
    float y;
    float zoom;
    float fov;
    float offset;
    float wrap;
    float x1;
    float x2;
    float y1;
    float y2;
};

struct fs_out
{
    float4 frag_color [[color(0)]];
};

struct fs_in
{
    float2 VaryingTexCoord [[user(locn0)]];
    float4 VaryingColor [[user(locn1)]];
};

// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()
template<typename Tx, typename Ty>
inline Tx mod(Tx x, Ty y)
{
    return x - y * floor(x / y);
}

fragment fs_out main0(fs_in in [[stage_in]], constant fs_params& uniform [[buffer(0)]], texture2d<float> MainTex [[texture(0)]], texture2d<float> map_tex [[texture(1)]], sampler MainTexSmplr [[sampler(0)]], sampler map_texSmplr [[sampler(1)]])
{
	float2x2 rotation = float2x2(uniform.x1, uniform.y1, uniform.x2, uniform.y2);
	float2 uv = float2(
		(0.5 - in.VaryingTexCoord.x) * uniform.zoom,
		(uniform.offset - in.VaryingTexCoord.y) * (uniform.zoom / uniform.fov)
	) * rotation;
	float2 uv2 = float2(
		(uv.x / in.VaryingTexCoord.y + uniform.x) / uniform.mapw,
		(uv.y / in.VaryingTexCoord.y + uniform.y) / uniform.maph
	);

    fs_out out = {};
	if (uniform.wrap == 0 && (uv2.x < 0.0 || uv2.x > 1.0 || uv2.y < 0.0 || uv2.y > 1.0)) {
		out.frag_color = float4(0.0, 0.0, 0.0, 0.0);
	} else {
        out.frag_color = map_tex.sample(map_texSmplr, mod(uv2, 1.0)) * in.VaryingColor;
	}

    return out;
}