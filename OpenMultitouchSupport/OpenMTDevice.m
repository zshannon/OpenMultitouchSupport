//
//  OpenMTDevice.m
//  OpenMultitouchSupport
//
//  Created by Zane Shannon on 1/31/24.
//  Copyright © 2024 Takuto Nakamura. All rights reserved.
//

#import "OpenMTDeviceInternal.h"

@implementation OpenMTDevice

- (NSString *)description {
    return [NSString stringWithFormat:@"type: %i; deviceID: %llu; familyId: %i; height: %i; width: %i; cols: %i; rows: %i; isOpaque: %b", _type, _deviceID, _familyID, _height, _width, _cols, _rows, _isOpaque];
}

@end
