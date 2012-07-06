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
  NBTContainer *item = (NBTContainer *)[dataView itemAtRow:[dataView clickedRow]];
  [[[item parent] children] removeObject:item];
  
  [dataView reloadData];
}

- (IBAction)addRowBelow:(id)sender
{
  NBTContainer *item = (NBTContainer *)[dataView itemAtRow:[dataView clickedRow]];
  NBTType type = NBTTypeByte;
  NSString *name = @"Row Below";
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

- (IBAction)addRowAbove:(id)sender
{
  NBTContainer *item = (NBTContainer *)[dataView itemAtRow:[dataView clickedRow]];
  NBTType type = NBTTypeByte;
  NSString *name = @"Row Above";
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
                      atIndex:[[[item parent] children] indexOfObject:item]];
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
  
  return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  if (item == nil) {
    if ([tableColumn.identifier isEqualToString:@"name"])
      return [fileData name];
    else if ([tableColumn.identifier intValue] == 2)
      return [NSNumber numberWithInt:[(NBTContainer *)item type]-1];
    else if ([tableColumn.identifier intValue] == 1)
      return [fileData numberValue];
  }
  
  if ([item isKindOfClass:[NBTContainer class]]) {
    // Key
    if ([tableColumn.identifier intValue] == 0) {
      return [(NBTContainer *)item name];
    }
    // Type
    else if ([tableColumn.identifier intValue] == 2) {
      return [NSNumber numberWithInt:[(NBTContainer *)item type]-1];
    }
    // Value
    else if ([tableColumn.identifier intValue] == 1) {
      if ([(NBTContainer *)item type] == NBTTypeString || [(NBTContainer *)item type] == NBTTypeByteArray)
        return [(NBTContainer *)item stringValue];
      else
        return [(NBTContainer *)item numberValue];
    }
  }  
  return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  NSString *stringValue = (NSString *)object;
  
  // Value
  if ([tableColumn.identifier intValue] == 1) {
    if ([item isKindOfClass:[NBTContainer class]]) {
      
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
  }
  // Type
  else if ([tableColumn.identifier intValue] == 2) {
    if ([item isKindOfClass:[NBTContainer class]])
      [(NBTContainer *)item setType:[(NSNumber *)object intValue]+1];
  }
  // Key
  else if ([tableColumn.identifier intValue] == 0) {
    if ([item isKindOfClass:[NBTContainer class]])
      [(NBTContainer *)item setName:(NSString *)object];
  }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
  //return [self outlineView:outlineView isItemExpandable:item];
  return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  if ([tableColumn.identifier intValue] == 0 || [tableColumn.identifier intValue] == 2) {
      if ([item isKindOfClass:[NBTContainer class]])
        return ([[(NBTContainer *)item parent] type] == NBTTypeList?NO:YES);
  }
  
  if ([self outlineView:outlineView isItemExpandable:item] && [tableColumn.identifier intValue] != 0)
    return NO;
  
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
    BOOL changeListTypeMenuEnabled = NO;
    NBTContainer *cont = [dataView itemAtRow:row];
    
    if (cont == nil) {
      if ([fileData type] == NBTTypeCompound || [fileData type] == NBTTypeList)
        addChildMenuEnabled = YES;
    }
    if ([cont isKindOfClass:[NBTContainer class]]) {
      if (cont.type == NBTTypeCompound || cont.type == NBTTypeList)
        addChildMenuEnabled = YES;
      
      if ((cont.parent && cont.parent.type == NBTTypeList) || cont.type == NBTTypeList)
        changeListTypeMenuEnabled = YES;
    
    }
    
    [[[outlineView menu] itemAtIndex:4] setEnabled:addChildMenuEnabled];
    [[[outlineView menu] itemAtIndex:6] setEnabled:changeListTypeMenuEnabled];
  }
}



@end
