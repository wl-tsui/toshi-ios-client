// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "GPUImageFilter.h"

#define PGShaderString(text) @ STRINGIZE2(text)

@interface PhotoProcessPassParameter : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) bool isConst;
@property (nonatomic, readonly) bool isUniform;
@property (nonatomic, readonly) bool isVarying;
@property (nonatomic, assign) NSInteger count;

- (void)setFloatValue:(CGFloat)floatValue;
- (void)setFloatArray:(NSArray *)floatArray;
- (void)setColorValue:(UIColor *)colorValue;

- (void)storeFilter:(GPUImageFilter *)filter uniformIndex:(GLint)uniformIndex;
- (NSString *)shaderString;

+ (instancetype)varyingWithName:(NSString *)name type:(NSString *)type;
+ (instancetype)parameterWithName:(NSString *)name type:(NSString *)type;
+ (instancetype)parameterWithName:(NSString *)name type:(NSString *)type count:(NSInteger)count;
+ (instancetype)constWithName:(NSString *)name type:(NSString *)type value:(NSString *)value;

@end

@interface PhotoProcessPass : NSObject
{
    GPUImageOutput <GPUImageInput> *_filter;
}

@property (nonatomic, readonly) GPUImageOutput <GPUImageInput> *filter;

- (void)updateParameters;
- (void)process;
- (void)invalidate;

@end

extern NSString *const PGPhotoEnhanceColorSwapShaderString;
