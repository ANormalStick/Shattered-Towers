shader_type canvas_item;

uniform bool is_hope = false;
uniform vec3 hope_tint = vec3(0.85, 1.0, 0.9);
uniform vec3 despair_tint = vec3(0.85, 0.85, 1.0);
uniform float strength = 0.6;

// IMPORTANT for Godot 4: sample the screen, not the rect
uniform sampler2D screen_tex : hint_screen_texture;

void fragment() {
    // Grab what's already rendered on screen at this pixel
    vec4 src = texture(screen_tex, SCREEN_UV);

    // Desaturate
    float gray = dot(src.rgb, vec3(0.299, 0.587, 0.114));
    vec3 desat = vec3(gray);

    // Apply dimension tint to the desaturated image
    vec3 tint = is_hope ? hope_tint : despair_tint;
    vec3 toned = mix(desat, desat * tint, strength);

    // Blend back toward original image by 'strength'
    vec3 final_rgb = mix(src.rgb, toned, strength);

    COLOR = vec4(final_rgb, src.a);
}
