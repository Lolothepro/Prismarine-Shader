/* 
BSL Shaders v8 Series by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying vec2 texCoord;
varying vec3 upVec, sunVec;

//Uniforms//
uniform int isEyeInWater;

#ifdef WATER_ABSORPTION
uniform float nightVision, blindFactor;
uniform float far;
#endif

#if defined OVERWORLD
uniform float rainStrength, timeAngle, timeBrightness;
#endif

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform sampler2D colortex12;
uniform sampler2D colortex0, colortex1;
uniform sampler2D depthtex0, depthtex1;

uniform mat4 gbufferModelViewInverse;

#ifdef WATER_ABSORPTION
uniform mat4 gbufferProjectionInverse;
#endif

#if defined OVERWORLD
#if REFLECTION == 2
uniform sampler2D colortex9;
#endif
#endif

//Common Variables//
#ifdef WATER_ABSORPTION
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
#endif

//Common Functions//
float GetLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

//Includes//
#ifdef WATER_ABSORPTION
#include "/lib/util/dither.glsl"
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/atmospherics/waterAbsorption.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/atmospherics/fog.glsl"
#endif

//Program//
void main() {
	vec4 color = texture2D(colortex0, texCoord);
	vec4 translucent = texture2D(colortex1, texCoord);

	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;

	vec4 waterData = texture2D(colortex12, texCoord);

	#if defined OVERWORLD
	#if REFLECTION == 2
	vec4 reflection = texture2D(colortex9, texCoord);
	#endif

	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	if (waterData.a > 0.5 && isEyeInWater == 0){
		#ifdef WATER_ABSORPTION
		if (z0 > 0.56 && z0 < 1.0){
			vec4 screenPosZ1 = vec4(texCoord, z1, 1.0);
			vec4 viewPosZ1 = gbufferProjectionInverse * (screenPosZ1 * 2.0 - 1.0);
			viewPosZ1 /= viewPosZ1.w;

			color.rgb = getWaterAbsorption(color.rgb, waterColor.rgb, viewPos.xyz, viewPosZ1.xyz, waterData.g);
		}
		#endif
	}

	if (waterData.r > 0.5 || waterData.a > 0.5){
		#if REFLECTION == 2
		color.rgb = mix(color.rgb, reflection.rgb, reflection.a);
		color.a = mix(color.a, 1.0, reflection.a);
		#endif
	}
	#endif

	#ifdef WATER_ABSORPTION
	if (z0 < z1) Fog(color.rgb, viewPos.xyz);
	#endif

    /*DRAWBUFFERS:0*/
	gl_FragData[0] = color;
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;
varying vec3 sunVec, upVec;

//Uniforms//
uniform float timeAngle;
uniform mat4 gbufferModelView;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
}

#endif