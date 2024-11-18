//
//  CollectionViewController.h
//  WallX
//
//  Created by Celestial on 05/11/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CollectionViewController : UIViewController<UICollectionViewDelegate,UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong,nonatomic) NSMutableArray *collections;
@end

NS_ASSUME_NONNULL_END
