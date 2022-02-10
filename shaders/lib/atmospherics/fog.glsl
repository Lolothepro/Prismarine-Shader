#ifdef OVERWORLD
vec3 GetFogColor(vec3 viewPos) {
	vec3 nViewPos = normalize(viewPos);

    float VoU = clamp(dot(nViewPos, upVec), -1.0, 1.0);

	float density = 0.25;
    float nightDensity = 0.75;
    float weatherDensity = exp2(1.0);
    
    float exposure = exp2(timeBrightness * 0.75 - 1.00);
    float nightExposure = exp2(-3.5);

	float baseGradient = exp(-(VoU * 0.5 + 0.5) * 0.5 / density);
	float ug = mix(clamp((cameraPosition.y - 48.0) / 16.0, 0.0, 1.0), 1.0, eBS);

    vec3 fog = mix(GetSkyColor(viewPos, false), skyCol, (1.0 - timeBrightness) * (1.0 - eBS)) * 4.0 * baseGradient / SKY_I;
	#ifdef FOG_PERBIOME
	fog = mix(fog, fogColBiome * baseGradient, 1.0 - ug);
	#endif
    fog = fog / sqrt(fog * fog + 1.0) * exposure * sunVisibility * SKY_I;

	float nightGradient = exp(-(VoU * 0.5 + 0.5) * 0.35 / nightDensity);
    vec3 nightFog = lightNight * lightNight * 6.0 * nightGradient * nightExposure;
    fog = mix(nightFog, fog, sunVisibility * sunVisibility);

    float rainGradient = exp(-(VoU * 0.5 + 0.5) * 0.25 / weatherDensity);
    vec3 weatherFog = weatherCol.rgb * weatherCol.rgb;
    weatherFog *= GetLuminance(ambientCol / (weatherFog)) * (0.4 * sunVisibility + 0.2);
    fog = mix(fog, weatherFog * rainGradient, rainStrength);

	fog = mix(minLightCol * 0.5, fog, ug);

	return fog;
}
#endif

void NormalFog(inout vec3 color, vec3 viewPos) {
	#if DISTANT_FADE > 0
	#if DISTANT_FADE_STYLE == 0
	float fogFactor = length(viewPos);
	#else
	vec4 worldPos = gbufferModelViewInverse * vec4(viewPos, 1.0);
	worldPos.xyz /= worldPos.w;
	float fogFactor = length(worldPos.xz);
	#endif
	#endif
	
	#ifdef OVERWORLD
	float density = (1.0 - timeBrightness * 0.75) * FOG_DENSITY * (1.0 + rainStrength * 0.25);
	float fog = length(viewPos) * density / 256.0;
	float clearDay = sunVisibility * (1.0 - rainStrength);
	fog *= mix(1.0, (0.5 * rainStrength + 1.0) / (4.0 * clearDay + 1.0) * eBS, eBS);
	fog = 1.0 - exp(-2.0 * pow(fog, 0.05 * clearDay * eBS + 1.35));

	vec3 pos = ToWorld(viewPos.xyz) + cameraPosition.xyz;
	float worldHeightFactor = clamp(pos.y * 0.0075, 0.0, 1.0);
	fog *= (1.0 - worldHeightFactor) * 1.25;

	vec3 fogColor = GetFogColor(viewPos);

	#if DISTANT_FADE == 1 || DISTANT_FADE == 3
	if(isEyeInWater == 0.0){
		#if MC_VERSION >= 11800
		float fogOffset = 0.0;
		#else
		float fogOffset = 12.0;
		#endif

		fogOffset *= 1.0 - rainStrength * 0.75;

		float vanillaFog = 1.0 - (far - (fogFactor + fogOffset)) * 5.0 / (FOG_DENSITY * 0.5 * far);
		vanillaFog = clamp(vanillaFog, 0.0, 1.0);
	
		if (vanillaFog > 0.0){
			vec3 vanillaFogColor = GetSkyColor(viewPos, false);
			vanillaFogColor *= 1.0 + nightVision;

			fogColor *= fog;
			
			fog = mix(fog, 1.0, vanillaFog);
			if (fog > 0.0) fogColor = mix(fogColor, vanillaFogColor, vanillaFog) / fog;
		}
	}
	#endif
	#endif

	#ifdef NETHER
	float viewLength = length(viewPos);
	float fog = 2.0 * pow(viewLength * FOG_DENSITY / 256.0, 1.5);
	#if DISTANT_FADE == 2 || DISTANT_FADE == 3
	fog += 6.0 * pow4(fogFactor * 1.5 / far);
	#endif
	fog = 1.0 - exp(-fog);
	vec3 fogColor = netherCol.rgb * 0.04;
	#endif

	#ifdef END
	discard;
	#endif

	color = mix(color, fogColor, fog * (1.0 - float(isEyeInWater > 0.9 && isEyeInWater < 1.1)));
}

void BlindFog(inout vec3 color, vec3 viewPos) {
	float fog = length(viewPos) * (blindFactor * 0.2);
	fog = (1.0 - exp(-6.0 * fog * fog * fog)) * blindFactor;
	color = mix(color, vec3(0.0), fog);
}

vec3 denseFogColor[2] = vec3[2](
	vec3(1.0, 0.3, 0.01),
	vec3(0.1, 0.14, 0.24) * clamp(timeBrightness, 0.1, 1.0)
);

void DenseFog(inout vec3 color, vec3 viewPos) {
	float fog = length(viewPos) * 0.5;
	fog = (1.0 - exp(-4.0 * fog * fog * fog));
	color = mix(color, denseFogColor[isEyeInWater - 2], fog);
}

void Fog(inout vec3 color, vec3 viewPos) {
	NormalFog(color, viewPos);
	if (isEyeInWater > 1) DenseFog(color, viewPos);
	if (blindFactor > 0.0) BlindFog(color, viewPos);
}
