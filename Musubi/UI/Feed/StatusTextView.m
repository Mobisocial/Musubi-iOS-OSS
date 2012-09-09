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

#import "StatusTextView.h"

@implementation StatusTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    [self moveSpellingCorrection];
}

/*
 * From: http://stackoverflow.com/questions/1977249/how-to-move-uitextview-correction-suggestion-above-text
 */
- (void) moveSpellingCorrection {
    for (UIView *view in self.subviews)
    {
        if ([[[view class] description] isEqualToString:@"UIAutocorrectInlinePrompt"])
        {
            UIView *correctionShadowView = nil; // [view correctionShadowView];
            
            for (UIView *subview in view.subviews)
            {
                if ([[[subview class] description] isEqualToString:@"UIAutocorrectShadowView"])
                {
                    correctionShadowView = subview;
                    break;
                }
            }
            
            if (correctionShadowView)
            {
                UIView *typedTextView = nil; //[view typedTextView];
                UIView *correctionView = nil; //[view correctionView];
                
                for (UIView *subview in view.subviews)
                {
                    if ([[[subview class] description] isEqualToString:@"UIAutocorrectTextView"])
                    {
                        if (CGRectContainsRect(correctionShadowView.frame,subview.frame))
                        {
                            correctionView = subview;
                        }
                        else
                        { 
                            typedTextView = subview;
                        }
                    }
                    
                }
                if (correctionView && typedTextView)
                {
                    
                    CGRect textRect = [typedTextView frame];
                    CGRect correctionRect = [correctionView frame];
                    if (textRect.origin.y < correctionRect.origin.y)
                    {
                        CGAffineTransform moveUp = CGAffineTransformMakeTranslation(0,-50.0);
                        [correctionView setTransform: moveUp];
                        [correctionShadowView setTransform: moveUp];
                        
                        CGRect windowPos = [self convertRect: view.frame toView: nil ];
                        [view removeFromSuperview];
                        [self.window addSubview: view];
                        view.frame = windowPos;
                    }
                    
                }
            }
            
        }
        
    }
}

@end
