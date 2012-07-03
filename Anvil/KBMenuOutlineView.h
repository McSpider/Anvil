//
//  KBMenuOutlineView.h
//  Anvil
//
//  Created by Benjamin Kohler on 12/07/03.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSOutlineView (VariableCellColumnDelegate)
- (void)outlineView:(NSOutlineView *)outlineView willShowMenuForRow:(NSInteger)row;
@end

@interface KBMenuOutlineView : NSOutlineView

@end
