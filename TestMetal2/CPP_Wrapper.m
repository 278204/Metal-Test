//
//  CPP_Wrapper.m
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-05.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

// File: CPP-Wrapper.mm
#import "CPP_Wrapper.h"

#import "TBXML.h"
#import <simd/simd.h>

@implementation CPP_Wrapper

- (NSDictionary *) hello_cpp_wrapped:(NSString *)name {
    
    NSError *error = nil;
    TBXML *xml = [TBXML newTBXMLWithXMLFile:[NSString stringWithFormat:@"%@.xml", name] error:&error];
    
    
    if(error) {
        NSLog(@"Couldn't open file, %@", error.description);
        return @{};
    }
    TBXMLElement *root = xml.rootXMLElement;
    
    TBXMLElement *geometry = [self traverseToChild:@[@"library_geometries", @"geometry"] fromParent:root];
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    while(error == nil) {
        NSString *geometry_id = [TBXML valueOfAttributeNamed:@"id" forElement:geometry];
        NSLog(@"Parsing: %@", geometry_id);
        TBXMLElement *source = [self traverseToChild:@[@"mesh", @"source"] fromParent:geometry];
        
        NSArray *a = [self parse:source root:root];
        [arr addObject:a];
        
        geometry = [TBXML nextSiblingNamed:@"geometry" searchFromElement:geometry error:&error];
    }
    
    NSDictionary *skin_dict = [self parseSkinningData:root];
    if(skin_dict == nil) {
        return @{@"geometry":arr[0]};
    }
    
    NSArray *skeleton_array = [self parseSkeleton:root skeletonName:skin_dict[@"name"]];
    NSArray *animations = [self parseAllAnimations:root];
    
    return @{@"geometry":arr[0], @"skin":skin_dict, @"skeleton":skeleton_array, @"animations" : animations};
}


-(NSArray *)parse:(TBXMLElement *)source root:(TBXMLElement *)root {
    NSString *source_id = [TBXML valueOfAttributeNamed:@"id" forElement:source];
    NSString *vertex_string = @"";
    NSString *normals_string = @"";
    NSString *tex_string = @"";
    if([source_id rangeOfString:@"-positions"].location != NSNotFound){
        
        TBXMLElement *floats = [TBXML childElementNamed:@"float_array" parentElement:source];
        int count = [[TBXML valueOfAttributeNamed:@"count" forElement:floats] intValue];
        vertex_string = [TBXML textForElement:floats];
        NSLog(@"Parse vertices, floats %d", count);
    }
    
    source = [TBXML nextSiblingNamed:@"source" searchFromElement:source];
    source_id = [TBXML valueOfAttributeNamed:@"id" forElement:source];
    if([source_id rangeOfString:@"-normals"].location != NSNotFound){
        TBXMLElement *floats = [TBXML childElementNamed:@"float_array" parentElement:source];
        int count = [[TBXML valueOfAttributeNamed:@"count" forElement:floats] intValue];
        normals_string = [TBXML textForElement:floats];
        NSLog(@"Parse normals, floats %d", count);
    }
    
    source = [TBXML nextSiblingNamed:@"source" searchFromElement:source];
    source_id = [TBXML valueOfAttributeNamed:@"id" forElement:source error:nil];
    if([source_id rangeOfString:@"-map"].location != NSNotFound) {
        TBXMLElement *floats = [TBXML childElementNamed:@"float_array" parentElement:source];
        tex_string = [TBXML textForElement:floats];
    }
    
    source = [TBXML nextSiblingNamed:@"polylist" searchFromElement:source];
    
    TBXMLElement *p = [TBXML childElementNamed:@"p" parentElement:source];
    NSString *vertices_and_normals_indexes = [TBXML textForElement:p];
    
    TBXMLElement *first_node = [self traverseToChild:@[@"library_visual_scenes", @"visual_scene", @"node"] fromParent:root];
    NSString *transform_matrix = [self getGeometryTransform:first_node];
    NSLog(@"transform: %@", transform_matrix);
    return @[vertex_string, normals_string, vertices_and_normals_indexes, transform_matrix, tex_string];
}


-(NSString *)getGeometryTransform:(TBXMLElement *)node {
    NSError *error = nil;
    [TBXML childElementNamed:@"instance_geometry" parentElement:node error:&error];
    if(error != nil) {
        error = nil;
        TBXMLElement *sibling = [TBXML nextSiblingNamed:@"node" searchFromElement:node error:&error];
        if(error == nil)
            return [self getGeometryTransform:sibling];
        else
            return @"";
    }
    return [TBXML textForElement:[TBXML childElementNamed:@"matrix" parentElement:node]];
}

-(TBXMLElement *)traverseToChild:(NSArray *)children fromParent:(TBXMLElement*)parent{
    TBXMLElement *newParent = parent;
    for(NSString *s in children){
        NSError *e;
        newParent = [TBXML childElementNamed:s parentElement:newParent error:&e];
        if(e){
            NSLog(@"ERROR traversing %@, %@", s, e.description);
            return nil;
        }
    }
    return newParent;
}



-(NSDictionary *)parseSkinningData:(TBXMLElement *)root{
    NSError *e = nil;
    TBXMLElement *library_controllers = [TBXML childElementNamed:@"library_controllers" parentElement:root];
    TBXMLElement *controller = [TBXML childElementNamed:@"controller" parentElement:library_controllers];
    TBXMLElement *skin = [TBXML childElementNamed:@"skin" parentElement:controller error:&e];
    
    if(e != nil) {
        return nil;
    }
    
    NSString *skeleton_id = [TBXML valueOfAttributeNamed:@"name" forElement:controller];
    
    controller = nil;
    library_controllers = nil;
    
    TBXMLElement *joints_elem = [TBXML childElementNamed:@"joints" parentElement:skin];
    NSString *joint_src = [self findSource:joints_elem semantic:@"JOINT"];
    NSString *inv_bind_matrix_src = [self findSource:joints_elem semantic:@"INV_BIND_MATRIX"];
    
    TBXMLElement *vertex_weights_elem = [TBXML childElementNamed:@"vertex_weights" parentElement:skin];
    NSString *weights_src = [self findSource:vertex_weights_elem semantic:@"WEIGHT"];
    
    NSString *weights = [self getWeights:skin source:weights_src];
    NSString *bind_shape_matrix = [self getBindShapeMatrix:skin];
    NSString *joints = [self getJoints:skin source:joint_src];
    NSString *weights_indicies = [self getVertexWeights:skin];
    NSString *inv_bind_matrix = [self getBindPose:skin source:inv_bind_matrix_src];

    
    NSDictionary *d = @{@"name":skeleton_id, @"weights":weights, @"bind_shape":bind_shape_matrix, @"joints":joints, @"weights_indicies":weights_indicies, @"inv_bind_matrix":inv_bind_matrix};
    return d;

}

-(NSMutableArray *)parseSkeleton:(TBXMLElement *)root skeletonName:(NSString *)skeleton_name{
    TBXMLElement *library_visual_scene  = [TBXML childElementNamed:@"library_visual_scenes" parentElement:root];
    TBXMLElement *visual_scene          = [TBXML childElementNamed:@"visual_scene" parentElement:library_visual_scene];
    TBXMLElement *skeleton_node         = [self getChildWithName:@"node" ID:skeleton_name fromParent:visual_scene];

    NSMutableArray *skeleton_array = [[NSMutableArray alloc] init];
    [self parseSkeletonNode:skeleton_node level:0 array:skeleton_array parent:@""];
    
    int level = 0;
    for(NSArray * a in skeleton_array){
        for(NSDictionary *d in a){
            NSLog(@"Name:%d %@", level, d[@"name"]);
        }
        level++;
    }
    
    return skeleton_array;
}

-(NSMutableArray *)parseSkeletonNode:(TBXMLElement*)node level:(int)level array:(NSMutableArray *)arr parent:(NSString *)parent{

    NSString *node_name = [TBXML valueOfAttributeNamed:@"id" forElement:node];
    NSString *transform = [self getMatrix:node];
//    NSLog(@"Parsing:%d %@", level, node_name);
    if(arr.count <= level){
        NSMutableArray *level_arr = [[NSMutableArray alloc] init];
        [arr insertObject:level_arr atIndex:level];
    }

    [arr[level] addObject:@{@"name":node_name, @"transform":transform, @"parent":parent}];
    
    NSError *error = nil;
    TBXMLElement *first_child = [TBXML childElementNamed:@"node" parentElement:node error:&error];
    if(error == nil ) {
        arr = [self parseSkeletonNode:first_child level:level+1 array:arr parent:node_name];
    }
    
    error = nil;
    TBXMLElement *first_neighbour = [TBXML nextSiblingNamed:@"node" searchFromElement:node error:&error];
    if(error == nil && level > 0) {
        arr = [self parseSkeletonNode:first_neighbour level:level array:arr parent:parent];
    }
    return arr;
}

-(NSString *)getMatrix:(TBXMLElement *)node{
    NSError *e = nil;
    TBXMLElement *child = [TBXML childElementNamed:@"matrix" parentElement:node error:&e];
    if(e == nil) {
        return [TBXML textForElement:child];
    }
    //WARNING: Parse translate, rotate, scale
//    TBXMLElement *translate = [TBXML childElementNamed:@"translate" parentElement:node];
//    TBXMLElement *rotateZ = [TBXML nextSiblingNamed:@"rotate" searchFromElement:translate];
//    TBXMLElement *rotateY = [TBXML nextSiblingNamed:@"rotate" searchFromElement:rotateZ];
//    TBXMLElement *rotateX = [TBXML nextSiblingNamed:@"rotate" searchFromElement:rotateY];
//    TBXMLElement *scale = [TBXML nextSiblingNamed:@"scale" searchFromElement:rotateX];
//    
//    NSString *translate_string = [TBXML textForElement:translate];
//    NSString *rotateZ_string = [TBXML textForElement:rotateZ];
//    NSString *rotateY_string = [TBXML textForElement:rotateY];
//    NSString *rotateX_string = [TBXML textForElement:rotateX];
//    NSString *scale_string = [TBXML textForElement:scale];
    
    return @"1 0 0 0 0 1 0 0 0 0 1 -2.102737 0 0 0 1";
}

-(NSString *)findSource:(TBXMLElement *)parent semantic:(NSString *)semantic{
    TBXMLElement *child = [TBXML childElementNamed:@"input" parentElement:parent];
    NSString *source = @"";
    while (true) {
        NSString *child_semantic = [TBXML valueOfAttributeNamed:@"semantic" forElement:child];
        if([child_semantic isEqualToString:semantic]){
            source = [TBXML valueOfAttributeNamed:@"source" forElement:child];
            break;
        } else {
            child = [TBXML nextSiblingNamed:@"input" searchFromElement:child];
        }
    }
    source = [source stringByReplacingOccurrencesOfString:@"#" withString:@""];
    return source;
}

-(NSString *)getBindShapeMatrix:(TBXMLElement *)skin{
    return [TBXML textForElement:[TBXML childElementNamed:@"bind_shape_matrix" parentElement:skin]];
}

-(NSString *)getJoints:(TBXMLElement *)skin source:(NSString *)source{
    TBXMLElement *joint_elem = [self getChildWithName:@"source" ID:source fromParent:skin];
    return [TBXML textForElement:[TBXML childElementNamed:@"Name_array" parentElement:joint_elem]];
}
-(NSString *)getBindPose:(TBXMLElement *)skin source:(NSString *)source{
    TBXMLElement *bind_pose_elem = [self getChildWithName:@"source" ID:source fromParent:skin];
    TBXMLElement *float_array = [TBXML childElementNamed:@"float_array" parentElement:bind_pose_elem];
    NSString *count = [TBXML valueOfAttributeNamed:@"count" forElement:float_array];
    NSString *val = [TBXML textForElement:float_array];
    return [NSString stringWithFormat:@"%@||%@", count, val];
}
-(NSString *)getWeights:(TBXMLElement *)skin source:(NSString *)source{
    return [self getFloatArrayFromSource:skin source:source];
}
-(NSString *)getFloatArrayFromSource:(TBXMLElement *)parent source:(NSString *)source {
    TBXMLElement *elem = [self getChildWithName:@"source" ID:source fromParent:parent];
    return [TBXML textForElement:[TBXML childElementNamed:@"float_array" parentElement:elem]];
}

-(NSString *)getFloatArrayCountFromSource:(TBXMLElement *)parent source:(NSString *)source {
    TBXMLElement *elem = [self getChildWithName:@"source" ID:source fromParent:parent];
    return [TBXML valueOfAttributeNamed:@"count" forElement:[TBXML childElementNamed:@"float_array" parentElement:elem]];
}

-(NSString *)getVertexWeights:(TBXMLElement *)skin {
    TBXMLElement *vertex_weights_elem = [TBXML childElementNamed:@"vertex_weights" parentElement:skin];
    NSString *count = [TBXML valueOfAttributeNamed:@"count" forElement:vertex_weights_elem];
    NSString *vcount = [TBXML textForElement:[TBXML childElementNamed:@"vcount" parentElement:vertex_weights_elem]];
    NSString *indicies = [TBXML textForElement:[TBXML childElementNamed:@"v" parentElement:vertex_weights_elem]];
    return [NSString stringWithFormat:@"%@||%@||%@", count,vcount, indicies];
}

-(TBXMLElement *)getChildWithName:(NSString *)name ID:(NSString *)id_s fromParent:(TBXMLElement *)parent{
    TBXMLElement *child = [TBXML childElementNamed:name parentElement:parent];

    while (true) {
        NSString *child_id = [TBXML valueOfAttributeNamed:@"id" forElement:child];
        if([child_id isEqualToString:id_s]){
            return child;

        } else {
            child = [TBXML nextSiblingNamed:name searchFromElement:child];
        }
    }
    return nil;
}




-(NSMutableArray *)parseAllAnimations:(TBXMLElement *)root{
    NSError *e = nil;
    TBXMLElement *library_animations = [TBXML childElementNamed:@"library_animations" parentElement:root];
    TBXMLElement *animation = [TBXML childElementNamed:@"animation" parentElement:library_animations error:&e];
    NSMutableArray *animations = [[NSMutableArray alloc] init];
    while(e == nil) {
        
        NSDictionary *d = [self parseAnimation:animation];
        [animations addObject:d];
        e = nil;
        animation = [TBXML nextSiblingNamed:@"animation" searchFromElement:animation error:&e];

    }
    return animations;
}

-(NSDictionary *)parseAnimation:(TBXMLElement *)animation{
    
    TBXMLElement *channel = [TBXML childElementNamed:@"channel" parentElement:animation];
    NSString *channel_target = [TBXML valueOfAttributeNamed:@"target" forElement:channel];
    NSString *joint_name = [channel_target componentsSeparatedByString:@"/"].firstObject;
    
    TBXMLElement *sampler = [TBXML childElementNamed:@"sampler" parentElement:animation];
    NSString *input_src = [self findSource:sampler semantic:@"INPUT"];
    NSString *output_src = [self findSource:sampler semantic:@"OUTPUT"];
    NSString *interpol_src = [self findSource:sampler semantic:@"INTERPOLATION"];
    
    NSString *times = [self getFloatArrayFromSource:animation source:input_src];
    NSString *times_count = [self getFloatArrayCountFromSource:animation source:input_src];
    NSString *values = [self getFloatArrayFromSource:animation source:output_src];
    
    
    return @{@"joint":joint_name, @"times":times, @"values":values, @"count":times_count};
}

@end