#version 120

uniform float frameTimeCounter;
uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform sampler2D depthtex0;
uniform sampler2D gaux1; //dither
uniform sampler2D gcolor;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;

varying vec2 texcoord;
varying vec3 lightColor;
varying vec3 shadowColor;

#include "/distort.glsl"

void main() {
	vec3 color = texture2D(gcolor, texcoord).rgb;
	vec4 pos = vec4(texcoord, texture2D(depthtex0, texcoord).r, 1.0);
	pos.xyz = pos.xyz * 2.0 - 1.0; //w is already 1
	pos = gbufferProjectionInverse * pos;
	pos.xyz /= pos.w;
	pos.w = 0.0;

	pos = gbufferModelViewInverse * pos;

	pos.xyz *= mix(1.0, 1.0 / 0.75, fract(texture2D(gaux1, gl_FragCoord.xy * 0.0625).r + frameTimeCounter));
	while (dot(pos.xyz, pos.xyz) > 0.25 * 0.25) {
		pos.xyz *= 0.75;
		vec4 shadowPos = vec4(pos.xyz + gbufferModelViewInverse[3].xyz, 1.0);
		shadowPos = shadowProjection * (shadowModelView * shadowPos);
		shadowPos.xyz = distort(shadowPos.xyz);
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5;
		color = mix(texture2D(shadowtex0, shadowPos.xy).r > shadowPos.z ? lightColor : shadowColor, color, exp2(length(pos.xyz) * -0.0085));
	}

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 0.1); //gcolor
}