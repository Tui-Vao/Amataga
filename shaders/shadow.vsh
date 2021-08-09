#version 120

uniform int entityId;
uniform int blockEntityId;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

#include "/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	gl_Position = ftransform();
	gl_Position.xyz = distort(gl_Position.xyz);
}