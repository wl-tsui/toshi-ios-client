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

#import "PSCoding.h"

#import "AudioWaveform.h"

@interface DocumentAttributeAudio : NSObject <NSCoding, PSCoding>

@property (nonatomic, readonly) bool isVoice;
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *performer;
@property (nonatomic, readonly) int32_t duration;
@property (nonatomic, strong, readonly) AudioWaveform *waveform;

- (instancetype)initWithIsVoice:(bool)isVoice title:(NSString *)title performer:(NSString *)performer duration:(int32_t)duration waveform:(AudioWaveform *)waveform;

@end
