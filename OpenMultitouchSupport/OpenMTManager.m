//
//  OpenMTManager.m
//  OpenMultitouchSupport
//
//  Created by Takuto Nakamura on 2019/07/11.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OpenMTManagerInternal.h"
#import "OpenMTListenerInternal.h"
#import "OpenMTTouchInternal.h"
#import "OpenMTEventInternal.h"
#import "OpenMTDeviceInternal.h"
#import "OpenMTInternal.h"

@interface OpenMTManager()

@property (strong, readwrite) NSMutableArray *devices;
@property (strong, readwrite) NSMutableArray *listeners;
@property (strong, readwrite) NSTimer *timer;

@end

@implementation OpenMTManager

+ (BOOL)systemSupportsMultitouch {
    return MTDeviceIsAvailable();
}

+ (OpenMTManager *)sharedManager {
    static OpenMTManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = self.new;
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.devices = NSMutableArray.new;
        self.listeners = NSMutableArray.new;
        
        [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(willSleep:) name:NSWorkspaceWillSleepNotification object:nil];
        [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(didWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
    }
    return self;
}

//- (void)handlePathEvent:(OpenMTTouch *)touch {
//    NSLog(@"%@", touch.description);
//}

- (void)checkMultitouchHardware {
    CGDirectDisplayID builtInDisplay = 0;
    CGDirectDisplayID activeDisplays[10];
    uint32_t numActiveDisplays;
    CGGetActiveDisplayList(10, activeDisplays, &numActiveDisplays);
    
    int activeDisplayCount = (int)numActiveDisplays;
    while (--activeDisplayCount >= 0) {
        if (CGDisplayIsBuiltin(activeDisplays[activeDisplayCount])) {
            builtInDisplay = activeDisplays[activeDisplayCount];
            break;
        }
    }
//    laptopLidClosed = (builtInDisplay == 0);
    
    NSArray *mtDevices = (NSArray *)CFBridgingRelease(MTDeviceCreateList());
    if (self.devices.count && self.devices.count != (int)mtDevices.count) {
        [self restartHandlingMultitouchEvents:nil];
    }
}

- (void)handleMultitouchEvent:(OpenMTEvent *)event {
    OpenMTDevice *device;

    for (int i = 0; i < (int)self.devices.count; i++) {
        if (device) continue;
        OpenMTDevice *d = self.devices[i];
        if (event.deviceID == (int)d.ref) {
            device = d;
        }
    }
    if (device) {
        event.device = device;
    }
    for (int i = 0; i < (int)self.listeners.count; i++) {
        OpenMTListener *listener = self.listeners[i];
        if (listener.dead) {
            [self removeListener:listener];
            continue;
        }
        if (!listener.listening) {
            continue;
        }
        dispatchResponse(^{
            [listener listenToEvent:event];
        });
    }
}

- (void)startHandlingMultitouchEvents {
    if (self.devices.count) {
        return;
    }
    
    NSArray *mtDevices = (NSArray *)CFBridgingRelease(MTDeviceCreateList());
    
    int mtDeviceCount = (int)mtDevices.count;
    while (--mtDeviceCount >= 0) {
        MTDeviceRef deviceRef = (__bridge MTDeviceRef)(mtDevices[mtDeviceCount]);
        
        @try {
            uuid_t guid;
            OSStatus err = MTDeviceGetGUID(deviceRef, &guid);
            if (!err) {
                uuid_string_t val;
                uuid_unparse(guid, val);
//                NSLog(@"GUID: %s", val);
            }
            
            int type;
            err = MTDeviceGetDriverType(deviceRef, &type);
//            if (!err) NSLog(@"Driver Type: %d", type);
            
            uint64_t deviceID;
            err = MTDeviceGetDeviceID(deviceRef, &deviceID);
//            if (!err) NSLog(@"DeviceID: %llu", deviceID);
            
            int familyID;
            err = MTDeviceGetFamilyID(deviceRef, &familyID);
//            if (!err) NSLog(@"FamilyID: %d", familyID);
            
            int width, height;
            err = MTDeviceGetSensorSurfaceDimensions(deviceRef, &width, &height);
//            if (!err) NSLog(@"Surface Dimensions: %d x %d ", width, height);
            
            int rows, cols;
            err = MTDeviceGetSensorDimensions(deviceRef, &rows, &cols);
//            if (!err) NSLog(@"Dimensions: %d x %d ", rows, cols);
            
            bool isOpaque = MTDeviceIsOpaqueSurface(deviceRef);
//            NSLog(isOpaque ? @"Opaque: true" : @"Opaque: false");
            
            OpenMTDevice *device = OpenMTDevice.new;
            device.guid = &guid;
            device.type = type;
            device.deviceID = deviceID;
            device.familyID = familyID;
            device.height = height;
            device.width = width;
            device.cols = cols;
            device.rows = rows;
            device.isOpaque = isOpaque;
            device.ref = deviceRef;
            
            MTRegisterContactFrameCallback(deviceRef, contactEventHandler);
            MTDeviceStart(deviceRef, 0);
            [self.devices addObject:device];
        } @catch (NSException *exception) {}
    }

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkMultitouchHardware) userInfo:nil repeats:YES];
}

- (void)stopHandlingMultitouchEvents {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    if (!self.devices.count) {
        return;
    }
    
    int deviceCount = (int)self.devices.count;
    while (--deviceCount >= 0) {
        OpenMTDevice *device = self.devices[deviceCount];
        
        [self.devices removeObject:device];
        
        @try {
            MTDeviceRef mtDevice = device.ref;
            MTUnregisterContactFrameCallback(mtDevice, contactEventHandler);
            MTDeviceStop(mtDevice);
            /// NB: this maybe needs to be here but causes hard crash if it is so...
//            MTDeviceRelease(mtDevice);
        } @catch (NSException *exception) {}
    }
}

- (void)restartHandlingMultitouchEvents:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopHandlingMultitouchEvents];
        [self startHandlingMultitouchEvents];
    });
}

- (void)willSleep:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopHandlingMultitouchEvents];
    });
}

- (void)didWakeUp:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.listeners.count > 0) {
            [self startHandlingMultitouchEvents];
        }
    });
}

// Public Function

- (OpenMTListener *)addListenerWithCallback:(OpenMTEventCallback)callback {
    __block OpenMTListener *listener = nil;
    dispatchSync(dispatch_get_main_queue(), ^{
        if (!self.class.systemSupportsMultitouch) { return; }
        listener = [[OpenMTListener alloc] initWithCallback:callback];
        if (self.listeners.count == 0) {
            [self startHandlingMultitouchEvents];
        }
        [self.listeners addObject:listener];
    });
    return listener;
}

- (OpenMTListener *)addListenerWithTarget:(id)target selector:(SEL)selector {
    __block OpenMTListener *listener = nil;
    dispatchSync(dispatch_get_main_queue(), ^{
        if (!self.class.systemSupportsMultitouch) { return; }
        listener = [[OpenMTListener alloc] initWithTarget:target selector:selector];
        if (self.listeners.count == 0) {
            [self startHandlingMultitouchEvents];
        }
        [self.listeners addObject:listener];
    });
    return listener;
}

- (void)removeListener:(OpenMTListener *)listener {
    dispatchSync(dispatch_get_main_queue(), ^{
        [self.listeners removeObject:listener];
        if (self.listeners.count == 0) {
            [self stopHandlingMultitouchEvents];
        }
    });
}

// Utility Tools C Language
static void dispatchSync(dispatch_queue_t queue, dispatch_block_t block) {
    if (!strcmp(dispatch_queue_get_label(queue), dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))) {
        block();
        return;
    }
    dispatch_sync(queue, block);
}

static void dispatchResponse(dispatch_block_t block) {
    static dispatch_queue_t responseQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        responseQueue = dispatch_queue_create("com.kyome.openmt", DISPATCH_QUEUE_SERIAL);
    });
    dispatch_sync(responseQueue, block);
}

static void contactEventHandler(MTDeviceRef eventDevice, MTTouch eventTouches[], int numTouches, double timestamp, int frame) {
    NSMutableArray *touches = [NSMutableArray array];
    
    for (int i = 0; i < numTouches; i++) {
        OpenMTTouch *touch = [[OpenMTTouch alloc] initWithMTTouch:&eventTouches[i]];
        [touches addObject:touch];
    }
    
    OpenMTEvent *event = OpenMTEvent.new;
    event.touches = touches;
    event.deviceID = (int)eventDevice;
    event.frameID = frame;
    event.timestamp = timestamp;
    
    [OpenMTManager.sharedManager handleMultitouchEvent:event];
}

//static void pathEventHandler(MTDeviceRef device, long pathID, long state, MTTouch* touch) {
//    OpenMTTouch *otouch = [[OpenMTTouch alloc] initWithMTTouch:touch];
//    [OpenMTManager.sharedManager handlePathEvent:otouch];
//}

@end
