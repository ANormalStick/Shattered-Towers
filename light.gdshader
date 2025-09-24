shader_type canvas_item;

uniform vec4 glow_color = vec4(1.0, 1.0, 0.8, 1.0);
uniform float glow_strength = 0.3;
uniform float pulse_speed = 3.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
    COLOR = tex_color + glow_color * glow_strength * pulse;
}
