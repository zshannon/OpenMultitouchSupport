//
//  OpenMTDevice.h
//  OpenMultitouchSupport
//
//  Created by Zane Shannon on 1/31/24.
//  Copyright © 2024 Takuto Nakamura. All rights reserved.
//

#ifndef OpenMTDevice_h
#define OpenMTDevice_h

#import <Foundation/Foundation.h>

@interface OpenMTDevice: NSObject

@property (assign, readonly) uuid_t* guid;
@property (assign, readonly) int type;
@property (assign, readonly) uint64_t deviceID;
@property (assign, readonly) int familyID;
@property (assign, readonly) int height;
@property (assign, readonly) int width;
@property (assign, readonly) int cols;
@property (assign, readonly) int rows;
@property (assign, readonly) bool isOpaque;

@end

#endif /* OpenMTDevice_h */
