//
//  JSQMessages.h
//  JSQMessages
//
//  Created by Hemanta Sapkota on 24/04/2015.
//
//

#import <UIKit/UIKit.h>

//! Project version number for JSQMessages.
FOUNDATION_EXPORT double JSQMessagesVersionNumber;

//! Project version string for JSQMessages.
FOUNDATION_EXPORT const unsigned char JSQMessagesVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <JSQMessages/PublicHeader.h>
#import "JSQMessagesViewController.h"

#import "JSQMessagesCollectionView.h"
#import "JSQMessagesCollectionViewCellIncoming.h"
#import "JSQMessagesCollectionViewCellOutgoing.h"
#import "JSQMessagesTypingIndicatorFooterView.h"
#import "JSQMessagesLoadEarlierHeaderView.h"

    //  Layout
#import "JSQMessagesBubbleSizeCalculating.h"
#import "JSQMessagesBubblesSizeCalculator.h"
#import "JSQMessagesCollectionViewFlowLayout.h"
#import "JSQMessagesCollectionViewLayoutAttributes.h"
#import "JSQMessagesCollectionViewFlowLayoutInvalidationContext.h"
#import "JSQAudioMediaViewAttributes.h"

    //  Toolbar
#import "JSQMessagesComposerTextView.h"
#import "JSQMessagesInputToolbar.h"
#import "JSQMessagesToolbarContentView.h"

    //  Model
#import "JSQMessage.h"

#import "JSQMediaItem.h"
#import "JSQAudioMediaItem.h"
#import "JSQPhotoMediaItem.h"
#import "JSQLocationMediaItem.h"
#import "JSQVideoMediaItem.h"

#import "JSQMessagesBubbleImage.h"
#import "JSQMessagesAvatarImage.h"

#import "JSQAudioMediaViewAttributes.h"

    //  Protocols
#import "JSQMessageData.h"
#import "JSQMessageMediaData.h"
#import "JSQMessageAvatarImageDataSource.h"
#import "JSQMessageBubbleImageDataSource.h"
#import "JSQMessagesCollectionViewDataSource.h"
#import "JSQMessagesCollectionViewDelegateFlowLayout.h"
#import "JSQMessagesViewAccessoryButtonDelegate.h"
#import "JSQMessagesViewActionButtonsDelegate.h"

    //  Factories
#import "JSQMessagesAvatarImageFactory.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"
#import "JSQMessagesTimestampFormatter.h"
#import "JSQMessagesToolbarButtonFactory.h"

    //  Categories
#import "NSString+JSQMessages.h"
#import "UIColor+JSQMessages.h"
#import "UIImage+JSQMessages.h"
#import "UIView+JSQMessages.h"
#import "NSBundle+JSQMessages.h"
