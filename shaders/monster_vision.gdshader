shader_type spatial;

render_mode unshaded, fog_disabled;

const float VIEW_DISTANCE = 30.0;

uniform float sonic_pulse_width : hint_range(1.0, 10.0, 0.001) = 5.0;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	
	//ALBEDO.rgb = vec3(fract(linear_depth));
	
	// 1. Sample the normal roughness texture
	vec4 normal_roughness = texture(normal_roughness_texture, SCREEN_UV);
	vec4 base_color = texture(screen_texture, SCREEN_UV);
	
	// 2. Unpack the normal vector (stored in RGB)
	vec3 view_normal = normal_roughness.rgb * 2.0 - 1.0;
	
	vec3 distance_color = smoothstep(vec3(1.0), vec3(0.0), vec3(linear_depth / VIEW_DISTANCE));
	
	float dist = distance(world_position, CAMERA_POSITION_WORLD);
	float mix_ratio = 0.0;
	
	float radius = fract(TIME / 2.0) * VIEW_DISTANCE;
	if (dist < radius && dist > radius - 0.1) {
		mix_ratio = 1.0 - (radius - dist);
		
		mix_ratio = clamp(mix_ratio, 0.0, 1.0);
	}
	
	// view_normal is now the normal vector in view/camera space!
	// For example, you can visualize it as color:
	//vec3 base_color = vec3(0.25) * normalize(view_normal) * 0.5 + 0.5;
	ALPHA = 1.0;
	ALBEDO = distance_color * mix(base_color.rgb * normal_roughness.w, vec3(100.0), mix_ratio);
	//ALBEDO = distance_color * base_color * (mix_ratio * 1000.0);
	//ALBEDO = vec3(mix_ratio * 1000.0);
	//EMISSION = vec3(1.0) * (mix_ratio * 100.0);
	//if (linear_depth > 30.0) {
		//ALBEDO = vec3(0.0);
	//} else {
		//ALBEDO = view_normal * 0.5 + 0.5;
	//}
	
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
