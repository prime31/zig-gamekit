#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct fs_out
{
    float4 frag_color [[color(0)]];
};

struct fs_in
{
    float2 VaryingTexCoord [[user(locn0)]];
    float4 VaryingColor [[user(locn1)]];
};

static inline __attribute__((always_inline))
float4 effect(thread const float4& vcolor, thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& texcoord)
{
    return tex.sample(texSmplr, texcoord) * vcolor;
}

// float4 effect(thread const float4& vcolor, thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& texcoord, constant fs_params& uniforms)
// fragment main0_out(fs_in in [[stage_in]], constant sepia_fs_params& v_52 [[buffer(0)]], texture2d<float> MainTex [[texture(0)]], sampler MainTexSmplr [[sampler(0)]])
fragment fs_out _main(fs_in in [[stage_in]], texture2d<float> MainTex [[texture(0)]], sampler MainTexSmplr [[sampler(0)]])
{
    fs_out out = {};
    out.frag_color = effect(in.VaryingColor, MainTex, MainTexSmplr, in.VaryingTexCoord);
    return out;
}