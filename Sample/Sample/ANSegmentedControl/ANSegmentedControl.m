//
//  ANSegmentedControl.m
//  test01
//
//  Created by Decors on 11/04/22.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ANSegmentedControl.h"
#import "ANSegmentedCell.h"
#import "NSBezierPath+MCAdditions.h"
#import "NSShadow+MCAdditions.h"

@interface ANKnobAnimation : NSAnimation {
    int start, range;
    id delegate;
}

@end

@implementation ANKnobAnimation

- (id)initWithStart:(int)begin end:(int)end
{
    [super init];
    start = begin;
    range = end - begin;
    return self;
}

- (void)setCurrentProgress:(NSAnimationProgress)progress
{
    int x = start + progress * range;
    [super setCurrentProgress:progress];
    [delegate performSelector:@selector(setPosition:) 
                   withObject:[NSNumber numberWithInteger:x]];
}

- (void)setDelegate:(id)d
{
    delegate = d;
}

@end

@interface ANSegmentedControl (Private)
- (void)drawBackgroud:(NSRect)rect;
- (void)drawKnob:(NSRect)rect;
- (void)animateTo:(int)x;
- (void)setPosition:(NSNumber *)x;
- (void)offsetLocationByX:(float)x;
@end

@implementation ANSegmentedControl

+ (Class)cellClass
{
	return [ANSegmentedCell class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (![aDecoder isKindOfClass:[NSKeyedUnarchiver class]])
		return [super initWithCoder:aDecoder];
        
	NSKeyedUnarchiver *unarchiver = (NSKeyedUnarchiver *)aDecoder;
	Class oldClass = [[self superclass] cellClass];
	Class newClass = [[self class] cellClass];
	
	[unarchiver setClass:newClass forClassName:NSStringFromClass(oldClass)];
	self = [super initWithCoder:aDecoder];
	[unarchiver setClass:oldClass forClassName:NSStringFromClass(oldClass)];
	
	return self;
}

- (void)awakeFromNib
{
    location.x = [self frame].size.width / [self segmentCount] * [self selectedSegment];
    [[self cell] setTrackingMode:NSSegmentSwitchTrackingSelectOne];
}

- (void)drawRect:(NSRect)dirtyRect
{    
	NSRect rect = dirtyRect;
	rect.size.height -= 1;
    
    [self drawBackgroud:rect];
    [self drawKnob:rect];
}

- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView
{
    float imageFraction;
    
    if ([[self window] isKeyWindow]) {
        imageFraction = .5;
    } else {
        imageFraction = .2;
    }
    
    [[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
    NSRect rect = NSMakeRect(frame.origin.x, 
                             frame.origin.y + 1,
                             [[self imageForSegment:segment] size].width, 
                             [[self imageForSegment:segment] size].height);
    [[self imageForSegment:segment] drawInRect:rect
                                      fromRect:NSZeroRect
                                     operation:NSCompositeSourceOver
                                      fraction:imageFraction
                                respectFlipped:YES
                                         hints:nil];
}

- (void)drawBackgroud:(NSRect)rect
{
	CGFloat radius = 3.5;
    NSGradient *gradient;
    NSColor *frameColor;

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect
                                                         xRadius:radius 
                                                         yRadius:radius];
    
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];   
    
    if ([[self window] isKeyWindow]) {
        gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:.75 alpha:1.0]
                                                 endingColor:[NSColor colorWithCalibratedWhite:.6 alpha:1.0]];
        frameColor = [[NSColor colorWithCalibratedWhite:.52 alpha:1.0] retain];
    } else {
        gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:.8 alpha:1.0]
                                                 endingColor:[NSColor colorWithCalibratedWhite:.77 alpha:1.0]];
        frameColor = [[NSColor colorWithCalibratedWhite:.68 alpha:1.0] retain];
    }
    
    // シャドウ
    [ctx saveGraphicsState];
    NSShadow *dropShadow = [[NSShadow alloc] init];
    [dropShadow setShadowOffset:NSMakeSize(0, -1.0)];
    [dropShadow setShadowBlurRadius:1.0];
    [dropShadow setShadowColor:[NSColor colorWithCalibratedWhite:.863 alpha:.75]];
	[dropShadow set];
	[path fill];
    [ctx restoreGraphicsState];
    
    // 塗り
	[gradient drawInBezierPath:path angle:-90];
    
    // 枠線
    [frameColor setStroke];
	[path strokeInside];
    
    float segmentWidth = rect.size.width / [self segmentCount];
    float segmentHeight = rect.size.height;
    NSRect segmentRect = NSMakeRect(0, 0, segmentWidth, segmentHeight);
    
    for(int s = 0; s < [self segmentCount]; s ++) {
        [self drawSegment:s
                  inFrame:segmentRect 
                 withView:self];
        segmentRect.origin.x += segmentWidth;
    }
}

- (void)drawKnob:(NSRect)rect
{
	CGFloat radius = 3;
    NSGradient *gradient;
    float imageFraction;
    NSColor *frameColor;
    
    if ([[self window] isKeyWindow]) {
        gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:.68 alpha:1.0]
                                                 endingColor:[NSColor colorWithCalibratedWhite:.91 alpha:1.0]];   
        imageFraction = 1.0;
        frameColor = [[NSColor colorWithCalibratedWhite:.52 alpha:1.0] retain];
    } else {
        gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:.76 alpha:1.0]
                                                 endingColor:[NSColor colorWithCalibratedWhite:.90 alpha:1.0]];   
        imageFraction = .25; 
        frameColor = [[NSColor colorWithCalibratedWhite:.68 alpha:1.0] retain];
    }
    
    CGFloat width = rect.size.width / [self segmentCount];
    CGFloat height = rect.size.height;
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(location.x, rect.origin.y, width, height)
                                                         xRadius:radius 
                                                         yRadius:radius];
    // 塗り
	[gradient drawInBezierPath:path angle:-90];
    // 枠線
    [frameColor setStroke];
	[path strokeInside];
    
    int newSegment = (int)round(location.x / width);
    NSPoint pt = location;
    pt.y += 1;
    NSRect knobRect = NSMakeRect(pt.x, 
                                 pt.y,
                                 [[self imageForSegment:newSegment] size].width, 
                                 [[self imageForSegment:newSegment] size].height);
    [[self imageForSegment:newSegment] drawInRect:knobRect
                                         fromRect:NSZeroRect
                                        operation:NSCompositeSourceOver
                                         fraction:imageFraction
                                   respectFlipped:YES
                                            hints:nil];
}

- (void)animateTo:(int)x
{
    float maxX = [self frame].size.width - ([self frame].size.width / [self segmentCount]);
    
    ANKnobAnimation *a = [[ANKnobAnimation alloc] initWithStart:location.x end:x];
    [a setDelegate:self];
    if (location.x == 0 || location.x == maxX){
        [a setDuration:0.20];
        [a setAnimationCurve:NSAnimationEaseInOut];
    } else {
        [a setDuration:0.35 * ((fabs(location.x - x)) / maxX)];
        [a setAnimationCurve:NSAnimationLinear];
    }
    
    [a setAnimationBlockingMode:NSAnimationBlocking];
    [a startAnimation];
    [a release];
}


- (void)setPosition:(NSNumber *)x
{
    location.x = [x intValue];
    [self display];
}

- (void)setSelectedSegment:(NSInteger)newSegment
{
    [self setSelectedSegment:newSegment animate:true];
}

- (void)setSelectedSegment:(NSInteger)newSegment animate:(bool)animate
{
    if(newSegment == [self selectedSegment])
        return;
    
    float maxX = [self frame].size.width - ([self frame].size.width / [self segmentCount]);
    
    int x = newSegment > [self segmentCount] ? maxX : newSegment * ([self frame].size.width / [self segmentCount]);
    
    if(animate)
        [self animateTo:x];
    else {
        [self setNeedsDisplay:YES];
    }
    
    [super setSelectedSegment:newSegment];
}


- (void)offsetLocationByX:(float)x
{
    location.x = location.x + x;
    float maxX = [self frame].size.width - ([self frame].size.width / [self segmentCount]);
    
    if (location.x < 0) location.x = 0;
    if (location.x > maxX) location.x = maxX;
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event
{
    BOOL loop = YES;
    
    NSPoint clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    float knobWidth = [self frame].size.width / [self segmentCount];
    NSRect knobRect = NSMakeRect(location.x, 0, knobWidth, [self frame].size.height);
    
    if (NSPointInRect(clickLocation, [self bounds])) {
        NSPoint newDragLocation;
        NSPoint localLastDragLocation;
        localLastDragLocation = clickLocation;
        
        while (loop) {
            NSEvent *localEvent;
            localEvent = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
            
            switch ([localEvent type]) {
                case NSLeftMouseDragged:
                    if (NSPointInRect(clickLocation, knobRect)) {
                        newDragLocation = [self convertPoint:[localEvent locationInWindow]
                                                                  fromView:nil];
                        
                        [self offsetLocationByX:(newDragLocation.x - localLastDragLocation.x)];
                        
                        localLastDragLocation = newDragLocation;
                        [self autoscroll:localEvent];
                    }             
                    break;
                case NSLeftMouseUp:
                    loop = NO;
                    
                    int newSegment;
                    
                    if (memcmp(&clickLocation, &localLastDragLocation, sizeof(NSPoint)) == 0) {
                        newSegment = floor(clickLocation.x / knobWidth);
                        //if (newSegment != [self selectedSegment]) {
                        [self animateTo:newSegment * knobWidth];
                        //}
                    } else {
                        newSegment = (int)round(location.x / knobWidth);
                        [self animateTo:newSegment * knobWidth];
                    }
                    
                    [self setSelectedSegment:newSegment];
                    [[self window] invalidateCursorRectsForView:self];
                    
                    break;
                default:
                    break;
            }
        }
    };
    return;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}
    
@end
