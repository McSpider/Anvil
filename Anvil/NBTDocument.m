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

- (void)changeViewSelectionTo:(NSIndexSet *)newSelection fromSelection:(NSIndexSet *)oldSelection;

- (void)loadNBTData:(NSData *)data;
- (void)loadRegionData:(NSData *)data;

@end


@implementation NBTDocument
@synthesize fileData;
@synthesize fileLoaded;

- (id)init
{
  self = [super init];
  if (!self)
    return nil;
  
  fileData = [[NBTFile alloc] initWithData:nil type:NBT_File];
  [self setFileType:@"NBT.dat"];
  
  // Default data
  NBTContainer *container = [NBTContainer compoundWithName:@"Data"];
  NBTContainer *child;
  child = [NBTContainer containerWithName:@"Child" type:NBTTypeByte];
  [child setNumberValue:[NSNumber numberWithInt:1]];
  [child setParent:container];
  
  [container.children addObject:child];
  [container setParent:fileData.container];
  [fileData.container.children addObject:container];
  
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
  
  // Expand the first item if it's a single item
  if ((fileData.fileType == NBT_File || fileData.fileType == SCHEM_File) && [fileData.container.children count] == 1) {
    [dataView expandItem:[fileData.container.children objectAtIndex:0]];
  }
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
  /*
   Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
  You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
  */
  
  if ([typeName isEqualToString:@"NBT.dat"] || [typeName isEqualToString:@"NBT.schematic"]) {
    return [fileData.container writeData];
  }
  
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
    [self performSelectorInBackground:@selector(loadNBTData:) withObject:data];
  }
  if ([typeName isEqualToString:@"NBT.mca"]) {
    self.fileLoaded = NO;
    [self performSelectorInBackground:@selector(loadRegionData:) withObject:data];
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


- (void)loadNBTData:(NSData *)data
{
  NBTContainer *container = [[NBTContainer alloc] init];
  [container readFromData:data];
  
  //[fileData release];
  [fileData setContainer:container];
  [container release];
  
  if (fileData.container.children.count == 0)
    [[NSAlert alertWithMessageText:@"Failed to Open File" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The file you atempted to load does not contain any loadable data."] runModal];
  
  // Update UI in the main thread
  [self performSelectorOnMainThread:@selector(dataLoaded) withObject:nil waitUntilDone:NO];  
}

- (void)loadRegionData:(NSData *)data
{
  NBTFile *newFileData = [[NBTFile alloc] initWithData:data type:MCA_File];
  self.fileData = newFileData;
  [newFileData release];
  [self dataLoaded];
}

- (void)dataLoaded
{
  self.fileLoaded = YES;
  [dataView reloadData];
  [dataView.window makeFirstResponder:dataView];
  
  if ([fileData.container.children count] == 1) {
    [dataView expandItem:[fileData.container.children objectAtIndex:0]];
  }
}


#pragma mark -
#pragma mark Actions

- (IBAction)removeRow:(id)sender
{
  NSInteger clickedRow = [dataView clickedRow];
  if (clickedRow != -1 && ![dataView isRowSelected:clickedRow]) {
    [self removeItemAtRow:clickedRow];
    
    // We want to keep the selected items selected so the selection below the deleted item will need to be moved up 1 row
    NSMutableIndexSet *newSelection = [[NSMutableIndexSet alloc] initWithIndexSet:[dataView selectedRowIndexes]];
    [newSelection shiftIndexesStartingAtIndex:clickedRow by:-1];
    [self changeViewSelectionTo:newSelection fromSelection:[dataView selectedRowIndexes]];
    [newSelection release];
  }
  else {
    NSIndexSet *selectedIndexes = [dataView selectedRowIndexes];
    // Clear selection first so that it can be undone properly
    [self changeViewSelectionTo:[NSIndexSet indexSet] fromSelection:selectedIndexes];
    
    [selectedIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger row, BOOL *stop) {
      [self removeItemAtRow:row];
    }];
  }
}

- (IBAction)insertRow:(id)sender
{
  id item = [dataView itemAtRow:[dataView clickedRow]];
  
  
  if (!item) {
    item = [dataView itemAtRow:[dataView selectedRow]];
  }
  if (!item && (fileData.fileType == NBT_File || fileData.fileType == SCHEM_File)) {
    item = fileData.container;
  }
  
  if ([item isKindOfClass:[NBTContainer class]]) {
    NBTContainer *container = (NBTContainer *)item;
    if ([dataView isItemExpanded:item] || item == fileData) {
      NBTType childType = NBTTypeByte;
      NSString *name = @"Child";
      if (container.type == NBTTypeList) {
        childType = container.listType;
        name = nil;
      }
      
      NBTContainer *newItem;
      if (container.listType == NBTTypeCompound) {
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
      [self changeViewSelectionTo:[NSIndexSet indexSetWithIndex:rowIndex] fromSelection:[dataView selectedRowIndexes]];
    }
    else {
      NSInteger itemIndex = [[[item parent] children] indexOfObject:item];
      NBTType type = NBTTypeByte;
      NSString *name = @"New Row";
      if (container.parent && container.parent.type == NBTTypeList) {
        type = container.parent.listType;
        name = nil;
      }
      
      NBTContainer *newItem;
      newItem = [NBTContainer containerWithName:name type:type];
      [newItem setNumberValue:[NSNumber numberWithInt:1]];
      [newItem setParent:[container parent]];
      
      [self addItem:newItem toContainer:[container parent] atIndex:itemIndex+1];
      
      // Select the newly added row
      NSInteger rowIndex = [dataView rowForItem:newItem];
      [self changeViewSelectionTo:[NSIndexSet indexSetWithIndex:rowIndex] fromSelection:[dataView selectedRowIndexes]];
    }
  }
}

- (IBAction)duplicateRow:(id)sender
{
  NSInteger clickedRow = [dataView clickedRow];
  NSMutableIndexSet *duplicatedRows = [NSMutableIndexSet indexSet];
  
  if (clickedRow != -1 && ![dataView isRowSelected:clickedRow]) {
    NBTContainer *item = (NBTContainer *)[dataView itemAtRow:clickedRow];
        
    NBTContainer *newItem = [[item copy] autorelease];
    NSInteger itemIndex = [[[item parent] children] indexOfObject:item];
    [self addItem:newItem toContainer:[item parent] atIndex:itemIndex+1];
    [duplicatedRows addIndex:[dataView rowForItem:newItem]];
  }
  else {
    // Get pointers to the original items before we start modifying the outline view
    NSMutableArray *selectedItems = [NSMutableArray array];
    [[dataView selectedRowIndexes] enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger row, BOOL *stop) {
      [selectedItems addObject:[dataView itemAtRow:row]];
    }];

    // Add the new items to the outlineview and to a temporary array so that we can get their indexes
    NSMutableArray *newItems = [NSMutableArray array];
    for (NBTContainer *item in selectedItems) {
      NBTContainer *newItem = [[item copy] autorelease];      
      NSInteger itemIndex = [[[item parent] children] indexOfObject:item];
      [self addItem:newItem toContainer:[item parent] atIndex:itemIndex+1];     
      [newItems addObject:newItem];
    }
    
    // Add the new item indexes to the indexSet
    for (NBTContainer *item in newItems) {
      [duplicatedRows addIndex:[dataView rowForItem:item]];
    }
  }
  
  // Select the duplicated row(s) whichever the case may be
  [self changeViewSelectionTo:duplicatedRows fromSelection:[dataView selectedRowIndexes]];
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
  
  // This is what happens when I get bored...
  /*NSRect poff = [dataView rectOfRow:[dataView rowForItem:[container.children objectAtIndex:index]]];
  NSPoint poffPos = [[dataView window] convertBaseToScreen:[dataView convertPoint:NSMakePoint(poff.origin.x+(poff.size.height/2), poff.origin.y+(poff.size.height/2)) toView:nil]];
  NSShowAnimationEffect(NSAnimationEffectPoof, poffPos, NSZeroSize, NULL, NULL, NULL);*/

  [container.children removeObjectAtIndex:index];
  
  [dataView reloadData];
  /*[dataView beginUpdates];
  [dataView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:(container == fileData?nil:container) withAnimation:NSTableViewAnimationEffectFade];
  [dataView endUpdates];*/
}

- (void)addItem:(NBTContainer *)item toContainer:(NBTContainer *)container atIndex:(NSInteger)index
{
  if (index == -1) {
    index = 0; // Insert as first item
  }
  if ((index > container.children.count) || index < 0) {
    NSLog(@"Add item, index invalid. %li",index);
    return;
  }
  
  [[[self undoManager] prepareWithInvocationTarget:self] removeItemAtIndex:index fromContainer:container];
  
  [container.children insertObject:item atIndex:index];
  [item setParent:container];
  
  [dataView reloadData];
  /*[dataView beginUpdates];
  [dataView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:(container == fileData?nil:container) withAnimation:NSTableViewAnimationEffectFade];
  [dataView endUpdates];*/
  
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
  // TODO: Changing the type doesn't reformat the value
  
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

- (void)changeViewSelectionTo:(NSIndexSet *)newSelection fromSelection:(NSIndexSet *)oldSelection
{
  [[[self undoManager] prepareWithInvocationTarget:self] changeViewSelectionTo:oldSelection fromSelection:newSelection];
  [dataView selectRowIndexes:newSelection byExtendingSelection:NO];
}


#pragma mark -
#pragma mark OutlineView data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
  if (item == nil && (fileData.fileType == NBT_File || fileData.fileType == SCHEM_File)) {
    return [fileData.container children].count;
  }
  else if (item == nil && (fileData.fileType == MCA_File || fileData.fileType == MCR_File)) {
    return [fileData.chunks count];
  }
  
  if ([item isKindOfClass:[NBTContainer class]]) {
    return [(NBTContainer *)item children].count;
  }
  else if ([item isKindOfClass:[NSArray class]]) {
    return [(NSArray *)item count];
  }
  else if ([item isKindOfClass:[McChunk class]]) {
    return [[(McChunk *)item container] children].count;
  }
  
  return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
  if (item == nil && (fileData.fileType == NBT_File || fileData.fileType == SCHEM_File)) {
    if ([[fileData.container children] count] > 0) {
      return YES;
    }
  }
  else if (item == nil && (fileData.fileType == MCA_File || fileData.fileType == MCR_File)) {
    if ([fileData.chunks count] > 0) {
      return YES;
    }
  }
  
  if ([item isKindOfClass:[NBTContainer class]]) {
    if ([(NBTContainer *)item type] == NBTTypeCompound || [(NBTContainer *)item type] == NBTTypeList) {
      return YES;
    }
  }
  else if ([item isKindOfClass:[NSArray class]]) {
    return YES;
  }
  else if ([item isKindOfClass:[McChunk class]]) {
    NBTContainer *chunkContainer = [(McChunk *)item container];
    if ([chunkContainer type] == NBTTypeCompound || [chunkContainer type] == NBTTypeList) {
      return YES;
    }
  }
  
  return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
  if (item == nil && (fileData.fileType == NBT_File || fileData.fileType == SCHEM_File)) {
    return [fileData.container.children objectAtIndex:index];
  }
  else if (item == nil && (fileData.fileType == MCA_File || fileData.fileType == MCR_File)) {
    return [fileData.chunks objectAtIndex:index];
  }
  
  if ([item isKindOfClass:[NBTContainer class]]) {
    return [[(NBTContainer *)item children] objectAtIndex:index];
  }
  else if ([item isKindOfClass:[NSArray class]]) {
    return [(NSArray *)item objectAtIndex:index];
  }
  else if ([item isKindOfClass:[McChunk class]]) {
    return [[[(McChunk *)item container] children] objectAtIndex:index];
  }

  
  return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  if (item == nil && (fileData.fileType == NBT_File || fileData.fileType == SCHEM_File)) {
    if ([tableColumn.identifier isEqualToString:@"Key"])
      return [fileData.container name];
    else if ([tableColumn.identifier isEqualToString:@"Type"])
      return [NSNumber numberWithInt:[fileData.container type]+1];
    else if ([tableColumn.identifier isEqualToString:@"Value"])
      return [fileData.container numberValue];
    else if ([tableColumn.identifier isEqualToString:@"Icon"])
      return [NSImage imageNamed:@"Folder"];
  }
  else if (item == nil && (fileData.fileType == MCA_File || fileData.fileType == MCR_File)) {
    if ([tableColumn.identifier isEqualToString:@"Icon"])
      return [NSImage imageNamed:@"Folder"];
  }
  
  if ([item isKindOfClass:[NBTContainer class]]) {
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
  }
  
  if ([item isKindOfClass:[McChunk class]]) {
    if ([tableColumn.identifier isEqualToString:@"Key"]) {
      return [NSString stringWithFormat:@"Chunk X%0.f Y%0.f",[(McChunk *)item chunkPos].x,[(McChunk *)item chunkPos].y];
    }
    else if ([tableColumn.identifier isEqualToString:@"Value"]) {
      return [NSString stringWithFormat:@"Timestamp:%i",[(McChunk *)item sectorTimestamp]];
    }
    else if ([tableColumn.identifier isEqualToString:@"Icon"]) {
      return [NSImage imageNamed:@"Meta"];
    }
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
  if ([item isKindOfClass:[NBTContainer class]]) {
    if ([tableColumn.identifier isEqualToString:@"Icon"]) {
      return NO;
    }
    else if ([tableColumn.identifier isEqualToString:@"Key"] || [tableColumn.identifier isEqualToString:@"Type"]) {
      return ([[(NBTContainer *)item parent] type] == NBTTypeList?NO:YES);
    }
    else if ([tableColumn.identifier isEqualToString:@"Value"]) {
      if ([(NBTContainer *)item type] == NBTTypeCompound || [(NBTContainer *)item type] == NBTTypeByteArray || [(NBTContainer *)item type] == NBTTypeIntArray)
        return NO;
    }
    
    return YES;
  }
  return NO;
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  if (!tableColumn) {
    return nil;
  }
  
  if ([item isKindOfClass:[NBTContainer class]]) {
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
  }
  else if ([item isKindOfClass:[McChunk class]]) {
    if ([tableColumn.identifier isEqualToString:@"Type"]) {
      // Disable the type popup for chunk items
      NSCell *dataCell = [[NSTextFieldCell alloc] init];
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
      // Being edited, save and move to next row/column, currently just ends editing
    }
  }
  
  return NO;
}


#pragma mark -
#pragma mark Functions

- (BOOL)item:(id)item isInsideItem:(id)possibleParent
{
  if (item == possibleParent) {
    return YES;
  }
  
  if ([item isKindOfClass:[NBTContainer class]]) {
    for (NBTContainer *child in [(NBTContainer *)possibleParent children]) {
      BOOL returnValue = [self item:item isInsideItem:child];
      if (returnValue == YES)
        return YES;
    }
  }
  
  return NO;
}


#pragma mark -
#pragma mark OutlineView drag & drop

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
  // Prevent dragging into anything that is not a NBTContainer
  if (item && ![item isKindOfClass:[NBTContainer class]]) {
    return NSDragOperationNone;
  }
  else if (item == nil && (fileData.fileType == MCA_File || fileData.fileType == MCR_File)) {
    return NSDragOperationNone;
  }
  
  // Check if we are dragging the items into themselves
  NSPasteboard *pboard = [info draggingPasteboard];
  NSData *pasteData = [pboard dataForType:NBTDragAndDropData];
  
  // Items returned is an array containting two arrays [[Copied items],[Dragged row indexes]]
  NSArray *pasteArray = [NSKeyedUnarchiver unarchiveObjectWithData:pasteData];
  // TODO: Row indexes are NOT reliable when items get expanded
  for (NSNumber *rowIndex in [pasteArray objectAtIndex:0]) {
    if ([self item:item isInsideItem:[dataView itemAtRow:[rowIndex integerValue]]]) {
      return NSDragOperationNone;
    }
  }

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
  NSMutableArray *itemRows = [NSMutableArray array];
  for (NBTContainer *container in items)
    [itemRows addObject:[NSNumber numberWithInteger:[dataView rowForItem:container]]];
  
  NSArray *dataArray = [NSArray arrayWithObjects:itemRows, items, nil];
  
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dataArray];
  [pasteboard declareTypes:[NSArray arrayWithObject:NBTDragAndDropData] owner:self];
  [pasteboard setData:data forType:NBTDragAndDropData];
  return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
  NSPasteboard *pboard = [info draggingPasteboard];
  NSData *pasteData = [pboard dataForType:NBTDragAndDropData];
  
  // Items returned is an array containting two arrays [[Copied items],[Dragged row indexes]]
  NSArray *pasteArray = [NSKeyedUnarchiver unarchiveObjectWithData:pasteData];
  
  if (!pasteArray)
    return NO;
  
  // [info draggingSourceOperationMask] returns NSDragOperationAll for Move operations?
  BOOL localReorderOperation = ([info draggingSourceOperationMask] != NSDragOperationCopy && [info draggingSource] == dataView);
  
  // If its a local reorder get all the original items before we modify the outline view
  NSMutableArray *draggedItems = nil;
  if (localReorderOperation) {
    draggedItems = [NSMutableArray array];
    // TODO: Row indexes are NOT reliable when items get expanded
    for (NSNumber *rowIndex in [pasteArray objectAtIndex:0]) {
      [draggedItems addObject:[dataView itemAtRow:[rowIndex integerValue]]];
    }
  }
  
  // Add new items, we are using reverseObjectEnumerator because for some reason the rows are stored with indexes from bottom to top
  for (NBTContainer *dropItem in [[pasteArray objectAtIndex:1] reverseObjectEnumerator]) {
    if (!item)
      item = fileData;
    
    [dropItem setParent:item];
    [self addItem:dropItem toContainer:item atIndex:index];
  }
  
  // Remove old items if the operation is not a copy and the source view is the same as the receiving one
  if (localReorderOperation && draggedItems) {
    for (NBTContainer *item in [draggedItems reverseObjectEnumerator]) {      
      [self removeItemAtRow:[dataView rowForItem:item]];
      // Add deselect undo so that if we undo a drop all items get deselected
      [[[self undoManager] prepareWithInvocationTarget:dataView] deselectAll:self];
    }
  }
  
  // Select the dropped items
  NSMutableIndexSet *droppedIndexes = [NSMutableIndexSet indexSet];
  for (NBTContainer *dropItem in [[pasteArray objectAtIndex:1] reverseObjectEnumerator]) {
    [droppedIndexes addIndex:[dataView rowForItem:dropItem]];
  }
  [self changeViewSelectionTo:droppedIndexes fromSelection:[dataView selectedRowIndexes]];
  
  return YES;
}



#pragma mark -
#pragma mark OutlineView copy & paste

- (IBAction)copy:(id)sender
{
  NSMutableArray *items = [NSMutableArray array];
  NSMutableArray *itemRows = [NSMutableArray array];
  [[dataView selectedRowIndexes] enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger row, BOOL *stop) {
    [items addObject:[dataView itemAtRow:row]];
    [itemRows addObject:[NSNumber numberWithInteger:row]];
  }];
  
  NSArray *dataArray = [NSArray arrayWithObjects:itemRows, items, nil];
  
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dataArray];  
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  [pasteboard declareTypes:[NSArray arrayWithObject:NBTCopyAndPasteData] owner:self];
  [pasteboard setData:data forType:NBTCopyAndPasteData];
}

- (IBAction)cut:(id)sender
{
  [self copy:sender];
  
  [[dataView selectedRowIndexes] enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger row, BOOL *stop) {
    [self removeItemAtRow:row];
  }];
  [self changeViewSelectionTo:[NSIndexSet indexSet] fromSelection:[dataView selectedRowIndexes]];
}

- (IBAction)paste:(id)sender
{
  NBTContainer *selectedItem = [dataView itemAtRow:[dataView selectedRow]];
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  NSData *pasteData = [pasteboard dataForType:NBTCopyAndPasteData];
    
  // Items returned is an array containting two arrays [[Copied items],[Dragged row indexes]]
  NSArray *pasteArray = [NSKeyedUnarchiver unarchiveObjectWithData:pasteData];
  
  if (!pasteArray)
    return;
  
  // Add new items
  for (NBTContainer *dropItem in [pasteArray objectAtIndex:1]) {
    if (!selectedItem && (fileData.fileType == NBT_File || fileData.fileType == SCHEM_File)) {
      selectedItem = fileData.container;
    } else if (!selectedItem && (fileData.fileType == MCA_File || fileData.fileType == MCR_File)) {
      // TODO
      return;
    }
    
    if ([self outlineView:dataView isItemExpandable:selectedItem] && [dataView isItemExpanded:selectedItem]) {
      // Paste as the first item in the selected item
      [self addItem:dropItem toContainer:selectedItem atIndex:0];
    }
    else {
      // Paste below the selected item
      NSInteger insertIndex = [[selectedItem.parent children] indexOfObject:selectedItem];
      [self addItem:dropItem toContainer:selectedItem.parent atIndex:insertIndex+1];
    }
  }
  
  // TODO: Select new items  
  // Select the pasted items
  NSMutableIndexSet *droppedIndexes = [NSMutableIndexSet indexSet];
  for (NBTContainer *dropItem in [[pasteArray objectAtIndex:1] reverseObjectEnumerator]) {
    [droppedIndexes addIndex:[dataView rowForItem:dropItem]];
  }
  [self changeViewSelectionTo:droppedIndexes fromSelection:[dataView selectedRowIndexes]];

}


- (BOOL)validateUserInterfaceItem:(id )anItem
{
  NSInteger selectedRow = [dataView selectedRow];
  id selectedItem = [dataView itemAtRow:selectedRow];
  
  if ([anItem action] == @selector(copy:)) {
    return (selectedRow != -1 && [selectedItem isKindOfClass:[NBTContainer class]]);
  }
  if ([anItem action] == @selector(cut:)) {
    return ([dataView selectedRow] != -1 && [selectedItem isKindOfClass:[NBTContainer class]]);
  }
  if ([anItem action] == @selector(paste:)) {
    return ([dataView selectedRow] != -1 && [selectedItem isKindOfClass:[NBTContainer class]]);
  }

  return YES;
}



#pragma mark -
#pragma mark NSMenu delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
  id clickedItem = [dataView itemAtRow:[dataView clickedRow]];
  NSMenu *dataViewRightClickMenu = [dataView menu];
  if (menu != dataViewRightClickMenu)
    return;
  
  if (![clickedItem isKindOfClass:[NBTContainer class]]) {
    for (NSMenuItem *menuItem in [menu itemArray]) {
      [menuItem setEnabled:NO];
    }
    return;
  }
    
  if ([dataView isItemExpanded:clickedItem]) {
    [[menu itemAtIndex:2] setTitle:@"Insert Child"];
  } else {
    [[menu itemAtIndex:2] setTitle:@"Insert Row"];
  }
  
  // If we clicked on a selected row, then we want to consider all rows in the selection. Otherwise, we only consider the clicked on row.
  BOOL clickedItemSelected = [dataView isRowSelected:[dataView rowForItem:clickedItem]];
  NSInteger selectedRowsCount = [[dataView selectedRowIndexes] count];
  if ((clickedItemSelected && selectedRowsCount > 1)) {
    [[menu itemAtIndex:0] setTitle:@"Remove Rows"];
    [[menu itemAtIndex:3] setTitle:@"Duplicate Rows"];
  } else {
    [[menu itemAtIndex:0] setTitle:@"Remove Row"];
    [[menu itemAtIndex:3] setTitle:@"Duplicate Row"];
  }
  
  
  if ([dataView clickedRow] == -1) {
    for (NSMenuItem *menuItem in [menu itemArray]) {
      [menuItem setEnabled:NO];
    }
    
    [[menu itemAtIndex:2] setEnabled:YES];
  }
  else {
    for (NSMenuItem *menuItem in [menu itemArray]) {
      [menuItem setEnabled:YES];
    }
  }
}



@end
