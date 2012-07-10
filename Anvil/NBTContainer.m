//
//  NBTFile.m
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
- (uint8_t)byteFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
- (uint16_t)shortFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
- (uint32_t)intFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
- (uint64_t)longFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;
- (NSString *)stringFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer;

- (void)appendString:(NSString *)str toData:(NSMutableData *)data;
- (void)appendByte:(uint8_t)v toData:(NSMutableData *)data;
- (void)appendShort:(uint16_t)v toData:(NSMutableData *)data;
- (void)appendInt:(uint32_t)v toData:(NSMutableData *)data;
- (void)appendLong:(uint64_t)v toData:(NSMutableData *)data;
- (void)appendFloat:(float)v toData:(NSMutableData *)data;
- (void)appendDouble:(double)v toData:(NSMutableData *)data;

- (NSData *)data;
@end


@implementation NBTContainer
@synthesize name, children, type;
@synthesize stringValue, numberValue, arrayValue, listType;
@synthesize parent;

- (id)init
{
	if (![super init])
    return nil;
  
  self.name = nil;
	self.stringValue = nil;
	self.numberValue = nil;
  self.arrayValue = nil;
  
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


- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@ %p name=%@ type=%i children=%i", NSStringFromClass([self class]), self, self.name, self.type, self.children.count];
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
  
  return @"";
}


+ (NBTContainer *)containerWithName:(NSString *)theName type:(NBTType)theType numberValue:(NSNumber *)theNumber
{
	NBTContainer *cont = [[[NBTContainer alloc] init] autorelease];
	cont.name = theName;
	cont.type = theType;
	cont.numberValue = theNumber;
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
	data = [data gzipInflate];
	
	const uint8_t *bytes = (const uint8_t *)[data bytes];
	
	uint32_t offset = 0;
	[self populateWithBytes:bytes offset:&offset];
}

- (NSData *)writeData
{
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
	self.type = [self byteFromBytes:bytes offset:&offset];
	self.name = [self stringFromBytes:bytes offset:&offset];
	
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
		listType = [self byteFromBytes:bytes offset:&offset];
		uint32_t listLength = [self intFromBytes:bytes offset:&offset];
		
		NBTLog(@">> start list named %@ with type=%d length=%d", self.name, listType, listLength);
		
		self.children = [NSMutableArray array];
		while (listLength > 0)
		{
			if (listType == NBTTypeFloat)
			{
				uint32_t i = [self intFromBytes:bytes offset:&offset];
				float f = *((float*)&i);
				NSNumber *num = [NSNumber numberWithFloat:f];
        NBTContainer *listItem = [NBTContainer containerWithName:nil type:listType numberValue:num];
        listItem.parent = self;
				[self.children addObject:listItem];
        NBTLog(@"      list item, float=%f", f);
			}
			else if (listType == NBTTypeDouble)
			{
				uint64_t l = [self longFromBytes:bytes offset:&offset];
				double d = *((double*)&l);
				NSNumber *num = [NSNumber numberWithDouble:d];
        NBTContainer *listItem = [NBTContainer containerWithName:nil type:listType numberValue:num];
        listItem.parent = self;
				[self.children addObject:listItem];
        NBTLog(@"      list item, double=%lf", d);
			}
			else if (listType == NBTTypeCompound)
			{
        NBTContainer *compound = [NBTContainer compoundWithName:nil];
        NBTLog(@"      start list item, compound");
				NSMutableArray *array = [NSMutableArray array];
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
					[array addObject:child];
					[child release];
				}
        
        [compound.children addObjectsFromArray:array];
        compound.parent = self;
				[self.children addObject:compound];
        NBTLog(@"      end list item, compound");
			}
			else
			{
				NBTLog(@"Unhandled list type: %d", listType);
			}
			listLength--;
		}
		
		NBTLog(@"<< end list %@", self.name);
	}	
	else if (self.type == NBTTypeString)
	{
		self.stringValue = [self stringFromBytes:bytes offset:&offset];
		NBTLog(@"   name=%@ string=%@", self.name, self.stringValue);
	}
	else if (self.type == NBTTypeLong)
	{
		self.numberValue = [NSNumber numberWithUnsignedLongLong:[self longFromBytes:bytes offset:&offset]];
		NBTLog(@"   name=%@ long=%qu", self.name, [self.numberValue unsignedLongLongValue]);
	}
	else if (self.type == NBTTypeInt)
	{
		self.numberValue = [NSNumber numberWithInt:[self intFromBytes:bytes offset:&offset]];
		NBTLog(@"   name=%@ int=0x%x", self.name, [self.numberValue unsignedIntValue]);
	}
	else if (self.type == NBTTypeShort)
	{
		self.numberValue = [NSNumber numberWithShort:[self shortFromBytes:bytes offset:&offset]];
		NBTLog(@"   name=%@ short=0x%x", self.name, [self.numberValue unsignedShortValue]);
	}
	else if (self.type == NBTTypeByte)
	{
		self.numberValue = [NSNumber numberWithUnsignedChar:[self byteFromBytes:bytes offset:&offset]];
		NBTLog(@"   name=%@ byte=0x%x", self.name, [self.numberValue unsignedCharValue]);
	}
	else if (self.type == NBTTypeFloat)
	{
		uint32_t i = [self intFromBytes:bytes offset:&offset];
		float f = *((float *)&i);
		self.numberValue = [NSNumber numberWithFloat:f];
		NBTLog(@"   name=%@ float=%f", self.name, [self.numberValue floatValue]);
	}
  else if (self.type == NBTTypeByteArray)
	{
    NBTLog(@">> start byte array named %@", self.name);

    NSMutableArray *byteArray = [[NSMutableArray alloc] init];
    int arrayLength = [self intFromBytes:bytes offset:&offset];
    for (uint i = 0; i < arrayLength; i++) {
      NSNumber *byteV =  [[NSNumber alloc] initWithUnsignedChar:[self byteFromBytes:bytes offset:&offset]];
      [byteArray addObject:byteV];
      [byteV release];
    }
    self.arrayValue = byteArray;
    
		NBTLog(@"   array count=%i", (int)[self.arrayValue count]);
    NBTLog(@"<< end byte array %@", self.name);
	}
  else if (self.type == NBTTypeIntArray)
	{
    NBTLog(@">> start int array named %@", self.name);
    
    NSMutableArray *intArray = [[NSMutableArray alloc] init];
    int arrayLength = [self intFromBytes:bytes offset:&offset];
    for (uint i = 0; i < arrayLength; i++) {
      NSNumber *intV =  [[NSNumber alloc] initWithInt:[self intFromBytes:bytes offset:&offset]];
      [intArray addObject:intV];
      [intV release];
    }
    self.arrayValue = intArray;
    
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
	[self appendByte:self.type toData:data];
	[self appendString:self.name toData:data];
	
	if (self.type == NBTTypeCompound)
	{
		for (NBTContainer *child in self.children)
		{
			[data appendData:[child data]];
		}
		uint8_t t = NBTTypeEnd;
		[data appendBytes:&t length:1];
	}
	else if (self.type == NBTTypeList)
	{
		[self appendByte:self.listType toData:data];
		[self appendInt:(int)self.children.count toData:data];
		for (NBTContainer *item in self.children)
		{
      // FIXME - Compounds in lists start to become rooted deeper and deeper after each save.
			if (listType == NBTTypeCompound)
      {
				[data appendData:[item data]];
				uint8_t t = NBTTypeEnd;
				[data appendBytes:&t length:1];
			}
			else if (listType == NBTTypeFloat)
			{
				[self appendFloat:[item.numberValue floatValue] toData:data];
			}
			else if (listType == NBTTypeDouble)
			{
				[self appendDouble:[item.numberValue doubleValue] toData:data];
			}
			else if (listType == NBTTypeByte)
			{
				[self appendByte:[item.numberValue unsignedCharValue] toData:data];
			}
			else
			{
				NBTLog(@"Unhandled list type: %d", listType);
			}
		}
	}
	else if (self.type == NBTTypeString)
	{
		[self appendString:self.stringValue toData:data];
	}
	else if (self.type == NBTTypeLong)
	{
		[self appendLong:[self.numberValue unsignedLongLongValue] toData:data];
	}
	else if (self.type == NBTTypeShort)
	{
		[self appendShort:[self.numberValue shortValue] toData:data];
	}
	else if (self.type == NBTTypeInt)
	{
		[self appendInt:[self.numberValue intValue] toData:data];
	}
	else if (self.type == NBTTypeByte)
	{
		[self appendByte:[self.numberValue unsignedCharValue] toData:data];
	}
	else if (self.type == NBTTypeDouble)
	{
		[self appendDouble:[self.numberValue doubleValue] toData:data];
	}
	else if (self.type == NBTTypeFloat)
	{
		[self appendFloat:[self.numberValue floatValue] toData:data];
	}
  else if (self.type == NBTTypeByteArray)
	{
    [self appendInt:(int)self.arrayValue.count toData:data];
    for (NSNumber *byteS in self.arrayValue) {
      uint8_t byteV = [byteS unsignedCharValue];
      [self appendByte:byteV toData:data];
    }
	}
  else if (self.type == NBTTypeIntArray)
	{
    [self appendInt:(int)self.arrayValue.count toData:data];
    for (NSNumber *intS in self.arrayValue) {
      uint32_t intV = [intS unsignedCharValue];
      [self appendInt:intV toData:data];
    }
	}
	else
	{
		NBTLog(@"Unhandled type: %d", self.type);
	}

	
	return data;
}


#pragma mark -
#pragma mark Data Helpers


- (NSString *)stringFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	uint16_t length = (bytes[offset] << 8) | bytes[offset + 1];
	*offsetPointer += 2 + length;
	return [[[NSString alloc] initWithBytes:bytes + offset + 2 length:length encoding:NSUTF8StringEncoding] autorelease];
}
- (uint8_t)byteFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	uint8_t n = bytes[offset];
	*offsetPointer += 1;
	return n;
}
- (uint16_t)shortFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	uint16_t n = (bytes[offset + 0] << 8) | bytes[offset + 1];
	*offsetPointer += 2;
	return n;
}
- (uint32_t)intFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	uint32_t n = ntohl(*((uint32_t *)(bytes + offset)));
	*offsetPointer += 4;
	return n;
}
- (uint64_t)longFromBytes:(const uint8_t *)bytes offset:(uint32_t *)offsetPointer
{
	uint32_t offset = *offsetPointer;
	uint64_t n = ntohl(*((uint32_t *)(bytes + offset)));
	n <<= 32;
	offset += 4;
	n += ntohl(*((uint32_t *)(bytes + offset)));
	*offsetPointer += 8;
	return n;
}


- (void)appendString:(NSString *)str toData:(NSMutableData *)data
{
	[self appendShort:str.length toData:data];
	[data appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}
- (void)appendByte:(uint8_t)v toData:(NSMutableData *)data
{
	[data appendBytes:&v length:1];
}
- (void)appendShort:(uint16_t)v toData:(NSMutableData *)data
{
	v = htons(v);
	[data appendBytes:&v length:2];
}
- (void)appendInt:(uint32_t)v toData:(NSMutableData *)data
{
	v = htonl(v);
	[data appendBytes:&v length:4];
}
- (void)appendLong:(uint64_t)v toData:(NSMutableData *)data
{
	uint32_t v0 = htonl(v >> 32);
	uint32_t v1 = htonl(v);
	[data appendBytes:&v0 length:4];
	[data appendBytes:&v1 length:4];
}
- (void)appendFloat:(float)v toData:(NSMutableData *)data
{
	uint32_t vi = *((uint32_t *)&v);
	vi = htonl(vi);
	[data appendBytes:&vi length:4];
}
- (void)appendDouble:(double)v toData:(NSMutableData *)data
{
	uint64_t vl = *((uint64_t *)&v);
	uint32_t v0 = htonl(vl >> 32);
	uint32_t v1 = htonl(vl);
	[data appendBytes:&v0 length:4];
	[data appendBytes:&v1 length:4];
}


@end
