#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float softPx;
    float widthPx;
    vec4 dimColor;
    vec4 hlColor;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 tex = texture(source, qt_TexCoord0);
    float x = qt_TexCoord0.x * widthPx;
    float edge = progress * widthPx;
    float t = smoothstep(edge - softPx, edge + softPx, x);
    // 高亮部分往白色方向提亮，唱过的字更醒目
    vec4 hl = mix(hlColor, vec4(1.0, 1.0, 1.0, 1.0), 0.3);
    vec4 col = mix(hl, dimColor, t);
    float glow = 1.0 - smoothstep(edge - softPx * 2.0, edge, x);
    col = mix(col, hl, glow * 0.25);
    fragColor = vec4(col.rgb * tex.a, col.a * tex.a) * qt_Opacity;
}
