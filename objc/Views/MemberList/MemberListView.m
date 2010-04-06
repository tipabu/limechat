// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "MemberListView.h"


@implementation MemberListView

@synthesize dropDelegate;
@synthesize theme;

- (void)setUp
{
	bgColor = [[NSColor controlBackgroundColor] retain];
}

- (id)initWithFrame:(NSRect)rect
{
	if (self = [super initWithFrame:rect]) {
		[self setUp];
	}
	return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
	if (self = [super initWithCoder:coder]) {
		[self setUp];
	}
	return self;
}

- (void)dealloc
{
	[theme release];
	[bgColor release];
	[topLineColor release];
	[bottomLineColor release];
	[gradient release];
	[super dealloc];
}

- (void)awakeFromNib
{
	[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

- (void)keyDown:(NSEvent *)e
{
	if (keyDelegate) {
		switch ([e keyCode]) {
			case 116:	// page up
			case 121:	// page down
			case 123 ... 126:	// cursor keys
				break;
			default:
				if ([keyDelegate respondsToSelector:@selector(memberListViewKeyDown:)]) {
					[keyDelegate memberListViewKeyDown:e];
				}
				return;
		}
	}
	
	[super keyDown:e];
}

- (void)themeChanged
{
	[bgColor release];
	[topLineColor release];
	[bottomLineColor release];
	[gradient release];
	
	bgColor = [[theme memberListBackgroundColor] retain];
	topLineColor = [[theme memberListSelTopLineColor] retain];
	bottomLineColor = [[theme memberListSelBottomLineColor] retain];
	
	NSColor* start = [theme memberListSelTopColor];
	NSColor* end = [theme memberListSelBottomColor];
	if (start && end) {
		gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
	}
	else {
		gradient = nil;
	}
}

- (NSColor*)_highlightColorForCell:(NSCell*)cell
{
	return nil;
}

- (void)_highlightRow:(int)row clipRect:(NSRect)clipRect
{
	NSRect frame = [self rectOfRow:row];
	
	if (topLineColor && bottomLineColor && gradient) {
		NSRect rect = frame;
		rect.origin.y += 1;
		rect.size.height -= 2;
		[gradient drawInRect:rect angle:90];
		
		[topLineColor set];
		rect = frame;
		rect.size.height = 1;
		NSRectFill(rect);
		
		[bottomLineColor set];
		rect = frame;
		rect.origin.y += rect.size.height - 1;
		rect.size.height = 1;
		NSRectFill(rect);
	}
	else {
		if ([self window] && [[self window] isMainWindow] && [[self window] firstResponder] == self) {
			[[NSColor alternateSelectedControlColor] set];
		}
		else {
			[[NSColor selectedControlColor] set];
		}
		NSRectFill(frame);
	}
}

- (void)drawBackgroundInClipRect:(NSRect)rect
{
	[bgColor set];
	NSRectFill(rect);
}

- (int)draggedRow:(id <NSDraggingInfo>)sender
{
	NSPoint p = [self convertPoint:[sender draggingLocation] fromView:nil];
	return [self rowAtPoint:p];
}

- (void)drawDraggingPoisition:(id <NSDraggingInfo>)sender on:(BOOL)on
{
	if (on) {
		int row = [self draggedRow:sender];
		if (row < 0) {
			[self deselectAll:nil];
		}
		else {
			[self select:row];
		}
	}
	else {
		[self deselectAll:nil];
	}
}

- (NSArray*)draggedFiles:(id <NSDraggingInfo>)sender
{
	return [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSArray* files = [self draggedFiles:sender];
	if ([files count] > 0 && [self draggedRow:sender] >= 0) {
		[self drawDraggingPoisition:sender on:YES];
		return NSDragOperationCopy;
	}
	else {
		[self drawDraggingPoisition:sender on:NO];
		return NSDragOperationNone;
	}
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	[self drawDraggingPoisition:sender on:NO];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[self drawDraggingPoisition:sender on:NO];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSArray* files = [self draggedFiles:sender];
	return [files count] > 0 && [self draggedRow:sender] >= 0;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSArray* files = [self draggedFiles:sender];
	if ([files count] > 0) {
		int row = [self draggedRow:sender];
		if (row >= 0) {
			if ([dropDelegate respondsToSelector:@selector(memberListViewDropFiles:row:)]) {
				[dropDelegate memberListViewDropFiles:files row:[NSNumber numberWithInt:row]];
			}
			return YES;
		}
		else {
			return NO;
		}
	}
	else {
		return NO;
	}
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
}

@end
