void getIntegratedEmission(inout float emissive, inout float giEmissive, in float mat){
	float newEmissive = 0.0;
	float jitter = 1.0 - sin(frameTimeCounter + cos(frameTimeCounter)) * BLOCKLIGHT_FLICKERING_STRENGTH;

    if (mat > 99.9 && mat < 100.1) { // Emissive Ores
        float stoneDif = max(abs(albedo.r - albedo.g), max(abs(albedo.r - albedo.b), abs(albedo.g - albedo.b)));
        float ore = max(max(stoneDif - 0.175, 0.0), 0.0);
        newEmissive = sqrt(ore) * GLOW_STRENGTH * 0.25;
		giEmissive = sqrt(ore) * GLOW_STRENGTH * jitter;
    } else if (mat > 100.9 && mat < 101.1){ // Crying Obsidian and Respawn Anchor
		newEmissive = (albedo.b - albedo.r) * albedo.r * GLOW_STRENGTH;
        newEmissive *= newEmissive * newEmissive * GLOW_STRENGTH * jitter;
	} else if (mat > 101.9 && mat < 102.1){
        vec3 comPos = fract(worldPos.xyz + cameraPosition.xyz);
             comPos = abs(comPos - vec3(0.5));

        float comPosM = min(max(comPos.x, comPos.y), min(max(comPos.x, comPos.z), max(comPos.y, comPos.z)));
        newEmissive = 0.0;

        if (comPosM < 0.1882) { // Command Block Center
            vec3 dif = vec3(albedo.r - albedo.b, albedo.r - albedo.g, albedo.b - albedo.g);
            dif = abs(dif);
            newEmissive = float(max(dif.r, max(dif.g, dif.b)) > 0.1) * 25.0;
            newEmissive *= float(albedo.r > 0.44 || albedo.g > 0.29);
			newEmissive *= 0.5;
			giEmissive = 3.0;
        }
	} else if (mat > 102.9 && mat < 103.1) { // Warped Stem & Hyphae
        float core = float(albedo.r < 0.1);
        float edge = float(albedo.b > 0.35 && albedo.b < 0.401 && core == 0.0);
        newEmissive = (core * 0.195 + 0.035 * edge);
		newEmissive *= 8.0 * GLOW_STRENGTH;
	} else if (mat > 103.9 && mat < 104.1) { // Crimson Stem & Hyphae
        newEmissive = float(albedo.b < 0.16);
        newEmissive = min(pow(length(albedo.rgb) * length(albedo.rgb), 2.0) * newEmissive * GLOW_STRENGTH, 0.3);
		newEmissive *= 8.0 * GLOW_STRENGTH;
	} else if (mat > 104.9 && mat < 105.1) { // Warped Nether Warts
		newEmissive = pow2(float(albedo.g - albedo.b)) * GLOW_STRENGTH;
	} else if (mat > 105.9 && mat < 106.1) { // Warped Nylium
		newEmissive = float(albedo.g > albedo.b && albedo.g > albedo.r) * pow(float(albedo.g - albedo.b), 3.0) * GLOW_STRENGTH;
	} else if (mat > 107.9 && mat < 108.1) { // Amethyst
		newEmissive = float(length(albedo.rgb) > 0.975) * 0.25 * GLOW_STRENGTH * jitter;
	} else if (mat > 109.9 && mat < 110.1) { // Glow Lichen
		newEmissive = (1.0 - lightmap.y) * float(albedo.r > albedo.g || albedo.r > albedo.b) * 3.0;
	} else if (mat > 110.9 && mat < 111.1) {
		newEmissive = float(albedo.r > albedo.g && albedo.r > albedo.b) * 0.2 * GLOW_STRENGTH;
	} else if (mat > 111.9 && mat < 112.1) { // Soul Emissives
		newEmissive = float(albedo.b > albedo.r || albedo.b > albedo.g) * 0.5 * GLOW_STRENGTH;
	} else if (mat > 112.9 && mat < 113.1) { // Brewing Stand
		newEmissive = float(albedo.r > 0.65) * 0.5 * GLOW_STRENGTH;
	} else if (mat > 113.9 && mat < 114.1) { // Glow berries
		newEmissive = float(albedo.r > albedo.g || albedo.r > albedo.b) * GLOW_STRENGTH;
	} else if (mat > 114.9 && mat < 115.1) { // Torches
		newEmissive = GLOW_STRENGTH * GLOW_STRENGTH * jitter;
	} else if (mat > 115.9 && mat < 116.1) { // Lantern
		newEmissive = float(albedo.r > albedo.b || albedo.r > albedo.g) * 2.0 * GLOW_STRENGTH * jitter;
	} else if (mat > 116.9 && mat < 117.1) { // Chorus
		newEmissive = float(albedo.r > albedo.b || albedo.r > albedo.g) * float(albedo.b > 0.575) * 0.25 * GLOW_STRENGTH;
	} else if (mat > 117.9 && mat < 118.1) {
		newEmissive = 0.0;
	}

	#ifdef OVERWORLD
	if (isPlant > 0.9 && isPlant < 1.1){ // Flowers
		newEmissive = float(albedo.b > albedo.g || albedo.r > albedo.g) * GLOW_STRENGTH * 0.1;
	}
	#endif

	emissive += newEmissive;
}