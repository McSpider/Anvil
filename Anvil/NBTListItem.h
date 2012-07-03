//
//  NBTListItem.h
//  Anvil
//
//  Created by Benjamin Kohler on 12/07/02.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	NBTTypeEnd = 0,
	NBTTypeByte = 1,
	NBTTypeShort = 2,
	NBTTypeInt = 3,
	NBTTypeLong = 4,
	NBTTypeFloat = 5,
	NBTTypeDouble = 6,
	NBTTypeByteArray = 7,
	NBTTypeString = 8,
	NBTTypeList = 9,
	NBTTypeCompound = 10,
} NBTType;

@interface NBTListItem : NSObject {
  id value;
  
  NBTType listType;
  int index;
}

@property (nonatomic, retain) id value;
@property (nonatomic, assign) NBTType listType;
@property int index;

- (id)initWithValue:(id)aValue type:(NBTType)aType;

@end
