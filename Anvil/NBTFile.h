//
//  NBTFile.h
//  Anvil
//
//  Created by Ben K on 2013-01-25.
//
//

#import <Foundation/Foundation.h>
#include "NBTContainer.h"

typedef enum {
  NBT_File = 0,
  MCA_File = 1,
  MCR_File = 2,
  SCHEM_File = 3
} NBTFileType;


@interface NBTFile : NSObject {
  uint fileType;
  NSData *fileData;
  
  // NBT & Schematic File Data
  NBTContainer *container;
  
  // MCR & MCA File Data
  NSMutableArray *header;
  NSMutableArray *chunks;
}

- (id)initWithData:(NSData *)data type:(NBTFileType)type;

@end



@interface McChunk : NSObject {  
  uint length;
  uint8_t compression; // 1:GZip 2:Zlib
  
  NBTContainer *container;
}

@property uint length;
@property uint8_t compression;

@property (nonatomic, retain) NBTContainer *container;

@end