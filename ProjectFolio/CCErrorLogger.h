//
//  CCErrorLogger.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/26/12.
//
//

@protocol CCLoggerDelegate <NSObject>

-(void)releaseLogger;

@end

@interface CCErrorLogger : NSObject

-(CCErrorLogger *)initWithDelegate:(id)delegate;
-(CCErrorLogger *)initWithError:(NSError *)error andDelegate:(id)delegate;
-(CCErrorLogger *)initWithErrorString:(NSString *)error andDelegate:(id)delegate;
-(NSString *)getErrorFile;
-(void)releaseLogger;
-(BOOL)removeErrorFile;

@end
