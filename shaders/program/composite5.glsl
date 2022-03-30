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
uniform float viewHeight, aspectRatio;

uniform sampler2D colortex0;

#ifdef BLOOM
//Optifine Constants//
const bool colortex0MipmapEnabled = true;

//Common Variables//
float ph = 0.8 / min(360.0, viewHeight);
float pw = ph / aspectRatio;

float weight[5] = float[5](1.0, 4.0, 6.0, 4.0, 1.0);

//Common Functions//
vec3 BloomTile(float lod, vec2 coord, vec2 offset) {
	vec3 bloom = vec3(0.0), temp = vec3(0.0);
	float scale = exp2(lod);
	coord = (coord - offset) * scale;
	float padding = 0.5 + 0.005 * scale;

	if (abs(coord.x - 0.5) < padding && abs(coord.y - 0.5) < padding) {
		for(int i = 0; i < 5; i++) {
			for(int j = 0; j < 5; j++) {
				float wg = weight[i] * weight[j];
				#ifdef ANAMORPHIC_BLOOM
				vec2 pixelOffset = vec2((float(i) - 2.0) * pw, 0.0);
				#else
				vec2 pixelOffset = vec2((float(i) - 2.0) * pw, (float(j) - 2.0) * ph);
				#endif
				vec2 sampleCoord = coord + pixelOffset * scale;
				bloom += texture2D(colortex0, sampleCoord).rgb * wg;
			}
		}
		bloom /= 256.0;
	}

	return sqrt(sqrt(bloom)) * 0.25;
}

//Includes//
#include "/lib/util/dither.glsl"
#endif

//Program//
void main() {
	#ifdef BLOOM
	vec2 bloomCoord = texCoord * viewHeight * 0.8 / min(360.0, viewHeight);
	vec3 blur =  BloomTile(1.0, bloomCoord, vec2(0.0      , 0.0   ));
	     blur += BloomTile(2.0, bloomCoord, vec2(0.51     , 0.0   ));
	     blur += BloomTile(3.0, bloomCoord, vec2(0.51     , 0.26  ));
	     blur += BloomTile(4.0, bloomCoord, vec2(0.645    , 0.26  ));
	     blur += BloomTile(5.0, bloomCoord, vec2(0.7175   , 0.26  ));
		
		 blur = clamp(blur + (Bayer64(gl_FragCoord.xy) - 0.5) / 64.0, vec3(0.0), vec3(1.0));
	#else
	vec3 blur = texture2D(colortex0, texCoord.xy).rgb;
	#endif

    /* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(blur, 1.0);
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