//
//  NBTListItem.m
//  Anvil
//
//  Created by Benjamin Kohler on 12/07/02.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "NBTListItem.h"

@implementation NBTListItem
@synthesize value, listType;
@synthesize index;


- (id)init
{  
  return [self initWithValue:nil type:NBTTypeLong];
}

- (id)initWithValue:(id)aValue type:(NBTType)aType;
{
  if (![super init])
    return nil;
  
  // Initialization code here.
  
  self.listType = aType;
  self.value = aValue;
  
  return self;
}

@end
