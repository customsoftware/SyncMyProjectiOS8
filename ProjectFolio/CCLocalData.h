//
//  CCLocalData.h
//  CDHarness
//
//  Created by Kenneth Cluff on 2/12/13.
//  Copyright (c) 2013 Kenneth Cluff. All rights reserved.
//


@interface CCLocalData : NSObject

@property (strong, nonatomic, readonly) NSDictionary *cloudDictionary;

+(NSArray *)entities;
+(NSString *)companyID;
+(NSString *)appID;
+(NSString *)dbFileName;
+(NSString *)ubiquityContainerID;
+(BOOL)isICloudAuthorized;

-(void)kvStoreDidChange:(NSNotification *)notification;
-(void)reloadFetchedResults:(NSNotification *)notification;

@end
