//
//  NBTDocument.h
//  Anvil
//
//  Created by Ben K on 12/07/01.
//  All code is provided under the New BSD license. Copyright 2013 Ben K.
//

#import <Cocoa/Cocoa.h>
#import "NBTFile.h"
#import "NBTContainer.h"
#import "NBTFormatter.h"

@interface NBTDocument : NSDocument <NSOutlineViewDelegate,NSOutlineViewDataSource,NSMenuDelegate> {
  NBTFile *fileData;
  IBOutlet NSMenu *typeMenu;
  
  IBOutlet NSOutlineView *dataView;
  BOOL loadingFile;
  
  NSArray *draggedItems;
  
  IBOutlet NSView *saveAccessoryView;
  IBOutlet NSButton *saveCompressedCheckbox;
}

@property (nonatomic, retain) NBTFile *fileData;
@property BOOL loadingFile;

- (IBAction)removeRow:(id)sender;
- (IBAction)insertRow:(id)sender;
- (IBAction)duplicateRow:(id)sender;

@end
