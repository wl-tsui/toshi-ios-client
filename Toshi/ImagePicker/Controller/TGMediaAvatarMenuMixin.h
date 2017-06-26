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
#import <UIKit/UIKit.h>

@class ViewController;

@interface TGMediaAvatarMenuMixin : NSObject

@property (nonatomic, copy) void (^didFinishWithImage)(UIImage *image);
@property (nonatomic, copy) void (^didFinishWithDelete)(void);
@property (nonatomic, copy) void (^didDismiss)(void);

- (instancetype)initWithParentController:(ViewController *)parentController hasDeleteButton:(bool)hasDeleteButton
NS_SWIFT_NAME(init(parentController:hasDeleteButton:));


- (instancetype)initWithParentController:(ViewController *)parentController hasDeleteButton:(bool)hasDeleteButton personalPhoto:(bool)personalPhoto
NS_SWIFT_NAME(init(parentController:hasDeleteButton:personalPhoto:));

- (void)present;

@end
