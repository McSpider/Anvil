//
//  MyDocument.m
//  Anvil
//
//  Created by Ben K on 12/07/01.
//  All code is provided under the New BSD license. Copyright 2011 Ben K.
//

#import "MyDocument.h"

@implementation MyDocument
@synthesize fileData;
@synthesize fileLoaded;

- (id)init
{
  if (![super init])
    return nil;
  
  fileData = [[NBTContainer compoundWithName:nil] retain];
  
  // Default data
  NBTContainer *container = [NBTContainer compoundWithName:@"Data"];
  NBTContainer *child;
  child = [NBTContainer containerWithName:@"Child" type:NBTTypeByte numberValue:[NSNumber numberWithInt:1]];
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
  
  /*
  [fileData release];
  fileData = [[NBTContainer nbtContainerWithData:data] retain];
  [dataView reloadData];
  */
  [fileData release];
  fileData = [[NBTContainer alloc] init];
  self.fileLoaded = NO;
  [self performSelectorInBackground:@selector(loadData:) withObject:data];
  
  
  if (outError) {
      *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
  }
  return YES;
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

- (void)loadData:(NSData *)data
{
  NBTContainer *container = [[NBTContainer alloc] init];
	[container readFromData:data];
  
  [fileData release];
  fileData = [container retain];
  
  self.fileLoaded = YES;
  [dataView reloadData];
  [dataView.window makeFirstResponder:dataView];
  [dataView expandItem:[fileData.children objectAtIndex:0]];
}

#pragma mark -
#pragma mark Actions

- (IBAction)removeRow:(id)sender
{
  NBTContainer *item = (NBTContainer *)[dataView itemAtRow:[dataView clickedRow]];
  [[[item parent] children] removeObject:item];
  
  [dataView reloadData];
}

- (IBAction)addRow:(id)sender
{
  NBTContainer *item = (NBTContainer *)[dataView itemAtRow:[dataView clickedRow]];
  NBTType type = NBTTypeByte;
  NSString *name = @"New Row";
  if (item.parent && item.parent.listType) {
    type = item.parent.listType;
    name = nil;
  }
  
  NBTContainer *newItem;
  if (item.parent && item.parent.listType == NBTTypeCompound)
    newItem = [NBTContainer compoundWithName:name];
  else
    newItem = [NBTContainer containerWithName:name type:type numberValue:[NSNumber numberWithInt:1]];
  [newItem setParent:[item parent]];

  [[[item parent] children] insertObject:newItem 
                                 atIndex:[[[item parent] children] indexOfObject:item]+1];
  [dataView reloadData];
}

- (IBAction)addChild:(id)sender
{
  NBTContainer *item = (NBTContainer *)[dataView itemAtRow:[dataView clickedRow]];
  NBTType type = NBTTypeByte;
  NSString *name = @"Child";
  if (item.listType) {
    type = item.listType;
    name = nil;
  }
  
  NBTContainer *newItem;
  if (item.listType == NBTTypeCompound)
    newItem = [NBTContainer compoundWithName:name];
  else
    newItem = [NBTContainer containerWithName:name type:type numberValue:[NSNumber numberWithInt:1]];
  [newItem setParent:item];

  [[item children] addObject:newItem];
  [dataView reloadData];
  
  [dataView expandItem:item];
}

- (IBAction)changeListType:(id)sender
{
  NBTType newType = (int)[sender tag];
  NBTContainer *item = (NBTContainer *)[dataView itemAtRow:[dataView clickedRow]];
  if (item.type == NBTTypeList) {
    item.listType = newType;
    for (NBTContainer *child in item.children) {
      child.type = item.listType;
    }
  }
  else if (item.parent && item.parent.type == NBTTypeList) {
    item.parent.listType = newType;
    for (NBTContainer *child in item.parent.children) {
      child.type = item.parent.listType;
    }
  }
  
  [dataView reloadData];  
}


#pragma mark -
#pragma mark TableView data source

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
    if ([tableColumn.identifier intValue] == 0)
      return [fileData name];
    else if ([tableColumn.identifier intValue] == 2)
      return [NSNumber numberWithInt:[fileData type]+1];
    else if ([tableColumn.identifier intValue] == 1)
      return [fileData numberValue];
    else if ([tableColumn.identifier intValue] == 4)
      return [NSImage imageNamed:@"Folder"];
  }
  
  if ([item isKindOfClass:[NBTContainer class]]) {
    // Key
    if ([tableColumn.identifier intValue] == 0) {
      if ([[(NBTContainer *)item parent] type] == NBTTypeList)
        return @"List Item";
      return [(NBTContainer *)item name];
    }
    // Type
    else if ([tableColumn.identifier intValue] == 2) {
      return [NSNumber numberWithInt:[(NBTContainer *)item type]+1];
    }
    // Value
    else if ([tableColumn.identifier intValue] == 1) {
      if ([(NBTContainer *)item type] == NBTTypeString)
        return [(NBTContainer *)item stringValue];
      else if ([(NBTContainer *)item type] == NBTTypeByteArray || [(NBTContainer *)item type] == NBTTypeIntArray)
        return [NSString stringWithFormat:@"(%i items)", (int)[[(NBTContainer *)item arrayValue] count]];
      else if ([(NBTContainer *)item type] == NBTTypeList) {
        return [NSNumber numberWithInt:[(NBTContainer *)item listType]+1];
      }
      else
        return [(NBTContainer *)item numberValue];
    }
    // Image
    else if ([tableColumn.identifier intValue] == 4) {
      if ([(NBTContainer *)item type] == NBTTypeCompound)
        return [NSImage imageNamed:@"Folder"];
      else if ([(NBTContainer *)item type] == NBTTypeList)
        return [NSImage imageNamed:@"List"];
      else if ([(NBTContainer *)item type] == NBTTypeByteArray || [(NBTContainer *)item type] == NBTTypeIntArray)
        return [NSImage imageNamed:@"Array"];
    }
  }  
  return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  NSString *stringValue = (NSString *)object;
  
  if ([item isKindOfClass:[NBTContainer class]]) {
    // Value
    if ([tableColumn.identifier intValue] == 1) {
      if ([(NBTContainer *)item type] == NBTTypeList) {
        [(NBTContainer *)item setListType:[(NSNumber *)object intValue]-1];
        return;
      }
      
      NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
      [formatter setNumberStyle:NSNumberFormatterNoStyle];
      NSNumber *myNumber = [formatter numberFromString:stringValue];
      [formatter release];
      
      if ([(NBTContainer *)item type] == NBTTypeString)
      {
        [(NBTContainer *)item setStringValue:stringValue];
      }
      else if ([(NBTContainer *)item type] == NBTTypeLong)
      {
        [(NBTContainer *)item setNumberValue:myNumber];//[NSNumber numberWithUnsignedLongLong:[stringValue unsignedLongLongValue]]];
      }
      else if ([(NBTContainer *)item type] == NBTTypeShort)
      {
        [(NBTContainer *)item setNumberValue:myNumber];//[NSNumber numberWithShort:[stringValue shortValue]]];
      }
      else if ([(NBTContainer *)item type] == NBTTypeInt)
      {
        [(NBTContainer *)item setNumberValue:myNumber];//[NSNumber numberWithInt:[stringValue intValue]]];
      }
      else if ([(NBTContainer *)item type] == NBTTypeByte)
      {
        [(NBTContainer *)item setNumberValue:myNumber];//[NSNumber numberWithUnsignedChar:[stringValue unsignedCharValue]]];
      }
      else if ([(NBTContainer *)item type] == NBTTypeDouble)
      {
        [(NBTContainer *)item setNumberValue:myNumber];//[NSNumber numberWithDouble:[stringValue doubleValue]]];
      }
      else if ([(NBTContainer *)item type] == NBTTypeFloat)
      {
        [(NBTContainer *)item setNumberValue:myNumber];//[NSNumber numberWithFloat:[stringValue floatValue]]];
      }      
    }
    // Type
    else if ([tableColumn.identifier intValue] == 2) {
      [(NBTContainer *)item setType:[(NSNumber *)object intValue]-1];
      [dataView reloadItem:item reloadChildren:YES];
    }
    // Key
    else if ([tableColumn.identifier intValue] == 0) {
      [(NBTContainer *)item setName:(NSString *)object];
    }
  }
}

/*- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
  return [self outlineView:outlineView isItemExpandable:item];
}*/

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  if ([tableColumn.identifier intValue] == 4)
    return NO;
  
  if ([tableColumn.identifier intValue] == 0 || [tableColumn.identifier intValue] == 2) {
      if ([item isKindOfClass:[NBTContainer class]])
        return ([[(NBTContainer *)item parent] type] == NBTTypeList?NO:YES);
  }
  
  if ([tableColumn.identifier intValue] == 1) {
    if ([item isKindOfClass:[NBTContainer class]])
      if ([(NBTContainer *)item type] == NBTTypeCompound || [(NBTContainer *)item type] == NBTTypeByteArray || [(NBTContainer *)item type] == NBTTypeIntArray)
        return NO;
  }  
  
  return YES;
}

- (void)outlineView:(NSOutlineView *)outlineView willShowMenuForRow:(NSInteger)row
{
  if (row == -1) {
    for (NSMenuItem *menuItem in [[outlineView menu] itemArray])
      [menuItem setEnabled:NO];
  }
  else {
    for (NSMenuItem *menuItem in [[outlineView menu] itemArray])
      [menuItem setEnabled:YES];
    
    
    BOOL addChildMenuEnabled = NO;
    NBTContainer *cont = [dataView itemAtRow:row];
    
    if (cont == nil) {
      if ([fileData type] == NBTTypeCompound || [fileData type] == NBTTypeList)
        addChildMenuEnabled = YES;
    }
    if ([cont isKindOfClass:[NBTContainer class]]) {
      if (cont.type == NBTTypeCompound || cont.type == NBTTypeList)
        addChildMenuEnabled = YES;
    }
    
    [[[outlineView menu] itemAtIndex:3] setEnabled:addChildMenuEnabled];
  }
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  if (tableColumn) {
    BOOL isContainer = [item isKindOfClass:[NBTContainer class]];
    
    if ([tableColumn.identifier intValue] == 1) {
      // Change list value field to a listType popup
      if (isContainer && [(NBTContainer *)item type] == NBTTypeList) {
        NSPopUpButtonCell *listTypeCell = [[NSPopUpButtonCell alloc] init];
        [listTypeCell setBordered:NO];
        NSMenu *aMenu = [typeMenu copy];
        [[aMenu itemAtIndex:0] setTitle:@"List Type"];
        [[aMenu itemWithTag:NBTTypeList] setHidden:YES];
        [[aMenu itemWithTag:NBTTypeByteArray] setHidden:YES];
        [[aMenu itemWithTag:NBTTypeIntArray] setHidden:YES];
        for (NSMenuItem *mItem in [aMenu itemArray]) {
          [mItem setTarget:self];
          [mItem setAction:@selector(changeListType:)];
        }
        [listTypeCell setMenu:aMenu];
        [aMenu release];
        return [listTypeCell autorelease];
      }
      // Disable byte/int array value fields
      else if (isContainer && ([(NBTContainer *)item type] == NBTTypeByteArray || [(NBTContainer *)item type] == NBTTypeIntArray)) {
        NSCell *dataCell = [[tableColumn dataCell] copy];
        [dataCell setEnabled:NO];
        return [dataCell autorelease];
      }
    }
    else if ([tableColumn.identifier intValue] == 2) {
      // Disable the type popup for list items
      if (isContainer && [[(NBTContainer *)item parent] type] == NBTTypeList) {
        NSCell *dataCell = [[tableColumn dataCell] copy];
        [dataCell setEnabled:NO];
        return [dataCell autorelease];
      }
    }
  }
  else
    return nil;
    
  return [tableColumn dataCell];
}



@end
