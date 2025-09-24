shader_type canvas_item;

uniform vec3 shadow_color = vec3(0.02, 0.02, 0.05); // very dark, cold shadows
uniform float shadow_strength = 0.7;               // how much light is absorbed

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // Darken the tile uniformly
    vec3 final_color = tex_color.rgb * (1.0 - shadow_strength) + shadow_color * shadow_strength;

    COLOR = vec4(final_color, tex_color.a);
}
