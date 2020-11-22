#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct VertexParams
{
    float4 transform_matrix[2];
};

struct main0_out
{
    float2 uv_out [[user(locn0)]];
    float4 color_out [[user(locn1)]];
    float4 gl_Position [[position]];
};

struct main0_in
{
    float2 pos_in [[attribute(0)]];
    float2 uv_in [[attribute(1)]];
    float4 color_in [[attribute(2)]];
};

#line 18 ""
vertex main0_out main0(main0_in in [[stage_in]], constant VertexParams& _28 [[buffer(0)]])
{
    main0_out out = {};
#line 18 ""
    out.uv_out = in.uv_in;
#line 19 ""
    out.color_out = in.color_in;
#line 20 ""
    out.gl_Position = float4(float3x2(float2(_28.transform_matrix[0].x, _28.transform_matrix[0].y), float2(_28.transform_matrix[0].z, _28.transform_matrix[0].w), float2(_28.transform_matrix[1].x, _28.transform_matrix[1].y)) * float3(in.pos_in, 1.0), 0.0, 1.0);
    return out;
}

