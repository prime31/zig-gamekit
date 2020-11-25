#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Mode7Params
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

struct main0_out
{
    float4 frag_color [[color(0)]];
};

struct main0_in
{
    float2 uv_out [[user(locn0)]];
    float4 color_out [[user(locn1)]];
};

// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()
template<typename Tx, typename Ty>
inline Tx mod(Tx x, Ty y)
{
    return x - y * floor(x / y);
}

#line 31 ""
static inline __attribute__((always_inline))
float4 effect(thread const texture2d<float> tex, thread const sampler texSmplr, thread const float2& tex_coord, thread const float4& vert_color, constant Mode7Params& v_38, thread texture2d<float> map_tex, thread const sampler map_texSmplr)
{
#line 31 ""
#line 32 ""
#line 35 ""
#line 33 ""
#line 34 ""
    float2 _86 = float2((0.5 - tex_coord.x) * v_38.zoom, (v_38.offset - tex_coord.y) * (v_38.zoom / v_38.fov)) * float2x2(float2(v_38.x1, v_38.y1), float2(v_38.x2, v_38.y2));
    float _100 = ((_86.x / tex_coord.y) + v_38.x) / v_38.mapw;
    float _113 = ((_86.y / tex_coord.y) + v_38.y) / v_38.maph;
#line 41 ""
    bool _119 = v_38.wrap == 0.0;
    bool _146;
    if (_119)
    {
        bool _124 = _100 < 0.0;
        bool _131;
        if (!_124)
        {
            _131 = _100 > 1.0;
        }
        else
        {
            _131 = _124;
        }
        bool _138;
        if (!_131)
        {
            _138 = _113 < 0.0;
        }
        else
        {
            _138 = _131;
        }
        bool _145;
        if (!_138)
        {
            _145 = _113 > 1.0;
        }
        else
        {
            _145 = _138;
        }
        _146 = _145;
    }
    else
    {
        _146 = _119;
    }
    if (_146)
    {
#line 42 ""
        return float4(0.0);
    }
    else
    {
#line 44 ""
        return map_tex.sample(map_texSmplr, mod(float2(_100, _113), float2(1.0))) * vert_color;
    }
}

#line 15 ""
fragment main0_out main0(main0_in in [[stage_in]], constant Mode7Params& v_38 [[buffer(0)]], texture2d<float> main_tex [[texture(0)]], texture2d<float> map_tex [[texture(1)]], sampler main_texSmplr [[sampler(0)]], sampler map_texSmplr [[sampler(1)]])
{
    main0_out out = {};
#line 15 ""
    float2 param = in.uv_out;
    float4 param_1 = in.color_out;
    out.frag_color = effect(main_tex, main_texSmplr, param, param_1, v_38, map_tex, map_texSmplr);
    return out;
}

