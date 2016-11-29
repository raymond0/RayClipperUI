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
#include <stdio.h>

@implementation ViewController
{
    IBOutlet PolygonView *_inputView;
    IBOutlet PolygonView *_outputView;
    FILE *polydebug;
    IBOutlet NSTextField *mousePositionLabel;
    IBOutlet NSTextField *inputSelfIntersectsLabel;
    IBOutlet NSTextField *outputSelfIntersectsLabel;
    ClipperWrapper *wrapper;
    BOOL _performingLarge;
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
    _performingLarge = ! _performingLarge;
    
    if ( _performingLarge )
    {
        [self performNextLarge];
    }
}


-(void)performNextLarge
{
    if ( wrapper == nil )
    {
        wrapper = [[ClipperWrapper alloc] initWithPath:@"/Users/ray/projects/atomicrabbit/maptools/maptool/workingdir_amsterdam/PolyDebug.bin"];
    }
    
    BOOL outputWasLarge = NO;
    //BOOL outputIntersects = NO;
    //BOOL inputSelfIntersects = NO;
    
    do
    {
        if ( ! [wrapper loadInput] )
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"End of file"];
            [alert runModal];
            return;
        }

       /* inputSelfIntersects = [wrapper inputSelfIntersects];
        if ( inputSelfIntersects )
        {
            continue;
        }*/
        
        [wrapper runClipper];
        //outputIntersects = [wrapper outputSelfIntersects];
        outputWasLarge = [wrapper outputWasLarge];
        
    } while ( ! outputWasLarge );

    //outputWasLarge = [wrapper outputWasLarge];
    inputSelfIntersectsLabel.hidden = ![wrapper inputSelfIntersects];
    outputSelfIntersectsLabel.hidden = ![wrapper outputSelfIntersects];

    NSArray *inputP = [wrapper getInputPolygons];
    NSArray *outputP = [wrapper getOutputPolygons];

    _inputView.polygons = inputP;
    _inputView.clipRect = wrapper.clipRectAsCGRect;
    _outputView.polygons = outputP;
    _outputView.clipRect = wrapper.clipRectAsCGRect;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        if ( self->_performingLarge )
        {
            [self performNextLarge];
        }
    });
    
    /*dispatch_async( dispatch_get_main_queue(), ^
    {
    });*/
}


- (IBAction)goPressed:(NSButton *)sender
{
    _performingLarge = ! _performingLarge;
    
    if ( _performingLarge )
    {
        [self performNext];
    }
}


-(void)performNext
{
    if ( wrapper == nil )
    {
        wrapper = [[ClipperWrapper alloc] initWithPath:@"/Users/ray/projects/atomicrabbit/maptools/maptool/workingdir_amsterdam/PolyDebug.bin"];
        //wrapper = [[ClipperWrapper alloc] initWithPath:@"/Users/ray/temp/FailedPolygons/PolyDebug.bin"];
        //wrapper = [[ClipperWrapper alloc] initWithPath:@"/Users/ray/temp/FailedPolygons/PolyDebug.bin"];
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
    //inputSelfIntersectsLabel.hidden = ![wrapper inputSelfIntersects];
    [wrapper runClipper];
    //outputSelfIntersectsLabel.hidden = ![wrapper outputSelfIntersects];
    NSArray *outputP = [wrapper getOutputPolygons];
    
    _inputView.polygons = inputP;
    _inputView.clipRect = wrapper.clipRectAsCGRect;
    _outputView.polygons = outputP;
    _outputView.clipRect = wrapper.clipRectAsCGRect;
    
    dispatch_async( dispatch_get_main_queue(), ^
    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        if ( self->_performingLarge )
        {
            [self performNext];
        }
    });
}


- (IBAction)repestPressed:(NSButton *)sender
{
    NSArray *inputP = [wrapper getInputPolygons];
    inputSelfIntersectsLabel.hidden = ![wrapper inputSelfIntersects];
    [wrapper runClipper];
    outputSelfIntersectsLabel.hidden = ![wrapper outputSelfIntersects];
    NSArray *outputP = [wrapper getOutputPolygons];
    
    _inputView.polygons = inputP;
    _inputView.clipRect = wrapper.clipRectAsCGRect;
    _outputView.polygons = outputP;
    _outputView.clipRect = wrapper.clipRectAsCGRect;
}


- (IBAction)failedPressed:(NSButton *)sender
{
    if ( polydebug == NULL )
    {
        polydebug = fopen("PolyDebug.bin", "wb");
    }
    
    NSData *data = [wrapper binaryData];
    if ( fwrite(data.bytes, 1, data.length, polydebug) != data.length )
    {
        printf( "binarydata write failed" );
    }
    
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
