//
//  TextureHandler.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-28.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation


class TextureHandler {
    static var textureID : Int = 0
    static let shared = TextureHandler()
    private var device : MTLDevice? {get { return DeviceSingleton.shared}}
    private var texture_map = [MTLTexture]()
    private var name_map = [String : Int]()

    func getTexture(textureID : Int?) -> MTLTexture? {
        guard textureID != nil && textureID! < texture_map.count else {
            return nil
        }
        return texture_map[textureID!]
    }
    func getTexture(textureName : String) -> MTLTexture? {
        return texture_map[name_map[textureName]!]
    }
    
    func newTexture(textureName : String) -> Int{
        var index = name_map[textureName]
        if index == nil {
            let image = UIImage(named: textureName )
            if image == nil {
                print("ERROR creating new material, image couldn't be found \(textureName)")
                assertionFailure()
            }
            index = texture_map.count
            texture_map.append(textureForImage(image!))
            name_map[textureName] = index
        }
        return index!
    }
    
    private func textureForImage(image : UIImage) -> MTLTexture{
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
    
    
}