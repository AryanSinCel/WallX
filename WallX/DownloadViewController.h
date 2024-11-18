//
//  DownloadViewController.h
//  WallX
//
//  Created by Celestial on 04/11/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadViewController : UIViewController

@property (nonatomic,strong) NSString *id;
@property (weak, nonatomic) IBOutlet UIImageView *wallImage;
- (IBAction)setWallpaper:(id)sender;
- (IBAction)addToFavorite:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *favoriteBtn;


@end

NS_ASSUME_NONNULL_END
