//
//  NBTFile.m
//  Anvil
//
//  Created by Ben K on 2013-01-25.
//
//

#import "NBTFile.h"
#import "NSData+CocoaDevAdditions.h"


@implementation NBTFile

- (id)initWithData:(NSData *)data type:(NBTFileType)type
{
  self = [super init];
  if (!self)
    return nil;
  
  header = [[NSMutableArray alloc] init];
  
  fileType = type;
  fileData = [data retain];
  
  if (type == NBT_File || type == SCHEM_File) {
    container = [NBTContainer nbtContainerWithData:data];
  }
  
  if (type == MCA_File || type == MCR_File) {
    const uint8_t *bytes = (const uint8_t *)[fileData bytes];
    if (bytes != 0) {
      [self parseHeader:bytes];
      NSLog(@"\n");
      
      // Loop through chunk info, validate chunk, load chunk
      for (NSDictionary *sectorInfo in header) {
        uint64_t sectorOffset = [[sectorInfo objectForKey:@"Offset"] intValue];
        uint32_t approxSectorLength = [[sectorInfo objectForKey:@"Length"] intValue];
        uint sectorTimestamp = [[sectorInfo objectForKey:@"Timestamp"] intValue];

        NSLog(@">> parse chunk sector; offset:%lli length:%i timestamp:%i",sectorOffset,approxSectorLength,sectorTimestamp);
        
        // Offset & length of the sector in 4KiB increments (4KiB = 4096bytes)
        sectorOffset = sectorOffset * 4096;
        approxSectorLength = approxSectorLength * 4096;
        NSLog(@">> sector actual offset:%lli length:%i",sectorOffset,approxSectorLength);
        
        const uint8_t *sectorBytes = bytes + sectorOffset;        
        [self parseSector:sectorBytes length:approxSectorLength];
      }
    }
  }
  
  return self;
}

- (void)dealloc
{
  [header release];
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
    NSLog(@">>   start sector info");
    // The offset of the chunk in 4KiB sectors from the start of the file, this is stored as a (big-endian) three-byte value (24 bits)
    uint32_t sectorOffset = [NBTDataHelper tribyteFromBytes:bytes offset:&offset];
    NSLog(@">>     sector offset %i",sectorOffset);
    
    // The length of the chunk in 4KiB sectors (rounded up)
    uint8_t sectorLength = [NBTDataHelper byteFromBytes:bytes offset:&offset];
    NSLog(@">>     sector length %i",sectorLength);
    
    // Chunk Timestamps
    uint32_t timestampOffset = offset + 4096;
    uint sectorTimestamp = [NBTDataHelper intFromBytes:bytes offset:&timestampOffset];
    NSLog(@">>     sector timestamp %i",sectorTimestamp);

    
    if (sectorOffset == 0 || sectorLength == 0) {
      // Chunk not generated
    }
    else {
      NSLog(@">>     sector valid");
      [header addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInt:sectorOffset], @"Offset",
                         [NSNumber numberWithInt:sectorLength], @"Length",
                         [NSNumber numberWithInt:sectorTimestamp], @"Timestamp", nil]];
    }
    NSLog(@">>   end sector info");
  }
  NSLog(@">> end header");
}

// Parse the data from the chunks found in parseHeader
- (void)parseSector:(const uint8_t *)bytes length:(uint32_t)length
{
  NSLog(@">> start chunk sector");  
  uint32_t offset = 0;
  
  // Chunk data begins with a (big-endian) four-byte length field which indicates the exact length of the remaining chunk data in bytes.
  uint32_t chunkLength = [NBTDataHelper intFromBytes:bytes offset:&offset];
  NSLog(@">>   chunk actual length %i",chunkLength);
  if (chunkLength > length)
    NSLog(@"ERROR: chunk length longer that header value");

  // The following byte indicates the compression scheme used for chunk data, and the remaining (length-1) bytes are the compressed chunk data.
  uint8_t chunkCompression = [NBTDataHelper byteFromBytes:bytes offset:&offset];
  NSLog(@">>   chunk compression %i",chunkCompression);
  
  NSData *chunkData = [NSData dataWithBytes:bytes + offset length:chunkLength-1];
  if (chunkCompression == 1) [chunkData gzipInflate];
  else if (chunkCompression == 2) [chunkData zlibInflate];
  
  McChunk *chunk = [[McChunk alloc] init];
  [chunk setLength:chunkLength];
  [chunk setCompression:chunkCompression];
  NBTContainer *chunkContainer = [NBTContainer nbtContainerWithData:chunkData];
  [chunk setContainer:chunkContainer];
  
  NSLog(@">> end chunk sector");
}

@end


@implementation McChunk
@synthesize length, compression;
@synthesize container;


@end


