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
  
  // NBT & Schematic File Data
  NBTContainer *container;
  
  // MCR & MCA File Data
  NSData *header;
  NSMutableArray *chunks;
}

- (void)loadFile:(NSURL *)path type:(NBTFileType)type;

@end


@interface McChunk : NSObject {
  uint length;
  uint compression; // 1:GZip 2:Zlib
  
  NBTContainer *container;
}

@end