//
//  Shaders.metal
//  BasicTexturing
//
//  Created by Warren Moore on 9/25/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct Light
{
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

constant Light light = {
    .direction = { 0.13, 0.72, 0.68 },
    .ambientColor = { 0.5, 0.5, 0.5 },
    .diffuseColor = { 1, 1, 1 },
    .specularColor = { 0.2, 0.2, 0.2 }
};

constant float3 kSpecularColor= { 1, 1, 1 };
constant float kSpecularPower = 80;

struct Uniforms
{
    float4x4 modelViewProjectionMatrix;
    float4x4 modelViewMatrix;
    float3x3 normalMatrix;
};

struct Vertex
{
    float4 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
    char bone1 [[attribute(3)]];
    char bone2 [[attribute(4)]];;
    float weight1 [[attribute(5)]];
    float weight2 [[attribute(6)]];
    
};


struct ProjectedVertex
{
    float4 position [[position]];
    float3 eyePosition;
    float3 normal;
    float2 texCoords;
};

vertex ProjectedVertex vertex_main(Vertex vert [[stage_in]],
                                   constant Uniforms &uniforms [[buffer(1)]],
                                   constant float4x4 *bones    [[buffer(2)]])
{
    ProjectedVertex outVert;
    float4 newpos = vert.position;
    float4 newnormal = float4(vert.normal, 0.0);
    
    if(vert.bone1 >= 0){
        newpos = (bones[vert.bone1] * vert.position) * vert.weight1;
        newnormal = (bones[vert.bone1] * float4(vert.normal, 0.0)) * vert.weight1;
    }
    if(vert.bone2 >= 0){
        newpos = (bones[vert.bone2] * vert.position) * vert.weight2 + newpos;
        newnormal = (bones[vert.bone2] * float4(vert.normal, 0.0)) * vert.weight2 + newnormal;
    }
    
    outVert.position = uniforms.modelViewProjectionMatrix * float4(newpos.xyz, 1.0);
    outVert.eyePosition = -(uniforms.modelViewMatrix * newpos).xyz;
    outVert.normal = uniforms.normalMatrix * newnormal.xyz;
    outVert.texCoords = vert.texCoords;
    return outVert;
}

fragment float4 fragment_main(ProjectedVertex vert [[stage_in]],
                              constant Uniforms &uniforms [[buffer(0)]],
                              texture2d<float> diffuseTexture [[texture(0)]],
                              sampler samplr [[sampler(0)]])
{
    float3 diffuseColor = diffuseTexture.sample(samplr, vert.texCoords).rgb;
    
    float3 ambientTerm = light.ambientColor * diffuseColor;
    
    float3 normal = normalize(vert.normal);
    float diffuseIntensity = saturate(dot(normal, light.direction));
    float3 diffuseTerm = light.diffuseColor * diffuseColor * diffuseIntensity;
    
    float3 specularTerm(0);
    if (diffuseIntensity > 0)
    {
        float3 eyeDirection = normalize(vert.eyePosition);
        float3 halfway = normalize(light.direction + eyeDirection);
        float specularFactor = pow(saturate(dot(normal, halfway)), kSpecularPower);
        specularTerm = light.specularColor * kSpecularColor * specularFactor;
    }
    
    return float4(ambientTerm + diffuseTerm + specularTerm, 1);
}
