//
//  OpenMTDeviceInternal.h
//  OpenMultitouchSupport
//
//  Created by Zane Shannon on 1/31/24.
//  Copyright © 2024 Takuto Nakamura. All rights reserved.
//

#ifndef OpenMTDeviceInternal_h
#define OpenMTDeviceInternal_h

#import "OpenMTDevice.h"

typedef void *MTDeviceRef;
MTDeviceRef MTDeviceCreateDefault(void);

@interface OpenMTDevice()

@property (assign, readwrite) uuid_t* guid;
@property (assign, readwrite) int type;
@property (assign, readwrite) uint64_t deviceID;
@property (assign, readwrite) int familyID;
@property (assign, readwrite) int height;
@property (assign, readwrite) int width;
@property (assign, readwrite) int cols;
@property (assign, readwrite) int rows;
@property (assign, readwrite) bool isOpaque;
@property (assign, readwrite) MTDeviceRef* ref;

@end

#endif /* OpenMTDeviceInternal_h */
