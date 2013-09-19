//
//  CCExpenseReporterViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/26/12.
//
//

#import "CCExpenseReporterViewController.h"
#define CR_LF   [[NSString alloc] initWithFormat:@"<br>"]
#define SCORE   [[NSString alloc] initWithFormat:@"_________________________________________________<br>"]

@interface CCExpenseReporterViewController ()

@property (strong, nonatomic) NSNumberFormatter *milageFormatter;
@property (strong, nonatomic) NSNumberFormatter *currencyFormatter;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation CCExpenseReporterViewController

#pragma mark - API
-(NSString *)getExpenseReportForProject:(Project *)project{
    float totalExpensed = 0;
    float totalMilage = 0;
    float totalExpensedTime = 0;
    
    NSMutableArray *workingReceipts = [[NSMutableArray alloc] init];
    self.receiptList = nil;
    
    // Header for report
    NSMutableString *message = [[NSMutableString alloc] initWithFormat:@"Expense Report:<br>"];
    NSString *valueString = [self.currencyFormatter stringFromNumber:project.costBudget];
    // Starting amount for the budget
    NSString *startString = [NSString stringWithFormat:@"Starting Budget..:"];
    [message appendString:startString];
    [message appendString:valueString];
    [message appendString:CR_LF];
    float remainingBudget = [project.costBudget floatValue];
    
    // Current available balance
    NSSortDescriptor *expenseDate = [[NSSortDescriptor alloc]initWithKey:@"datePaid" ascending:YES];
    NSArray *sortList = [[NSArray alloc] initWithObjects:expenseDate, nil];
    NSArray *expenses = [project.projectExpense sortedArrayUsingDescriptors:sortList];
    for (Deliverables *expense in expenses) {
        if ([expense.expensed integerValue] == 1 && [expense.milage floatValue] == 0) {
            remainingBudget = remainingBudget - [expense.amount floatValue];
        }
    }
    valueString = [self.currencyFormatter stringFromNumber:[NSNumber numberWithFloat:remainingBudget]];
    startString = [NSString stringWithFormat:@"Available Budget.:"];
    [message appendString:startString];
    [message appendString:valueString];
    
    [message appendString:CR_LF];
    [message appendString:CR_LF];
    
    //Itemization of non-milage expenses
    [message appendString:@"Expense itemization:<br>"];
    [message appendString:SCORE];
    int itemCount = 0;
    NSString *documentString = [self getDocumentsDirectory];
    for (Deliverables *expense in expenses) {
        if ([expense.expensed integerValue] == 0 && [expense.milage floatValue] == 0) {
            totalExpensed = totalExpensed + [expense.amount floatValue];
            NSString *lineItem = [NSString stringWithFormat:@"%@     %@    %@",
                                  [self.dateFormatter stringFromDate:expense.datePaid],
                                  expense.pmtDescription,
                                  [self.currencyFormatter stringFromNumber:expense.amount]];
            [message appendString:lineItem];
            [message appendString:CR_LF];
            itemCount++;
            
            if (expense.receiptPath != nil) {
                // Read the receipt from the file path
                NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentString,expense.receiptPath];
                UIImage *image = [UIImage imageWithContentsOfFile:fullPath];
                [workingReceipts addObject:image];
            }
        }
    }
    
    self.receiptList = [NSArray arrayWithArray:workingReceipts];
    
    [message appendString:SCORE];
    NSString *expenseTotal = [NSString stringWithFormat:@"Items %d                     Total:", itemCount];
    [message appendString:expenseTotal];
    valueString = [self.currencyFormatter stringFromNumber:[NSNumber numberWithFloat:totalExpensed]];
    [message appendString:valueString];
    [message appendString:CR_LF];
    [message appendString:CR_LF];
    
    
    //Itemization of milage expenses
    [message appendString:@"Milage Itemization:"];
    [message appendString:CR_LF];
    [message appendString:SCORE];
    int mileCount = 0;
    for (Deliverables *expense in expenses) {
        if ([expense.expensed integerValue] == 0 && [expense.milage floatValue] > 0) {
            totalMilage = totalMilage + [expense.milage floatValue];
            NSString *lineItem = [NSString stringWithFormat:@"%@            %@",
                                  [self.dateFormatter stringFromDate:expense.datePaid],
                                  expense.pmtDescription];
            [message appendString:lineItem];
            [message appendString:CR_LF];
            mileCount++;
        }
    }
    
    [message appendString:SCORE];
    NSString *milageTotal = [NSString stringWithFormat:@"Trips: %d                     Total Milage:", mileCount];
    [message appendString:milageTotal];
    valueString = [NSString stringWithFormat:@"%@", [self.milageFormatter stringFromNumber:[NSNumber numberWithFloat:totalMilage]]];
    [message appendString:valueString];
    
    //Summation of billed hours
    if ([project.hourlyRate floatValue] > 0) {
        for (WorkTime * hourExpense in project.projectWork) {
            if ([hourExpense.billed integerValue] == 1 ) {
                NSTimeInterval elapseTime = [hourExpense.end timeIntervalSinceDate:hourExpense.start];
                totalExpensedTime = totalExpensedTime + elapseTime;
            }
        }
        
        [message appendString:CR_LF];
        [message appendString:CR_LF];
        [message appendString:SCORE];
    
        totalExpensedTime = round(totalExpensedTime/36)/100;
        totalExpensedTime = totalExpensedTime * [project.hourlyRate floatValue];
        NSString *hoursTotal = [NSString stringWithFormat:@"Total of Billed Hours:  %@", [self.currencyFormatter stringFromNumber:[NSNumber numberWithFloat:totalExpensedTime]]];
        [message appendString:hoursTotal];
        [message appendString:CR_LF];
        remainingBudget = remainingBudget - totalExpensedTime;
        // NSLog(@"Total time expense: %f", totalExpensedTime);
    }
    
    
    [message appendString:CR_LF];
    [message appendString:CR_LF];
    [message appendString:SCORE];
    
    remainingBudget = remainingBudget - totalExpensed;
    valueString = [self.currencyFormatter stringFromNumber:[NSNumber numberWithFloat:remainingBudget]];
    NSString *reportSummary = [NSString stringWithFormat:@"Remaining Balance:"];
    [message appendString:reportSummary];
    [message appendString:valueString];
    [message appendString:CR_LF];
    [message appendString:SCORE];
    
    return (NSString *)message;
}

-(NSString *)getLocationOfPDFExpenseReportForProject:(Project *)project{
    return @"Not finished yet";
}

#pragma mark - Helpers
- (NSString *)getDocumentsDirectory{
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

#pragma mark - Life Cycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Lazy Getter
-(NSNumberFormatter *)currencyFormatter{
    if (_currencyFormatter == nil) {
        _currencyFormatter = [[NSNumberFormatter alloc] init];
        [_currencyFormatter setCurrencyCode:@"USD"];
        [_currencyFormatter setRoundingMode:NSNumberFormatterRoundHalfUp];
        [_currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [_currencyFormatter setFormatWidth:12];
        [_currencyFormatter setPaddingCharacter:@" "];
    }
    return _currencyFormatter;
}

-(NSNumberFormatter *)milageFormatter{
    if (_milageFormatter == nil) {
        _milageFormatter = [[NSNumberFormatter alloc] init];
        [_milageFormatter setRoundingMode:NSNumberFormatterRoundHalfUp];
        [_milageFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        _milageFormatter.maximumFractionDigits = 4;
        [_milageFormatter setFormatWidth:12];
        [_milageFormatter setPaddingCharacter:@" "];
    }
    return _milageFormatter;
}

-(NSDateFormatter *)dateFormatter{
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    return _dateFormatter;
}

@end
