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
    float4 direction;
    float4 ambientColor;
    float4 diffuseColor;
    float4 specularColor;
};

constant Light light = {
    .direction = { 0, 1.0, 1.0, 1.0 },
    .ambientColor = { 0.8, 0.8, 0.8, 1.0  },
    .diffuseColor = { 0.3, 0.3, 0.3, 1.0 },
    .specularColor = { 0.0, 0.0, 0.0, 1.0 }
};

constant float4 kSpecularColor= { 1, 1, 1, 1.0 };
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
    float4 newpos = float4(0,0,0,0);
    float4 newnormal = float4(0,0,0,0);
    
    if(vert.bone1 >= 0 || vert.bone2 >= 0) {
        if(vert.bone1 >= 0){
            newpos += (bones[vert.bone1] * vert.position) * vert.weight1;
            newnormal += (bones[vert.bone1] * float4(vert.normal, 0.0)) * vert.weight1;
        }
        if(vert.bone2 >= 0){
            newpos += (bones[vert.bone2] * vert.position) * vert.weight2;
            newnormal += (bones[vert.bone2] * float4(vert.normal, 0.0)) * vert.weight2;
        }
    } else{
        newpos = vert.position;
        newnormal = float4(vert.normal, 0);
    }
    
    outVert.position = uniforms.modelViewProjectionMatrix * float4(newpos.xyz, 1.0);
    outVert.eyePosition = -(uniforms.modelViewMatrix * float4(newpos.xyz, 1.0)).xyz;
    outVert.normal = uniforms.normalMatrix * newnormal.xyz;
    outVert.texCoords = vert.texCoords;
    return outVert;
}


fragment float4 fragment_main(ProjectedVertex vert [[stage_in]],
                              constant Uniforms &uniforms [[buffer(0)]],
                              constant uint &fragmentType [[buffer(1)]],
                              texture2d<float> diffuseTexture [[texture(0)]],
                              sampler samplr [[sampler(0)]])
{
    if(fragmentType == 0) {//Texture
        float4 diffuseColor = diffuseTexture.sample(samplr, vert.texCoords).rgba;
        if (diffuseColor.a < 0.1) {
            discard_fragment();
        }
        return diffuseColor;
        
        
    } else if (fragmentType == 1) {//TextureLight
        
        float4 diffuseColor = diffuseTexture.sample(samplr, vert.texCoords).rgba;
        
        float4 ambientTerm = light.ambientColor * diffuseColor;
        
        float4 normal = float4(normalize(vert.normal), 1.0);
        float diffuseIntensity = saturate(dot(normal, light.direction));
        float4 diffuseTerm = light.diffuseColor * diffuseColor * diffuseIntensity;
        
        float4 specularTerm(0);
        if (diffuseIntensity > 0)
        {
            float4 eyeDirection = float4(normalize(vert.eyePosition), 1.0);
            float4 halfway = normalize(light.direction + eyeDirection);
            float specularFactor = pow(saturate(dot(normal, halfway)), kSpecularPower);
            specularTerm = light.specularColor * kSpecularColor * specularFactor;
        }
        
        return ambientTerm + diffuseTerm + specularTerm;
    }
    return float4(0,0,0,1);

}


