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
    self = [super init];
    if( self )
    {
        start = begin;
        range = end - begin;
    }
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
- (void)drawCenteredImage:(NSImage*)image inFrame:(NSRect)frame imageFraction:(float)imageFraction;
- (void)setDefaultDurations;
@end

@implementation ANSegmentedControl
@synthesize fastAnimationDuration=_fastAnimationDuration;
@synthesize slowAnimationDuration=_slowAnimationDuration;


+ (Class)cellClass
{
	return [ANSegmentedCell class];
}
- (id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if( self )
    {
        [self setDefaultDurations];
    }
    return self;
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
    
    [self setDefaultDurations]; 
	
	return self;
}

- (void)awakeFromNib
{
    [self setBoundsSize:NSMakeSize([self bounds].size.width, 25)];
    [self setFrameSize:NSMakeSize([self frame].size.width, 25)];
    location.x = [self frame].size.width / [self segmentCount] * [self selectedSegment];
    [[self cell] setTrackingMode:NSSegmentSwitchTrackingSelectOne];
}

-(void)drawCenteredImage:(NSImage*)image inFrame:(NSRect)frame imageFraction:(float)imageFraction
{
    CGSize imageSize = [image size];
    CGRect rect= NSMakeRect(frame.origin.x + (frame.size.width-imageSize.width)/2.0, 
               frame.origin.y + (frame.size.height-imageSize.height)/2.0,
               imageSize.width, 
               imageSize.height ); 
    [image drawInRect:rect
                                      fromRect:NSZeroRect
                                     operation:NSCompositeSourceOver
                                      fraction:imageFraction
                                respectFlipped:YES
                                         hints:nil];
}
- (void)drawRect:(NSRect)dirtyRect
{    
	NSRect rect = [self bounds];
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
    
    NSImage *image = [self imageForSegment:segment];
    [[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
    [self drawCenteredImage:image inFrame:frame imageFraction:imageFraction];
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
        
        frameColor = [NSColor colorWithCalibratedWhite:.37 alpha:1.0] ;
    } else {
        gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:.8 alpha:1.0]
                                                 endingColor:[NSColor colorWithCalibratedWhite:.77 alpha:1.0]];
        frameColor = [NSColor colorWithCalibratedWhite:.68 alpha:1.0] ;
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
#if ! __has_feature(objc_arc)
    [gradient release];
    [dropShadow release];
#endif
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
        frameColor = [NSColor colorWithCalibratedWhite:.37 alpha:1.0] ;
    } else {
        gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:.76 alpha:1.0]
                                                 endingColor:[NSColor colorWithCalibratedWhite:.90 alpha:1.0]];   
        imageFraction = .25; 
        frameColor = [NSColor colorWithCalibratedWhite:.68 alpha:1.0] ;
    }
    
    CGFloat width = rect.size.width / [self segmentCount];
    CGFloat height = rect.size.height;
    NSRect knobRect=NSMakeRect(location.x, rect.origin.y, width, height);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:  knobRect
                                                         xRadius:radius 
                                                         yRadius:radius];
    // 塗り
	[gradient drawInBezierPath:path angle:-90];
    // 枠線
    [frameColor setStroke];
	[path strokeInside];
    
    int newSegment = (int)round(location.x / width);
    NSImage *image = [self imageForSegment:newSegment];
    [self drawCenteredImage:image inFrame:knobRect imageFraction:imageFraction];

#if ! __has_feature(objc_arc)
    [gradient release];
#endif
}

- (void)animateTo:(int)x
{
    float maxX = [self frame].size.width - ([self frame].size.width / [self segmentCount]);
    
    ANKnobAnimation *a = [[ANKnobAnimation alloc] initWithStart:location.x end:x];
    [a setDelegate:self];
    if (location.x == 0 || location.x == maxX){
        [a setDuration:_fastAnimationDuration];
        [a setAnimationCurve:NSAnimationEaseInOut];
    } else {
        [a setDuration:_slowAnimationDuration * ((fabs(location.x - x)) / maxX)];
        [a setAnimationCurve:NSAnimationLinear];
    }
    
    [a setAnimationBlockingMode:NSAnimationBlocking];
    [a startAnimation];
#if ! __has_feature(objc_arc)
    [a release];
#endif
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

- (void)setDefaultDurations
{
    _fastAnimationDuration = 0.20;
    _slowAnimationDuration = 0.35;
}

@end
