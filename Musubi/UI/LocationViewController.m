
//
//  LocationViewController.m
//  musubi
//
//  Created by Ian Vo on 7/9/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "LocationViewController.h"
#import "LocationObjItemCell.h"

@interface LocationViewController ()

@end

@implementation LocationViewController
@synthesize mapView = _mapView;
@synthesize managedObjFeedItem = _managedObjFeedItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    coord.latitude = [[LocationObjItemCell latForItem:_managedObjFeedItem] floatValue];
    coord.longitude = [[LocationObjItemCell lonForItem:_managedObjFeedItem] floatValue];
    text = [LocationObjItemCell textForItem:_managedObjFeedItem];
    
    self.title = [NSString stringWithFormat: @"Where's %@?", _managedObjFeedItem.sender];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance (coord, 50, 50);
    [_mapView setRegion:region animated:NO];
    
    [_mapView setScrollEnabled:YES];
    [_mapView setZoomEnabled:YES];
    
    MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
    [annotationPoint setCoordinate:coord];
    [annotationPoint setTitle:[_managedObjFeedItem sender]];
    //[annotationPoint setSubtitle:text];
    [_mapView addAnnotation:annotationPoint];
    [_mapView selectAnnotation:annotationPoint animated:NO];
    

    
    //_mapView.delegate = self; 
    /*UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapViewTapped:)];
     tapGestureRecognizer.delegate = self;
     [_mapView addGestureRecognizer:tapGestureRecognizer];*/
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
