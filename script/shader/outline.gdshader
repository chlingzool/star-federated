shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float grow = 0.05;

void vertex() {
VERTEX += NORMAL * grow;
}

void fragment() {
ALBEDO = color.rgb;
}