//
//  NBTFile.m
//  Anvil
//
//  Created by Ben K on 2013-01-25.
//
// References:
// http://www.minecraftwiki.net/wiki/Region_file_format
// https://github.com/twoolie/NBT/blob/master/nbt/region.py
// http://en.wikipedia.org/wiki/Kibibyte

#import "NBTFile.h"
#import "NSData+CocoaDevAdditions.h"


@implementation NBTFile
@synthesize container;
@synthesize chunks;

- (id)initWithData:(NSData *)data type:(NBTFileType)type
{
  self = [super init];
  if (!self)
    return nil;
  
  chunks = [[NSMutableArray alloc] init];
  
  fileType = type;
  fileData = [data retain];
  
  if (type == NBT_File || type == SCHEM_File) {
    container = [NBTContainer nbtContainerWithData:data];
  }
  
  if (type == MCA_File || type == MCR_File) {
    const uint8_t *bytes = (const uint8_t *)[fileData bytes];
    unsigned long length = [fileData length];
    NSLog(@"Data length %li",length);
    
    if (bytes != 0) {
      [self parseHeader:bytes];
      NSLog(@"\n");
      
      // Loop through chunk info, validate chunk, load chunk
      for (McChunk *chunk in chunks) {
        if (chunk.status != Chunk_OK)
          continue;
        
        uint64_t sectorOffset = [chunk sectorOffset];
        uint32_t approxSectorLength = [chunk sectorApproxLength];
        uint sectorTimestamp = [chunk sectorTimestamp];

        NSLog(@">> parse chunk sector; offset:%lli length:%i timestamp:%i status:%i",sectorOffset,approxSectorLength,sectorTimestamp,chunk.status);
        
        // Offset & length of the sector are in 4KiB increments (4KiB = 4096bytes)
        sectorOffset = sectorOffset * 4096;
        approxSectorLength = approxSectorLength * 4096;
        NSLog(@">> sector actual offset:%lli length:%i",sectorOffset,approxSectorLength);
        
        const uint8_t *sectorBytes = bytes + sectorOffset;        
        [self parseSector:sectorBytes length:approxSectorLength intoChunk:chunk];
      }
    }
  }
  
  return self;
}

- (void)dealloc
{
  [chunks release];
  [fileData release];
  [super dealloc];
}


// Get the locations of all the chunks in the file
- (void)parseHeader:(const uint8_t *)bytes
{
  NSLog(@">> start header");
  uint32_t offset = 0;
  
  // Chunk locations
  while (offset < 4096) {
    int X = (offset/4) % 32;
    int Y = (offset/4)/32;
    NSLog(@">>   start sector info X%iY%i",X,Y);
    // The offset of the chunk in 4KiB sectors from the start of the file, this is stored as a (big-endian) three-byte value (24 bits)
    uint32_t sectorOffset = [NBTDataHelper tribyteFromBytes:bytes offset:&offset];
    NSLog(@"       sector offset %i",sectorOffset);
    
    // The length of the chunk in 4KiB sectors (rounded up)
    uint8_t sectorLength = [NBTDataHelper byteFromBytes:bytes offset:&offset];
    NSLog(@"       sector length %i",sectorLength);
    
    // Chunk Timestamps
    uint32_t timestampOffset = offset + 4096;
    uint sectorTimestamp = [NBTDataHelper intFromBytes:bytes offset:&timestampOffset];
    NSLog(@"       sector timestamp %i",sectorTimestamp);

    
    McChunk *chunk = [[McChunk alloc] init];
    [chunk setChunkPos:NSMakePoint(X, Y)];
    if (sectorOffset == 0 || sectorLength == 0) {
      [chunk setStatus:Chunk_Not_Created];
    }
    else if (sectorOffset < 2 && sectorOffset != 0) {
      NSLog(@"ERROR: sector in header");
      [chunk setStatus:Chunk_In_Header];
    }
    else {
      NSLog(@"       sector valid");
      [chunk setStatus:Chunk_OK];
      [chunk setSectorOffset:sectorOffset];
      [chunk setSectorApproxLength:sectorLength];
      [chunk setSectorTimestamp:sectorTimestamp];
    }
    [chunks addObject:chunk];
    [chunk release];
    
    NSLog(@"<<   end sector info");
  }
  NSLog(@"<< end header");
}

// Parse the data from the chunks found in parseHeader
- (void)parseSector:(const uint8_t *)bytes length:(uint32_t)length intoChunk:(McChunk *)chunk
{
  NSLog(@">> start chunk sector X%0.fY%0.f",chunk.chunkPos.x,chunk.chunkPos.y);
  uint32_t offset = 0;
  
  // Chunk data begins with a (big-endian) four-byte length field which indicates the exact length of the remaining chunk data in bytes.
  uint32_t chunkLength = [NBTDataHelper intFromBytes:bytes offset:&offset];
  NSLog(@"     chunk actual length %i",chunkLength);
  if (chunkLength == 0) {
    NSLog(@"ERROR: chunk has zero length");
    [chunk setStatus:Chunk_Zero_Length];
  }
  else if (chunkLength > length) {
    NSLog(@"ERROR: chunk length longer that header value");
    [chunk setStatus:Chunk_Mismatched_Length];
  }

  // The following byte indicates the compression scheme used for chunk data, and the remaining (length-1) bytes are the compressed chunk data.
  uint8_t chunkCompression = [NBTDataHelper byteFromBytes:bytes offset:&offset];
  NSLog(@"     chunk compression %i",chunkCompression);
  
  NSData *chunkData = [NSData dataWithBytes:bytes + offset length:chunkLength-1];
  if (chunkCompression == 1) [chunkData gzipInflate];
  else if (chunkCompression == 2) [chunkData zlibInflate];
  
  [chunk setLength:chunkLength];
  [chunk setCompression:chunkCompression];
  NBTContainer *chunkContainer = [NBTContainer nbtContainerWithData:chunkData];
  [chunk setContainer:chunkContainer];
  
  NSLog(@"<< end chunk sector");
}

@end


@implementation McChunk
@synthesize status;
@synthesize sectorOffset, sectorApproxLength, sectorTimestamp;
@synthesize chunkPos;
@synthesize length, compression;
@synthesize container;


@end


