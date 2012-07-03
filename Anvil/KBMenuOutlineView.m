//
//  KBMenuOutlineView.m
//  Anvil
//
//  Created by Benjamin Kohler on 12/07/03.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "KBMenuOutlineView.h"

@implementation KBMenuOutlineView

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
  id delegate = [self delegate];

  NSInteger row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
  if ([delegate respondsToSelector:@selector(outlineView:willShowMenuForRow:)])
    [delegate outlineView:self willShowMenuForRow:row];
    
  return [super menuForEvent:theEvent];
}

@end
