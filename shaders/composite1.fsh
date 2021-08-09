#version 120

//vignette is more visible when it's applied to gray fog than it is when applied to black fog.
//this is why NIGHT_VIGNETTE is darker than DAY_VIGNETTE by default.
#define DAY_VIGNETTE 0.375 //At 0, the edges of your screen are pitch black. At 1, the edges of your screen are normal brightness. [0.0 0.125 0.25 0.375 0.5 0.625 0.75 0.875 1.0]
#define NIGHT_VIGNETTE 0.25 //At 0, the edges of your screen are pitch black. At 1, the edges of your screen are normal brightness. [0.0 0.125 0.25 0.375 0.5 0.625 0.75 0.875 1.0]

uniform float dayTime;
uniform sampler2D gaux1; //the dithering texture
uniform sampler2D gcolor;

varying vec2 texcoord;

//fog and vignette are both capable of producing banding effects.
//we use dithering to solve both cases.
//however, by the time vignette is ready to work, fog has already been written to gcolor.
//if we only applied dithering after fog, the banding would still be noticeable on the vignette.
//if we only applied it after vignette, then banding would be visible on fog.
//if we applied it twice, once after each effect, the dithering itself might become visible.
//to solve these issues, we instead use a higher precision for gcolor.
//that way, neither effect will have banding issues to begin with until the final color is drawn to your screen.
//we then apply one layer of dithering after fog and vignette have been applied, but before the final color is drawn to your screen.

/*
const int gcolorFormat = RGBA16;
*/

void main() {
	vec3 color = texture2D(gcolor, texcoord).rgb;

	//apply vignette
	
	//the strength of our vignette is (1 - x^2) * (1 - y^2) where x is texcoord.x and y is texcoord.y.
	//however, texcoord is in the range 0 to 1, but we need it to be -1 to +1 for the above equation to work.
	vec2 vignetteCoord = texcoord * 2.0 - 1.0;
	//now that vignetteCoord is in the range -1 to +1, we can apply the previously mentioned equation.
	float vignetteStrength = (1.0 - vignetteCoord.x * vignetteCoord.x) * (1.0 - vignetteCoord.y * vignetteCoord.y);
	//that equation will spit out 0 at the edges of your screen, and 1 in the middle.
	//we use that as our mix level, where the DAY/NIGHT_VIGNETTE settings tell us what brightness the edges of your screen SHOULD be.
	color *= mix(mix(NIGHT_VIGNETTE, DAY_VIGNETTE, dayTime), 1.0, vignetteStrength);

	//apply dithering
	//0.0625 is 1 / 16, and 16 is the resolution of our dithering image.
	color += texture2D(gaux1, gl_FragCoord.xy * 0.0625).rgb / 256.0;

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}