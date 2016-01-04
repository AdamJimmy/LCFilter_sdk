//
//  FilterItem.m
//  LCFilter-Lofter
//
//  Created by NetEase on 15/12/28.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import "FilterItem.h"

@implementation FilterItem
+(instancetype)filterItemWithDict:(NSDictionary *)dict{
    return [[self alloc] initWithDict:dict];
}
- (instancetype)initWithDict:(NSDictionary *)dict{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}
@end
