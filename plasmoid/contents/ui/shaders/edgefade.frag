#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float fadePx;
    float viewW;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 tex = texture(source, qt_TexCoord0);
    float x = qt_TexCoord0.x * viewW;
    float fade = min(smoothstep(0.0, fadePx, x), smoothstep(0.0, fadePx, viewW - x));
    fragColor = tex * fade * qt_Opacity;
}
