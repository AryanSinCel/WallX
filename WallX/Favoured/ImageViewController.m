#import "ImageViewController.h"
#import <Photos/Photos.h>

@interface ImageViewController ()
@end

@implementation ImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar.topItem setTitle:@""];
    
    if (self.favUrl) {
        NSURL *imageURL = [NSURL URLWithString:self.favUrl];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            UIImage *image = [UIImage imageWithData:imageData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image) {
                    self.favImg.image = image;
                } else {
                    self.favImg.image = [UIImage imageNamed:@"placeholder"];
                }
            });
        });
    }
}

- (IBAction)downloadFav:(id)sender {
    if (self.favImg.image) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authorizationStatus) {
                if (authorizationStatus == PHAuthorizationStatusAuthorized) {
                    [self saveImageToPhotoLibrary];
                }
            }];
        } else if (status == PHAuthorizationStatusAuthorized) {
            [self saveImageToPhotoLibrary];
        } else {
            NSLog(@"Photo library access denied.");
        }
    }
}

- (void)saveImageToPhotoLibrary {
    UIImage *imageToSave = self.favImg.image;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:imageToSave];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSLog(@"Image successfully saved to Photos.");
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download Complete"
                                                                               message:@"Image has been saved to your Photos."
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:nil];
                [alert addAction:okAction];
                [self presentViewController:alert animated:YES completion:nil];
                
            } else {
                NSLog(@"Error saving image: %@", error.localizedDescription);
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download Failed"
                                                                               message:@"There was an error saving the image."
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:nil];
                [alert addAction:okAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.tabBarController.tabBar.hidden = NO;
}

@end
