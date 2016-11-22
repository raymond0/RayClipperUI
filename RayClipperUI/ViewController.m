//
//  ViewController.m
//  RayClipperUI
//
//  Created by Ray Hunter on 20/11/2016.
//  Copyright © 2016 Atomic Rabbit Ltd. All rights reserved.
//

#import "ViewController.h"
#import "PolygonView.h"
#import "ClipperWrapper.h"

@implementation ViewController
{
    IBOutlet PolygonView *_inputView;
    IBOutlet PolygonView *_outputView;
    ClipperWrapper *wrapper;
    FILE *polydebug;
    IBOutlet NSTextField *mousePositionLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _inputView.delegate = self;
    _outputView.delegate = self;

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (IBAction)largePressed:(NSButton *)sender
{
    if ( wrapper == nil )
    {
        wrapper = [[ClipperWrapper alloc] initWithPath:@"/Users/ray/projects/atomicrabbit/maptools/maptool/workingdir_amsterdam/PolyDebug.bin"];
    }
    
    BOOL outputWasLarge = NO;
    do
    {
        if ( ! [wrapper loadInput] )
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"End of file"];
            [alert runModal];
            return;
        }
        
        [wrapper runClipper];
        outputWasLarge = [wrapper outputWasLarge];
        
    } while ( ! outputWasLarge );
    
    NSArray *inputP = [wrapper getInputPolygons];
    NSArray *outputP = [wrapper getOutputPolygons];

    _inputView.polygons = inputP;
    _inputView.clipRect = wrapper.cliprect;
    _outputView.polygons = outputP;
    _outputView.clipRect = wrapper.cliprect;
}


- (IBAction)goPressed:(NSButton *)sender
{
    if ( wrapper == nil )
    {
        //wrapper = [[ClipperWrapper alloc] initWithPath:@"/Users/ray/projects/atomicrabbit/maptools/maptool/workingdir_amsterdam/PolyDebug.bin"];
        //wrapper = [[ClipperWrapper alloc] initWithPath:@"/Users/ray/temp/FailedPolygons/PolyDebug.bin"];
        wrapper = [[ClipperWrapper alloc] initWithPath:@"/Users/ray/temp/FailedPolygons/PolyDebug3.bin"];
        //wrapper = [[ClipperWrapper alloc] init];
    }
    
    if ( ! [wrapper loadInput] )
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"End of file"];
        [alert runModal];
        return;
    }
    
    NSArray *inputP = [wrapper getInputPolygons];
    [wrapper runClipper];
    NSArray *outputP = [wrapper getOutputPolygons];
    
    _inputView.polygons = inputP;
    _inputView.clipRect = wrapper.cliprect;
    _outputView.polygons = outputP;
    _outputView.clipRect = wrapper.cliprect;
}


- (IBAction)failedPressed:(NSButton *)sender
{
    printf("Failed rectangle: (%d, %d) -> (%d, %d)\n", wrapper.cliprect.l.x, wrapper.cliprect.l.y,
           wrapper.cliprect.h.x, wrapper.cliprect.h.y);
    
    NSArray *inputAll = [wrapper getInputPolygons];
    NSAssert (inputAll.count == 1, @"1 at a time please");
    
    NSArray *inputOnly = inputAll[0];
    for ( NSValue *v in inputOnly )
    {
        NSPoint point = [v pointValue];
        printf("%d, %d\n", (int) point.x, (int) point.y);
    }
    
    if ( polydebug == NULL )
    {
        polydebug = fopen("PolyDebug.bin", "wb");
    }
    
    struct rect cr = wrapper.cliprect;
    fwrite(&cr, sizeof(struct rect), 1, polydebug);
    int nrCoords = (int) inputOnly.count;
    fwrite(&nrCoords, sizeof(int), 1, polydebug);
    struct coord *rawCoordPtr = [wrapper rawInputCoords];
    fwrite(rawCoordPtr, sizeof(struct coord), nrCoords, polydebug);
    fflush(polydebug);
}


- (IBAction)sliderAction:(NSSlider *)sender
{
    _inputView.scale = sender.doubleValue;
    _outputView.scale = sender.doubleValue;
}


-(void)mouseMovedTo:(NSPoint)position
{
    NSString *posStr = [NSString stringWithFormat:@"(%f, %f)", position.x, position.y];
    [mousePositionLabel setStringValue:posStr];
}


@end
