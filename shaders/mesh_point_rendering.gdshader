shader_type spatial;

void vertex() {
	POINT_SIZE = 5.0;
}

void fragment() {
	ALBEDO = vec3(10000.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
