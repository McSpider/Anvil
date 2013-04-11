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
  NSMutableArray *header; // Array containing all the sectors
  NSMutableArray *chunks; // Array containing only sectors with valid chunks
}
@property uint fileType;
@property (nonatomic, retain) NBTContainer *container;
@property (nonatomic, retain) NSMutableArray *header;
@property (nonatomic, retain) NSMutableArray *chunks;


- (id)initWithData:(NSData *)data type:(NBTFileType)type;

@end



enum  {
  Chunk_Zero_Length = 0,
  Chunk_OK = 1,
  Chunk_Not_Created = 2,
  Chunk_Mismatched_Length = 3,
  Chunk_In_Header = 4,
  Chunk_Not_In_File = 5,
}; typedef uint8_t ChunkStatus;


@interface McChunk : NSObject {
  uint8_t status;
  
  // Sector header data
  uint32_t sectorOffset;
  uint32_t sectorApproxLength;
  uint sectorTimestamp;
  
  NSPoint chunkPos;
  
  // Chunk data
  uint32_t length;
  uint8_t compression; // 1:GZip 2:Zlib
  
  NBTContainer *container;
}

@property uint8_t status;

@property uint32_t sectorOffset;
@property uint32_t sectorApproxLength;
@property uint sectorTimestamp;

@property NSPoint chunkPos;

@property uint32_t length;
@property uint8_t compression;

@property (nonatomic, retain) NBTContainer *container;

@end