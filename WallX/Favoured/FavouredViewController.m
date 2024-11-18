#import "FavouredViewController.h"
#import "FavouredCollectionViewCell.h"
#import "ImageViewController.h"

@interface FavouredViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSCache *imageCache;
@end

@implementation FavouredViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *savedFavorites = [[NSUserDefaults standardUserDefaults] objectForKey:@"favorites"];
    self.favorites = [savedFavorites mutableCopy] ?: [NSMutableArray array];
    
    self.imageCache = [[NSCache alloc] init];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadFavorites)
                                                 name:@"FavoriteAdded"
                                               object:nil];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.collectionView addGestureRecognizer:longPress];
    
    [self.collectionView reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FavoriteAdded" object:nil];
}

#pragma mark - Notification Handling

- (void)reloadFavorites {
    NSArray *savedFavorites = [[NSUserDefaults standardUserDefaults] objectForKey:@"favorites"];
    self.favorites = [savedFavorites mutableCopy] ?: [NSMutableArray array];
    [self.collectionView reloadData];
}

#pragma mark - Long Press Handling

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [gestureRecognizer locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
        
        if (indexPath) {
            // Show confirmation alert
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Remove Favorite"
                                                                           message:@"Do you want to remove this image from favorites?"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                // Remove the favorite image
                [self.favorites removeObjectAtIndex:indexPath.row];
                
                // Update UserDefaults
                [[NSUserDefaults standardUserDefaults] setObject:self.favorites forKey:@"favorites"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                // Reload collection view
                [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
            }];
            
            UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
            
            [alert addAction:yesAction];
            [alert addAction:noAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.favorites.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FavouredCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
 
    NSDictionary *favorite = self.favorites[indexPath.row];
    NSString *imageUrlString = favorite[@"url"];
    NSURL *imageURL = [NSURL URLWithString:imageUrlString];
    
    cell.favImage.image = [UIImage imageNamed:@"placeholder"];
    
    UIImage *cachedImage = [self.imageCache objectForKey:imageUrlString];
    if (cachedImage) {
        cell.favImage.image = cachedImage;
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            UIImage *image = [UIImage imageWithData:imageData];
            
            if (image) {
                [self.imageCache setObject:image forKey:imageUrlString];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    FavouredCollectionViewCell *updateCell = (FavouredCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
                    if (updateCell) {
                        updateCell.favImage.image = image;
                    }
                });
            }
        });
    }
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showFav"]) {
        ImageViewController *view = [segue destinationViewController];
        NSIndexPath *indexPath = [self.collectionView indexPathsForSelectedItems].firstObject;
        if (indexPath) {
            NSDictionary *url = self.favorites[indexPath.row];
            view.favUrl = url[@"url"];
            NSLog(@"%@", view.favUrl);
        }
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [self.navigationController.navigationBar.topItem setTitle:@"Favorites"];
}

@end
