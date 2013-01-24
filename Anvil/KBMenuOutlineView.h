//
//  KBMenuOutlineView.h
//  Anvil
//
//  Created by Ben K on 12/07/03.
//  All code is provided under the New BSD license. Copyright 2012 Ben K
//

#import <AppKit/AppKit.h>

@interface NSOutlineView (VariableCellColumnDelegate)
- (void)outlineView:(NSOutlineView *)outlineView willShowMenuForRow:(NSInteger)row;
- (BOOL)outlineView:(NSOutlineView *)outlineView handleKeyDown:(NSEvent *)theEvent;
@end

@interface KBMenuOutlineView : NSOutlineView

@end
