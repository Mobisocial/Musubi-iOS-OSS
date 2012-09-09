#import "Three20/Three20.h"
#import "ManagedObjFeedItem.h"

@class FeedItem, LikeView;

@interface FeedItemCell : TTTableLinkedItemCell {
    UILabel*      _senderLabel;
    UILabel*      _timestampLabel;
    UIButton*     _profilePictureButton;
    LikeView*     _likeView;
    
    UIButton*     _likeButton;
}
 
@property (nonatomic, readonly, retain) UILabel*      senderLabel;
@property (nonatomic, readonly, retain) UILabel*      timestampLabel;
@property (nonatomic, readonly, retain) UIButton*     profilePictureButton;
@property (nonatomic, readonly, retain) LikeView*     likeView;
@property (nonatomic, readonly, retain) UIButton*     likeButton;

+ (void) prepareItem: (ManagedObjFeedItem*) item;
+ (CGFloat) renderHeightForItem: (FeedItem*) item;

@end

@interface LikeView : UIView {
    UILabel* _label;
    UIImageView* _icon;
}

@property (nonatomic, readonly, retain) UILabel*      label;
@property (nonatomic, readonly, retain) UIImageView*      icon;

- (void)prepareForReuse;
- (void)setObject: (FeedItem*) item;
+ (CGFloat)renderHeightForItem:(FeedItem *)item;

@end