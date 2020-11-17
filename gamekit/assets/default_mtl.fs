#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct main0_out
{
    float4 frag_color [[color(0)]];
};

struct main0_in
{
    float2 VaryingTexCoord [[user(locn0)]];
    float4 VaryingColor [[user(locn1)]];
};

static inline __attribute__((always_inline))
float4 effect(thread const float4& vcolor, thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& texcoord)
{
    return tex.sample(texSmplr, texcoord) * vcolor;
}

fragment main0_out _main(main0_in in [[stage_in]], texture2d<float> MainTex [[texture(0)]], sampler MainTexSmplr [[sampler(0)]])
{
    main0_out out = {};
    float4 param = in.VaryingColor;
    float2 param_1 = in.VaryingTexCoord;
    out.frag_color = effect(param, MainTex, MainTexSmplr, param_1);
    return out;
}