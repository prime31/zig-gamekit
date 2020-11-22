#version 330

uniform vec4 Mode7Params[3];
uniform sampler2D main_tex;
uniform sampler2D map_tex;

layout(location = 0) out vec4 frag_color;
in vec2 uv_out;
in vec4 color_out;

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color)
{
    vec2 _86 = vec2((0.5 - tex_coord.x) * Mode7Params[1].x, (Mode7Params[1].z - tex_coord.y) * (Mode7Params[1].x / Mode7Params[1].y)) * mat2(vec2(Mode7Params[2].x, Mode7Params[2].z), vec2(Mode7Params[2].y, Mode7Params[2].w));
    float _100 = ((_86.x / tex_coord.y) + Mode7Params[0].z) / Mode7Params[0].x;
    float _113 = ((_86.y / tex_coord.y) + Mode7Params[0].w) / Mode7Params[0].y;
    bool _119 = Mode7Params[1].w == 0.0;
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
        return vec4(0.0);
    }
    else
    {
        return texture(map_tex, mod(vec2(_100, _113), vec2(1.0))) * vert_color;
    }
}

void main()
{
    vec2 param = uv_out;
    vec4 param_1 = color_out;
    frag_color = effect(main_tex, param, param_1);
}

