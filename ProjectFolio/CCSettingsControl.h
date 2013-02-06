//
//  CCSettingsControl.h
//  ProjectFolio
//
//  Created by Ken Cluff on 11/30/12.
//
//

#import <Foundation/Foundation.h>

@interface CCSettingsControl : NSObject

-(BOOL)saveString:(NSString *)stringValue atKey:(NSString *)keyName;
-(NSString *)recallStringAtKey:(NSString *)keyName;
-(BOOL)saveNumber:(NSNumber *)numberValue atKey:(NSString *)keyName;
-(NSNumber *)recallNumberAtKey:(NSString *)keyName;
-(BOOL)isICloudAuthorized;

@end
