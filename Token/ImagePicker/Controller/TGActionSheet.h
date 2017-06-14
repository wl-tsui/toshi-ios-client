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

#import <UIKit/UIKit.h>

typedef enum {
    TGActionSheetActionTypeGeneric = 0,
    TGActionSheetActionTypeCancel = 1,
    TGActionSheetActionTypeDestructive = 2
} TGActionSheetActionType;

@interface TGActionSheetAction : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *action;
@property (nonatomic) TGActionSheetActionType type;

- (instancetype)initWithTitle:(NSString *)title action:(NSString *)action;
- (instancetype)initWithTitle:(NSString *)title action:(NSString *)action type:(TGActionSheetActionType)type;

@end

@interface TGActionSheet : UIActionSheet

@property (nonatomic, copy) bool (^dismissBlock)(id target, NSString *action);

- (instancetype)initWithTitle:(NSString *)title actions:(NSArray *)actions actionBlock:(void (^)(id target, NSString *action))actionBlock target:(id)target;

@end
