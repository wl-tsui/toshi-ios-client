    //
    //  Created by Jesse Squires
    //  http://www.jessesquires.com
    //
    //  Documentation
    //  http://cocoadocs.org/docsets/JSQMessagesViewController
    //
    //
    //  GitHub
    //  https://github.com/jessesquires/JSQMessagesViewController
    //
    //
    //  License
    //  Copyright (c) 2014 Jesse Squires
    //  Released under an MIT license: http://opensource.org/licenses/MIT
    //

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class JSQMessagesCollectionView;

/**
 *  The `JSQMessagesViewAccessoryButtonDelegate` protocol defines methods that allow you to
 *  handle accessory actions for the collection view.
 */
@protocol JSQMessagesViewActionButtonsDelegate <NSObject>

@required

- (void)messageView:(JSQMessagesCollectionView *)messageView didTapApproveAtIndexPath:(NSIndexPath *)indexPath;

- (void)messageView:(JSQMessagesCollectionView *)messageView didTapRejectAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
