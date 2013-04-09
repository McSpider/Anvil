//
//  NBTContainer.m
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//
//  Spec for the Named Binary Tag format: http://www.minecraft.net/docs/NBT.txt

#import "NBTContainer.h"
#import "NSData+CocoaDevAdditions.h"


#ifndef NBT_LOGGING
#define NBT_LOGGING 0
#endif

#if NBT_LOGGING
#define NBTLog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
#define NBTLog(format, ...) while(0)
#endif


@interface NBTContainer ()
- (void)populateWithBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
- (NSData *)data;
@end


@implementation NBTContainer
@synthesize name, children, type;
@synthesize stringValue, numberValue, arrayValue, listType;
@synthesize parent;

- (id)init
{
  self = [super init];
  if (!self)
    return nil;
  
  compressed = YES;
  self.name = nil;
  self.children = [NSMutableArray array];
  self.stringValue = nil;
  self.numberValue = nil;
  self.arrayValue = nil;
  self.parent = nil;
  
  self.type = NBTTypeByte;
  self.listType = NBTTypeByte;
  
  return self;
}

- (void)dealloc
{
  [name release];
  [children release];
  [stringValue release];
  [numberValue release];
  [arrayValue release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
  NBTContainer *instanceCopy = [[NBTContainer allocWithZone:zone] init];
  
  instanceCopy.name = [[self.name copy] autorelease];
  instanceCopy.children = [[[NSMutableArray alloc] initWithArray:self.children copyItems:YES] autorelease];
  instanceCopy.type = self.type;
  instanceCopy.stringValue = [[self.stringValue copy] autorelease];
  instanceCopy.numberValue = [[self.numberValue copy] autorelease];
  instanceCopy.arrayValue = [[[NSMutableArray alloc] initWithArray:self.arrayValue copyItems:YES] autorelease];
  instanceCopy.listType = self.listType;
  
  // Re-link children to parents
  for (NBTContainer *child in instanceCopy.children) {
    [child setParent:instanceCopy];
  }
  
  return instanceCopy;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if  (!self)
    return nil;
  
  name = [[decoder decodeObjectForKey:@"name"] retain];
  children = [[decoder decodeObjectForKey:@"children"] retain];
  type = [decoder decodeIntForKey:@"type"];
  stringValue = [[decoder decodeObjectForKey:@"stringValue"] retain];
  numberValue = [[decoder decodeObjectForKey:@"numberValue"] retain];
  arrayValue = [[decoder decodeObjectForKey:@"arrayValue"] retain];
  listType = [decoder decodeIntForKey:@"listType"];
  
  // Re-link children to parents
  for (NBTContainer *child in children) {
    [child setParent:self];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:name forKey:@"name"];
  [encoder encodeObject:children forKey:@"children"];
  [encoder encodeInt:type forKey:@"type"];
  [encoder encodeObject:stringValue forKey:@"stringValue"];
  [encoder encodeObject:numberValue forKey:@"numberValue"];
  [encoder encodeObject:arrayValue forKey:@"arrayValue"];
  [encoder encodeInt:listType forKey:@"listType"];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@ %p name=%@ type=%i list type=%i children=%li", NSStringFromClass([self class]), self, self.name, self.type, self.listType, self.children.count];
}

- (NSString *)containerType
{
  if (self.type == NBTTypeEnd)
    return @"End";
  if (self.type == NBTTypeByte)
    return @"Byte";
  if (self.type == NBTTypeShort)
    return @"Short";
  if (self.type == NBTTypeInt)
    return @"Int";
  if (self.type == NBTTypeLong)
    return @"Long";
  if (self.type == NBTTypeFloat)
    return @"Float";
  if (self.type == NBTTypeDouble)
    return @"Double";
  if (self.type == NBTTypeByteArray)
    return @"Byte Array";
  if (self.type == NBTTypeString)
    return @"String";
  if (self.type == NBTTypeList)
    return @"List";
  if (self.type == NBTTypeCompound)
    return @"Compound";
  if (self.type == NBTTypeIntArray)
    return @"Int Array";
  
  
  return @"";
}


+ (NBTContainer *)containerWithName:(NSString *)theName type:(NBTType)theType
{
  NBTContainer *cont = [[[NBTContainer alloc] init] autorelease];
  cont.name = theName;
  cont.type = theType;
  return cont;
}

+ (NBTContainer *)containerWithName:(NSString *)theName type:(NBTType)theType value:(id)theValue
{
  NBTContainer *cont = [[[NBTContainer alloc] init] autorelease];
  cont.name = theName;
  cont.type = theType;
  
  if (cont.type == NBTTypeByte || cont.type == NBTTypeShort || cont.type == NBTTypeInt || cont.type == NBTTypeLong
      || cont.type == NBTTypeFloat || cont.type == NBTTypeDouble) {
    if ([theValue isKindOfClass:[NSNumber class]]) {
      cont.numberValue = (NSNumber *)theValue;
    } else {
      return nil;
    }
  }
  else if (cont.type == NBTTypeString) {
    if ([theValue isKindOfClass:[NSString class]]) {
      cont.stringValue = (NSString *)theValue;
    } else {
      return nil;
    }
  }
  
  else if (!cont.type || cont.type == NBTTypeList || cont.type == NBTTypeCompound || cont.type == NBTTypeEnd
           || cont.type == NBTTypeByteArray || cont.type == NBTTypeIntArray) {
    return nil;
  }
  
  return cont;
}

+ (NBTContainer *)compoundWithName:(NSString *)theName
{
  NBTContainer *cont = [[[NBTContainer alloc] init] autorelease];
  cont.name = theName;
  cont.type = NBTTypeCompound;
  cont.children = [NSMutableArray array];
  return cont;
}

+ (NBTContainer *)listWithName:(NSString *)theName type:(NBTType)theType;
{
  NBTContainer *cont = [[[NBTContainer alloc] init] autorelease];
  cont.name = theName;
  cont.type = NBTTypeList;
  cont.listType = theType;
  return cont;
}


+ (id)nbtContainerWithData:(NSData *)data;
{
  if (!data)
    return nil;
  
  id obj = [[[self class] alloc] init];
  [obj readFromData:data];
  return [obj autorelease];
}

- (void)readFromData:(NSData *)data
{
  if (!data)
    return;
  
  // TODO: move this to a more correct location
  NSData *uData = [data gzipInflate];
  if (uData) {
    data = uData;
  } else {
    compressed = NO;
  }
  
  const uint8_t *bytes = (const uint8_t *)[data bytes];
  
  uint32_t offset = 0;
  [self populateWithBytes:bytes offset:&offset];
}

- (NSData *)writeData
{
  if (!compressed) {
    return [self data];
  }
  
  return [[self data] gzipDeflate];
}

- (NBTContainer *)childNamed:(NSString *)theName
{
  if (self.type != NBTTypeCompound)
  {
    NSLog(@"ERROR: Cannot find named children inside a non-compound NBTContainer.");
    return nil;
  }
  for (NBTContainer *container in self.children)
  {
    if ([container.name isEqual:theName])
      return container;
  }
  return nil;
}

#pragma mark -
#pragma mark Private I/O API

- (void)populateWithBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
  uint32_t offset = *offsetPointer;
  self.type = [NBTDataHelper byteFromBytes:bytes offset:&offset];
  self.name = [NBTDataHelper stringFromBytes:bytes offset:&offset];
  
  if (self.type == NBTTypeCompound)
  {
    NBTLog(@">> start compound named %@", self.name);
    self.children = [NSMutableArray array];
    
    while (1)
    {
      NBTType childType = bytes[offset]; // peek
      if (childType == NBTTypeEnd)
      {
        offset += 1;
        break;
      }
      
      NBTContainer *child = [[NBTContainer alloc] init];
      [child populateWithBytes:bytes offset:&offset];
      child.parent = self;
      [self.children addObject:child];
      [child release];
    }
    NBTLog(@"<< end compound %@", self.name);
  }
  else if (self.type == NBTTypeList)
  {
    self.listType = [NBTDataHelper byteFromBytes:bytes offset:&offset];
    uint32_t listLength = [NBTDataHelper intFromBytes:bytes offset:&offset];
    
    NBTLog(@">> start list named %@ with type=%d length=%d", self.name, self.listType, listLength);
    
    self.children = [NSMutableArray array];
    while (listLength > 0)
    {
      if (self.listType == NBTTypeFloat)
      {
        uint32_t i = [NBTDataHelper intFromBytes:bytes offset:&offset];
        float f = *((float*)&i);
        NSNumber *num = [NSNumber numberWithFloat:f];
        NBTContainer *listItem = [NBTContainer containerWithName:nil type:self.listType];
        listItem.numberValue = num;
        listItem.parent = self;
        [self.children addObject:listItem];
        NBTLog(@"   list item, float=%f", f);
      }
      
      else if (self.listType == NBTTypeString)
      {
        NBTContainer *listItem = [NBTContainer containerWithName:nil type:self.listType];
        listItem.stringValue = [NBTDataHelper stringFromBytes:bytes offset:&offset];
        listItem.parent = self;
        [self.children addObject:listItem];
        NBTLog(@"   name=%@ string=%@", self.name, self.stringValue);
      }
      else if (self.listType == NBTTypeLong)
      {
        NBTContainer *listItem = [NBTContainer containerWithName:nil type:self.listType];
        listItem.numberValue = [NSNumber numberWithUnsignedLongLong:[NBTDataHelper longFromBytes:bytes offset:&offset]];
        listItem.parent = self;
        [self.children addObject:listItem];
        NBTLog(@"   name=%@ long=%qu", self.name, [self.numberValue unsignedLongLongValue]);
      }
      else if (self.listType == NBTTypeInt)
      {
        NBTContainer *listItem = [NBTContainer containerWithName:nil type:self.listType];
        listItem.numberValue = [NSNumber numberWithInt:[NBTDataHelper intFromBytes:bytes offset:&offset]];
        listItem.parent = self;
        [self.children addObject:listItem];
        NBTLog(@"   name=%@ int=0x%x", self.name, [self.numberValue unsignedIntValue]);
      }
      else if (self.listType == NBTTypeShort)
      {
        NBTContainer *listItem = [NBTContainer containerWithName:nil type:self.listType];
        listItem.numberValue = [NSNumber numberWithShort:[NBTDataHelper shortFromBytes:bytes offset:&offset]];
        listItem.parent = self;
        [self.children addObject:listItem];
        NBTLog(@"   name=%@ short=0x%x", self.name, [self.numberValue unsignedShortValue]);
      }
      
      else if (self.listType == NBTTypeDouble)
      {
        uint64_t l = [NBTDataHelper longFromBytes:bytes offset:&offset];
        double d = *((double*)&l);
        NSNumber *num = [NSNumber numberWithDouble:d];
        NBTContainer *listItem = [NBTContainer containerWithName:nil type:self.listType];
        listItem.numberValue = num;
        listItem.parent = self;
        [self.children addObject:listItem];
        NBTLog(@"   list item, double=%lf", d);
      }
      else if (self.listType == NBTTypeByte)
      {
        NSNumber *num = [NSNumber numberWithUnsignedChar:[NBTDataHelper byteFromBytes:bytes offset:&offset]];
        NBTContainer *listItem = [NBTContainer containerWithName:nil type:self.listType];
        listItem.numberValue = num;
        listItem.parent = self;
        [self.children addObject:listItem];
        NBTLog(@"   list item, byte=0x%x", [num unsignedCharValue]);
      }
      else if (self.listType == NBTTypeCompound)
      {
        NBTLog(@"   start list item, compound");
        NBTContainer *compound = [NBTContainer compoundWithName:nil];
        compound.children = [NSMutableArray array];
        while (1)
        {
          NBTType childType = bytes[offset]; // peek
          if (childType == NBTTypeEnd) {
            offset += 1;
            break;
          }
          
          NBTContainer *child = [[NBTContainer alloc] init];
          [child populateWithBytes:bytes offset:&offset];
          child.parent = compound;
          [compound.children addObject:child];
          [child release];
        }
        
        compound.parent = self;
        [self.children addObject:compound];
        NBTLog(@"   end list item, compound");
      }
      else
      {
        NBTLog(@"Unhandled list type: %d", self.listType);
      }
      listLength--;
    }
    
    NBTLog(@"<< end list %@", self.name);
  }
  else if (self.type == NBTTypeString)
  {
    self.stringValue = [NBTDataHelper stringFromBytes:bytes offset:&offset];
    NBTLog(@"   name=%@ string=%@", self.name, self.stringValue);
  }
  else if (self.type == NBTTypeLong)
  {
    self.numberValue = [NSNumber numberWithUnsignedLongLong:[NBTDataHelper longFromBytes:bytes offset:&offset]];
    NBTLog(@"   name=%@ long=%qu", self.name, [self.numberValue unsignedLongLongValue]);
  }
  else if (self.type == NBTTypeInt)
  {
    self.numberValue = [NSNumber numberWithInt:[NBTDataHelper intFromBytes:bytes offset:&offset]];
    NBTLog(@"   name=%@ int=0x%x", self.name, [self.numberValue unsignedIntValue]);
  }
  else if (self.type == NBTTypeShort)
  {
    self.numberValue = [NSNumber numberWithShort:[NBTDataHelper shortFromBytes:bytes offset:&offset]];
    NBTLog(@"   name=%@ short=0x%x", self.name, [self.numberValue unsignedShortValue]);
  }
  else if (self.type == NBTTypeByte)
  {
    self.numberValue = [NSNumber numberWithUnsignedChar:[NBTDataHelper byteFromBytes:bytes offset:&offset]];
    NBTLog(@"   name=%@ byte=0x%x", self.name, [self.numberValue unsignedCharValue]);
  }
  else if (self.listType == NBTTypeDouble)
  {
    uint64_t l = [NBTDataHelper longFromBytes:bytes offset:&offset];
    double d = *((double*)&l);
    self.numberValue = [NSNumber numberWithDouble:d];
    NBTLog(@"   name=%@ double=%lf", self.name, d);
  }
  else if (self.type == NBTTypeFloat)
  {
    uint32_t i = [NBTDataHelper intFromBytes:bytes offset:&offset];
    float f = *((float *)&i);
    self.numberValue = [NSNumber numberWithFloat:f];
    NBTLog(@"   name=%@ float=%f", self.name, [self.numberValue floatValue]);
  }
  else if (self.type == NBTTypeByteArray)
  {
    NBTLog(@">> start byte array named %@", self.name);
    
    NSMutableArray *byteArray = [[NSMutableArray alloc] init];
    int arrayLength = [NBTDataHelper intFromBytes:bytes offset:&offset];
    for (uint i = 0; i < arrayLength; i++) {
      NSNumber *byteV =  [[NSNumber alloc] initWithUnsignedChar:[NBTDataHelper byteFromBytes:bytes offset:&offset]];
      [byteArray addObject:byteV];
      [byteV release];
    }
    self.arrayValue = byteArray;
    [byteArray release];
    
    NBTLog(@"   array count=%i", (int)[self.arrayValue count]);
    NBTLog(@"<< end byte array %@", self.name);
  }
  else if (self.type == NBTTypeIntArray)
  {
    NBTLog(@">> start int array named %@", self.name);
    
    NSMutableArray *intArray = [[NSMutableArray alloc] init];
    int arrayLength = [NBTDataHelper intFromBytes:bytes offset:&offset];
    for (uint i = 0; i < arrayLength; i++) {
      NSNumber *intV =  [[NSNumber alloc] initWithInt:[NBTDataHelper intFromBytes:bytes offset:&offset]];
      [intArray addObject:intV];
      [intV release];
    }
    self.arrayValue = intArray;
    [intArray release];
    
    NBTLog(@"   array count=%i", (int)[self.arrayValue count]);
    NBTLog(@"<< end int array %@", self.name);
  }
  else
  {
    NBTLog(@"Unhandled type: %d", self.type);
  }
  
  *offsetPointer = offset;
}


- (NSData *)data
{
  NSMutableData *data = [NSMutableData data];
  [NBTDataHelper appendByte:self.type toData:data];
  [NBTDataHelper appendString:self.name toData:data];
  
  if (self.type == NBTTypeCompound)
  {
    NBTLog(@">> start compound named %@", self.name);
    for (NBTContainer *child in self.children)
    {
      [data appendData:[child data]];
    }
    uint8_t t = NBTTypeEnd;
    [data appendBytes:&t length:1];
    NBTLog(@"<< end compound %@", self.name);
  }
  else if (self.type == NBTTypeList)
  {
    NBTLog(@">> start list named %@ with type=%d length=%i", self.name, self.listType, (int)self.children.count);
    [NBTDataHelper appendByte:self.listType toData:data];
    [NBTDataHelper appendInt:(int)self.children.count toData:data];
    
    for (NBTContainer *item in self.children)
    {
      if (self.listType == NBTTypeCompound)
      {
        NBTLog(@"   start list item, compound");
        for (NBTContainer *i in item.children)
        {
          [data appendData:[i data]];
        }
        uint8_t t = NBTTypeEnd;
        [data appendBytes:&t length:1];
        NBTLog(@"   end list item, compound");
      }
      
      else if (self.listType == NBTTypeString)
      {
        NBTLog(@"   list item, string=%@", item.stringValue);
        [NBTDataHelper appendString:item.stringValue toData:data];
      }
      else if (self.listType == NBTTypeLong)
      {
        NBTLog(@"   list item, long=%qu", [item.numberValue unsignedLongLongValue]);
        [NBTDataHelper appendLong:[item.numberValue unsignedLongLongValue] toData:data];
      }
      else if (self.listType == NBTTypeInt)
      {
        NBTLog(@"   list item, int=0x%x", [item.numberValue unsignedIntValue]);
        [NBTDataHelper appendInt:[item.numberValue intValue] toData:data];
      }
      else if (self.listType == NBTTypeShort)
      {
        NBTLog(@"   list item, short=0x%x", [item.numberValue unsignedShortValue]);
        [NBTDataHelper appendShort:[item.numberValue shortValue] toData:data];
      }
      
      else if (self.listType == NBTTypeFloat)
      {
        NBTLog(@"   list item, float=%f", [item.numberValue floatValue]);
        [NBTDataHelper appendFloat:[item.numberValue floatValue] toData:data];
      }
      else if (self.listType == NBTTypeDouble)
      {
        NBTLog(@"   list item, double=%lf", [item.numberValue doubleValue]);
        [NBTDataHelper appendDouble:[item.numberValue doubleValue] toData:data];
      }
      else if (self.listType == NBTTypeByte)
      {
        NBTLog(@"   list item, byte=0x%x", [item.numberValue unsignedCharValue]);
        [NBTDataHelper appendByte:[item.numberValue unsignedCharValue] toData:data];
      }
      else
      {
        NBTLog(@"Unhandled list type: %d", self.listType);
      }
    }
    
    NBTLog(@"<< end list %@", self.name);
  }
  else if (self.type == NBTTypeString)
  {
    NBTLog(@"   name=%@ string=%@", self.name, self.stringValue);
    [NBTDataHelper appendString:self.stringValue toData:data];
  }
  else if (self.type == NBTTypeLong)
  {
    NBTLog(@"   name=%@ long=%qu", self.name, [self.numberValue unsignedLongLongValue]);
    [NBTDataHelper appendLong:[self.numberValue unsignedLongLongValue] toData:data];
  }
  else if (self.type == NBTTypeShort)
  {
    NBTLog(@"   name=%@ short=0x%x", self.name, [self.numberValue unsignedShortValue]);
    [NBTDataHelper appendShort:[self.numberValue shortValue] toData:data];
  }
  else if (self.type == NBTTypeInt)
  {
    NBTLog(@"   name=%@ int=0x%x", self.name, [self.numberValue unsignedIntValue]);
    [NBTDataHelper appendInt:[self.numberValue intValue] toData:data];
  }
  else if (self.type == NBTTypeByte)
  {
    NBTLog(@"   name=%@ byte=0x%x", self.name, [self.numberValue unsignedCharValue]);
    [NBTDataHelper appendByte:[self.numberValue unsignedCharValue] toData:data];
  }
  else if (self.type == NBTTypeDouble)
  {
    [NBTDataHelper appendDouble:[self.numberValue doubleValue] toData:data];
  }
  else if (self.type == NBTTypeFloat)
  {
    NBTLog(@"   name=%@ float=%f", self.name, [self.numberValue floatValue]);
    [NBTDataHelper appendFloat:[self.numberValue floatValue] toData:data];
  }
  else if (self.type == NBTTypeByteArray)
  {
    NBTLog(@">> start byte array named %@", self.name);
    [NBTDataHelper appendInt:(int)self.arrayValue.count toData:data];
    for (NSNumber *byteS in self.arrayValue) {
      uint8_t byteV = [byteS unsignedCharValue];
      [NBTDataHelper appendByte:byteV toData:data];
    }
    NBTLog(@"   array count=%i", (int)[self.arrayValue count]);
    NBTLog(@"<< end byte array %@", self.name);
  }
  else if (self.type == NBTTypeIntArray)
  {
    NBTLog(@">> start int array named %@", self.name);
    [NBTDataHelper appendInt:(int)self.arrayValue.count toData:data];
    for (NSNumber *intS in self.arrayValue) {
      uint32_t intV = [intS unsignedCharValue];
      [NBTDataHelper appendInt:intV toData:data];
    }
    NBTLog(@"   array count=%i", (int)[self.arrayValue count]);
    NBTLog(@"<< end int array %@", self.name);
  }
  else
  {
    NBTLog(@"Unhandled type: %d", self.type);
  }
  
  
  return data;
}

@end



@implementation NBTDataHelper

#pragma mark -
#pragma mark Data Helpers


+ (NSString *)stringFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
  uint32_t offset = *offsetPointer;
  uint16_t length = (bytes[offset] << 8) | bytes[offset + 1];
  *offsetPointer += 2 + length;
  return [[[NSString alloc] initWithBytes:bytes + offset + 2 length:length encoding:NSUTF8StringEncoding] autorelease];
}
+ (uint8_t)byteFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
  uint32_t offset = *offsetPointer;
  uint8_t n = bytes[offset];
  *offsetPointer += 1;
  return n;
}
+ (uint32_t)tribyteFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
  uint32_t offset = *offsetPointer;
  uint32_t n = ((int)bytes[offset + 2]) << 16;
  n |= ((int)bytes[offset + 1]) << 8;
  n |= bytes[offset];
  *offsetPointer += 3;
  return n;
}
+ (uint16_t)shortFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
  uint32_t offset = *offsetPointer;
  uint16_t n = (bytes[offset + 0] << 8) | bytes[offset + 1];
  *offsetPointer += 2;
  return n;
}
+ (uint32_t)intFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
  uint32_t offset = *offsetPointer;
  uint32_t n = ntohl(*((uint32_t *)(bytes + offset)));
  *offsetPointer += 4;
  return n;
}
+ (uint64_t)longFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
  uint32_t offset = *offsetPointer;
  uint64_t n = ntohl(*((uint32_t *)(bytes + offset)));
  n <<= 32;
  offset += 4;
  n += ntohl(*((uint32_t *)(bytes + offset)));
  *offsetPointer += 8;
  return n;
}


+ (void)appendString:(NSString *)str toData:(NSMutableData *)data
{
  NSData *strData = [str dataUsingEncoding:NSUTF8StringEncoding];
  [self appendShort:strData.length toData:data];
  [data appendData:strData];
}
+ (void)appendByte:(uint8_t)v toData:(NSMutableData *)data
{
  [data appendBytes:&v length:1];
}
+ (void)appendTribyte:(uint32_t)v toData:(NSMutableData *)data
{
  Byte* bytes;
  bytes[0] = v & 0xff;
  bytes[1] = (v >> 8) & 0xff;
  bytes[2] = (v >> 16) & 0xff;
  [data appendBytes:&bytes length:3];
}
+ (void)appendShort:(uint16_t)v toData:(NSMutableData *)data
{
  v = htons(v);
  [data appendBytes:&v length:2];
}
+ (void)appendInt:(uint32_t)v toData:(NSMutableData *)data
{
  v = htonl(v);
  [data appendBytes:&v length:4];
}
+ (void)appendLong:(uint64_t)v toData:(NSMutableData *)data
{
  uint32_t v0 = htonl(v >> 32);
  uint32_t v1 = htonl(v);
  [data appendBytes:&v0 length:4];
  [data appendBytes:&v1 length:4];
}
+ (void)appendFloat:(float)v toData:(NSMutableData *)data
{
  uint32_t vi = *((uint32_t *)&v);
  vi = htonl(vi);
  [data appendBytes:&vi length:4];
}
+ (void)appendDouble:(double)v toData:(NSMutableData *)data
{
  uint64_t vl = *((uint64_t *)&v);
  uint32_t v0 = htonl(vl >> 32);
  uint32_t v1 = htonl(vl);
  [data appendBytes:&v0 length:4];
  [data appendBytes:&v1 length:4];
}

@end
