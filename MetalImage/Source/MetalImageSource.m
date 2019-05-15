//
//  MetalImageSource.m
//  MetalImage
//
//  Created by David.Dai on 2018/11/30.
//

#import "MetalImageSource.h"

@interface MetalImageSource()
@property (nonatomic, strong) id<MetalImageTarget> syncTarget;
@property (nonatomic, strong) NSMutableArray<id<MetalImageTarget>> *asncTargets;
@end

@implementation MetalImageSource

- (NSMutableArray<id<MetalImageTarget>> *)asncTargets {
    if (!_asncTargets) {
        _asncTargets = [[NSMutableArray alloc] init];
    }
    return _asncTargets;
}

- (BOOL)haveTarget {
    if (!_syncTarget && (!_asncTargets || !_asncTargets.count)) {
        return NO;
    }
    return YES;
}

- (void)addTarget:(id<MetalImageTarget>)target {
    if (!target) {
        return;
    }
    
    if (!_syncTarget) {
        _syncTarget = target;
    } else {
        [self.asncTargets addObject:target];
    }
}

-(void)removeTarget:(id<MetalImageTarget>)target {
    if (!target) {
        return;
    }
    
    if (target == _syncTarget) {
        _syncTarget = nil;
    }
    
    if ([self.asncTargets containsObject:target]) {
        [self.asncTargets removeObject:target];
    }
}

- (void)removeAllTarget {
    _syncTarget = nil;
    [_asncTargets removeAllObjects];
}

- (void)send:(MetalImageResource *)resource withTime:(CMTime)time {
    if (!_asncTargets || !_asncTargets.count) {
        [_syncTarget receive:resource withTime:time];
        return;
    }
    
    dispatch_queue_t processQueue = resource.processingQueue ? resource.processingQueue : [MetalImageDevice shared].concurrentQueue;
    id<MetalImageTarget> snycTarget = _syncTarget;
    
    for (NSUInteger index = 0; index < _asncTargets.count; index++) {
        id<MetalImageTarget> asyncTarget = [_asncTargets objectAtIndex:index];
        @autoreleasepool {
            MetalImageResource *newResource = [resource newResourceFromSelf];
            dispatch_async(processQueue, ^{
                [asyncTarget receive:newResource withTime:time];
            });
        }
    }
    
    [snycTarget receive:resource withTime:time];
}

- (NSArray<id<MetalImageTarget>> *)targets {
    NSMutableArray *array = @[].mutableCopy;
    if (_syncTarget) {
        [array addObject:_syncTarget];
    }
    
    if (_asncTargets) {
        [array addObjectsFromArray:_asncTargets];
    }
    return array;
}
@end
