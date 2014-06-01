//
//  XYObserve.m
//  JoinShow
//
//  Created by Heaven on 13-11-6.
//  Copyright (c) 2013年 Heaven. All rights reserved.
//

#import "XYObserver.h"
#import "XYPrecompile.h"

void (*action)(id, SEL, ...) = (void (*)(id, SEL, ...))objc_msgSend;

#pragma mark - XYObserver
@interface XYObserver ()

@property (nonatomic, assign) XYObserverType type;      // 观察者的类型

@property (nonatomic, weak) id target;                  // 被观察的对象的值改变时后的响应方法所在的对象
@property (nonatomic, assign) SEL selector;             // 被观察的对象的值改变时后的响应方法
@property (nonatomic, copy) XYObserver_block_sourceObject_new_old block;        // 值改变时执行的block

@property (nonatomic, assign) id  sourceObject;         // 被观察的对象
@property (nonatomic, strong) NSString *keyPath;        // 被观察的对象的keyPath

-(instancetype) initWithSourceObject:(id)sourceObject keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector type:(XYObserverType)type;

-(instancetype) initWithSourceObject:(id)sourceObject keyPath:(NSString*)keyPath block:(XYObserver_block_sourceObject_new_old)block;

@end

@implementation XYObserver

-(instancetype) initWithSourceObject:(id)sourceObject keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector type:(XYObserverType)type
{
    self = [super init];
    if (self) {
        _target = target;
        _selector = selector;
        _sourceObject = sourceObject;
        _keyPath = keyPath;
        _type = type;
        [_sourceObject addObserver:self forKeyPath:keyPath options:XYObserver_newAndNew context:nil];
    } 
    return self; 
}

-(instancetype) initWithSourceObject:(id)sourceObject keyPath:(NSString*)keyPath block:(XYObserver_block_sourceObject_new_old)block{
    self = [super init];
    if (self) {
        _sourceObject = sourceObject;
        _keyPath = keyPath;
        _block = block;
        [_sourceObject addObserver:self forKeyPath:keyPath options:XYObserver_newAndNew context:nil];
    }
    return self;
}
-(void) dealloc
{
    if (_sourceObject) { [_sourceObject removeObserver:self forKeyPath:_keyPath]; }
}

#pragma mark NSKeyValueObserving
-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    __weak __typeof(self) weakSelf = self;
    if (_block) {
        _block(weakSelf, change[NSKeyValueChangeNewKey], change[NSKeyValueChangeOldKey]);
        return;
    }
    
    if (_type == XYObserverType_new) {
        action(_target, _selector, change[NSKeyValueChangeNewKey]);
    }else if (_type == XYObserverType_new_old) {
        action(_target, _selector, change[NSKeyValueChangeNewKey], change[NSKeyValueChangeOldKey]);
    }else if (_type == XYObserverType_self_new) {
        action(_target, _selector, _sourceObject, change[NSKeyValueChangeNewKey]);
    }else if (_type == XYObserverType_self_new_old) {
        action(_target, _selector, _sourceObject, change[NSKeyValueChangeNewKey], change[NSKeyValueChangeOldKey]);
    }
}

@end

#pragma mark - NSObject (XYObserverPrivate)
@interface NSObject (XYObserverPrivate)

-(void) observeWithObject:(id)sourceObject keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector type:(XYObserverType)type;

@end

@implementation NSObject (XYObserver)

@dynamic observers;

-(id) observers{
    id object = objc_getAssociatedObject(self, NSObject_observers);
    
    if (nil == object) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:8];
        objc_setAssociatedObject(self, NSObject_observers, dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return dic;
    }
    
    return object;
}

-(void) observeWithObject:(id)object property:(NSString*)property{
    SEL aSel = NSSelectorFromString([NSString stringWithFormat:@"%@New:", property]);
    if ([self respondsToSelector:aSel]) {
        [self observeWithObject:object
                        keyPath:property
                         target:self
                       selector:aSel
                        type:XYObserverType_new];
        return;
    }
    
    aSel = NSSelectorFromString([NSString stringWithFormat:@"%@New:old:", property]);
    if ([self respondsToSelector:aSel]) {
        [self observeWithObject:object
                        keyPath:property
                         target:self selector:aSel
                        type:XYObserverType_new_old];
        return;
    }
    
    aSel = NSSelectorFromString([NSString stringWithFormat:@"%@In:new:", property]);
    if ([self respondsToSelector:aSel]) {
        [self observeWithObject:object
                        keyPath:property
                         target:self
                       selector:aSel
                           type:XYObserverType_self_new];
        return;
    }
    
    aSel = NSSelectorFromString([NSString stringWithFormat:@"%@In:new:old:", property]);
    if ([self respondsToSelector:aSel]) {
        [self observeWithObject:object
                        keyPath:property
                         target:self
                       selector:aSel
                           type:XYObserverType_self_new_old];
        return;
    }
}

-(void) observeWithObject:(id)object property:(NSString*)property block:(XYObserver_block_sourceObject_new_old)block{
    [self observeWithObject:object keyPath:property block:block];
}

-(void) observeWithObject:(id)object keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector type:(XYObserverType)type{
    NSAssert([target respondsToSelector:selector], @"selector 必须存在");
    NSAssert(keyPath.length > 0, @"property 必须存在");
    NSAssert(object, @"被观察的对象object 必须存在");
    
    XYObserver *ob = [[XYObserver alloc] initWithSourceObject:object keyPath:keyPath target:target selector:selector type:type];

    NSString *key = [NSString stringWithFormat:@"%@_%@", object, keyPath];
    [self.observers setObject:ob forKey:key];
}

-(void) observeWithObject:(id)object keyPath:(NSString*)keyPath block:(XYObserver_block_sourceObject_new_old)block{
    NSAssert(block, @"block 必须存在");
    
    XYObserver *ob = [[XYObserver alloc] initWithSourceObject:object keyPath:keyPath block:block];
    
    NSString *key = [NSString stringWithFormat:@"%@_%@", object, keyPath];
    [self.observers setObject:ob forKey:key];
}

-(void) removeObserverWithObject:(id)object property:(NSString *)property{
    NSString *key = [NSString stringWithFormat:@"%@_%@", object, property];
    [self.observers removeObjectForKey:key];
}

-(void) removeObserverWithObject:(id)object{
    NSString *prefix = [NSString stringWithFormat:@"%@", object];
    [self.observers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key hasPrefix:prefix]) { [self.observers removeObjectForKey:key]; }
    }];
}

-(void) removeAllObserver{
    [self.observers removeAllObjects];
}

@end

                                                            

                                                            
                                                            
                                                            
                                                            
                                                            
