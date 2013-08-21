//
//  ExampleViewController.h
//  iCoAP_Example
//
//  Created by Wojtek Kordylewski on 26.07.13.


#import <UIKit/UIKit.h>
#import "ICoAPExchange.h"

@interface ExampleViewController : UIViewController<ICoAPExchangeDelegate, UITextFieldDelegate> {
    ICoAPExchange *iExchange;
    int count;
    
    NSDateFormatter *completeDateFormat;
}
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)onTapSend:(id)sender;
@end
