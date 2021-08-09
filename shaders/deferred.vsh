#version 120

uniform float adjustedTime;
uniform float day;
uniform float night;
uniform float rainStrength;
uniform float sunset;
uniform vec3 fogColor;

varying vec2 texcoord;
varying vec3 lightColor;
varying vec3 shadowColor;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	#include "/colors.glsl"
}