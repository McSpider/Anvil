//
//  NBTFormatter.h
//  Anvil
//
//  Created by Ben K on 2013-01-24.
//
//

#import <Foundation/Foundation.h>
#import "NBTContainer.h"

@interface NBTFormatter : NSFormatter {
  NBTType formatterType;
}

@property NBTType formatterType;

+ (NSFormatter *)formatterWithType:(NBTType)formatType;

@end
