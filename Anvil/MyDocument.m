//
//  MyDocument.m
//  Anvil
//
//  Created by Benjamin Kohler on 12/07/01.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument
@synthesize fileData;

- (id)init
{
  if (![super init])
    return nil;
  
  fileData = [[NBTContainer alloc] init];
  
  return self;
}

- (void)dealloc
{
  [fileData release];
  [super dealloc];
}


- (NSString *)windowNibName
{
  // Override returning the nib file name of the document
  // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
  return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
  [super windowControllerDidLoadNib:aController];
  // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
  /*
   Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
  You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
  */
  
  //return [fileData writeData];
  
  if (outError) {
      *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
  }
  return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
  /*
  Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
  You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
  If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
  */
  
  [fileData release];
  fileData = [[NBTContainer nbtContainerWithData:data] retain];
  [dataView reloadData];
  
  
  if (outError) {
      *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
  }
  return YES;
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

#pragma mark -
#pragma mark Actions

- (IBAction)removeRow:(id)sender
{
  
}

- (IBAction)addRowBelow:(id)sender
{
  
}

- (IBAction)addRowAbove:(id)sender
{
  
}

- (IBAction)addChild:(id)sender
{
  
}



#pragma mark -
#pragma mark TableView data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
  if (item == nil)
      return [fileData children].count;
  
  if ([item isKindOfClass:[NBTContainer class]])
    return [(NBTContainer *)item children].count;
  else if ([item isKindOfClass:[NSArray class]])
    return [(NSArray *)item count];

  
  return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
  if (item == nil)
    if ([[fileData children] count] > 0)
      return YES;
  
  if ([item isKindOfClass:[NBTContainer class]] && [[(NBTContainer *)item children] count] > 0)
    return YES;    
    
  return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
  if (item == nil)
    return [fileData.children objectAtIndex:index];
  
  if ([item isKindOfClass:[NBTContainer class]])
    return [[(NBTContainer *)item children] objectAtIndex:index];
  else if ([item isKindOfClass:[NSArray class]])
    return [(NSArray *)item objectAtIndex:index];
  
  return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  if (item == nil)
    if ([tableColumn.identifier isEqualToString:@"name"])
      return [fileData name];
    else if ([tableColumn.identifier intValue] == 2)
      return [NSNumber numberWithInt:[(NBTContainer *)item type]-1];
    else if ([tableColumn.identifier intValue] == 1)
      return [fileData numberValue];
  
  if ([item isKindOfClass:[NBTContainer class]]) {
    if ([tableColumn.identifier intValue] == 0)
      return [(NBTContainer *)item name];
    else if ([tableColumn.identifier intValue] == 2)
      return [NSNumber numberWithInt:[(NBTContainer *)item type]-1];
    else if ([tableColumn.identifier intValue] == 1)
      return ([(NBTContainer *)item type] == NBTTypeString?[(NBTContainer *)item stringValue]:[(NBTContainer *)item numberValue]);
  }
  else if ([item isKindOfClass:[NBTListItem class]]) {
    if ([tableColumn.identifier intValue] == 0)
      return [NSString stringWithFormat:@"Item %i",[(NBTListItem *)item index]];
    else if ([tableColumn.identifier intValue] == 2)
      return [NSNumber numberWithInt:[(NBTListItem *)item listType]];
    else if ([tableColumn.identifier intValue] == 1)
      return ([(NBTListItem *)item listType] == NBTTypeString?[(NBTListItem *)item value]:[(NBTListItem *)item value]);
  }
  
  return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  if ([tableColumn.identifier intValue] == 1) {
    if ([(NBTContainer *)item type] == NBTTypeString) {
      [(NBTContainer *)item setStringValue:(NSString *)object];
    }
    else {
      [(NBTContainer *)item setNumberValue:(NSNumber *)object];
    }
  }
  else if ([tableColumn.identifier intValue] == 2) {
    [(NBTContainer *)item setType:[(NSNumber *)object intValue]+1];
  }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
  //return [self outlineView:outlineView isItemExpandable:item];
  return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  if ([tableColumn.identifier intValue] == 0)
    return NO;
  
  if ([self outlineView:outlineView isItemExpandable:item])
    return NO;
  
  return YES;
}

- (void)outlineView:(NSOutlineView *)outlineView willShowMenuForRow:(NSInteger)row
{
  if (row == -1)
    for (NSMenuItem *menuItem in [[outlineView menu] itemArray])
      [menuItem setEnabled:NO];
  else {
    for (NSMenuItem *menuItem in [[outlineView menu] itemArray])
      [menuItem setEnabled:YES];
  
    [[[outlineView menu] itemAtIndex:4] setEnabled:[self outlineView:dataView isItemExpandable:[dataView itemAtRow:row]]];
  }
}



@end
