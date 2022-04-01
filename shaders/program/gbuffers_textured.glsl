/* 
BSL Shaders v8 Series by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying vec2 texCoord, lmCoord;

varying vec3 normal;
varying vec3 sunVec, upVec, eastVec;

varying vec4 color;

//Uniforms//
uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float blindFactor, nightVision;
uniform float far, near;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float shadowFade, voidFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;

uniform ivec2 eyeBrightnessSmooth;

#ifdef INTEGRATED_EMISSION
uniform ivec2 atlasSize;
#endif

uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;

#ifdef SOFT_PARTICLES
uniform sampler2D depthtex0;
#endif

#ifdef DYNAMIC_HANDLIGHT
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
#endif

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

//Common Functions//
float GetLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

#ifdef SOFT_PARTICLES
float GetLinearDepth(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}
#endif

//Includes//
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/atmospherics/fog.glsl"
#include "/lib/lighting/forwardLighting.glsl"

//Program//
void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;

	if (albedo.a > 0.001) {
		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		vec3 viewPos = ToNDC(screenPos);
		vec3 worldPos = ToWorld(viewPos);
	
		vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));
		
		#ifdef DYNAMIC_HANDLIGHT
		float heldLightValue = max(float(heldBlockLightValue), float(heldBlockLightValue2));
		float handlight = clamp((heldLightValue - 2.0 * length(viewPos)) / 15.0, 0.0, 0.9333);
		lightmap.x = max(lightmap.x, handlight);
		#endif

    	albedo.rgb = pow(albedo.rgb, vec3(2.2));

		#ifdef WHITE_WORLD
		albedo.rgb = vec3(0.35);
		#endif

		float emission = 0.0;
		float NoL = 1.0;
		float NoU = clamp(dot(normal, upVec), -1.0, 1.0);
		float NoE = clamp(dot(normal, eastVec), -1.0, 1.0);
		float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
			  vanillaDiffuse*= vanillaDiffuse;
		
		#ifdef INTEGRATED_EMISSION // almost entirely stolen from complementary, blame me now
			if (atlasSize.x < 900.0) { // We don't want to detect particles from the block atlas
				float lengthAlbedo = length(albedo.rgb);
				vec3 pos = worldPos + cameraPosition;

				if (albedo.b > 1.15 * (albedo.r + albedo.g) && albedo.g > albedo.r * 1.25 && albedo.g < 0.425 && albedo.b > 0.75) // Water Particle
					albedo.rgb = vec3(0.7, 0.9, 1.2) * 2.0 * lengthAlbedo;

				else if (albedo.r == albedo.g && albedo.r - 0.5 * albedo.b < 0.06) { // Underwater Particle
					if (isEyeInWater == 1) {
						albedo.rgb = vec3(0.7, 0.9, 1.2) * 2.0 * lengthAlbedo;
						if (fract(pos.r + pos.g + pos.b) > 0.2) discard;
					}
				}

				else if (max(abs(albedo.r - albedo.b), abs(albedo.b - albedo.g)) < 0.001) { // Grayscale Particles
					if (lengthAlbedo > 0.5 && color.g < 0.5 && color.b > color.r * 1.1 && color.r > 0.3) // Ender Particle, Crying Obsidian Drop
						emission = max(pow(albedo.r, 5.0), 0.1);
					if (lengthAlbedo > 0.5 && color.g < 0.5 && color.r > (color.g + color.b) * 3.0) // Redstone Particle
						lightmap = vec2(0.0);
						emission = max(pow(albedo.r, 5.0), 0.1);
				}
			}
		#endif

		vec3 shadow = vec3(0.0);
		GetLighting(albedo.rgb, shadow, viewPos, worldPos, lightmap, 1.0, NoL, 1.0,
				    1.0, emission, 0.0);

		#if defined FOG && MC_VERSION >= 11500
		Fog(albedo.rgb, viewPos);
		#endif

		#if ALPHA_BLEND == 0
		albedo.rgb = sqrt(max(albedo.rgb, vec3(0.0)));
		#endif
	}

	#ifdef SOFT_PARTICLES
	float linearZ = GetLinearDepth(gl_FragCoord.z) * (far - near);
	float backZ = texture2D(depthtex0, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).r;
	float linearBackZ = GetLinearDepth(backZ) * (far - near);

	float difference = clamp(linearBackZ - linearZ, 0.0, 1.0);
	difference = difference * difference * (3.0 - 2.0 * difference);

	float opaqueThreshold = fract(Bayer64(gl_FragCoord.xy) + frameTimeCounter * 8.0);

	if (albedo.a > 0.999) albedo.a *= float(difference > opaqueThreshold);
	else albedo.a *= difference;
	#endif
	
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = albedo;

	#ifdef SSGI
	/* RENDERTARGETS:0,6,10 */
	gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
	gl_FragData[2] = vec4(albedo.rgb, float(length(albedo.rgb) > 0.99));
	#endif

	#ifdef ADVANCED_MATERIALS
	/* DRAWBUFFERS:0367 */
	gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
	#endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord, lmCoord;

varying vec3 normal;
varying vec3 sunVec, upVec, eastVec;

varying vec4 color;

//Uniforms//
uniform int worldTime;

uniform float frameTimeCounter;
uniform float timeAngle;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView, gbufferModelViewInverse;

#ifdef SOFT_PARTICLES
uniform float far, near;
#endif

//Attributes//
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

//Common Variables//
#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

//Common Functions//
#ifdef SOFT_PARTICLES
float GetLinearDepth(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

float GetLogarithmicDepth(float depth) {
	return -(2.0 * near / depth - (far + near)) / (far - near);
}
#endif

//Includes//
#ifdef WORLD_CURVATURE
#include "/lib/vertex/worldCurvature.glsl"
#endif

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	normal = normalize(gl_NormalMatrix * gl_Normal);
    
	color = gl_Color;

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

    #ifdef WORLD_CURVATURE
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	position.y -= WorldCurvature(position.xz);
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	#else
	gl_Position = ftransform();
    #endif

	#ifdef SOFT_PARTICLES
	gl_Position.z = GetLinearDepth(gl_Position.z / gl_Position.w) * (far - near);
	gl_Position.z -= 0.25;
	gl_Position.z = GetLogarithmicDepth(gl_Position.z / (far - near)) * gl_Position.w;
	#endif
}

#endif