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

//Uniforms//
#ifdef DOF
uniform float viewWidth, viewHeight, aspectRatio;
uniform float centerDepthSmooth;

uniform mat4 gbufferProjection;

uniform sampler2D depthtex1;
#endif

#ifdef WATER_REFRACTION
uniform int worldTime;

uniform float frameTimeCounter;

uniform vec3 cameraPosition;

uniform sampler2D depthtex0, colortex9, noisetex;

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;
#endif

uniform sampler2D colortex0;

//Optifine Constants//
const bool colortex0MipmapEnabled = true;

//Common Variables//
#ifdef WATER_REFRACTION
#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif
#endif

#ifdef DOF
vec2 dofOffsets[60] = vec2[60](
	vec2( 0.0    ,  0.25  ),
	vec2(-0.2165 ,  0.125 ),
	vec2(-0.2165 , -0.125 ),
	vec2( 0      , -0.25  ),
	vec2( 0.2165 , -0.125 ),
	vec2( 0.2165 ,  0.125 ),
	vec2( 0      ,  0.5   ),
	vec2(-0.25   ,  0.433 ),
	vec2(-0.433  ,  0.25  ),
	vec2(-0.5    ,  0     ),
	vec2(-0.433  , -0.25  ),
	vec2(-0.25   , -0.433 ),
	vec2( 0      , -0.5   ),
	vec2( 0.25   , -0.433 ),
	vec2( 0.433  , -0.2   ),
	vec2( 0.5    ,  0     ),
	vec2( 0.433  ,  0.25  ),
	vec2( 0.25   ,  0.433 ),
	vec2( 0      ,  0.75  ),
	vec2(-0.2565 ,  0.7048),
	vec2(-0.4821 ,  0.5745),
	vec2(-0.51295,  0.375 ),
	vec2(-0.7386 ,  0.1302),
	vec2(-0.7386 , -0.1302),
	vec2(-0.51295, -0.375 ),
	vec2(-0.4821 , -0.5745),
	vec2(-0.2565 , -0.7048),
	vec2(-0      , -0.75  ),
	vec2( 0.2565 , -0.7048),
	vec2( 0.4821 , -0.5745),
	vec2( 0.51295, -0.375 ),
	vec2( 0.7386 , -0.1302),
	vec2( 0.7386 ,  0.1302),
	vec2( 0.51295,  0.375 ),
	vec2( 0.4821 ,  0.5745),
	vec2( 0.2565 ,  0.7048),
	vec2( 0      ,  1     ),
	vec2(-0.2588 ,  0.9659),
	vec2(-0.5    ,  0.866 ),
	vec2(-0.7071 ,  0.7071),
	vec2(-0.866  ,  0.5   ),
	vec2(-0.9659 ,  0.2588),
	vec2(-1      ,  0     ),
	vec2(-0.9659 , -0.2588),
	vec2(-0.866  , -0.5   ),
	vec2(-0.7071 , -0.7071),
	vec2(-0.5    , -0.866 ),
	vec2(-0.2588 , -0.9659),
	vec2(-0      , -1     ),
	vec2( 0.2588 , -0.9659),
	vec2( 0.5    , -0.866 ),
	vec2( 0.7071 , -0.7071),
	vec2( 0.866  , -0.5   ),
	vec2( 0.9659 , -0.2588),
	vec2( 1      ,  0     ),
	vec2( 0.9659 ,  0.2588),
	vec2( 0.866  ,  0.5   ),
	vec2( 0.7071 ,  0.7071),
	vec2( 0.5    ,  0.8660),
	vec2( 0.2588 ,  0.9659)
);

//Common Functions//
vec3 DepthOfField(vec3 color, float z) {
	vec3 dof = vec3(0.0);
	float hand = float(z < 0.56);
	
	float fovScale = gbufferProjection[1][1] / 1.37;
	float coc = max(abs(z - centerDepthSmooth) * DOF_STRENGTH - 0.01, 0.0);
	coc = coc / sqrt(coc * coc + 0.1);
	
	if (coc > 0.0 && hand < 0.5) {
		for(int i = 0; i < 60; i++) {
			vec2 offset = dofOffsets[i] * coc * 0.015 * fovScale * vec2(1.0 / aspectRatio, 1.0);
			float lod = log2(viewHeight * aspectRatio * coc * fovScale / 320.0);
			dof += texture2DLod(colortex0, texCoord + offset, lod).rgb;
		}
		dof /= 60.0;
	}
	else dof = color;
	return dof;
}
#endif

#ifdef WATER_REFRACTION
vec3 ToWorld(vec3 pos) {
	return mat3(gbufferModelViewInverse) * pos + gbufferModelViewInverse[3].xyz;
}
#endif

//Includes//
#ifdef WATER_REFRACTION
#include "/lib/lighting/refraction.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2DLod(colortex0, texCoord, 0.0).rgb;
	
	#ifdef WATER_REFRACTION
	float z0 = texture2D(depthtex0, texCoord).r;

    vec4 waterData = texture2D(colortex9, texCoord);

    if (waterData.a > 0.5){
        vec4 screenPos = vec4(texCoord, z0, 1.0);
        vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
        viewPos /= viewPos.w;

        vec3 worldPos = ToWorld(viewPos.xyz);
        vec3 waterPos = worldPos + cameraPosition;

        vec2 refractCoord = getRefraction(texCoord, waterPos, waterData.b, waterData.g);
        color = texture2D(colortex0, refractCoord).rgb;
    }
	#endif

	#ifdef DOF
	float z1 = texture2D(depthtex1, texCoord.st).x;

	color = DepthOfField(color, z1);
	#endif
	
    /*DRAWBUFFERS:0*/
	gl_FragData[0] = vec4(color, 1.0);
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();
}

#endif