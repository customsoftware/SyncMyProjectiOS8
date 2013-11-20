//
//  CCLocationController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 9/22/12.
//
//

#import <CoreLocation/CoreLocation.h>

@protocol CCLocationDelegate <NSObject>

@required
- (void)locationUpdate:(CLLocation *)location;
- (void)locationError:(NSError *)error;
@end

@interface CCLocationController : NSObject<CLLocationManagerDelegate>

@property (strong, nonatomic) id<CCLocationDelegate>locationDelegate;

-(CLLocationDistance)getApproximateMilesFrom:(CLLocation *)fromLocation To:(CLLocation *)toLocation;
-(CLLocationDistance)getBirdFlyMilesFrom:(CLLocation *)fromLocation To:(CLLocation *)toLocation;
-(void)getLocation;
-(void)forceShutdownOfLocator;


@end
