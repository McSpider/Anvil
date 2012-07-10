//
//  MyDocument.h
//  Anvil
//
//  Created by Ben K on 12/07/01.
//  All code is provided under the New BSD license. Copyright 2011 Ben K.
//

#import <Cocoa/Cocoa.h>
#import "NBTContainer.h"

@interface MyDocument : NSDocument <NSOutlineViewDelegate,NSOutlineViewDataSource> {
  NBTContainer *fileData;
  IBOutlet NSMenu *typeMenu;
  
  IBOutlet NSOutlineView *dataView;
  BOOL fileLoaded;
}

@property (nonatomic, retain) NBTContainer *fileData;
@property BOOL fileLoaded;

- (IBAction)removeRow:(id)sender;
- (IBAction)addRow:(id)sender;
- (IBAction)addChild:(id)sender;
- (IBAction)changeListType:(id)sender;

@end
