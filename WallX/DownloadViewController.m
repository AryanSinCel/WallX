#import "DownloadViewController.h"
#import "Photos/Photos.h"
#import "Favoured/FavouredViewController.h"

@interface DownloadViewController ()
@property (nonatomic,strong) NSString *imageURL;
@property (nonatomic,strong) NSString *imageId;
@end

@implementation DownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.id){
        [self fetchPhotoById:self.id];
        
        NSMutableArray *favorites = [[[NSUserDefaults standardUserDefaults] objectForKey:@"favorites"] mutableCopy];
        
        if(favorites){
            for(NSDictionary *dic in favorites){
                if([[dic valueForKey:@"id"]isEqualToString:self.id]){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.favoriteBtn setImage:[UIImage systemImageNamed:@"heart.fill"] forState:UIControlStateNormal];
                    });
                    break;
                }
            }
        }
    }
}

- (void)fetchPhotoById:(NSString *)photoID {
    NSString *apiKey = @"Vx3ZDEsfuzniqsD3_oCbdxMf-poBoQb2vtNQwu4D254";
    self.imageId = photoID;
    NSString *urlString = [NSString stringWithFormat:@"https://api.unsplash.com/photos/%@", photoID];
    NSURL *url = [NSURL URLWithString:urlString];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"Client-ID %@", apiKey] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            return;
        }

        if (data) {
            NSError *jsonError = nil;
            NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

            if (jsonError) {
                return;
            } else {
                NSString *fullImageURLString = photoInfo[@"urls"][@"full"];
                self.imageURL = fullImageURLString;
                if (fullImageURLString) {
                    NSURL *fullImageURL = [NSURL URLWithString:fullImageURLString];
                    
                    NSURLSessionDataTask *imageDownloadTask = [[NSURLSession sharedSession] dataTaskWithURL:fullImageURL completionHandler:^(NSData *imageData, NSURLResponse *response, NSError *error) {
                        if (error) {
                            return;
                        }
                        
                        if (imageData) {
                            UIImage *image = [UIImage imageWithData:imageData];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.wallImage.image = image;
                            });
                        }
                    }];
                    
                    [imageDownloadTask resume];
                }
            }
        }
    }];
    [task resume];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.tabBarController.tabBar.hidden = NO;
}

- (IBAction)addToFavorite:(id)sender {
    if (self.imageURL && self.imageId) {
        NSMutableArray *favorites = [[[NSUserDefaults standardUserDefaults] objectForKey:@"favorites"] mutableCopy];
        
        if (!favorites) {
            favorites = [NSMutableArray array];
        }
        
        BOOL alreadyFavorited = NO;
        for (NSDictionary *dic in favorites) {
            if ([dic[@"id"] isEqualToString:self.imageId]) {
                alreadyFavorited = YES;
                break;
            }
        }
        
        if (!alreadyFavorited) {
            NSDictionary *favorite = @{@"url": self.imageURL, @"id": self.imageId};
            [favorites addObject:favorite];
            
            [[NSUserDefaults standardUserDefaults] setObject:favorites forKey:@"favorites"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.favoriteBtn setImage:[UIImage systemImageNamed:@"heart.fill"] forState:UIControlStateNormal];
            });

            [[NSNotificationCenter defaultCenter] postNotificationName:@"FavoriteAdded" object:nil userInfo:@{@"id": self.imageId}];
        }
    }
}

- (IBAction)setWallpaper:(id)sender {
    if (self.wallImage.image) {
        [self setAsWallpaper:self.wallImage.image];
    }
}

- (void)setAsWallpaper:(UIImage *)image {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                [self saveImageToPhotoLibrary:image];
            }
        }];
    } else if (status == PHAuthorizationStatusAuthorized) {
        [self saveImageToPhotoLibrary:image];
    }
}

- (void)saveImageToPhotoLibrary:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (!error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Saved!"
                                                                       message:@"Image saved to your Photos. Please set it as wallpaper from your Photos app."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
