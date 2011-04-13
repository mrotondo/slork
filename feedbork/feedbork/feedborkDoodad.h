//
//  feedborkDoodad.h
//  feedbork
//
//  Created by Nick Kruge on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol feedborkDoodadDelegate;

@interface feedborkDoodad : UIImageView {
    id <feedborkDoodadDelegate> delegate;
}

@property (nonatomic,retain) id <feedborkDoodadDelegate> delegate;
- (id)initWithImageNamed:(NSString*)_imageName superview:(UIView*)sview center:(CGPoint)_center size:(CGSize)_size color:(UIColor*)_color delegate:(id)_delegate;
- (void)animateMe:(CGPoint)originalcenter;

@end

@protocol feedborkDoodadDelegate
- (void)killMe:(feedborkDoodad*)doodad;
@end