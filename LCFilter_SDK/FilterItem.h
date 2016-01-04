//
//  FilterItem.h
//  LCFilter-Lofter
//
//  Created by NetEase on 15/12/28.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FilterItem : NSObject

@property (nonatomic, copy) NSString *type;
@property (nonatomic, strong) NSString *filterName;

+ (instancetype)filterItemWithDict:(NSDictionary *)dict;
- (instancetype)initWithDict:(NSDictionary *)dict;
@end
