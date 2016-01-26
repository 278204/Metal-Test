//
//  CPP_Wrapper.h
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-05.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

// File: CPP-Wrapper.h


#import <UIKit/UIKit.h>
@interface CPP_Wrapper : NSObject
- (NSDictionary *) hello_cpp_wrapped:(NSString *)name;
- (NSDictionary *) importAnimaiton:(NSString *)name;
@end

