
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

class DeviceSingleton{
    static let shared = MTLCreateSystemDefaultDevice()
}

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
    var device : MTLDevice? {get { return DeviceSingleton.shared }}
    var library : MTLLibrary?
    
    var pipeline : MTLRenderPipelineState?
    var depthStencilState : MTLDepthStencilState?
    
    var commandEncoder : MTLRenderCommandEncoder?
    var commandBuffer : MTLCommandBuffer?
    var drawable : CAMetalDrawable?
    var lastDrawable : CAMetalDrawable?
    var sampler : MTLSamplerState?
    
    //OPTIMIZE, unnecessary?
    var depthTexture : MTLTexture?
    

    func initilize(){
        
        print("Init renderer")
        if self.device == nil {
            print("ERROR Unable to create default device")
        }
        
        
        metalLayer?.device = device
        metalLayer?.pixelFormat = MTLPixelFormat.BGRA8Unorm
        //WARNING, optimize?
        metalLayer?.framebufferOnly = false
        
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
        
        vertexDescriptor.layouts[0].stride = Vertex.offsetForWeight2() + sizeof(Float)
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
    
    func createDepthBuffer(){
        print("metallayer \(self.metalLayer?.bounds.size)")
        let drawableSize = self.metalLayer!.drawableSize
        let depthTexDesc =  MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.Depth32Float, width: Int(drawableSize.width), height: Int(drawableSize.height), mipmapped: false)
        
        self.depthTexture = self.device?.newTextureWithDescriptor(depthTexDesc)
    }
    
    let inflightSemaphore = dispatch_semaphore_create(3)
    
    func startFrame() -> Bool{
        dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER)
        var failure = false
        if self.depthTexture == nil {
            self.createDepthBuffer()
        }
        
        self.drawable = self.metalLayer?.nextDrawable()
        let frameBufferTexture = self.drawable?.texture
        
        if frameBufferTexture == nil {
            print("ERROR, unable to fetch texture, drawable may be \(self.drawable)")
            dispatch_semaphore_signal(inflightSemaphore)
            failure = true
            return false
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
    
        return !failure
    }
    
    func drawMesh(mesh : Mesh, skeletonBuffer : MTLBuffer, uniformBuffer : MTLBuffer, texture : MTLTexture?){

        self.commandEncoder?.setVertexBuffer(mesh.vertexBuffer!, offset: 0, atIndex: 0)
        self.commandEncoder?.setVertexBuffer(uniformBuffer, offset: 0, atIndex: 1)
        
        self.commandEncoder?.setVertexBuffer(skeletonBuffer, offset: 0, atIndex: 2)
       
        
        self.commandEncoder?.setFragmentBuffer(uniformBuffer, offset: 0, atIndex: 0)
        self.commandEncoder?.setFragmentBuffer(mesh.fragmentTypeBuffer!, offset: 0, atIndex: 1)
        self.commandEncoder?.setFragmentTexture(texture, atIndex: 0)
        self.commandEncoder?.setFragmentSamplerState(self.sampler, atIndex: 0)
        
        self.commandEncoder?.drawPrimitives(mesh.primativeType, vertexStart: 0, vertexCount: mesh.nr_vertices)
    }
    
    func drawLineMesh(vertexBuffer : MTLBuffer, uniformBuffer : MTLBuffer, nrOfVertices : Int, texture : MTLTexture?){
        self.commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        self.commandEncoder?.setVertexBuffer(uniformBuffer, offset: 0, atIndex: 1)
        self.commandEncoder?.setFragmentBuffer(uniformBuffer, offset: 0, atIndex: 0)
        self.commandEncoder?.setFragmentTexture(texture, atIndex: 0)
        self.commandEncoder?.setFragmentSamplerState(self.sampler, atIndex: 0)
        self.commandEncoder?.drawPrimitives(.Line, vertexStart: 0, vertexCount: nrOfVertices)
    }
    
    func endFrame(){

        self.commandEncoder?.endEncoding()

        if self.drawable != nil {
            self.commandBuffer?.presentDrawable(self.drawable!)
            lastDrawable = self.drawable
            self.drawable = nil
        }
        
        self.commandBuffer?.addCompletedHandler({ buf -> Void in
            dispatch_semaphore_signal(self.inflightSemaphore)
        })
        self.commandBuffer?.commit()
    }
    
    func newBufferWithBytes(bytes : UnsafePointer<Void>, length : Int)->MTLBuffer{
        return self.device!.newBufferWithBytes(bytes, length: length, options: MTLResourceOptions.OptionCPUCacheModeDefault)
    }
    

}