struct TriplanarMappingResult {
	vec3 triplanar_pos;
	vec3 triplanar_power_normal;
};

TriplanarMappingResult triplanar_vertex(
	mat4 p_model_matrix,
	vec3 p_vertex,
	vec3 p_normal, 
	float p_blend_sharpness, 
	vec3 p_scale, 
	vec3 p_offset
) {
	vec3 power_normal = pow(abs(p_normal), vec3(p_blend_sharpness));
	vec3 triplanar_pos = (p_model_matrix * vec4(p_vertex, 1.0)).xyz * p_scale + p_offset;
	power_normal /= dot(power_normal, vec3(1.0));
	triplanar_pos *= vec3(1.0, -1.0, 1.0);
	
	TriplanarMappingResult result;
	result.triplanar_pos = triplanar_pos;
	result.triplanar_power_normal = power_normal;
	
	return result;
}

vec4 triplanar_texture(sampler3D p_sampler, vec3 p_weights, vec3 p_triplanar_pos, float p_noise_index) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, vec3(p_triplanar_pos.xy, p_noise_index)) * p_weights.z;
	samp += texture(p_sampler, vec3(p_triplanar_pos.xz, p_noise_index)) * p_weights.y;
	samp += texture(p_sampler, vec3(p_triplanar_pos.zy * vec2(-1.0, 1.0), p_noise_index)) * p_weights.x;
	//samp += hex2colTex(p_sampler, vec3(p_triplanar_pos.xy, noise_index), rot_strength, contrast_adjust) * p_weights.z;
	//samp += hex2colTex(p_sampler, vec3(p_triplanar_pos.xz, noise_index), rot_strength, contrast_adjust) * p_weights.y;
	//samp += hex2colTex(p_sampler, vec3(p_triplanar_pos.zy * vec2(-1.0, 1.0), noise_index), rot_strength, contrast_adjust) * p_weights.x;
	return samp;
}
