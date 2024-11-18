#import "CollectionViewController.h"
#import "CustomViewCell.h"
#import "../Favoured/ImageViewController.h"
#import "UserNotifications/UserNotifications.h"

@interface CollectionViewController ()
@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, strong) NSMutableArray *previousImageUrls;
@property (nonatomic, strong) NSTimer *pollingTimer;
@end

@implementation CollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.collections = [NSMutableArray array];
    self.imageCache = [[NSCache alloc] init];
    
    NSArray *savedImageUrls = [[NSUserDefaults standardUserDefaults] objectForKey:@"previousImageUrls"];
    self.previousImageUrls = savedImageUrls ? [savedImageUrls mutableCopy] : [NSMutableArray array];
    
    [self requestNotificationPermission];
    
    [self fetchDataFromAPI];
    self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                         target:self
                                                       selector:@selector(fetchDataFromAPI)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)requestNotificationPermission {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            NSLog(@"Notification permission granted.");
        } else {
            NSLog(@"Notification permission denied.");
        }
    }];
}

- (void)fetchDataFromAPI {
    NSURL *url = [NSURL URLWithString:@"https://672b0299976a834dd025356a.mockapi.io/image"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error fetching data: %@", error.localizedDescription);
            
          
            NSArray *savedImageUrls = [[NSUserDefaults standardUserDefaults] objectForKey:@"previousImageUrls"];
            if (savedImageUrls) {
                self.collections = [savedImageUrls mutableCopy];
                NSLog(@"Loaded saved image URLs from NSUserDefaults");
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
            return;
        }
        
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError) {
            NSLog(@"JSON parsing error: %@", jsonError.localizedDescription);
            return;
        }
        
        NSMutableArray *newImageUrls = [NSMutableArray array];
        [self.collections removeAllObjects];
        for (NSDictionary *imageData in jsonArray) {
            NSString *urlString = imageData[@"url"];
            if (urlString) {
                [self.collections addObject:urlString];
                [newImageUrls addObject:urlString];
            }
        }
        
        [self checkForNewWallpapers:newImageUrls];
        
        self.previousImageUrls = [newImageUrls mutableCopy];
        [[NSUserDefaults standardUserDefaults] setObject:self.previousImageUrls forKey:@"previousImageUrls"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    }];
    
    [dataTask resume];
}

- (void)checkForNewWallpapers:(NSArray *)newImageUrls {
    NSMutableSet *newSet = [NSMutableSet setWithArray:newImageUrls];
    NSSet *previousSet = [NSSet setWithArray:self.previousImageUrls];
    [newSet minusSet:previousSet];
    
    if (newSet.count > 0) {
        [self sendNewWallpaperNotificationWithCount:newSet.count];
    }
}

- (void)sendNewWallpaperNotificationWithCount:(NSUInteger)count {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"New Wallpapers Available!";
    content.body = [NSString stringWithFormat:@"There are %lu new wallpapers added.", (unsigned long)count];
    content.sound = [UNNotificationSound defaultSound];
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"NewWallpaperNotification" content:content trigger:trigger];
    
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error scheduling notification: %@", error.localizedDescription);
        } else {
            NSLog(@"Notification scheduled.");
        }
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.collections.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CustomViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    NSString *imageUrlString = self.collections[indexPath.row];
    
    UIImage *cachedImage = [self.imageCache objectForKey:imageUrlString];
    if (cachedImage) {
        cell.animeImage.image = cachedImage;
    } else {
        cell.animeImage.image = nil;
        
        NSURL *imageURL = [NSURL URLWithString:imageUrlString];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            UIImage *image = [UIImage imageWithData:imageData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                CustomViewCell *updateCell = [collectionView cellForItemAtIndexPath:indexPath];
                if (updateCell) {
                    if (image) {
                        [self.imageCache setObject:image forKey:imageUrlString];
                        updateCell.animeImage.image = image;
                    } else {
                        updateCell.animeImage.image = [UIImage imageNamed:@"placeholder"];
                    }
                }
            });
        });
    }
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showCustom"]) {
        ImageViewController *view = [segue destinationViewController];
        NSIndexPath *indexPath = [self.collectionView indexPathsForSelectedItems].firstObject;
        if (indexPath) {
            NSString *url = self.collections[indexPath.row];
            view.favUrl = url;
            NSLog(@"Selected image URL: %@", view.favUrl);
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController.navigationBar.topItem setTitle:@"My Anime Collection"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}

@end
