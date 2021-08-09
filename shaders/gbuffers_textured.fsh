#version 120

//you may notice that terrain is actually brighter during the day than it is at night.
//this is intended.
//black fog on top of black terrain doesn't look very good imo.
//terrain needs to be bright at night so that fog is visible.
//on the other hand, bright fog on top of bright terrain also doesn't look that good imo.
//that's why daytime terrain is darker than nighttime terrain.
//still, they're both configurable, so you can play around with both values to see how they look.
#define DAY_TERRAIN_BRIGHTNESS 0.125 //At 0, the terrain is pitch black. At 1, the terrain is normal brightness. [0.0 0.0625 0.125 0.1875 0.25 0.3125 0.375 0.4375 0.5 0.5625 0.625 0.6875 0.75 0.8125 0.875 0.9375 1.0]
#define NIGHT_TERRAIN_BRIGHTNESS 0.375 //At 0, the terrain is pitch black. At 1, the terrain is normal brightness. [0.0 0.0625 0.125 0.1875 0.25 0.3125 0.375 0.4375 0.5 0.5625 0.625 0.6875 0.75 0.8125 0.875 0.9375 1.0]

//nighttime IS however less saturated than night.
#define DAY_TERRAIN_SATURATION 0.5 //At 0, the terrain is black and white. At 1, the terrain is normal colored. [0.0 0.0625 0.125 0.1875 0.25 0.3125 0.375 0.4375 0.5 0.5625 0.625 0.6875 0.75 0.8125 0.875 0.9375 1.0]
#define NIGHT_TERRAIN_SATURATION 0.25 //At 0, the terrain is black and white. At 1, the terrain is normal colored. [0.0 0.0625 0.125 0.1875 0.25 0.3125 0.375 0.4375 0.5 0.5625 0.625 0.6875 0.75 0.8125 0.875 0.9375 1.0]

//as you might expect, daytime fog is brighter than nighttime fog.
#define DAY_FOG_BRIGHTNESS 0.5 //At 0, there is no fog. At 1, there is a LOT of fog. [0.0 0.0625 0.125 0.1875 0.25 0.3125 0.375 0.4375 0.5 0.5625 0.625 0.6875 0.75 0.8125 0.875 0.9375 1.0]
#define NIGHT_FOG_BRIGHTNESS 0.0 //At 0, there is no fog. At 1, there is a LOT of fog. [0.0 0.0625 0.125 0.1875 0.25 0.3125 0.375 0.4375 0.5 0.5625 0.625 0.6875 0.75 0.8125 0.875 0.9375 1.0]

//by default, fog is the same density during the day and the night.
//I think 0.125 is a good number here, but as usual you're welcome to change it.
#define DAY_FOG_DENSITY 0.125 //At 0, there is no fog. At 1, there is a LOT of fog. [0.0 0.00390625 0.0078125 0.015625 0.03125 0.0625 0.125 0.25 0.5 1.0]
#define NIGHT_FOG_DENSITY 0.125 //At 0, there is no fog. At 1, there is a LOT of fog. [0.0 0.00390625 0.0078125 0.015625 0.03125 0.0625 0.125 0.25 0.5 1.0]

uniform float dayTime;
uniform float frameTimeCounter;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform sampler2D gaux1; //dither
uniform sampler2D lightmap;
uniform sampler2D shadowtex0;
uniform sampler2D texture;


varying vec2 lmcoord;
varying vec2 texcoord;
varying vec3 lightColor;
varying vec3 shadowColor;
varying vec3 pos;
varying vec4 glcolor;
varying vec4 shadowPos;

#include "/distort.glsl"

float getLightAmount() {
	vec2 coord = shadowPos.xy * shadowMapResolution;
	vec2 f = fract(coord);
	coord -= f; //floor
	vec2 a = coord / shadowMapResolution;
	vec2 b = (coord + 1.0) / shadowMapResolution;
	f = f * f * (3.0 - 2.0 * f); //smooth
	return mix(
		mix(
			step(shadowPos.z, texture2D(shadowtex0, vec2(a.x, a.y)).r),
			step(shadowPos.z, texture2D(shadowtex0, vec2(b.x, a.y)).r),
			f.x
		),
		mix(
			step(shadowPos.z, texture2D(shadowtex0, vec2(a.x, b.y)).r),
			step(shadowPos.z, texture2D(shadowtex0, vec2(b.x, b.y)).r),
			f.x
		),
		f.y
	);
}

void main() {
	vec4 sampleColor = texture2D(texture, texcoord) * glcolor;
	if (sampleColor.a < 0.1) discard;
	vec4 whiteColor;
	whiteColor.rgb = shadowPos.w > 0.5 ? mix(shadowColor, lightColor, getLightAmount()) : shadowColor;
	whiteColor.a = step(0.1, texture2D(texture, texcoord).a * glcolor.a);
	vec4 color = mix(whiteColor, sampleColor, lmcoord.x);
	// vec4 color = texture2D(texture, texcoord) * glcolor;


	
	//apply saturation
	color.rgb = mix(
		//the average brightness of the pixel. this is always grayscale.
		//the human eye is more sensitive to green light than other colors.
		//that's why green has a higher weight than the other colors here.
		//as expected, all 3 of these numbers add up to 1.
		vec3(dot(color.rgb,	vec3(0.299, 0.587, 0.114))),
		
		//our normal color.
		//we mix this with the average brightness to make it look less saturated.
		color.rgb,
		
		//the amount of saturation we want.
		//if the saturation is 0, then the final color will be 100% brightness and 0% color.
		//in other words, pure gray.
		//if the saturation color is 1 though, then the final color will be the same as our starting color.
		mix(NIGHT_TERRAIN_SATURATION, DAY_TERRAIN_SATURATION, dayTime)
	);
	
	//apply brightness
	color.rgb *= mix(NIGHT_TERRAIN_BRIGHTNESS, DAY_TERRAIN_BRIGHTNESS, dayTime);
	
	//apply fog
	color.rgb = mix(
		//the color of the fog. this is always grayscale.
		//the brightness depends on the time of day.
		vec3(mix(NIGHT_FOG_BRIGHTNESS, DAY_FOG_BRIGHTNESS, dayTime)),
		
		//our notmal color.
		//we mix this with our fog color to make it look more foggy.
		color.rgb,
		
		//the mix level. AKA the density of the fog.
		//length(pos) is the distance from the camera to the current pixel.
		//we negate this so that exp2(distance) approaches 0 instead of infinity.
		//if the density is 0, then the final color will be 100% fog, and 0% terrain.
		exp2(-length(pos) * mix(NIGHT_FOG_DENSITY, DAY_FOG_DENSITY, dayTime))
	);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}