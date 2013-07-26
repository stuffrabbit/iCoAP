//
//  ExampleViewController.h
//  iCoAP_Example
//
//  Created by Wojtek Kordylewski on 26.07.13.


#import <UIKit/UIKit.h>
#import "iCoAPTransmission.h"

@interface ExampleViewController : UIViewController<iCoAPTransmissionDelegate, UITextFieldDelegate> {
    iCoAPTransmission *iTrans;
    int count;
}
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)onTapSend:(id)sender;
@end
