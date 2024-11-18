//
//  ImageViewController.h
//  WallX
//
//  Created by Celestial on 05/11/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *favImg;
- (IBAction)downloadFav:(id)sender;

@property (strong,nonatomic) NSString *favUrl;

@end

NS_ASSUME_NONNULL_END
