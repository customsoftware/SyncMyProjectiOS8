//
//  CCLatestNewsViewController.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 8/3/13.
//
//

#import "CCLatestNewsViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface CCLatestNewsViewController ()
@property (weak, nonatomic) IBOutlet UITextView *latestNews;

- (IBAction)dsimissView:(UIBarButtonItem *)sender;
- (IBAction)dontShow:(UISwitch *)sender;

@end

@implementation CCLatestNewsViewController

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
	NSString* path = [[NSBundle mainBundle] pathForResource:@"Latest" ofType:@"txt"];

    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    self.latestNews.text = content;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dsimissView:(UIBarButtonItem *)sender {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popDelegate cancelPopover];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)dontShow:(UISwitch *)sender {
    if ([sender isOn]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"dontShowNewsAgain"];
    }
}
@end
