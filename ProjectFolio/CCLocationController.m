//
//  CCLocationController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/22/12.
//
//

#import "CCLocationController.h"

@interface CCLocationController()

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation CCLocationController

-(double)degreeToRadian:(double)degree{
    return degree * M_PI / 180;
}

-(double)radianToDegree:(double)radian{
    return radian * 180 / M_PI;
}

- (double)bearingFromCordinate:(CLLocationCoordinate2D)fromCoord to:(CLLocationCoordinate2D)toCoord{
	double fromLatitude, toLatitude;
    
	double deltaLongitude;
    
	double x, y;
    
	double bearing;
    
	fromLatitude = [self degreeToRadian:fromCoord.latitude];
	toLatitude = [self degreeToRadian:toCoord.latitude];
    
	deltaLongitude = [self degreeToRadian:(toCoord.longitude - fromCoord.longitude)];
    
	y = sin(deltaLongitude) * cos(toLatitude);
	x = (cos(fromLatitude) * sin(toLatitude)) - (sin(fromLatitude) * cos(toLatitude) * cos(deltaLongitude));
	bearing = atan2(y,x);
	return fmod(([self radianToDegree:bearing] + 360.0), 360.0) ;
}

-(CLLocationDistance)getApproximateMilesFrom:(CLLocation *)fromLocation To:(CLLocation *)toLocation{
    CLLocationDistance distance = [self getBirdFlyMilesFrom:fromLocation To:toLocation];
    
    // If distance is > 100 then do great arc only
    if ( distance > 100.0f ) {
        double bearing = [self bearingFromCordinate:fromLocation.coordinate to:toLocation.coordinate];
        double x = fabs(sin(bearing) * distance);
        double y = fabs(cos(bearing) * distance);
        distance = ( x + y ) * 1.07;
    } else {
        // If distance <= 100 then use modified distance
        distance = distance * 1.15;
    }
    
    return distance;
}

-(CLLocationDistance)getBirdFlyMilesFrom:(CLLocation *)fromLocation To:(CLLocation *)toLocation{
    CLLocationDistance distance = [toLocation distanceFromLocation:fromLocation];
    // distance is in meters along an arc between the two points. Need to do better for milage.
    distance = distance * 3.28084;
    distance = distance / 5280;
    return distance;
}

- (void)whineAboutLocationWithExplanation:(NSString *)reason{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't tell where you are because..." message:reason delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

-(void)getLocation{
//    self.locationManager = [[CLLocationManager alloc] init];
//    self.locationManager.delegate = self;
//    self.locationManager.distanceFilter = 500;
//   self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([CLLocationManager locationServicesEnabled]) {
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusAuthorized:
                [self.locationManager startUpdatingLocation];
                break;
                
            case kCLAuthorizationStatusDenied:
                [self whineAboutLocationWithExplanation:@"Access to location services has been denied."];
                break;
                
            case kCLAuthorizationStatusRestricted:
                [self whineAboutLocationWithExplanation:@"Parental controls to restrict access are in place."];
                break;
                
            default:
                //[self whineAboutLocationWithExplanation:@"Can't determine access to location services, it may be unavailable."];
                [self.locationManager startUpdatingLocation];
                break;
        }
    } else {
        [self whineAboutLocationWithExplanation:@"Location services are not enabled"];
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    if ([CLLocationManager locationServicesEnabled]) {
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusAuthorized:
                [self.locationDelegate locationUpdate:newLocation];
                [manager stopUpdatingLocation];
                break;
                
            case kCLAuthorizationStatusDenied:
                [self whineAboutLocationWithExplanation:@"Access to location services has been denied."];
                break;
                
            case kCLAuthorizationStatusRestricted:
                [self whineAboutLocationWithExplanation:@"Parental controls to restrict access are in place."];
                break;
                
            default:
                [self whineAboutLocationWithExplanation:@"Can't determine access to location services, it may be unavailable."];
                break;
        }
    } else {
        [self whineAboutLocationWithExplanation:@"Location services are not enabled"];
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    if ([CLLocationManager locationServicesEnabled]) {
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusAuthorized:
                [self.locationDelegate locationError:error];
                [self.locationManager stopUpdatingLocation];
                break;
                
            case kCLAuthorizationStatusDenied:
                [self whineAboutLocationWithExplanation:@"Access to location services has been denied."];
                break;
                
            case kCLAuthorizationStatusRestricted:
                [self whineAboutLocationWithExplanation:@"Parental controls to restrict access are in place."];
                break;
                
            default:
                [self whineAboutLocationWithExplanation:@"Can't determine access to location services, it may be unavailable."];
                break;
        }
    } else {
        [self whineAboutLocationWithExplanation:@"Location services are not enabled"];
    }

}

-(void)forceShutdownOfLocator{
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - Accessors
- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = 500;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    return _locationManager;
}

@end
