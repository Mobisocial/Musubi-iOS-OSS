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

#import "HtmlObjItemCell.h"
#import "ManagedObjFeedItem.h"
#import "ObjHelper.h"

@implementation HtmlObjItemCell {
    UIWebView* webView;
}

@synthesize webView;

+ (void)prepareItem:(ManagedObjFeedItem *)item {
    NSString* html = [[item parsedJson] objectForKey:kObjFieldHtml];
    UIWebView *wv = [[UIWebView alloc] init];
    //[wv setDelegate:<#(id<UIWebViewDelegate>)#>
    [wv setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [wv setContentMode:UIViewContentModeScaleAspectFit];
    [wv loadHTMLString:html baseURL:[NSURL URLWithString:@"http://localhost"]];
    item.computedData = wv;
    NSLog(@"set webview %@", wv);
}

+ (CGFloat)renderHeightForItem:(ManagedObjFeedItem *)item {
    CGSize goodSize = [item.computedData sizeThatFits:CGSizeZero];
    NSLog(@"sized to %f, %f", goodSize.width, goodSize.height); 
    //return goodSize.height + 10;
    return 80;
}

/* delegate method:
- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    CGRect frame = aWebView.frame;
    frame.size.height = 1;
    aWebView.frame = frame;
    CGSize fittingSize = [aWebView sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    aWebView.frame = frame;
    
    NSLog(@"size: %f, %f", fittingSize.width, fittingSize.height);
}*/

- (void)setObject:(ManagedObjFeedItem *)item {
    [super setObject:item];
    [self.contentView addSubview:item.computedData];
    self.webView = item.computedData;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.webView.frame = CGRectMake(self.detailTextLabel.frame.origin.x, self.detailTextLabel.frame.origin.y + 5, self.detailTextLabel.frame.size.width, self.detailTextLabel.frame.size.height);
}
@end
