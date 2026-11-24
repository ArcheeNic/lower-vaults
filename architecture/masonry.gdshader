shader_type spatial;
#include "res://architecture/relief.gdshaderinc"
#include "res://architecture/room_axes.gdshaderinc"

uniform sampler2D mineral : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec4 stone_color : source_color;
uniform bool blocks = true;
uniform bool metal = false;
uniform float broadening = 1.0;
varying vec3 stone_pos;
varying vec3 face_normal;

void vertex() {
    stone_pos = room_axes(mat3(MODEL_MATRIX) * VERTEX) + INSTANCE_CUSTOM.xyz;
    face_normal = room_axes(normalize(MODEL_NORMAL_MATRIX * NORMAL));
}

float tile_value(vec2 v) {
    vec3 p = fract(vec3(v.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

void fragment() {
    vec3 n = abs(normalize(face_normal));
    bool floor_face = n.y > max(n.x, n.z);
    vec2 plane = floor_face ? stone_pos.xz : (n.x > n.z ? stone_pos.zy : stone_pos.xy);
    vec3 grain = texture(mineral, plane * 0.34).rgb;
    float stain = texture(mineral, (plane + vec2(plane.y * 0.06, 0.0)) * vec2(0.095,0.115)).r;
    float tint = 0.79 + 0.30 * grain.r + 0.13 * grain.g - 0.43 * grain.b + 0.19 * stain;
    vec3 cuts = texture(mineral, plane * 1.7).rgb;
    float pit = smoothstep(.45,.8,cuts.b);
    float relief = .019*grain.r + .006*cuts.g - .019*pit;
    tint *= 1.0 - .48*pit;
    if (blocks) {
        vec2 scale = (floor_face ? vec2(1.3, 0.83) : vec2(1.54, 0.64)) * broadening;
        vec2 course = (plane + (grain.rg - 0.5) * 0.031) / scale;
        course.x += 0.47 * mod(floor(course.y), 2.) + (tile_value(vec2(floor(course.y), 36.)) - 0.5) * .33;
        vec2 ed = (0.5 - abs(fract(course) - 0.5)) * scale;
        float dist = min(ed.x, ed.y);
        float aa = min(fwidth(plane.x) + fwidth(plane.y), 0.16) * 0.48 + 0.001;
        float mortar = smoothstep(0.008-aa, 0.021+aa, dist);
        relief += .022*smoothstep(.004-aa,.044+aa,dist);
        float lip = max(0., 1.0 - abs(dist - 0.029) / (0.018 + aa)) * 0.09;
        tint *= (0.85 + tile_value(floor(course)) * .26) * (mix(0.47, 1., mortar) + lip);
    }
    vec3 c = stone_color.rgb * COLOR.rgb * tint;
    ALBEDO = c * mix(vec3(1.0), vec3(0.81, 0.72, 0.60), smoothstep(.53, .79, stain) * .70);
    NORMAL = relief_normal(VERTEX,normalize(NORMAL),relief);
    ROUGHNESS = metal ? mix(.39,.81,grain.r) : mix(.63,.96,grain.r + pit*.25);
    METALLIC = metal ? 0.62 : 0.0;
    SPECULAR = metal ? 0.46 : 0.22;
}
