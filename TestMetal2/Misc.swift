//
//  Misc.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd




class Matrix{
    class func Identity() -> float4x4 {
        return float4x4(diagonal: float4(1,1,1,1))
    }
    class func parseMatrix(input : String) -> float4x4{
        let scanner = NSScanner(string: input)
        scanner.charactersToBeSkipped = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        return Matrix.parseMatrix(scanner)
    }
    
    class func parseMatrix(scanner : NSScanner) -> float4x4{
        var matrix = float4x4()
        
        for i in 0..<4 {
            for j in 0..<4 {
                var x : Float = 0
                scanner.scanFloat(&x)
                matrix[j][i] = x
            }
        }
        
        return matrix
    }
    
    
    class func rotationY(degrees : Float) ->float4x4 {
        var rotate_mat = Matrix.Identity()
        
        let theta = Math.DegToRad(degrees)
        let cos_r = cos(theta)
        let sin_r = sin(theta)
        rotate_mat[0][0] = cos_r
        rotate_mat[2][0] = -sin_r
        rotate_mat[0][2] = sin_r
        rotate_mat[2][2] = cos_r
        return rotate_mat
    }
    
    class func rotationZ(degrees : Float) ->float4x4 {
        var rotate_mat = Matrix.Identity()
        
        let theta = Math.DegToRad(degrees)
        let cos_r = cos(theta)
        let sin_r = sin(theta)
        rotate_mat[0][0] = cos_r
        rotate_mat[1][0] = -sin_r
        rotate_mat[0][1] = sin_r
        rotate_mat[1][1] = cos_r
        return rotate_mat
    }
    class func rotationX(degrees : Float) -> float4x4{
        var rotate_mat = Matrix.Identity()
        let theta = Math.DegToRad(degrees)
        let cos_r = cos(theta)
        let sin_r = sin(theta)
        rotate_mat[1][1] = cos_r
        rotate_mat[2][1] = -sin_r
        rotate_mat[1][2] = sin_r
        rotate_mat[2][2] = cos_r
        return rotate_mat
    }
}


class QuatTrans {
    var quaternion : float4
    var translate : float4
    
    init(){
        quaternion = float4()
        translate = float4()
    }
    
    class func convertMatrixToQuaternion(mat : float4x4)-> float4{
        return Quaternion.convertMatrix(mat)
    }
    
    class func convertMatrixToTranslation(mat : float4x4) -> float4 {
        return mat[3]
    }
    
    func convertToMatrix() -> float4x4{
        var q = Quaternion.convertToMatrix(self.quaternion)
        q[3] = translate
        q[0][3] = 0
        q[1][3] = 0
        q[2][3] = 0
        return q
    }
}

class Quaternion {
    
    class func copySign(v : Float, sign : Float) -> Float{
        if sign > 0 && v > 0 || sign < 0 && v < 0 {
            return v
        } else{
            return -v
        }
    }
    class func convertMatrix(mat : float4x4) -> float4 {

        var qw : Float = 0;
        var qx : Float = 1
        var qy : Float = 0;
        var qz : Float = 0;
        var S : Float = 0;
        
//        if( (mat[0][0] + mat[1][1] + mat[2][2]) > 0 ) {
//            S = 0.5 * sqrtf(mat[0][0] + mat[1][1] + mat[2][2] + 1)
//            qw = S;
//            qx = ( mat[2][1] - mat[1][2]) / (S * 4)
//            qy = ( mat[0][2] - mat[2][0] ) / (S * 4)
//            qz = ( mat[1][0] - mat[0][1] ) / (S * 4)
//        } else{
            if mat[0][0] > mat[1][1] && mat[0][0] > mat[2][2] {
                if (( 1.0 + mat[0][0] - mat[1][1] - mat[2][2] ) <= 0) {
                    print("ERROR")
                }
                S = 2.0 * sqrtf( 1.0 + mat[0][0] - mat[1][1] - mat[2][2] )// S=4*qx
                qw = (mat[2][1] - mat[1][2]) / S;
                qx = 0.25 * S;
                qy = (mat[0][1] + mat[1][0]) / S;
                qz = (mat[0][2] + mat[2][0]) / S;
            }
//            else
//            if (mat[1][1] > mat[2][2]) {
//                if (( 1.0 + mat[1][1] - mat[0][0] - mat[2][2] ) <= 0) {
//                    print("ERROR")
//
//                }
//                S = 2.0 * sqrtf( 1.0 + mat[1][1] - mat[0][0] - mat[2][2]) // S=4*qy
//                qw = (mat[0][2] - mat[2][0]) / S;
//                qx = (mat[0][1] + mat[1][0]) / S;
//                qy = 0.25 * S;
//                qz = (mat[1][2] + mat[2][1]) / S; 
//            }
            else {
                if (( 1.0 + mat[2][2] - mat[0][0] - mat[1][1] ) <= 0) {
                    print("ERROR")
                }
                S = 2.0 * sqrtf( 1.0 + mat[2][2] - mat[0][0] - mat[1][1] ) // S=4*qz
                qw = (mat[1][0] - mat[0][1]) / S;
                qx = (mat[0][2] + mat[2][0]) / S; 
                qy = (mat[1][2] + mat[2][1]) / S; 
                qz = 0.25 * S;
            }
//        }
        return float4(qx, qy, qz, qw)
    }
    
    class func convertToMatrix(q : float4) -> float4x4{
        var mat1 = Matrix.Identity()
        mat1[0] = float4(q.w, -q.z, q.y, -q.x)
        mat1[1] = float4(q.z, q.w, -q.x, -q.y)
        mat1[2] = float4(-q.y, q.x, q.w, -q.z)
        mat1[3] = float4(q.x, q.y, q.z, q.w)
        
        var mat2 = float4x4()
        mat2[0] = float4(q.w, -q.z, q.y, q.x)
        mat2[1] = float4(q.z, q.w, -q.x, q.y)
        mat2[2] = float4(-q.y, q.x, q.w, q.z)
        mat2[3] = float4(-q.x, -q.y, -q.z, q.w)
        
        return mat1 * mat2
    }
    
    class func slerp(t : Float, q1 : float4, var q2 : float4) -> float4{
        
        var cos_theta_div2 = q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z

        //WARNING, unneccessary?
        if cos_theta_div2 < 0.0{
            q2.w = -q2.w; q2.x = -q2.x; q2.y = -q2.y; q2.z = q2.z;
            cos_theta_div2 = -cos_theta_div2
        }
        
        if fabs(cos_theta_div2) >= 1.0 {
            return q1
        }
        
        let theta_div2 = acosf(cos_theta_div2)
        let sin_theta_div2 = sqrtf(1.0 - cos_theta_div2 * cos_theta_div2)
        
        if fabs(sin_theta_div2) < 0.001 {
            let qm = float4(q1.x * 0.5 + q2.x * 0.5,
                q1.y * 0.5 + q2.y * 0.5,
                q1.z * 0.5 + q2.z * 0.5,
                q1.w * 0.5 + q2.w * 0.5)
            return qm
        }
        
        let ratio_a = sinf((1 - t) * theta_div2) / sin_theta_div2
        let ratio_b = sinf(t * theta_div2) / sin_theta_div2
        
        let qm = float4(
            q1.x * ratio_a + q2.x * ratio_b,
            q1.y * ratio_a + q2.y * ratio_b,
            q1.z * ratio_a + q2.z * ratio_b,
            q1.w * ratio_a + q2.w * ratio_b
        )
        
        return qm
    }
}


class Math {
    class func DegToRad(deg : Float) -> Float{
        return deg * (Float(M_PI) / 180.0);
    }
    class func sign(v : CGFloat)->Int8{
        if v == 0 {
            return 0
        }
        return v < 0 ? -1 : 1
    }
    
    class func signWithZero(v : Float)->Int8{
        if v == 0 {
            return 0
        }
        return v < 0 ? -1 : 1
    }
    
    class func sign(v : Float)->Int8{
        return v < 0 ? -1 : 1
    }
}

func / (left : float3, right : Float) ->float3 {
    var l = left
    l.x = l.x/right
    l.y = l.y/right
    l.z = l.z/right
    return l
}

func * (left : CGPoint, right : CGPoint) -> CGPoint {
    return CGPoint(x: left.x * right.x, y: left.y * right.y)
}

func * (left : CGPoint, right : CGFloat) -> CGPoint {
    return CGPoint(x: left.x * right, y: left.y * right)
}

func + (left : CGPoint, right : CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left : CGPoint, right : CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (left:float2, right : Float) -> float2 {
    var l = left
    l.x = l.x * right
    l.y = l.y * right
    return l
}


extension float2 {
    var xyz : float3 {get{return float3(x,y, 0)}}
    
    func cross(d : float2) -> Float{
        return (x * d.y) - (y * d.x)
    }
    func normalize() -> float2{
        let len = length()
        return float2(x / len, y / len)
    }
    func length() -> Float{
        return sqrtf(lengthSq())
    }
    func lengthSq() -> Float {
        return x*x + y*y
    }
}

extension float3{
    var xy : float2 {get{return float2(x,y)}}
    func length() -> Float{
        return sqrtf(x*x + y*y + z*z)
    }
    
    
}
extension float4 {
    func xyz()->float3 {
        return float3(x, y, z)
    }
}
extension float4x4 {
    func printOut(){
        print("Matrix:")
        print("\(self.cmatrix.columns.0.x) \(self.cmatrix.columns.1.x) \(self.cmatrix.columns.2.x) \(self.cmatrix.columns.3.x)")
        print("\(self.cmatrix.columns.0.y) \(self.cmatrix.columns.1.y) \(self.cmatrix.columns.2.y) \(self.cmatrix.columns.3.y)")
        print("\(self.cmatrix.columns.0.z) \(self.cmatrix.columns.1.z) \(self.cmatrix.columns.2.z) \(self.cmatrix.columns.3.z)")
        print("\(self.cmatrix.columns.0.w) \(self.cmatrix.columns.1.w) \(self.cmatrix.columns.2.w) \(self.cmatrix.columns.3.w)")
        print("")
    }
}

extension MTLTexture {
    
    func bytes() -> UnsafeMutablePointer<Void> {
        let width = self.width
        let height   = self.height
        let rowBytes = self.width * 4
        let p = malloc(width * height * 4)
        
        self.getBytes(p, bytesPerRow: rowBytes, fromRegion: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        
        return p
    }
    
    func toImage() -> CGImage? {
        let p = bytes()
        
        let pColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let rawBitmapInfo = CGImageAlphaInfo.NoneSkipFirst.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
        
        let selftureSize = self.width * self.height * 4
        let rowBytes = self.width * 4
        let provider = CGDataProviderCreateWithData(nil, p, selftureSize, nil)
        let cgImageRef = CGImageCreate(self.width, self.height, 8, 32, rowBytes, pColorSpace, bitmapInfo, provider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)!
        
        return cgImageRef
    }
}