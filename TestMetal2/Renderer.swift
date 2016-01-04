//
//  Renderer.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit
import QuartzCore
import Metal
import simd

class Renderer {
    
    var vertexFunctionName : String = "" {
        didSet{
            pipelineIsDirty = true
        }
    }
    var fragmentFunctionName : String = "" {
        didSet{
            pipelineIsDirty = true
        }
    }
    
    var pipelineIsDirty : Bool = true
    
    var metalLayer : CAMetalLayer?
    var commandQueue : MTLCommandQueue?
    var device : MTLDevice?
    var library : MTLLibrary?
    
    var pipeline : MTLRenderPipelineState?
    var depthStencilState : MTLDepthStencilState?
    
    var commandEncoder : MTLRenderCommandEncoder?
    var commandBuffer : MTLCommandBuffer?
    var drawable : CAMetalDrawable?
    var sampler : MTLSamplerState?
    
    func initilize(){
        device = MTLCreateSystemDefaultDevice()
        if device == nil {
            print("ERROR Unable to create default device")
        }
        
        metalLayer?.device = device
        metalLayer?.pixelFormat = MTLPixelFormat.BGRA8Unorm
        
        library = device?.newDefaultLibrary()
        pipelineIsDirty = true
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = MTLSamplerMinMagFilter.Nearest
        samplerDescriptor.magFilter = MTLSamplerMinMagFilter.Linear
        self.sampler = self.device?.newSamplerStateWithDescriptor(samplerDescriptor)
        
    }
    
    func buildPipeline(){
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = MTLVertexFormat.Float4
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        vertexDescriptor.attributes[1].format = MTLVertexFormat.Float4
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = sizeof(float4) * 1
        
//        vertexDescriptor.attributes[2].format = MTLVertexFormat.Float2;
//        vertexDescriptor.attributes[2].bufferIndex = 0;
//        vertexDescriptor.attributes[2].offset = sizeof(float4) * 2
        
        vertexDescriptor.layouts[0].stride = sizeof(Vertex)
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.PerVertex
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        pipelineDescriptor.vertexFunction = self.library?.newFunctionWithName(self.vertexFunctionName)
        pipelineDescriptor.fragmentFunction = self.library?.newFunctionWithName(self.fragmentFunctionName)
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunction.Less
        depthStencilDescriptor.depthWriteEnabled = true
        self.depthStencilState = self.device?.newDepthStencilStateWithDescriptor(depthStencilDescriptor)
        
        do {
            self.pipeline = try self.device?.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
        } catch {
            print("ERROR, couldn't create new render pipeline state..")
        }
        
        self.commandQueue = self.device?.newCommandQueue()
    }
    
    
    
    func newTexture(textureName : String) -> MTLTexture?{
        let image = UIImage(named: textureName)
        if image == nil {
            print("ERROR creating new material, image couldn't be found \(image)")
            return nil
        }
        return textureForImage(image!)
    }
    
    func textureForImage(image : UIImage) -> MTLTexture{
        let imageRef = image.CGImage
        
        let width = CGImageGetWidth(imageRef)
        let height = CGImageGetHeight(imageRef)
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let rawData = calloc(height * width * 4, sizeof(UInt8));
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponents = 8
        //WARNING: options are not correct
        let context = CGBitmapContextCreate(rawData, width, height, bitsPerComponents, bytesPerRow, colorspace, CGImageAlphaInfo.PremultipliedLast.rawValue)
        
        CGContextTranslateCTM(context, 0, CGFloat(height))
        CGContextScaleCTM(context, 1, -1)
        
        CGContextDrawImage(context, CGRect(x: 0, y: 0, width: width, height: height), imageRef)
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: width, height: height, mipmapped: true)
        
        let texture = self.device?.newTextureWithDescriptor(textureDescriptor)
        let region = MTLRegionMake2D(0, 0, width, height)
        texture?.replaceRegion(region, mipmapLevel: 0, withBytes: rawData, bytesPerRow: bytesPerRow)
        
        free(rawData)
        
        return texture!
    }
    
    
    
    
    func startFrame(){
        self.drawable = self.metalLayer?.nextDrawable()
        let frameBufferTexture = self.drawable?.texture
        
        if frameBufferTexture == nil {
            print("ERROR, unable to fetch texture, drawable may be nil")
            return
        }
        
        if self.pipelineIsDirty {
            self.buildPipeline()
            self.pipelineIsDirty = false
        }
        
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = frameBufferTexture
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.9, 0.9, 0.9, 1)
        renderPass.colorAttachments[0].storeAction = MTLStoreAction.Store
        renderPass.colorAttachments[0].loadAction = MTLLoadAction.Clear
        
        self.commandBuffer = self.commandQueue?.commandBuffer()
        self.commandEncoder = self.commandBuffer?.renderCommandEncoderWithDescriptor(renderPass)
        self.commandEncoder?.setRenderPipelineState(self.pipeline!)
        self.commandEncoder?.setDepthStencilState(self.depthStencilState)
        self.commandEncoder?.setFrontFacingWinding(MTLWinding.Clockwise)
        //WARNING, cull = none
        self.commandEncoder?.setCullMode(MTLCullMode.None)
    }
    
    func drawTrianglesWithInterleavedBuffer(positionBuffer : MTLBuffer, indexBuffer : MTLBuffer, uniformBuffer : MTLBuffer, indexCount : size_t, texture : MTLTexture?){
        
        self.commandEncoder?.setVertexBuffer(positionBuffer, offset: 0, atIndex: 0)
        self.commandEncoder?.setVertexBuffer(uniformBuffer, offset: 0, atIndex: 1)
        self.commandEncoder?.setFragmentBuffer(uniformBuffer, offset: 0, atIndex: 0)

        self.commandEncoder?.setFragmentTexture(texture, atIndex: 0)
        self.commandEncoder?.setFragmentSamplerState(self.sampler, atIndex: 0)
        
        self.commandEncoder?.drawIndexedPrimitives(MTLPrimitiveType.Triangle, indexCount: indexCount, indexType: MTLIndexType.UInt16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    }
    
    func endFrame(){
        self.commandEncoder?.endEncoding()
        
        if self.drawable != nil {
            self.commandBuffer?.presentDrawable(self.drawable!)
            self.commandBuffer?.commit()
        }
    }
    
    func newBufferWithBytes(bytes : UnsafePointer<Void>, length : Int)->MTLBuffer{
        return self.device!.newBufferWithBytes(bytes, length: length, options: MTLResourceOptions.CPUCacheModeDefaultCache)
    }

}