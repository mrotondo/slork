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

- (void) animateMe:(CGPoint)originalcenter;

@end

@protocol feedborkDoodadDelegate
- (void)killMe:(feedborkDoodad*)doodad;
@end