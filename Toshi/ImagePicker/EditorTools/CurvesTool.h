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

#import "PhotoTool.h"

typedef enum
{
    PGCurvesTypeLuminance,
    PGCurvesTypeRed,
    PGCurvesTypeGreen,
    PGCurvesTypeBlue
} PGCurvesType;

@interface CurvesValue : NSObject <NSCopying>

@property (nonatomic, assign) CGFloat blacksLevel;
@property (nonatomic, assign) CGFloat shadowsLevel;
@property (nonatomic, assign) CGFloat midtonesLevel;
@property (nonatomic, assign) CGFloat highlightsLevel;
@property (nonatomic, assign) CGFloat whitesLevel;

- (NSArray *)interpolateCurve;

@end

@interface CurvesToolValue : NSObject <NSCopying, CustomToolValue>

@property (nonatomic, strong) CurvesValue *luminanceCurve;
@property (nonatomic, strong) CurvesValue *redCurve;
@property (nonatomic, strong) CurvesValue *greenCurve;
@property (nonatomic, strong) CurvesValue *blueCurve;

@property (nonatomic, assign) PGCurvesType activeType;

@end

@interface CurvesTool : PhotoTool

@end
