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

#import "StoryObj.h"
#import "TFHpple.h"
#import "UIImage+Resize.h"


#define OPENGRAPH_TYPE_TAG @"property"
#define OPENGRAPH_VALUE_TAG @"content"
#define OPENGRAPH_VALUE_TAG2 @"value"

#define OPENGRAPH_TITLE @"og:title"
#define OPENGRAPH_DESCRIPTION @"og:description"
#define OPENGRAPH_IMAGEURL @"og:image"
#define OPENGRAPH_LINKURL @"og:url"

#define META_TYPE_TAG @"name"
#define META_VALUE_TAG @"content"
#define META_VALUE_TAG2 @"value"
#define META_TITLE @"title"
#define META_DESCRIPTION @"description"


@implementation StoryObj
@synthesize text = _text;
@synthesize story_url= _story_url;
@synthesize story_title = _story_title;
@synthesize story_description = _story_description;
@synthesize story_thumbnail = _story_thumbnail;


- (id)initWithURL:(NSURL *)url text:(NSString*) text {
    NSURL* originalUrl = url;
    //Make a htmlstring from urlString
    
    //NSString *agentString = @"Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3";
    
    NSString *agentString = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.6.1 (KHTML, like Gecko) Version/5.2 Safari/536.6.1";
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setValue:agentString forHTTPHeaderField:@"User-Agent"];
	NSData *data = [ NSURLConnection sendSynchronousRequest:request returningResponse: nil error: nil ];	
	NSString *html = [[NSString alloc] initWithBytes: [data bytes] length:[data length] encoding: NSUTF8StringEncoding];
    
    TFHpple *hpple = [TFHpple hppleWithHTMLData:[html dataUsingEncoding:NSUTF8StringEncoding]];    
    
    // Find title!    
    NSString *story_title = nil;
    TFHppleElement *titleOGTag = [hpple peekAtSearchWithXPathQuery:@"//meta[@property='og:title']"];    
    if(titleOGTag){
        story_title = [titleOGTag objectForKey:@"content"];
        if(!story_title){
            story_title = [titleOGTag objectForKey:@"value"];
        }
    }
    
    if(!story_title){
        TFHppleElement *titleMetaTag = [hpple peekAtSearchWithXPathQuery:@"//meta[@name='title']"];
        if(titleMetaTag){
            story_title = [titleMetaTag objectForKey:@"content"];
            if(!story_title){
                story_title = [titleMetaTag objectForKey:@"value"];
            }
        }
    }
    
    if(!story_title){
        story_title = [[hpple peekAtSearchWithXPathQuery:@"//title/text()[1]"] content];
    }
    
    
    // Find Description!    
    NSString *story_description = nil;
    TFHppleElement *descriptionOGTag = [hpple peekAtSearchWithXPathQuery:@"//meta[@property='og:description']"];    
    if(descriptionOGTag){
        story_description = [descriptionOGTag objectForKey:@"content"];
        if(!story_description){
            story_description = [descriptionOGTag objectForKey:@"value"];
        }
    }    
    if(!story_description){
        TFHppleElement *descriptionMetaTag = [hpple peekAtSearchWithXPathQuery:@"//meta[@name='description']"];
        if( descriptionMetaTag ){
            story_description = [descriptionMetaTag objectForKey:@"content"];
            if(!story_description){
                story_description = [descriptionMetaTag objectForKey:@"value"];
            }
        }
    }
    
    TFHppleElement *urlOGTag = [hpple peekAtSearchWithXPathQuery:@"//meta[@property='og:url']"];    
    NSString* newUrl = [urlOGTag objectForKey:@"content"];
    if(!newUrl){
        url = [NSURL URLWithString:[urlOGTag objectForKey:@"value"] ];
    }
    if(!url)
        url = originalUrl;
    
    // Find Thumbnail Image URL!
    NSString *story_thumnail_url = nil;
    TFHppleElement *thumbOGTag = [hpple peekAtSearchWithXPathQuery:@"//meta[@property='og:image']"];    
    if(thumbOGTag){
        story_thumnail_url = [thumbOGTag objectForKey:@"content"];
        if(!story_thumnail_url){
            story_thumnail_url = [thumbOGTag objectForKey:@"value"];
        }
    }   
    if(!story_thumnail_url){
        //TODO: find the largest image
        TFHppleElement *iconTag = [hpple peekAtSearchWithXPathQuery:@"//link[@rel='shortcut icon']"];    
        if(!iconTag){
            iconTag = [hpple peekAtSearchWithXPathQuery:@"//link[@rel='icon']"];    
        }
        if(!iconTag){
            iconTag = [hpple peekAtSearchWithXPathQuery:@"//link[@rel='apple-touch-icon']"];    
        }
        if(!iconTag){
            iconTag = [hpple peekAtSearchWithXPathQuery:@"//link[@rel='apple-touch-icon-precomposed']"];    
        }
        if(iconTag){
            story_thumnail_url = [iconTag objectForKey:@"href"];
        }
    }
            
    if(story_thumnail_url && [story_thumnail_url rangeOfString:@"http://"].location ==NSNotFound){
        story_thumnail_url = [[NSURL URLWithString:story_thumnail_url relativeToURL:url] absoluteString];
    }    
    
    NSMutableDictionary *result_dic = [NSMutableDictionary dictionary];
    [result_dic setObject:[url absoluteString] forKey:kObjFieldStoryUrl];
    [result_dic setObject:[originalUrl absoluteString] forKey:kObjFieldStoryOriginalUrl];
    [result_dic setObject:text forKey:kObjFieldStoryText];
    if(story_title){
        [result_dic setObject:story_title forKey:kObjFieldStoryTitle];
    }
    if(story_description){
        [result_dic setObject:story_description forKey:kObjFieldStoryDescription];
    }
    
    NSLog(@"%@",result_dic);
    NSLog(@"Thumnail :%@",story_thumnail_url);
    
    NSData *thumbnail = nil;
    if(story_thumnail_url){
        thumbnail = [NSData dataWithContentsOfURL:[NSURL URLWithString:story_thumnail_url]];
    }    
    return [super initWithType:kObjTypeStory data:result_dic andRaw:thumbnail];
}


-(void)setData:(NSDictionary *)data{
    _data = data;
    self.story_url = [_data objectForKey:kObjFieldStoryUrl];
    self.story_title = [_data objectForKey:kObjFieldStoryTitle];
    self.story_description = [_data objectForKey:kObjFieldStoryDescription];
    self.text = [_data objectForKey:kObjFieldStoryText];
}

-(void)setRaw:(NSData *)raw{
    _raw = raw;
    if(_raw){
        self.story_thumbnail = [[UIImage imageWithData:_raw] resizedImage:CGSizeMake(80,80) interpolationQuality:kCGInterpolationHigh];
    }
}

@end
