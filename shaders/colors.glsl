lightColor = day > 0.001 ? vec3(1.0 - rainStrength * 0.5) : vec3(0.06, 0.12, 0.18) * (1.0 - rainStrength);
shadowColor = vec3(0.0);
if (sunset > 0.01) {
	vec3 sunsetColor = clamp(vec3(7.4, 6.9, 6.4) - adjustedTime, 0.0, 1.0); //color of sunset gradient at the horizon, and mix level
	sunsetColor = mix(sunsetColor, vec3(0.5), rainStrength * 0.625); //reduce redness intensity when raining
	lightColor  = mix(lightColor,  sunsetColor.rgb, sunset);
	shadowColor = mix(shadowColor, sunsetColor.rgb, sunset);
}