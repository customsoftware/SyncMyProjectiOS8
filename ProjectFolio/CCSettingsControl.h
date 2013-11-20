//
//  CCSettingsControl.h
//  SyncMyProject
//
//  Created by Ken Cluff on 11/30/12.
//
//

@interface CCSettingsControl : NSObject

-(BOOL)saveString:(NSString *)stringValue atKey:(NSString *)keyName;
-(NSString *)recallStringAtKey:(NSString *)keyName;
-(BOOL)saveNumber:(NSNumber *)numberValue atKey:(NSString *)keyName;
-(NSNumber *)recallNumberAtKey:(NSString *)keyName;
-(BOOL)isICloudAuthorized;
-(BOOL)isTimeAuthorized;
-(BOOL)isExpenseAuthorized;
// These support in-app purchases
-(void)authorizeTime;
-(void)authorizeExpenses;
-(void)deAuthorizeTime;
-(void)deAuthorizeExpenses;

@end
