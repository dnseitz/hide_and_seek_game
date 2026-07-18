shader_type spatial;

#include "triplanar_mapping.gdshaderinc"

uniform sampler3D noise_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float scroll_speed = 1.0;

varying vec3 uv1_triplanar_pos;
varying vec3 uv2_triplanar_pos;

uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv1_power_normal;
uniform float uv2_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv2_power_normal;

// TODO: Make these uniforms global and randomize on each pulse for even more jittering
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

void vertex() {
	vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;

	TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	TANGENT = inverse(MODEL_NORMAL_MATRIX) * normalize(TANGENT);

	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	BINORMAL = inverse(MODEL_NORMAL_MATRIX) * normalize(BINORMAL);
	
	// UV1 Triplanar: Enabled (with World Triplanar)
	TriplanarMappingResult uv_1_mapping = triplanar_vertex(
		MODEL_MATRIX,
		VERTEX,
		normal,
		uv1_blend_sharpness,
		uv1_scale,
		uv1_offset
	);
	uv1_triplanar_pos = uv_1_mapping.triplanar_pos;
	uv1_power_normal = uv_1_mapping.triplanar_power_normal;
	//uv1_power_normal = pow(abs(normal), vec3(uv1_blend_sharpness));
	//uv1_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv1_scale + uv1_offset;
	//uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	//uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);

	// UV2 Triplanar: Enabled (with World Triplanar)
	TriplanarMappingResult uv_2_mapping = triplanar_vertex(
		MODEL_MATRIX,
		VERTEX,
		normal,
		uv2_blend_sharpness,
		uv2_scale,
		uv2_offset
	);
	uv2_triplanar_pos = uv_2_mapping.triplanar_pos;
	uv2_power_normal = uv_2_mapping.triplanar_power_normal;
}

void fragment() {
	vec2 base_uv2 = UV2;
	
	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(
		triplanar_texture(
			noise_texture, 
			uv1_power_normal,
			uv1_triplanar_pos,
			(TIME * scroll_speed)
		), 
		roughness_texture_channel
	);

	// Detail: Enabled
	float detail_roughness_tex = dot(
		triplanar_texture(
			noise_texture, 
			uv2_power_normal, 
			uv2_triplanar_pos,
			(TIME * scroll_speed / 2.0)
		),
		roughness_texture_channel
	);
	
	ROUGHNESS = mix(roughness_tex, detail_roughness_tex, 0.5);
}
