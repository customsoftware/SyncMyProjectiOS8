//
//  ExpenseCell.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/3/12.
//
//

#import <UIKit/UIKit.h>

@interface ExpenseCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *paidTo;
@property (strong, nonatomic) IBOutlet UILabel *description;
@property (strong, nonatomic) IBOutlet UILabel *amountPaid;

@end
