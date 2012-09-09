/*
 * Copyright 2012 The Stanford MobiSocial Laboratory
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "StoryObjItemCell.h"
#import "StoryObj.h"
#import "UIImage+Resize.h"

@implementation StoryObjItemCell
@synthesize thumbnailView = _thumbnailView;
@synthesize statusView = _statusView;
@synthesize subjectView = _subjectView;
@synthesize descriptionView = _descriptionView;
@synthesize url = _url;

#define STORY_THUMBNAIL_WIDTH 80
#define STORY_THUMBNAIL_HEIGHT 80

+ (void)prepareItem:(ManagedObjFeedItem *)item { 
    if(item.managedObj.raw){
        item.computedData = [UIImage imageWithData:item.managedObj.raw];
    }else{
        NSString* musubiLogoFilePath = [[NSBundle mainBundle] 
                                  pathForResource:@"logo" ofType:@"png"];
        item.computedData = [UIImage imageWithContentsOfFile:musubiLogoFilePath];
    }
} 

+ textForItem:(ManagedObjFeedItem*) item {
    NSString* text = [item.parsedJson objectForKey:kObjFieldStoryText];
    NSString* title = [item.parsedJson objectForKey:kObjFieldStoryTitle];
    NSString* url = [item.parsedJson objectForKey:kObjFieldStoryUrl];
    NSString* description = [item.parsedJson objectForKey:kObjFieldStoryDescription];
    return [NSString stringWithFormat:@"[%@]\n\n%@\n\n%@\n\n%@", title, text, url,description];
}

+ (CGFloat)renderHeightForItem:(ManagedObjFeedItem *)item {
    NSString* text = [item.parsedJson objectForKey:kObjFieldStoryText];
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];    
    
    NSString* subjext_text = [item.parsedJson objectForKey:kObjFieldStoryTitle];
    CGSize subject_size = [subjext_text sizeWithFont:[UIFont boldSystemFontOfSize:12] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];    
    
    NSString* description_text = [item.parsedJson objectForKey:kObjFieldStoryDescription];
    CGSize description_size = [description_text sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];    
    
//    NSLog(@"%@",NSStringFromCGSize(size));
    return description_size.height + subject_size.height + size.height+STORY_THUMBNAIL_HEIGHT;
}

- (void)setObject:(ManagedObjFeedItem*)object {
    [super setObject:object];
    _url = [object.parsedJson objectForKey:kObjFieldStoryUrl];
    //  self.detailTextLabel.text = [object.parsedJson objectForKey:kObjFieldStoryText];

    NSString* status_text = [object.parsedJson objectForKey:kObjFieldStoryText];
    CGSize status_size = [status_text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];    
    self.statusView.frame = CGRectMake(0, 0, status_size.width, status_size.height);    
    self.statusView.text = status_text;
    
    NSString* subjext_text = [object.parsedJson objectForKey:kObjFieldStoryTitle];
    CGSize subject_size = [subjext_text sizeWithFont:[UIFont boldSystemFontOfSize:12] constrainedToSize:CGSizeMake(164, 1024) lineBreakMode:UILineBreakModeWordWrap];    
    self.subjectView.frame = CGRectMake(0, 0, subject_size.width, subject_size.height);    
    self.subjectView.text = subjext_text;
    
    NSString* description_text = [object.parsedJson objectForKey:kObjFieldStoryDescription];
    CGSize description_size = [description_text sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];    
    self.descriptionView.frame = CGRectMake(0, 0, description_size.width, description_size.height);    
    self.descriptionView.text = description_text;
    
    UIImage* image = object.computedData;
    [self.thumbnailView setImage: image];

}

- (UIImageView *)thumbnailView {
    if (!_thumbnailView) {
        _thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, STORY_THUMBNAIL_WIDTH, STORY_THUMBNAIL_HEIGHT)];
//        [_thumbnailView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
//        [_thumbnailView setContentMode:UIViewContentModeScaleAspectFit];
        [self.contentView addSubview:_thumbnailView];
    }
    
    return _thumbnailView;
}

-(UILabel*)statusView{
    if(!_statusView){
        _statusView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        _statusView.font = TTSTYLEVAR(font);
        _statusView.textColor = TTSTYLEVAR(tableSubTextColor);
        _statusView.highlightedTextColor = TTSTYLEVAR(highlightedTextColor);
        _statusView.backgroundColor = TTSTYLEVAR(backgroundTextColor);
        _statusView.textAlignment = UITextAlignmentLeft;
        _statusView.lineBreakMode = UILineBreakModeWordWrap;
        _statusView.numberOfLines = 0;
        _statusView.contentMode = UIViewContentModeTopLeft;
        [self.contentView addSubview:_statusView];
    }
    return _statusView;
}

-(UILabel*)subjectView{
    if(!_subjectView){
        _subjectView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        _subjectView.font = [UIFont boldSystemFontOfSize:12];
        _subjectView.textColor = TTSTYLEVAR(tableSubTextColor);
        _subjectView.highlightedTextColor = TTSTYLEVAR(highlightedTextColor);
        _subjectView.backgroundColor = TTSTYLEVAR(backgroundTextColor);
        _subjectView.textAlignment = UITextAlignmentLeft;
        _subjectView.lineBreakMode = UILineBreakModeWordWrap;
        _subjectView.numberOfLines = 4;
        _subjectView.contentMode = UIViewContentModeTopLeft;
        [self.contentView addSubview:_subjectView];
    }
    return _subjectView;
}


-(UILabel*)descriptionView{
    if(!_descriptionView){
        _descriptionView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        _descriptionView.font = [UIFont systemFontOfSize:12];
        _descriptionView.textColor = TTSTYLEVAR(tableSubTextColor);
        _descriptionView.highlightedTextColor = TTSTYLEVAR(highlightedTextColor);
        _descriptionView.backgroundColor = TTSTYLEVAR(backgroundTextColor);
        _descriptionView.textAlignment = UITextAlignmentLeft;
        _descriptionView.lineBreakMode = UILineBreakModeWordWrap;
        _descriptionView.numberOfLines = 0;
        _descriptionView.contentMode = UIViewContentModeTopLeft;
        [self.contentView addSubview:_descriptionView];
    }
    return _descriptionView;
}


- (void)layoutSubviews {
    [super layoutSubviews];
//    NSLog(@"%@",NSStringFromCGRect(self.subjectView.frame));
//    NSLog(@"%@",NSStringFromCGRect(self.detailTextLabel.frame));
    self.statusView.frame = CGRectMake(self.detailTextLabel.frame.origin.x, self.detailTextLabel.frame.origin.y,self.statusView.frame.size.width,self.statusView.frame.size.height);

//    
    self.thumbnailView.frame = CGRectMake(self.statusView.frame.origin.x, self.statusView.frame.origin.y + self.statusView.frame.size.height + 5, self.thumbnailView.frame.size.width, self.thumbnailView.frame.size.height);
    
    self.subjectView.frame = CGRectMake(self.thumbnailView.frame.origin.x + self.thumbnailView.frame.size.width + 5, self.thumbnailView.frame.origin.y, self.subjectView.frame.size.width, self.subjectView.frame.size.height);
    
    self.descriptionView.frame = CGRectMake(self.thumbnailView.frame.origin.x, self.thumbnailView.frame.origin.y + self.thumbnailView.frame.size.height + 5, self.descriptionView.frame.size.width, self.descriptionView.frame.size.height);
    
}

@end
