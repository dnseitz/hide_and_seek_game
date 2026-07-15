shader_type spatial;

#include "tiling_helper.gdshaderinc"

uniform sampler3D noise_texture : source_color, filter_linear_mipmap, repeat_enable;
//uniform sampler3D noise_texture : source_color;
uniform float scroll_speed = 1.0;
//uniform vec2 scroll_speed = vec2(0.1, 0.05);

varying vec3 uv1_triplanar_pos;

uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001) = 1.0;
varying vec3 uv1_power_normal;

uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);

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
	uv1_power_normal = pow(abs(normal), vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv1_scale + uv1_offset;
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

vec4 triplanar_texture(sampler3D p_sampler, vec3 p_weights, vec3 p_triplanar_pos, float noise_index) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, vec3(p_triplanar_pos.xy, noise_index)) * p_weights.z;
	samp += texture(p_sampler, vec3(p_triplanar_pos.xz, noise_index)) * p_weights.y;
	samp += texture(p_sampler, vec3(p_triplanar_pos.zy * vec2(-1.0, 1.0), noise_index)) * p_weights.x;
	//samp += hex2colTex(p_sampler, vec3(p_triplanar_pos.xy, noise_index), rot_strength, contrast_adjust) * p_weights.z;
	//samp += hex2colTex(p_sampler, vec3(p_triplanar_pos.xz, noise_index), rot_strength, contrast_adjust) * p_weights.y;
	//samp += hex2colTex(p_sampler, vec3(p_triplanar_pos.zy * vec2(-1.0, 1.0), noise_index), rot_strength, contrast_adjust) * p_weights.x;
	return samp;
}

void fragment() {
	vec2 scrolled_uv = UV + scroll_speed * sin(TIME) * vec2(1.0, 1.0);
	
	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(
		triplanar_texture(
			noise_texture, 
			uv1_power_normal, 
			uv1_triplanar_pos,
			TIME * scroll_speed// * uv1_triplanar_pos.x
		), 
		roughness_texture_channel
	);
	ROUGHNESS = roughness_tex;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
