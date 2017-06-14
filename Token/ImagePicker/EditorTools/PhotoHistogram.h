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

#import <Foundation/Foundation.h>
#import "CurvesTool.h"

@interface PhotoHistogramBins : NSObject

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (NSUInteger)count;

@end

@interface PhotoHistogram : NSObject

- (instancetype)initWithLuminanceCArray:(NSUInteger *)luminanceArray redCArray:(NSUInteger *)redArray greenCArray:(NSUInteger *)greenArray blueCArray:(NSUInteger *)blueArray;

- (PhotoHistogramBins *)histogramBinsForType:(PGCurvesType)type;

@end
