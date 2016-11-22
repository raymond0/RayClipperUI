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
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (IBAction)goPressed:(NSButton *)sender
{
    if ( wrapper == nil )
    {
        wrapper = [[ClipperWrapper alloc] init];
    }
    
    [wrapper loadInput];
    NSArray *inputP = [wrapper getInputPolygons];
    [wrapper runClipper];
    NSArray *outputP = [wrapper getOutputPolygons];
    
    _inputView.polygons = inputP;
    _inputView.clipRect = wrapper.cliprect;
    _outputView.polygons = outputP;
    _outputView.clipRect = wrapper.cliprect;
    
    /*
    NSMutableArray *polygons = [NSMutableArray array];
    NSMutableArray *polygon = [NSMutableArray array];
    
    NSPoint p1 = NSMakePoint(50, 50);
    NSPoint p2 = NSMakePoint(-20, 50);
    NSPoint p3 = NSMakePoint(-20, 150);
    NSPoint p4 = NSMakePoint(50, 150);
    
    [polygon addObject:[NSValue valueWithPoint:p1]];
    [polygon addObject:[NSValue valueWithPoint:p2]];
    [polygon addObject:[NSValue valueWithPoint:p3]];
    [polygon addObject:[NSValue valueWithPoint:p4]];
    
    [polygons addObject:polygon];
    _inputView.polygons = polygons;*/
    
    
}

- (IBAction)sliderAction:(NSSlider *)sender
{
    _inputView.scale = sender.doubleValue;
    _outputView.scale = sender.doubleValue;
}

@end
