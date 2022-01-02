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

#if defined OVERWORLD || defined END
varying vec3 sunVec, upVec;
#endif

//Uniforms//
uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float blindFactor, nightVision;
uniform float far, near;
uniform float frameTimeCounter;

#if defined OVERWORLD || defined END
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
#endif

uniform float viewWidth, viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;

#if defined LIGHT_SHAFT || defined NETHER_SMOKE || defined END_SMOKE
uniform mat4 gbufferModelViewInverse;

uniform sampler2D colortex1;
uniform sampler2D depthtex1;
#endif

#if defined LIGHTSHAFT_CLOUDY_NOISE || defined NETHER_SMOKE || defined END_SMOKE || defined VOLUMETRIC_CLOUDS
uniform sampler2D noisetex;
#endif

#ifdef LIGHT_SHAFT
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif

//Optifine Constants//
const bool colortex5Clear = false;

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;

#if defined OVERWORLD || defined END
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#endif

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

//Includes//
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/atmospherics/waterFog.glsl"

#if defined LIGHT_SHAFT || defined NETHER_SMOKE || defined END_SMOKE || defined VOLUMETRIC_CLOUDS
#include "/lib/atmospherics/stuffForVolumetrics.glsl"
#include "/lib/util/dither.glsl"
#endif

#ifdef VOLUMETRIC_CLOUDS
#include "/lib/atmospherics/volumetricClouds.glsl"
#endif

#ifdef LIGHT_SHAFT
#include "/lib/atmospherics/volumetricLight.glsl"
#endif

#if defined END_SMOKE || defined NETHER_SMOKE
#include "/lib/atmospherics/volumetricSmoke.glsl"
#endif

//Program//
void main() {
    vec3 color = texture2D(colortex0, texCoord).rgb;

	float z0 = texture2D(depthtex0, texCoord).r;

	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	if (isEyeInWater == 1.0) {
		vec4 waterFog = GetWaterFog(viewPos.xyz);
		waterFog.a = mix(waterAlpha * 0.5, 1.0, waterFog.a);
		color.rgb = mix(sqrt(color.rgb), sqrt(waterFog.rgb), waterFog.a);
		color.rgb *= color.rgb;
	}

	#if defined LIGHT_SHAFT || defined NETHER_SMOKE || defined END_SMOKE
    vec4 translucent = texture2D(colortex1, texCoord);

	float dither = InterleavedGradientNoiseVL();
	float z1 = texture2D(depthtex1, texCoord).r;
	#endif

	vec3 vl = vec3(0.0);

	//Overworld Volumetric Light
	#ifdef LIGHT_SHAFT
	vl += GetLightShafts(z0, z1, translucent.rgb, dither);
	#endif
	
	//Nether & End Smoke
	#if defined NETHER_SMOKE || defined END_SMOKE
	vl += GetVolumetricSmoke(z0, z1, viewPos.xyz);
	#endif

	//Volumetric Clouds
	#ifdef VOLUMETRIC_CLOUDS
	getVolumetricCloud(viewPos.xyz, z1, z0, InterleavedGradientNoiseVL(), color, translucent);
	#endif

	#if ALPHA_BLEND == 0
	color.rgb *= color.rgb;
	#endif

    /* DRAWBUFFERS:01 */
	gl_FragData[0] = vec4(color.rgb, 1.0);
	gl_FragData[1] = vec4(vl, 1.0);
	
    #ifdef REFLECTION_PREVIOUS
	vec3 reflectionColor = pow(color.rgb, vec3(0.125)) * 0.5;

    /*DRAWBUFFERS:015*/
	gl_FragData[2] = vec4(reflectionColor, float(z0 < 1.0));
	#endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

#if defined OVERWORLD || defined END
varying vec3 sunVec, upVec;
#endif

//Uniforms//
#if defined OVERWORLD || defined END
uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();

	#if defined OVERWORLD || defined END
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	#endif
}

#endif
