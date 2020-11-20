#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wmissing-braces"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct vs_params
{
    float3x2 TransformMatrix;
};

struct vs_in
{
    float2 VertPosition [[attribute(0)]];
    float2 VertTexCoord [[attribute(1)]];
    float4 VertColor [[attribute(2)]];
};

struct vs_out
{
    float2 VaryingTexCoord [[user(locn0)]];
    float4 VaryingColor [[user(locn1)]];
    float4 gl_Position [[position]];
};

static inline __attribute__((always_inline))
float4 position(thread const float3x2& transMat, thread const float2& localPosition)
{
    return float4(transMat * float3(localPosition, 1.0), 0.0, 1.0);
}

vertex vs_out _main(vs_in in [[stage_in]], constant vs_params& vs_uniforms [[buffer(1)]])
{
    vs_out out = {};
    out.VaryingTexCoord = in.VertTexCoord;
    out.VaryingColor = in.VertColor;
    float3x2 matrix = vs_uniforms.TransformMatrix;
    // matrix = float3x2(0.002500, -0.000000, -0.000000, -0.003333, -1.000000, 1.000000); // 800x600 at 0,0
    out.gl_Position = position(matrix, in.VertPosition);
    return out;
}