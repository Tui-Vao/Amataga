#version 120

uniform float adjustedTime;
uniform float day;
uniform float night;
uniform float rainStrength;
uniform float sunset;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 fogColor;
uniform vec3 shadowLightPosition;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec3 lightColor;
varying vec3 shadowColor;
varying vec3 pos;
varying vec4 glcolor;
varying vec4 shadowPos;

#include "/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	pos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	gl_Position = gl_ProjectionMatrix * vec4(pos, 1.0); 	vec4 pos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
	gl_Position = gl_ProjectionMatrix * (gbufferModelView * pos);

	float lightDot = dot(normalize(shadowLightPosition), normalize(gl_NormalMatrix * gl_Normal));
	if (lightDot > 0.0) {
		shadowPos = shadowProjection * (shadowModelView * pos);
		float distortFactor = getDistortFactor(shadowPos.xy);
		shadowPos.xy /= distortFactor;
		shadowPos.z *= 0.5;
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5;
		shadowPos.z -= SHADOW_BIAS * (distortFactor * distortFactor) / lightDot;
	}
	else {
		shadowPos = vec4(0.0);
	}

	#include "/colors.glsl"
}