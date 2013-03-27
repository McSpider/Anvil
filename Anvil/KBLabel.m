//
//  KBLabel.m
//  Inside Job
//
//  Created by Ben K on 2011/03/08.
//  All code is provided under the New BSD license. Copyright 2013 Ben K.
//

#import "KBLabel.h"


@implementation KBLabel

- (id)initWithCoder:(NSCoder *)decoder;
{
  self = [super initWithCoder:decoder];
  if (!self)
    return nil;
  
  [[self cell] setBackgroundStyle:NSBackgroundStyleRaised];
  return self;
}


@end
