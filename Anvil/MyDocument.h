//
//  MyDocument.h
//  Anvil
//
//  Created by Benjamin Kohler on 12/07/01.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NBTContainer.h"

@interface MyDocument : NSDocument <NSOutlineViewDelegate,NSOutlineViewDataSource> {
  NBTContainer *fileData;
  IBOutlet NSOutlineView *dataView;
}

@property (nonatomic, retain) NBTContainer *fileData;

- (IBAction)removeRow:(id)sender;
- (IBAction)addRowBelow:(id)sender;
- (IBAction)addRowAbove:(id)sender;
- (IBAction)addChild:(id)sender;

@end
