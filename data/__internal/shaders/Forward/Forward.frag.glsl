#version 400 core

#define PI 3.14159265359
const float PI2 = PI * 2.0;

in vec3 eyeNormal;
in vec3 eyePosition;
in vec2 texCoord;

in vec4 currPosition;
in vec4 prevPosition;

uniform float layer;
uniform float energy;
uniform float opacity;

uniform bool shaded;
uniform vec3 sunDirection;
uniform vec4 sunColor;
uniform float sunEnergy;
uniform bool sunScattering;
uniform float sunScatteringG;
uniform float sunScatteringDensity;

#include <gamma.glsl>
#include <cotangentFrame.glsl>
#include <envMapEquirect.glsl>

/*
 * Diffuse color subroutines.
 * Used to switch color/texture.
 */
subroutine vec4 srtColor(in vec2 uv);

uniform vec4 diffuseVector;
subroutine(srtColor) vec4 diffuseColorValue(in vec2 uv)
{
    return diffuseVector;
}

uniform sampler2D diffuseTexture;
subroutine(srtColor) vec4 diffuseColorTexture(in vec2 uv)
{
    return texture(diffuseTexture, uv);
}

subroutine uniform srtColor diffuse;

/*
 * Normal mapping subroutines.
 */
subroutine vec3 srtNormal(in vec2 uv, in float ysign, in mat3 tangentToEye);

uniform vec3 normalVector;
subroutine(srtNormal) vec3 normalValue(in vec2 uv, in float ysign, in mat3 tangentToEye)
{
    vec3 tN = normalVector;
    tN.y *= ysign;
    return normalize(tangentToEye * tN);
}

uniform sampler2D normalTexture;
subroutine(srtNormal) vec3 normalMap(in vec2 uv, in float ysign, in mat3 tangentToEye)
{
    vec3 tN = normalize(texture(normalTexture, uv).rgb * 2.0 - 1.0);
    tN.y *= ysign;
    return normalize(tangentToEye * tN);
}

subroutine uniform srtNormal normal;


/*
 * Height mapping
 */
subroutine float srtHeight(in vec2 uv);

uniform float heightScalar;
subroutine(srtHeight) float heightValue(in vec2 uv)
{
    return heightScalar;
}

subroutine(srtHeight) float heightMap(in vec2 uv)
{
    return texture(normalTexture, uv).a;
}

subroutine uniform srtHeight height;


/*
 * Parallax mapping
 */
subroutine vec2 srtParallax(in vec3 E, in vec2 uv, in float h);

uniform float parallaxScale;
uniform float parallaxBias;

subroutine(srtParallax) vec2 parallaxNone(in vec3 E, in vec2 uv, in float h)
{
    return uv;
}

subroutine(srtParallax) vec2 parallaxSimple(in vec3 E, in vec2 uv, in float h)
{
    float currentHeight = h * parallaxScale + parallaxBias;
    return uv + (currentHeight * E.xy);
}

// Based on code written by Igor Dykhta (Sun and Black Cat)
// http://sunandblackcat.com/tipFullView.php?topicid=28
subroutine(srtParallax) vec2 parallaxOcclusionMapping(in vec3 E, in vec2 uv, in float h)
{
    const float minLayers = 10.0;
    const float maxLayers = 15.0;
    float numLayers = mix(maxLayers, minLayers, abs(dot(vec3(0.0, 0.0, 1.0), E)));
    float layerHeight = 1.0 / numLayers;
    float curLayerHeight = 0.0;
    vec2 dtex = parallaxScale * E.xy / E.z / numLayers;
    vec2 currentTextureCoords = uv;

    float currentHeight = h;
    while(currentHeight > curLayerHeight)
    {
        curLayerHeight += layerHeight;
        currentTextureCoords += dtex;
        currentHeight = height(currentTextureCoords);
    }

    vec2 prevTCoords = currentTextureCoords - dtex;
    float nextH = currentHeight - curLayerHeight;
    float prevH = height(prevTCoords) - curLayerHeight + layerHeight;
    float weight = nextH / (nextH - prevH);
    return prevTCoords * weight + currentTextureCoords * (1.0 - weight);
}

subroutine uniform srtParallax parallax;


/*
 * Roughness
 */
uniform sampler2D pbrTexture;

subroutine float srtRoughness(in vec2 uv);

uniform float roughnessScalar;
subroutine(srtRoughness) float roughnessValue(in vec2 uv)
{
    return roughnessScalar;
}

subroutine(srtRoughness) float roughnessMap(in vec2 uv)
{
    return texture(pbrTexture, uv).r;
}

subroutine uniform srtRoughness roughness;


/*
 * Metallic
 */
subroutine float srtMetallic(in vec2 uv);

uniform float metallicScalar;
subroutine(srtMetallic) float metallicValue(in vec2 uv)
{
    return metallicScalar;
}

subroutine(srtMetallic) float metallicMap(in vec2 uv)
{
    return texture(pbrTexture, uv).g;
}

subroutine uniform srtMetallic metallic;


/*
 * Specularity
 */
subroutine float srtSpecularity(in vec2 uv);

uniform float specularityScalar;
subroutine(srtSpecularity) float specularityValue(in vec2 uv)
{
    return specularityScalar;
}

subroutine(srtSpecularity) float specularityMap(in vec2 uv)
{
    return texture(pbrTexture, uv).b;
}

subroutine uniform srtSpecularity specularity;


/*
 * Emission
 */
subroutine vec3 srtEmission(in vec2 uv);

uniform vec4 emissionVector;
subroutine(srtEmission) vec3 emissionColorValue(in vec2 uv)
{
    return emissionVector.rgb * energy;
}

uniform sampler2D emissionTexture;
subroutine(srtEmission) vec3 emissionColorTexture(in vec2 uv)
{
    return texture(emissionTexture, uv).rgb * energy;
}

subroutine uniform srtEmission emission;


/*
 * Ambient
 */
uniform float ambientEnergy;

subroutine vec3 srtAmbient(in vec3 wN, in float roughness);

uniform vec4 ambientVector;
subroutine(srtAmbient) vec3 ambientColor(in vec3 wN, in float roughness)
{
    return toLinear(ambientVector.rgb) * ambientEnergy;
}

uniform sampler2D ambientTexture;
subroutine(srtAmbient) vec3 ambientEquirectangularMap(in vec3 wN, in float roughness)
{
    ivec2 envMapSize = textureSize(ambientTexture, 0);
    float size = float(max(envMapSize.x, envMapSize.y));
    float glossyExponent = 2.0 / pow(roughness, 4.0) - 2.0;
    float lod = log2(size * sqrt(3.0)) - 0.5 * log2(glossyExponent + 1.0);
    return textureLod(ambientTexture, envMapEquirect(wN), lod).rgb * ambientEnergy;
}

uniform samplerCube ambientTextureCube;
subroutine(srtAmbient) vec3 ambientCubemap(in vec3 wN, in float roughness)
{
    ivec2 envMapSize = textureSize(ambientTextureCube, 0);
    float size = float(max(envMapSize.x, envMapSize.y));
    float glossyExponent = 2.0 / pow(roughness, 4.0) - 2.0;
    float lod = log2(size * sqrt(3.0)) - 0.5 * log2(glossyExponent + 1.0);
    return textureLod(ambientTextureCube, wN, lod).rgb * ambientEnergy;
}

subroutine uniform srtAmbient ambient;


// Mie scaterring approximated with Henyey-Greenstein phase function.
float scattering(float lightDotView)
{
    float result = 1.0 - sunScatteringG * sunScatteringG;
    result /= 4.0 * PI * pow(1.0 + sunScatteringG * sunScatteringG - (2.0 * sunScatteringG) * lightDotView, 1.5);
    return result;
}


uniform vec2 viewSize;

uniform vec4 fogColor;
uniform float fogStart;
uniform float fogEnd;

layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 fragVelocity;

void main()
{
    vec3 E = normalize(-eyePosition);
    vec3 N = normalize(eyeNormal);
    
    mat3 tangentToEye = cotangentFrame(N, eyePosition, texCoord);
    vec3 tE = normalize(E * tangentToEye);
    
    vec2 shiftedTexCoord = parallax(tE, texCoord, height(texCoord));

    N = normal(shiftedTexCoord, -1.0, tangentToEye);

    vec4 fragDiffuse = diffuse(shiftedTexCoord);
    
    // 
    vec3 outColor = toLinear(fragDiffuse.rgb);
    
    // TODO: shading
    
    // Fog
    float linearDepth = abs(eyePosition.z);
    float fogFactor = clamp((fogEnd - linearDepth) / (fogEnd - fogStart), 0.0, 1.0);
    outColor = mix(toLinear(fogColor.rgb), outColor, fogFactor);
    
    // Velocity
    vec2 posScreen = (currPosition.xy / currPosition.w) * 0.5 + 0.5;
    vec2 prevPosScreen = (prevPosition.xy / prevPosition.w) * 0.5 + 0.5;
    vec2 screenVelocity = posScreen - prevPosScreen;
    
    fragColor = vec4(outColor, fragDiffuse.a);
    fragVelocity = vec4(screenVelocity, 0.0, 1.0);
}
