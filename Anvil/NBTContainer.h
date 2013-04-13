//
//  NBTContainer.h
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum  {
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
  NBTTypeIntArray = 11
}; typedef uint8_t NBTType;


@interface NBTContainer : NSObject {
  NSString *name;
  NSMutableArray *children;
  NBTType type;
  NSString *stringValue;
  NSNumber *numberValue;
  NSMutableArray *arrayValue;
  NBTType listType;
  
  NBTContainer *parent;
  
  BOOL compressed;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, assign) NBTType type;
@property (nonatomic, retain) NSString *stringValue;
@property (nonatomic, retain) NSNumber *numberValue;
@property (nonatomic, retain) NSMutableArray *arrayValue;
@property (nonatomic, assign) NBTType listType;
@property (nonatomic, assign) NBTContainer *parent;
@property (nonatomic, readonly, getter = isCompressed) BOOL compressed;

+ (NBTContainer *)containerWithName:(NSString *)theName type:(NBTType)theType;
+ (NBTContainer *)containerWithName:(NSString *)theName type:(NBTType)theType value:(id)theValue;
+ (NBTContainer *)compoundWithName:(NSString *)theName;
+ (NBTContainer *)listWithName:(NSString *)theName type:(NBTType)theType;

+ (id)nbtContainerWithData:(NSData *)data;
- (void)readFromData:(NSData *)data;
- (NSData *)writeData;
- (NSData *)writeCompressedData;
- (NBTContainer *)childNamed:(NSString *)theName;

- (NSString *)containerType;

@end



@interface NBTDataHelper
+ (uint8_t)byteFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
+ (uint32_t)tribyteFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
+ (uint16_t)shortFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
+ (uint32_t)intFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
+ (uint64_t)longFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
+ (NSString *)stringFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;

+ (void)appendString:(NSString *)str toData:(NSMutableData *)data;
+ (void)appendByte:(uint8_t)v toData:(NSMutableData *)data;
+ (void)appendTribyte:(uint32_t)v toData:(NSMutableData *)data;
+ (void)appendShort:(uint16_t)v toData:(NSMutableData *)data;
+ (void)appendInt:(uint32_t)v toData:(NSMutableData *)data;
+ (void)appendLong:(uint64_t)v toData:(NSMutableData *)data;
+ (void)appendFloat:(float)v toData:(NSMutableData *)data;
+ (void)appendDouble:(double)v toData:(NSMutableData *)data;
@end
