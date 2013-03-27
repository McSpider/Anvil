//
//  KBOutlineView.m
//  Anvil
//
//  Created by Ben K on 12/07/03.
//  All code is provided under the New BSD license. Copyright 2012 Ben K
//

#import "KBOutlineView.h"

@implementation KBOutlineView

- (id)init
{
  if (!(self = [super init]))
    return nil;
  
  // Initialization code here.
  return self;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
  id delegate = [self delegate];

  NSInteger row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
  if ([delegate respondsToSelector:@selector(outlineView:shouldShowMenuForRow:)]) {
    if (![delegate outlineView:self shouldShowMenuForRow:row]) {
      return nil;
    }
  }

  return [super menuForEvent:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent
{
  id delegate = [self delegate];
  if ([delegate respondsToSelector:@selector(outlineView:handleKeyDown:)]) {
    if ([delegate outlineView:self handleKeyDown:theEvent]) {
      return;
    }
  }
  
  [super keyDown:theEvent];
}

@end
