//
//  Misc.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

struct Uniforms{
    let modelViewProjectionMatrix : float4x4
    let modelViewMatrix : float4x4
    let normalMatrix : float3x3
}


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
        let q = Quaternion.convertToMatrix(self.quaternion)
        var mat_t = Matrix.Identity()
        mat_t[3] = translate
        
        return mat_t * q
    }
}

class Quaternion {
    
    class func convertMatrix(mat : float4x4) -> float4 {

        let tr = mat[0][0] + mat[1][1] + mat[2][2]
        
        if tr > 0 {
            let qw4 = 2.0 * sqrtf(1.0 + tr)
            let qw = 0.25 * qw4
            let qx = (mat[2][1] - mat[1][2]) / qw4
            let qy = (mat[0][2] - mat[2][0]) / qw4
            let qz = (mat[1][0] - mat[0][1]) / qw4
            
            return float4(qx, qy, qz, qw)
            
        } else if mat[0][0] > mat[1][1] && mat[0][0] > mat[2][2] {
            
            let qw4 = 2.0 * sqrtf(1.0 + mat[0][0] - mat[1][1] - mat[2][2])

            let qw = (mat[2][1] - mat[1][2])/qw4
            let qx = 0.25 * qw4
            let qy = (mat[0][1] + mat[1][0])/qw4
            let qz = (mat[0][2] + mat[2][0])/qw4
            
            return float4(qx, qy, qz, qw)
            
        } else if mat[1][1] > mat[2][2] {
            
            let qw4 = 2.0 * sqrtf(1.0 + mat[1][1] - mat[0][0] - mat[2][2])
            
            let qw = (mat[0][2] - mat[2][0])/qw4
            let qx = (mat[0][1] + mat[1][0])/qw4
            let qy = 0.25 * qw4
            let qz = (mat[1][2] + mat[2][1])/qw4
            return float4(qx, qy, qz, qw)
            
        } else{
            let qw4 = 2.0 * sqrtf(1.0 + mat[2][2] - mat[0][0] - mat[1][1])
        
            let qw = (mat[1][0] - mat[0][1])/qw4
            let qx = (mat[0][2] + mat[2][0])/qw4
            let qy = (mat[1][2] + mat[2][1])/qw4
            let qz = 0.25 * qw4
            
            return float4(qx, qy, qz, qw)
        }
        
//        return float4(qx, qy, qz, qw)
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
        
//        mat1[0][0] = 1 - 2 * q.y * q.y - 2 * q.z * q.z
//        mat1[0][1] = 2 * q.x * q.y - 2 * q.z * q.w
//        mat1[0][2] = 2 * q.x * q.z + 2 * q.y * q.w
//        
//        mat1[1][0] = 2 * q.x * q.y + 2 * q.z * q.w
//        mat1[1][1] = 1 - 2 * q.x * q.x - 2 * q.z * q.z
//        mat1[1][2] = 2 * q.y * q.z - 2 * q.x * q.w
//        
//        mat1[2][0] = 2 * q.x * q.z - 2 * q.y * q.w
//        mat1[2][1] = 2 * q.y * q.z + 2 * q.x * q.w
//        mat1[2][2] = 1 - 2 * q.x * q.x - 2 * q.y * q.y
//        
//        return mat1
        
//        let sqw = q.w * q.w
//        let sqx = q.x * q.x
//        let sqy = q.y * q.y
//        let sqz = q.z * q.z
//        
//        let inv = 1 / (sqx + sqy + sqz + sqw)
//        
//        mat1[0][0] = ( sqx - sqy - sqz + sqw) * inv
//        mat1[1][1] = (-sqx + sqy - sqz + sqw) * inv
//        mat1[2][2] = (-sqx - sqy + sqz + sqw) * inv
//        
//        var tmp1 = q.x * q.y
//        var tmp2 = q.z * q.w
//        mat1[1][0] = 2.0 * (tmp1 + tmp2) * inv
//        mat1[0][1] = 2.0 * (tmp1 - tmp2) * inv
//        
//        tmp1 = q.x * q.z
//        tmp2 = q.y * q.w
//        mat1[2][0] = 2.0 * (tmp1 - tmp2) * inv
//        mat1[0][2] = 2.0 * (tmp1 + tmp2) * inv
//        
//        tmp1 = q.y * q.z
//        tmp2 = q.x * q.w
//        mat1[2][1] = 2.0 * (tmp1 + tmp2) * inv
//        mat1[1][2] = 2.0 * (tmp1 - tmp2) * inv
//        
//        return mat1
        
    }
    
    class func slerp(t : Float, q1 : float4, var q2 : float4) -> float4{
        
        let cos_theta_div2 = q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z

//        //WARNING, unneccessary?
//        if cos_theta_div2 < 0.0 {
//            q2.w = -q2.w; q2.x = -q2.x; q2.y = -q2.y; q2.z = q2.z;
//            cos_theta_div2 = -cos_theta_div2
//        }
        
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
}

func / (left : float3, right : Float) ->float3 {
    var l = left
    l.x = l.x/right
    l.y = l.y/right
    l.z = l.z/right
    return l
}

extension float3{
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