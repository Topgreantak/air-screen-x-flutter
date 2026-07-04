#include <metal_stdlib>
using namespace metal;

// Fullscreen triangle-strip quad. Samples a BGRA texture (VideoToolbox gives us a
// Metal-compatible pixel buffer; sampling as bgra8Unorm yields display-ready RGB).

struct VOut { float4 pos [[position]]; float2 uv; };

constant float2 kPos[4]  = { float2(-1,-1), float2(1,-1), float2(-1,1), float2(1,1) };
constant float2 kUV[4]   = { float2(0,1),   float2(1,1),  float2(0,0),  float2(1,0) };

vertex VOut vertexShader(uint vid [[vertex_id]]) {
    VOut o;
    o.pos = float4(kPos[vid], 0, 1);
    o.uv  = kUV[vid];
    return o;
}

fragment float4 fragmentShader_ycbcr(VOut in [[stage_in]],
                                     texture2d<float> tex [[texture(0)]]) {
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    return tex.sample(s, in.uv);
}
