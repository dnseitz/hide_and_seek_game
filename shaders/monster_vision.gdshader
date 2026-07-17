shader_type spatial;

render_mode unshaded, fog_disabled;

const float VIEW_DISTANCE = 30.0;

uniform vec3 pulse_start_point = vec3(0.0);

uniform float pulse_radius = 0.0;
uniform float pulse_brightness = 0.0;
uniform float sonic_pulse_width : hint_range(0.0, 1.0, 0.001) = 0.1;

uniform float environment_visibility : hint_range(0.0, 1.0, 0.001) = 0.0;

uniform float visible_radius = 0.0;
uniform float visible_radius_start_feather = 10.0;
uniform float visible_radius_end_feather = 1.0;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture;

void vertex() {
	// Position quad to cover entire screen
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

/// Calculate how visible a point is based on how far it is from the start of
/// a radius.
///
/// - Parameters:
///   - distance_from_start: The distance a point is from the center of the radius.
///   - radius: The radius of the sphere measured.
///   - start_feather: The feathering factor toward the center of the radius.
///   - end_feather: The feathering factor away from the center of the radius.
///
/// - Returns: A value between [0.0, 1.0] indicating how visible the point should
///     be based on its distance from the center of the radius.
float visibility_for_distance(float distance_from_start, float radius, float start_feather, float end_feather) {
	float visibility_start = smoothstep(
		radius - start_feather,
		radius, 
		distance_from_start
	);
	//return visibility_start;
	float visibility_end = 1.0 - smoothstep(
		radius,
		radius + end_feather,
		distance_from_start
	);
	//
	//return visibility_end;
	//
	return visibility_start * visibility_end * environment_visibility;
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	//float distance_from_center = length(vec3(view.xy, linear_depth));
	
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	
	float dist = distance(world_position, pulse_start_point);
	
	//ALBEDO.rgb = vec3(fract(linear_depth));
	
	// 1. Sample the normal roughness texture
	vec4 normal_roughness = texture(normal_roughness_texture, SCREEN_UV);
	vec4 base_color = texture(screen_texture, SCREEN_UV);
	
	// 2. Unpack the normal vector (stored in RGB)
	vec3 view_normal = normal_roughness.rgb * 2.0 - 1.0;
	
	vec3 visibility_color = vec3(visibility_for_distance(
		dist, 
		visible_radius, 
		visible_radius_start_feather, 
		visible_radius_end_feather
	));
	
	//float dist = distance(world_position, CAMERA_POSITION_WORLD);
	float mix_ratio = 0.0;
	
	//float radius = fract(TIME / 2.0) * VIEW_DISTANCE;
	if (dist < pulse_radius && dist > pulse_radius - sonic_pulse_width) {
		mix_ratio = 1.0 - (pulse_radius - dist);
		
		mix_ratio = clamp(mix_ratio, 0.0, 1.0);
		//visibility_color = max(visibility_color, vec3(mix_ratio)); // Try this
	}
	
	// view_normal is now the normal vector in view/camera space!
	// For example, you can visualize it as color:
	//vec3 base_color = vec3(0.25) * normalize(view_normal) * 0.5 + 0.5;
	//ALPHA = 1.0;
	ALBEDO = visibility_color * mix(
		base_color.rgb / 2.0, // * normal_roughness.w, -- Can use roughness channel for special effects in monster-mode
		vec3(pulse_brightness), 
		mix_ratio
	);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
