//
//  MetalImageSource.m
//  MetalImage
//
//  Created by David.Dai on 2018/11/30.
//

#import "MetalImageSource.h"

@interface MetalImageSource()
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
    if (!_target && (!_asncTargets || !_asncTargets.count)) {
        return NO;
    }
    return YES;
}

- (void)setTarget:(id<MetalImageTarget>)target {
    _target = target;
}

- (void)addAsyncTarget:(id<MetalImageTarget>)target {
    if (![self.asncTargets containsObject:target]) {
        [self.asncTargets addObject:target];
    }
}

-(void)removeTarget:(id<MetalImageTarget>)target {
    if (target == _target) {
        _target = nil;
    }
    
    if ([self.asncTargets containsObject:target]) {
        [self.asncTargets removeObject:target];
    }
}

- (void)removeAllTarget {
    _target = nil;
    [_asncTargets removeAllObjects];
}

- (void)send:(MetalImageResource *)resource withTime:(CMTime)time {
    if (!_asncTargets || !_asncTargets.count) {
        [_target receive:resource withTime:time];
        return;
    }
    
    dispatch_queue_t processQueue = resource.processingQueue ? resource.processingQueue : [MetalImageDevice shared].concurrentQueue;
    NSUInteger startAsncIndex = 0;
    id<MetalImageTarget> snycTarget = _target;
    if (!_target) {
        snycTarget = [_asncTargets firstObject];
        startAsncIndex = 1;
    }
    
    for (NSUInteger index = startAsncIndex; index < _asncTargets.count; index++) {
        id<MetalImageTarget> asyncTarget = [_asncTargets objectAtIndex:index];
        MetalImageResource *newResource = [resource newResourceFromSelf];
        dispatch_async(processQueue, ^{
            [asyncTarget receive:newResource withTime:time];
        });
    }
    
    [snycTarget receive:resource withTime:time];
}

@end
