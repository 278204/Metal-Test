
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
    var depthTexture : MTLTexture?
    
    func initilize(){
        device = MTLCreateSystemDefaultDevice()
        if device == nil {
            print("ERROR Unable to create default device")
        }
        
        metalLayer?.device = device
        metalLayer?.pixelFormat = MTLPixelFormat.BGRA8Unorm

        library = device?.newDefaultLibrary()
        pipelineIsDirty = true
        
        vertexFunctionName = "vertex_main"
        fragmentFunctionName = "fragment_main"
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = MTLSamplerMinMagFilter.Nearest
        samplerDescriptor.magFilter = MTLSamplerMinMagFilter.Linear
        self.sampler = self.device?.newSamplerStateWithDescriptor(samplerDescriptor)
        
    }
    
    func buildPipeline(){
        let vertexDescriptor = MTLVertexDescriptor()

        vertexDescriptor.attributes[0].format = MTLVertexFormat.Float4
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = Vertex.offsetForPosition()
        
        vertexDescriptor.attributes[1].format = MTLVertexFormat.Float3
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = Vertex.offsetForNormal()
        
        vertexDescriptor.attributes[2].format = MTLVertexFormat.Float2;
        vertexDescriptor.attributes[2].bufferIndex = 0;
        vertexDescriptor.attributes[2].offset = Vertex.offsetForTexCoords()
        
        vertexDescriptor.attributes[3].format = MTLVertexFormat.Short2
        vertexDescriptor.attributes[3].bufferIndex = 0;
        vertexDescriptor.attributes[3].offset = Vertex.offsetForBone1()
        
        vertexDescriptor.attributes[4].format = MTLVertexFormat.Short2
        vertexDescriptor.attributes[4].bufferIndex = 0;
        vertexDescriptor.attributes[4].offset = Vertex.offsetForBone2()
        
        vertexDescriptor.attributes[5].format = MTLVertexFormat.Float
        vertexDescriptor.attributes[5].bufferIndex = 0;
        vertexDescriptor.attributes[5].offset = Vertex.offsetForWeight1()
        
        vertexDescriptor.attributes[6].format = MTLVertexFormat.Float
        vertexDescriptor.attributes[6].bufferIndex = 0;
        vertexDescriptor.attributes[6].offset = Vertex.offsetForWeight2()
        
        vertexDescriptor.layouts[0].stride = sizeof(Vertex)
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.PerVertex
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = self.library?.newFunctionWithName(self.vertexFunctionName)
        pipelineDescriptor.fragmentFunction = self.library?.newFunctionWithName(self.fragmentFunctionName)
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.Depth32Float
        
        
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
        var bitmapInfo = CGBitmapInfo.ByteOrder32Big.rawValue
        bitmapInfo |= CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue).rawValue

        let context = CGBitmapContextCreate(rawData, width, height, bitsPerComponents, bytesPerRow, colorspace, bitmapInfo)
        
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
    
    
    func createDepthBuffer(){
        let drawableSize = self.metalLayer?.drawableSize
        let depthTexDesc =  MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.Depth32Float, width: Int(drawableSize!.width), height: Int(drawableSize!.height), mipmapped: false)
        
        self.depthTexture = self.device?.newTextureWithDescriptor(depthTexDesc)
    }
    
    func startFrame(){
        if self.depthTexture == nil {
            self.createDepthBuffer()
        }
        
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
        renderPass.colorAttachments[0].loadAction = MTLLoadAction.Clear
        renderPass.colorAttachments[0].storeAction = MTLStoreAction.Store
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.9, 0.9, 0.9, 1)
        
        renderPass.depthAttachment.texture = self.depthTexture!
        renderPass.depthAttachment.loadAction = MTLLoadAction.Clear;
        renderPass.depthAttachment.storeAction = MTLStoreAction.Store;
        renderPass.depthAttachment.clearDepth = 1;
        
        self.commandBuffer = self.commandQueue?.commandBuffer()
        self.commandEncoder = self.commandBuffer?.renderCommandEncoderWithDescriptor(renderPass)
        self.commandEncoder?.setRenderPipelineState(self.pipeline!)
        self.commandEncoder?.setDepthStencilState(self.depthStencilState)
        self.commandEncoder?.setFrontFacingWinding(MTLWinding.CounterClockwise)

        self.commandEncoder?.setCullMode(MTLCullMode.Back)
    }
    
    func drawMesh(mesh : Mesh, uniformBuffer : MTLBuffer){
        
        self.commandEncoder?.setVertexBuffer(mesh.vertexBuffer!, offset: 0, atIndex: 0)
        self.commandEncoder?.setVertexBuffer(uniformBuffer, offset: 0, atIndex: 1)
        
        self.commandEncoder?.setVertexBuffer(mesh.skeletonBuffer!, offset: 0, atIndex: 2)
       
        
        self.commandEncoder?.setFragmentBuffer(uniformBuffer, offset: 0, atIndex: 0)
        self.commandEncoder?.setFragmentTexture(mesh.texture, atIndex: 0)
        self.commandEncoder?.setFragmentSamplerState(self.sampler, atIndex: 0)
        
        self.commandEncoder?.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: mesh.nr_vertices)
//        self.commandEncoder?.drawIndexedPrimitives(
//            MTLPrimitiveType.Triangle,
//            indexCount: Int(mesh.indexBuffer!.length / sizeof(UInt16)),
//            indexType: MTLIndexType.UInt16,
//            indexBuffer: mesh.indexBuffer!,
//            indexBufferOffset: 0)
    }
    
    func endFrame(){
        self.commandEncoder?.endEncoding()
        
        if self.drawable != nil {
            self.commandBuffer?.presentDrawable(self.drawable!)
            self.commandBuffer?.commit()
        }
    }
    
    func newBufferWithBytes(bytes : UnsafePointer<Void>, length : Int)->MTLBuffer{
        return self.device!.newBufferWithBytes(bytes, length: length, options: MTLResourceOptions.OptionCPUCacheModeDefault)
    }
    
    func newbufferWithBytesNoCopy(bytes : UnsafeMutablePointer<Void>, length : Int) -> MTLBuffer{
        return (self.device?.newBufferWithBytesNoCopy(bytes, length: length, options: MTLResourceOptions.StorageModeShared, deallocator: nil))!
    }

}