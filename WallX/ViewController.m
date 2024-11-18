#import "ViewController.h"
#import "DownloadViewController.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching, UISearchBarDelegate>
@property (nonatomic, strong) NSMutableArray *wallpapers; // Array to store wallpaper URLs
@property (nonatomic, strong) NSCache *imageCache; // Cache for images
@property (nonatomic, assign) NSInteger currentPage; // Track the current page
@property (nonatomic, assign) BOOL isLoading; // Track loading state
@property (nonatomic, strong) NSString *searchQuery; // Store the current search term
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar; // Reference to the UISearchBar
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize wallpapers array and image cache
    self.wallpapers = [NSMutableArray array];
    self.imageCache = [[NSCache alloc] init];
    self.currentPage = 1; // Start at the first page
    self.isLoading = NO; // Not loading initially
    self.searchQuery = @""; // Empty string for no search initially
    
    // Set collection view delegate, data source, and search bar delegate
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.prefetchingEnabled = YES; // Enable prefetching
    self.searchBar.delegate = self; // Set search bar delegate

    // Fetch initial wallpapers
    [self fetchWallpapers:self.currentPage];
}

- (void)fetchWallpapers:(NSInteger)page {
    if (self.isLoading) return; // Prevent multiple requests
    self.isLoading = YES; // Set loading state
    
    NSString *apiKey = @"Vx3ZDEsfuzniqsD3_oCbdxMf-poBoQb2vtNQwu4D254";
    NSString *urlString;
    
    // If there's a search query, use the Unsplash search endpoint
    if (self.searchQuery.length > 0) {
        urlString = [NSString stringWithFormat:@"https://api.unsplash.com/search/photos?client_id=%@&query=%@&per_page=30&page=%ld", apiKey, [self.searchQuery stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], (long)page];
    } else {
        // Default endpoint for general wallpaper fetching
        urlString = [NSString stringWithFormat:@"https://api.unsplash.com/photos?client_id=%@&per_page=30&page=%ld", apiKey, (long)page];
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error fetching wallpapers: %@", error.localizedDescription);
            self.isLoading = NO; // Reset loading state
            return;
        }
        
        NSError *jsonError;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSArray *jsonArray = self.searchQuery.length > 0 ? jsonDict[@"results"] : (NSArray *)jsonDict;

        if (jsonError || !jsonArray) {
            NSLog(@"Error parsing JSON: %@", jsonError.localizedDescription);
            self.isLoading = NO; // Reset loading state
            return;
        }
        
        if (page == 1) { // If it's a new search, reset the wallpapers array
            [self.wallpapers removeAllObjects];
        }
        
        for (NSDictionary *photoDict in jsonArray) {
            NSDictionary *urlsDict = photoDict[@"urls"];
            NSString *imageUrl = urlsDict[@"small"];
            NSString *photoID = photoDict[@"id"];
            
            if (imageUrl && photoID) {
                [self.wallpapers addObject:@{@"url": imageUrl, @"id": photoID}];
            }
        }
        
        self.currentPage++; // Increment page number for next fetch
        self.isLoading = NO; // Reset loading state
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    }];
    
    [dataTask resume];
}

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.wallpapers.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    // Reset the image view
    cell.imageView.image = [UIImage imageNamed:@"placeholder"];
    
    NSDictionary *wallpaperDict = self.wallpapers[indexPath.row];
    NSString *imageUrlString = wallpaperDict[@"url"];
    NSURL *imageURL = [NSURL URLWithString:imageUrlString];
    
    UIImage *cachedImage = [self.imageCache objectForKey:imageUrlString];
    if (cachedImage) {
        cell.imageView.image = cachedImage;
    } else {
        NSURLSessionDataTask *imageDataTask = [[NSURLSession sharedSession] dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Error downloading image: %@", error.localizedDescription);
                return;
            }
            
            if (data) {
                UIImage *image = [UIImage imageWithData:data];
                [self.imageCache setObject:image forKey:imageUrlString];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    CollectionViewCell *updateCell = (CollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
                    if (updateCell) {
                        updateCell.imageView.image = image;
                    }
                });
            }
        }];
        
        [imageDataTask resume];
    }
    
    return cell;
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.searchQuery = searchBar.text;
    self.currentPage = 1;
    [self fetchWallpapers:self.currentPage];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchQuery = @"";
    self.currentPage = 1;
    [self fetchWallpapers:self.currentPage];
    [searchBar resignFirstResponder];
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    
    if (offsetY + scrollView.frame.size.height >= contentHeight - 100) {
        [self fetchWallpapers:self.currentPage];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDown"]) {
        DownloadViewController *view = [segue destinationViewController];
        
        NSIndexPath *selectedIndexPath = [self.collectionView indexPathsForSelectedItems].firstObject;
        if (selectedIndexPath) {
            NSDictionary *selectedWallpaper = self.wallpapers[selectedIndexPath.row];
            view.id = selectedWallpaper[@"id"];
        }
    }
}

#pragma mark - UICollectionViewDataSourcePrefetching

- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    for (NSIndexPath *indexPath in indexPaths) {
        // Prefetch images for the next cells
        NSString *imageUrlString = self.wallpapers[indexPath.row];
        NSURL *imageURL = [NSURL URLWithString:imageUrlString];
        
        // Preload the images
        NSURLSessionDataTask *prefetchTask = [[NSURLSession sharedSession] dataTaskWithURL:imageURL];
        [prefetchTask resume];
    }
}

@end
