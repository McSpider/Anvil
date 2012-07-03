//
//  NBTFile.h
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NBTListItem.h"

@interface NBTContainer : NSObject {
	NSString *name;
	NSMutableArray *children;
	NBTType type;
	NSString *stringValue;
	NSNumber *numberValue;
	NBTType listType;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, assign) NBTType type;
@property (nonatomic, retain) NSString *stringValue;
@property (nonatomic, retain) NSNumber *numberValue;
@property (nonatomic, assign) NBTType listType;

+ (NBTContainer *)containerWithName:(NSString *)theName type:(NBTType)theType numberValue:(NSNumber *)theNumber;
+ (NBTContainer *)compoundWithName:(NSString *)theName;
+ (NBTContainer *)listWithName:(NSString *)theName type:(NBTType)theType;

+ (id)nbtContainerWithData:(NSData *)data;
- (void)readFromData:(NSData *)data;
- (NSData *)writeData;
- (NBTContainer *)childNamed:(NSString *)theName;

- (NSString *)containerType;

@end
