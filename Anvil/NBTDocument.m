//
//  NBTDocument.m
//  Anvil
//
//  Created by Ben K on 12/07/01.
//  All code is provided under the New BSD license. Copyright 2013 Ben K.
//

#import "NBTDocument.h"

#define NBTDragAndDropData @"NBTDragAndDropData"
#define NBTCopyAndPasteData @"NBTCopyAndPasteData"


@interface NBTDocument ()
- (void)removeItemAtRow:(NSInteger)row;
- (void)removeItem:(NBTContainer *)item fromContainer:(NBTContainer *)container;
- (void)removeItemAtIndex:(NSInteger)index fromContainer:(NBTContainer *)container;
- (void)addItem:(NBTContainer *)item toContainer:(NBTContainer *)container atIndex:(NSInteger)index;

- (void)setItem:(NBTContainer *)item listType:(NBTType)type;
- (void)setItem:(NBTContainer *)item type:(NBTType)type;

- (void)setItem:(NBTContainer *)item stringValue:(NSString *)value;
- (void)setItem:(NBTContainer *)item numberValue:(NSNumber *)value;
- (void)setItem:(NBTContainer *)item name:(NSString *)name;

- (void)loadDatData:(NSData *)data;

@end


@implementation NBTDocument
@synthesize fileData;
@synthesize fileLoaded;

- (id)init
{
  self = [super init];
  if (!self)
    return nil;
  
  fileData = [[NBTContainer compoundWithName:nil] retain];
  
  // Default data
  NBTContainer *container = [NBTContainer compoundWithName:@"Data"];
  NBTContainer *child;
  child = [NBTContainer containerWithName:@"Child" type:NBTTypeByte];
  [child setNumberValue:[NSNumber numberWithInt:1]];
  [child setParent:container];
  
  [container.children addObject:child];
  [container setParent:fileData];
  [fileData.children addObject:container];
  
  self.fileLoaded = YES;
  
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
  return @"NBTDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
  [super windowControllerDidLoadNib:aController];
  // Add any code here that needs to be executed once the windowController has loaded the document's window.
  
  [dataView registerForDraggedTypes:[NSArray arrayWithObjects:NBTDragAndDropData, nil]];
  if ([fileData.children count] == 1)
    [dataView expandItem:[fileData.children objectAtIndex:0]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
  /*
   Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
  You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
  */
  
  return [fileData writeData];
  
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
  
  if ([typeName isEqualToString:@"NBT.dat"] || [typeName isEqualToString:@"NBT.schematic"]) {
    self.fileLoaded = NO;
    [self performSelectorInBackground:@selector(loadDatData:) withObject:data];
  }
  
  if (outError) {
    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
  }
  return YES;
}

+ (BOOL)autosavesInPlace
{
    return NO;
}


- (void)loadDatData:(NSData *)data
{
  NBTContainer *container = [[NBTContainer alloc] init];
  [container readFromData:data];
  
  [fileData release];
  fileData = [container retain];
  [container release];
  
  if (fileData.children.count == 0)
    [[NSAlert alertWithMessageText:@"Failed to Open File" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The file you atempted to load does not contain any loadable data."] runModal];
  
  // Update UI in the main thread
  [self performSelectorOnMainThread:@selector(dataLoaded) withObject:nil waitUntilDone:NO];  
}

- (void)dataLoaded
{
  self.fileLoaded = YES;
  [dataView reloadData];
  [dataView.window makeFirstResponder:dataView];
  
  if ([fileData.children count] == 1)
    [dataView expandItem:[fileData.children objectAtIndex:0]];
}


#pragma mark -
#pragma mark Actions

- (IBAction)removeRow:(id)sender
{
  NSInteger row = [dataView clickedRow];
  if (row == -1) {
    row = [dataView selectedRow];
  }
  if (row != -1) {
    [self removeItemAtRow:row];
  }
}

- (IBAction)insertRow:(id)sender
{
  NBTContainer *item = (NBTContainer *)[dataView itemAtRow:[dataView clickedRow]];
  if (!item) {
    item = [dataView itemAtRow:[dataView selectedRow]];
  }
  if (!item) {
    item = fileData;
  }
  
  if ([dataView isItemExpanded:item] || item == fileData) {
    NBTType childType = NBTTypeByte;
    NSString *name = @"Child";
    if (item.type == NBTTypeList) {
      childType = item.listType;
      name = nil;
    }
    
    NBTContainer *newItem;
    if (item.listType == NBTTypeCompound) {
      newItem = [NBTContainer compoundWithName:name];
    }
    else {
      newItem = [NBTContainer containerWithName:name type:childType];
      [newItem setNumberValue:[NSNumber numberWithInt:1]];
    }
    [newItem setParent:item];
    
    [self addItem:newItem toContainer:item atIndex:0];
    
    // Select the newly added child
    NSInteger rowIndex = [dataView rowForItem:newItem];
    [dataView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
  }
  else {
    NSInteger itemIndex = [[[item parent] children] indexOfObject:item];
    NBTType type = NBTTypeByte;
    NSString *name = @"New Row";
    if (item.parent && item.parent.type == NBTTypeList) {
      type = item.parent.listType;
      name = nil;
    }
    
    NBTContainer *newItem;
    newItem = [NBTContainer containerWithName:name type:type];
    [newItem setNumberValue:[NSNumber numberWithInt:1]];
    [newItem setParent:[item parent]];
    
    [self addItem:newItem toContainer:[item parent] atIndex:itemIndex+1];
    
    // Select the newly added row
    NSInteger rowIndex = [dataView rowForItem:newItem];
    [dataView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
  }  
}

- (IBAction)duplicateRow:(id)sender
{
  NBTContainer *item = (NBTContainer *)[dataView itemAtRow:[dataView clickedRow]];
  if (!item) {
    item = [dataView itemAtRow:[dataView selectedRow]];
  }

  NSInteger itemIndex = [[[item parent] children] indexOfObject:item];
  [self addItem:[[item copy] autorelease] toContainer:[item parent] atIndex:itemIndex+1];
  
  // Select the duplicated row
  NSInteger rowIndex = [dataView rowForItem:item];
  if ([dataView isItemExpanded:item] && (item.type == NBTTypeCompound || item.type == NBTTypeList))
    rowIndex = rowIndex + item.children.count;
  [dataView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex+1] byExtendingSelection:NO];
}


#pragma mark -
#pragma mark Undo-able data methods

- (void)removeItemAtRow:(NSInteger)row
{
  NBTContainer *container = [(NBTContainer *)[dataView itemAtRow:row] parent];
  NSInteger childIndex = [container.children indexOfObject:[dataView itemAtRow:row]];
  
  [self removeItemAtIndex:childIndex fromContainer:container];
}

- (void)removeItem:(NBTContainer *)item fromContainer:(NBTContainer *)container
{
  [self removeItemAtIndex:[container.children indexOfObject:item] fromContainer:container];
}

- (void)removeItemAtIndex:(NSInteger)index fromContainer:(NBTContainer *)container
{
  if ((index > container.children.count) || index < 0) {
    NSLog(@"Remove item, index invalid. %li",index);
    return;
  }
  
  [[[self undoManager] prepareWithInvocationTarget:self] addItem:[container.children objectAtIndex:index] toContainer:container atIndex:index];
  
  [container.children removeObjectAtIndex:index];
  [dataView reloadData];
}

- (void)addItem:(NBTContainer *)item toContainer:(NBTContainer *)container atIndex:(NSInteger)index
{
  if (index == -1) {
    index = container.children.count;
  }
  if ((index > container.children.count) || index < 0) {
    NSLog(@"Add item, index invalid. %li",index);
    return;
  }
  
  [[[self undoManager] prepareWithInvocationTarget:self] removeItemAtIndex:index fromContainer:container];
  
  [container.children insertObject:item atIndex:index];
  [item setParent:container];
  
  [dataView reloadData];
  [dataView expandItem:container];
}

- (void)setItem:(NBTContainer *)item listType:(NBTType)type
{
  [[[self undoManager] prepareWithInvocationTarget:self] setItem:item listType:item.listType];
  
  if (item.type == NBTTypeList) {
    item.listType = type;
    for (NBTContainer *child in item.children) {
      [self setItem:child type:item.listType];
    }
    [dataView reloadItem:item reloadChildren:YES];
  }
  else if (item.parent && item.parent.type == NBTTypeList) {
    item.parent.listType = type;
    for (NBTContainer *child in item.parent.children) {
      [self setItem:child type:item.parent.listType];
    }
    [dataView reloadItem:item.parent reloadChildren:YES];
  }  
}

- (void)setItem:(NBTContainer *)item type:(NBTType)type
{
  [[[self undoManager] prepareWithInvocationTarget:self] setItem:item type:item.type];
  
  [item setType:type];
  [dataView reloadItem:item reloadChildren:YES];
}

- (void)setItem:(NBTContainer *)item stringValue:(NSString *)value
{
  [[[self undoManager] prepareWithInvocationTarget:self] setItem:item stringValue:item.stringValue];
  
  [item setStringValue:value];
  [dataView reloadItem:item];
}

- (void)setItem:(NBTContainer *)item numberValue:(NSNumber *)value
{
  [[[self undoManager] prepareWithInvocationTarget:self] setItem:item numberValue:item.numberValue];
  
  [item setNumberValue:value];
  [dataView reloadItem:item];
}

- (void)setItem:(NBTContainer *)item name:(NSString *)name
{
  [[[self undoManager] prepareWithInvocationTarget:self] setItem:item name:item.name];
  
  [item setName:name];
  [dataView reloadItem:item];
}


#pragma mark -
#pragma mark OutlineView data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
  if (item == nil)
    return [fileData children].count;
  
  if ([item isKindOfClass:[NBTContainer class]])
    return [(NBTContainer *)item children].count;
  
  return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
  if (item == nil)
    if ([[fileData children] count] > 0)
      return YES;
  
  if ([item isKindOfClass:[NBTContainer class]] && ([(NBTContainer *)item type] == NBTTypeCompound || [(NBTContainer *)item type] == NBTTypeList))
    return YES;
  
  return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
  if (item == nil)
    return [fileData.children objectAtIndex:index];
  
  if ([item isKindOfClass:[NBTContainer class]])
    return [[(NBTContainer *)item children] objectAtIndex:index];
  
  return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  if (item == nil) {
    if ([tableColumn.identifier isEqualToString:@"Key"])
      return [fileData name];
    else if ([tableColumn.identifier isEqualToString:@"Type"])
      return [NSNumber numberWithInt:[fileData type]+1];
    else if ([tableColumn.identifier isEqualToString:@"Value"])
      return [fileData numberValue];
    else if ([tableColumn.identifier isEqualToString:@"Icon"])
      return [NSImage imageNamed:@"Folder"];
  }
  
  if ([tableColumn.identifier isEqualToString:@"Key"]) {
    if ([[(NBTContainer *)item parent] type] == NBTTypeList)
      return @"List Item";
    return [(NBTContainer *)item name];
  }
  else if ([tableColumn.identifier isEqualToString:@"Type"]) {
    return [NSNumber numberWithInt:[(NBTContainer *)item type]+1];
  }
  else if ([tableColumn.identifier isEqualToString:@"Value"]) {
    if ([(NBTContainer *)item type] == NBTTypeString)
      return [(NBTContainer *)item stringValue];
    else if ([(NBTContainer *)item type] == NBTTypeByteArray || [(NBTContainer *)item type] == NBTTypeIntArray)
      return [NSString stringWithFormat:@"(%i items)", (int)[[(NBTContainer *)item arrayValue] count]];
    else if ([(NBTContainer *)item type] == NBTTypeList)
      return [NSNumber numberWithInt:[(NBTContainer *)item listType]+1];
    else if ([(NBTContainer *)item type] == NBTTypeCompound)
      return nil;
    else
      return [(NBTContainer *)item numberValue];
  }
  else if ([tableColumn.identifier isEqualToString:@"Icon"]) {
    if ([(NBTContainer *)item type] == NBTTypeCompound)
      return [NSImage imageNamed:@"Folder"];
    else if ([(NBTContainer *)item type] == NBTTypeList)
      return [NSImage imageNamed:@"List"];
    else if ([(NBTContainer *)item type] == NBTTypeByteArray || [(NBTContainer *)item type] == NBTTypeIntArray)
      return [NSImage imageNamed:@"Array"];
  }
  return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  // TODO: Only update the item if its value has actually changed
  if ([item isKindOfClass:[NBTContainer class]]) {
    if ([tableColumn.identifier isEqualToString:@"Value"]) {
      if ([(NBTContainer *)item type] == NBTTypeList) {
        [self setItem:item listType:[(NSNumber *)object intValue] - 1];        
        return;
      }
      else if ([(NBTContainer *)item type] == NBTTypeString) {
        [self setItem:item stringValue:(NSString *)object];
      }
      else if ([(NBTContainer *)item type] == NBTTypeLong || [(NBTContainer *)item type] == NBTTypeShort ||
               [(NBTContainer *)item type] == NBTTypeInt || [(NBTContainer *)item type] == NBTTypeInt ||
               [(NBTContainer *)item type] == NBTTypeByte || [(NBTContainer *)item type] == NBTTypeDouble ||
               [(NBTContainer *)item type] == NBTTypeFloat) {
        
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterNoStyle];
        NSNumber *myNumber = [formatter numberFromString:(NSString *)object];
        [formatter release];
        
        [self setItem:item numberValue:myNumber];
      }
    }
    else if ([tableColumn.identifier isEqualToString:@"Type"]) {
      [self setItem:item type:[(NSNumber *)object intValue] - 1];      
    }
    else if ([tableColumn.identifier isEqualToString:@"Key"]) {;
      [self setItem:item name:(NSString *)object];
    }
  }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  if ([tableColumn.identifier isEqualToString:@"Icon"])
    return NO;
  
  if ([tableColumn.identifier isEqualToString:@"Key"] || [tableColumn.identifier isEqualToString:@"Type"]) {
      if ([item isKindOfClass:[NBTContainer class]])
        return ([[(NBTContainer *)item parent] type] == NBTTypeList?NO:YES);
  }
  
  if ([tableColumn.identifier isEqualToString:@"Value"]) {
    if ([item isKindOfClass:[NBTContainer class]])
      if ([(NBTContainer *)item type] == NBTTypeCompound || [(NBTContainer *)item type] == NBTTypeByteArray || [(NBTContainer *)item type] == NBTTypeIntArray)
        return NO;
  }  
  
  return YES;
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  if (!tableColumn) {
    return nil;
  }
  
  if ([tableColumn.identifier isEqualToString:@"Key"]) {
    // Add formatter to cell
    [[tableColumn dataCell] setFormatter:[NBTFormatter formatterWithType:NBTTypeString]];
    
    // Disable list item name fields
    if ([[(NBTContainer *)item parent] type] == NBTTypeList) {
      NSCell *dataCell = [[tableColumn dataCell] copy];
      [dataCell setEnabled:NO];
      return [dataCell autorelease];
    }
  }
  else if ([tableColumn.identifier isEqualToString:@"Value"]) {
    // Add formatter to cell
    [[tableColumn dataCell] setFormatter:[NBTFormatter formatterWithType:[(NBTContainer *)item type]]];
    
    // Change list value field to a listType popup
    if ([(NBTContainer *)item type] == NBTTypeList) {
      NSPopUpButtonCell *listTypeCell = [[NSPopUpButtonCell alloc] init];
      [listTypeCell setBordered:NO];
      NSMenu *aMenu = [typeMenu copy];
      [[aMenu itemAtIndex:0] setTitle:@"List Type"];
      [[aMenu itemWithTag:NBTTypeList] setHidden:YES];
      [[aMenu itemWithTag:NBTTypeByteArray] setHidden:YES];
      [[aMenu itemWithTag:NBTTypeIntArray] setHidden:YES];
      [listTypeCell setMenu:aMenu];
      [aMenu release];
      [listTypeCell selectItemWithTag:NBTTypeByte];
      return [listTypeCell autorelease];
    }
    // Disable byte/int array value fields
    else if (([(NBTContainer *)item type] == NBTTypeByteArray || [(NBTContainer *)item type] == NBTTypeIntArray)) {
      NSCell *dataCell = [[tableColumn dataCell] copy];
      [dataCell setEnabled:NO];
      return [dataCell autorelease];
    }
  }
  else if ([tableColumn.identifier isEqualToString:@"Type"]) {
    // Disable the type popup for list items
    if ([[(NBTContainer *)item parent] type] == NBTTypeList) {
      NSCell *dataCell = [[tableColumn dataCell] copy];
      [dataCell setEnabled:NO];
      return [dataCell autorelease];
    }
  }
  
  return [tableColumn dataCell];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
  return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView handleKeyDown:(NSEvent *)theEvent
{
  unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
  
  if (([theEvent modifierFlags] & NSCommandKeyMask) || ([theEvent modifierFlags] & NSAlternateKeyMask)
      || ([theEvent modifierFlags] & NSControlKeyMask) || ([theEvent modifierFlags] & NSFunctionKeyMask)) {
    // Handle any key events with modifier keys here
    
    if (([theEvent modifierFlags] & NSCommandKeyMask) && (key == 'd')) {
      if ([outlineView selectedRow] != -1) {
        [self duplicateRow:nil];
        return YES;
      }
    }
    return NO;
  }
  
  if (key == NSDeleteCharacter) {
    NBTContainer *selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
    if (selectedItem) {
      [self removeRow:nil];
      return YES;
    }
  }
  if ((key == NSEnterCharacter) || (key == NSCarriageReturnCharacter)) {
    if ([dataView editedRow] == -1) { // Not being edited, Insert new row
      [self insertRow:nil];
      return YES;
    }
    else {
      // Being edited, save and move to next row/column, Currently just ends editing
    }
  }
  
  return NO;
}


#pragma mark -
#pragma mark OutlineView drag & drop

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
  // TODO: Prevent dragging and dropping into itself.
  // Only drag into compounds or lists.
  if (item && [(NBTContainer *)item type] != NBTTypeCompound && [(NBTContainer *)item type] != NBTTypeList)
    return NSDragOperationNone;
  
  // Drag is coming from a different view
  if ([info draggingSource] != dataView)
    return NSDragOperationCopy;
  
  if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask)
    return NSDragOperationCopy;
  
  return NSDragOperationMove;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
  NSMutableDictionary *itemsDictionary = [NSMutableDictionary dictionary];
  for (NBTContainer *container in items)
    [itemsDictionary setObject:container forKey:[NSNumber numberWithInteger:[dataView rowForItem:container]]];
  
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:itemsDictionary];
  [pasteboard declareTypes:[NSArray arrayWithObject:NBTDragAndDropData] owner:self];
  [pasteboard setData:data forType:NBTDragAndDropData];
  return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
  NSPasteboard *pboard = [info draggingPasteboard];
  NSData *rowData = [pboard dataForType:NBTDragAndDropData];
  NSDictionary *items = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
  
  if (!items)
    return NO;
  
  for (NSNumber *key in items) {
    NBTContainer *dropItem = [items objectForKey:key];
    if (!dropItem)
      return NO;
    
    if (!item)
      item = fileData;
    
    if ([item isKindOfClass:[NBTContainer class]]) {
      // TODO: Properly handle copy/move
      [dropItem setParent:item];
      [self addItem:dropItem toContainer:item atIndex:index];
      
      // Remove the item if the operation is not a copy and the source view is the same as the receiving one
      // [info draggingSourceOperationMask] returns NSDragOperationAll for Move operations?
      if ([info draggingSourceOperationMask] != NSDragOperationCopy && [info draggingSource] == dataView)
        [self removeItemAtRow:[key integerValue]]; // Remove after insert to prevent shifting of rows
    }
  }
  
  return YES;
}



#pragma mark -
#pragma mark OutlineView copy & paste

- (IBAction)copy:(id)sender
{
  // TODO: Possibly rewrite to support multiple items.
  NBTContainer *selectedItem = [dataView itemAtRow:[dataView selectedRow]];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selectedItem];
  
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  [pasteboard declareTypes:[NSArray arrayWithObject:NBTCopyAndPasteData] owner:self];
  [pasteboard setData:data forType:NBTCopyAndPasteData];
}

- (IBAction)cut:(id)sender
{
  // TODO: Possibly rewrite to support multiple items.
  NBTContainer *selectedItem = [dataView itemAtRow:[dataView selectedRow]];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selectedItem];
  
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  [pasteboard declareTypes:[NSArray arrayWithObject:NBTCopyAndPasteData] owner:self];
  [pasteboard setData:data forType:NBTCopyAndPasteData];
  
  [self removeItem:selectedItem fromContainer:selectedItem.parent];
}

- (IBAction)paste:(id)sender
{
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  NSData *data = [pasteboard dataForType:NBTCopyAndPasteData];
  if (!data) return;
  
  NBTContainer *item = [NSKeyedUnarchiver unarchiveObjectWithData:data];  
  if (!item) return;
  
  NBTContainer *selectedItem = [dataView itemAtRow:[dataView selectedRow]];
  if ([self outlineView:dataView isItemExpandable:selectedItem] && [dataView isItemExpanded:selectedItem]) {
    // Paste as the first item in the selected item
    [self addItem:item toContainer:selectedItem atIndex:0];
  }
  else {
    // Paste below the selected item
    NSInteger insertIndex = [[selectedItem.parent children] indexOfObject:selectedItem];
    [self addItem:item toContainer:selectedItem.parent atIndex:insertIndex+1];
  }
  
  // Select the pasted item
  NSInteger rowIndex = [dataView rowForItem:item];
  [dataView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
}


- (BOOL)validateUserInterfaceItem:(id )anItem
{
  if ([anItem action] == @selector(copy:)) {
    return ([dataView selectedRow] != -1);
  }
  if ([anItem action] == @selector(cut:)) {
    return ([dataView selectedRow] != -1);
  }
  if ([anItem action] == @selector(paste:)) {
    return ([dataView selectedRow] != -1);
  }

  return YES;
}



#pragma mark -
#pragma mark NSMenu delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{  
  NSMenu *dataViewRightClickMenu = [dataView menu];
  if (menu != dataViewRightClickMenu)
    return;
  
  if ([dataView clickedRow] == -1) {
    for (NSMenuItem *menuItem in [menu itemArray])
      [menuItem setEnabled:NO];
    
    [[menu itemAtIndex:2] setEnabled:YES];
  }
  else {
    for (NSMenuItem *menuItem in [menu itemArray])
      [menuItem setEnabled:YES];
  }
}



@end
