//
//  QREncoderViewController.m
//  musubi
//
//  Created by Steve on 12-06-18.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QREncoderViewController.h"
#import "IdentityManager.h"
#import "Musubi.h"
#import "MIdentity.h"

@interface QREncoderViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation QREncoderViewController

@synthesize imageView;
@synthesize dataToEncode;

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
	
    //the qrcode is square. now we make it 250 pixels wide
    int qrcodeImageDimension = self.imageView.frame.size.width;
        
    //first encode the string into a matrix of bools, TRUE for black dot and FALSE for white. Let the encoder decide the error correction level and version
    DataMatrix* qrMatrix = [QREncoder encodeWithECLevel:QR_ECLEVEL_H version:QR_VERSION_AUTO string:dataToEncode];
    
    //then render the matrix
    UIImage* qrcodeImage = [QREncoder renderDataMatrix:qrMatrix imageDimension:qrcodeImageDimension];
    
    [[self imageView] setImage:qrcodeImage];
    
    IdentityManager* idMgr = [[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MIdentity *identity = [idMgr defaultIdentity];
    UIImage *thumbnail = [[UIImage alloc] initWithData:identity.musubiThumbnail == nil ? 
                          identity.thumbnail : identity.musubiThumbnail];

    
//    //put the image into the view
//    UIImageView* qrcodeImageView = [[UIImageView alloc] initWithImage:qrcodeImage];
//    CGRect parentFrame = self.view.frame;
//    CGRect tabBarFrame = self.tabBarController.tabBar.frame;
//    
//    //center the image
//    CGFloat x = (parentFrame.size.width - qrcodeImageDimension) / 2.0;
//    CGFloat y = (parentFrame.size.height - qrcodeImageDimension - tabBarFrame.size.height) / 2.0;
//    CGRect qrcodeImageViewFrame = CGRectMake(x, y, qrcodeImageDimension, qrcodeImageDimension);
//    [qrcodeImageView setFrame:qrcodeImageViewFrame];
//    
//    //and that's it!
//    [self.view addSubview:qrcodeImageView];
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
