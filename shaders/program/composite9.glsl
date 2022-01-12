/* 
BSL Shaders v8 Series by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

#ifdef SSGI
//Varyings//
varying vec2 texCoord;

//Uniforms//
uniform sampler2D colortex11;

uniform sampler2D colortex13, depthtex1;
uniform float viewWidth, viewHeight;
uniform int frameCounter;

uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;

#ifdef DENOISE
uniform sampler2D colortex6;
uniform sampler2D depthtex0;
#endif

//Includes//
#include "/lib/util/temporalAccumulation.glsl"

#ifdef DENOISE
#include "/lib/util/encode.glsl"
#include "/lib/filters/normalAwareBlur.glsl"
#endif

//Program//
void main() {
    vec3 gi = texture2D(colortex11, texCoord).rgb;
    vec4 prev = vec4(texture2DLod(colortex13, texCoord, 0.0).r, 0.0, 0.0, 0.0);
    prev = TemporalAccumulation(gi.rgb, prev.r, colortex13);

    #ifdef DENOISE
    gi = NormalAwareBlur().rgb;
    #endif

    /* RENDERTARGETS:11,13 */
    gl_FragData[0] = vec4(gi, 1.0);
    gl_FragData[1] = vec4(prev);
}

#else

void main(){
    discard;
}

#endif

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