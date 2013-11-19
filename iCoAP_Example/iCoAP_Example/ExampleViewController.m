//
//  ExampleViewController.m
//  iCoAP_Example
//
//  Created by Wojtek Kordylewski on 26.07.13.


#import "ExampleViewController.h"

@interface ExampleViewController ()

@end

@implementation ExampleViewController

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
    completeDateFormat = [[NSDateFormatter alloc] init];
    [completeDateFormat setDateFormat:@"EEE dd.MM.yyyy"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - iCoAP Exchange Delegate

- (void)iCoAPExchange:(ICoAPExchange *)exchange didReceiveCoAPMessage:(ICoAPMessage *)coapMessage {

    if (!exchange.isMessageInTransmission) {
        self.activityIndicator.hidden = YES;
    }
    
    count++;
    NSString *codeString = [self getCodeDisplayStringForCoAPObject:coapMessage];
    NSString *typeString = [self getTypeDisplayStringForCoAPObject:coapMessage];
    NSString *dateString = [completeDateFormat stringFromDate:coapMessage.timestamp];

    NSMutableString *optString = [[NSMutableString alloc] init];
    for (id key in coapMessage.optionDict) {
        [optString appendString:@"Option: "];
        [optString appendString:[self getOptionDisplayStringForCoAPOptionDelta:[key intValue]]];
        
        //Iterate over the array of option values
        NSMutableArray *valueArray = [coapMessage.optionDict valueForKey:key];
        for (uint i = 0; i < [valueArray count]; i++) {
            [optString appendString:[NSString stringWithFormat:@" \nValue (%i): ", i + 1]];
            [optString appendString:[valueArray objectAtIndex:i]];
            [optString appendString:@"\n"];
        }
        [optString appendString:@"\n-----\n"];
    }
    
    NSLog(@"---------------------------");
    NSLog(@"---------------------------");
    

    if (exchange == iExchange) {
        [self.textView setText:[NSString stringWithFormat:@"(%i) Message from: %@\n\nType: %@\nResponseCode: %@\n%@\nMessageID: %i\nToken: %i\nPayload: '%@'\n\n%@", count, dateString, typeString, codeString, optString , coapMessage.messageID, coapMessage.token, coapMessage.payload, self.textView.text]];
        
    }
    
    NSLog(@"\nMessage: %@\n\nType: %@\nResponseCode: %@\nOption: %@\nMessageID: %i\nToken: %i\nPayload: '%@'", dateString, typeString, codeString, optString, coapMessage.messageID, coapMessage.token, coapMessage.payload);
    NSLog(@"---------------------------");
    NSLog(@"---------------------------");
    
    // did you receive the expected message? then it is recommended to use the closeTransmission method
    // unless more messages are expected, like e.g. block messages, or observe messages.
    
    //          [iExchange closeExchange];


}
- (void)iCoAPExchange:(ICoAPExchange *)exchange didFailWithError:(NSError *)error {
    //Handle Errors
    if (error.code == IC_UDP_SOCKET_ERROR || error.code == IC_RESPONSE_TIMEOUT) {
        [self.textView setText:[NSString stringWithFormat:@"Failed: %@\n\n%@", [error localizedDescription], self.textView.text]];
        self.activityIndicator.hidden = YES;
    }
}


- (void)iCoAPExchange:(ICoAPExchange *)exchange didRetransmitCoAPMessage:(ICoAPMessage *)coapMessage number:(uint)number finalRetransmission:(BOOL)final {
    //Received retransmission notification
    [self.textView setText:[NSString stringWithFormat:@"Retransmission: %i\n\n%@", number, self.textView.text]];
}


#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self onTapSend:self];
    return YES;
}

#pragma mark - Action

- (IBAction)onTapSend:(id)sender {
    [self.textField resignFirstResponder];
    // Create ICoAPMessage first. You can alternatively use the standard 'init' method
    // and set all properties manually
    ICoAPMessage *cO = [[ICoAPMessage alloc] initAsRequestConfirmable:YES requestMethod:IC_GET sendToken:YES payload:@""];
    [cO addOption:IC_URI_PATH withValue:self.textField.text];

    // add more Options here if required e.g. observe
    // [cO addOption:IC_OBSERVE withValue:@""];
    
    
    // finally initialize the ICoAPExchange Object. You can alternatively use the standard 'init' method
    // and set all properties manually.
    // coap.me is a test coap server you can use for testing. Note that it might be offline from time to time.
    if (!iExchange) {
        iExchange = [[ICoAPExchange alloc] initAndSendRequestWithCoAPMessage:cO toHost:@"4.coap.me" port:5683 delegate:self];
    }
    else {
        [iExchange sendRequestWithCoAPMessage:cO toHost:@"4.coap.me" port:5683];
    }

    self.activityIndicator.hidden = NO;
}

#pragma mark - Display Helper

- (NSString *)getOptionDisplayStringForCoAPOptionDelta:(uint)delta {
    switch (delta) {
        case IC_IF_MATCH:
            return @"If Match";
        case IC_URI_HOST:
            return @"URI Host";
        case IC_ETAG:
            return @"ETAG";
        case IC_IF_NONE_MATCH:
            return @"If None Match";
        case IC_URI_PORT:
            return @"URI Port";
        case IC_LOCATION_PATH:
            return @"Location Path";
        case IC_URI_PATH:
            return @"URI Path";
        case IC_CONTENT_FORMAT:
            return @"Content Format";
        case IC_MAX_AGE:
            return @"Max Age";
        case IC_URI_QUERY:
            return @"URI Query";
        case IC_ACCEPT:
            return @"Accept";
        case IC_LOCATION_QUERY:
            return @"Location Query";
        case IC_PROXY_URI:
            return  @"Proxy URI";
        case IC_PROXY_SCHEME:
            return @"Proxy Scheme";
        case IC_BLOCK2:
            return @"Block 2";
        case IC_BLOCK1:
            return @"Block 1";
        case IC_SIZE2:
            return @"Size 2";
        case IC_OBSERVE:
            return @"Observe";
        case IC_SIZE1:
            return @"Size 1";
        default:
            return [NSString stringWithFormat:@"Unknown: %i", delta];
    }
}

- (NSString *)getTypeDisplayStringForCoAPObject:(ICoAPMessage *)cO {
    switch (cO.type) {
        case IC_CONFIRMABLE:
            return @"Confirmable (CON)";
        case IC_NON_CONFIRMABLE:
            return @"Non Confirmable (NON)";
        case IC_ACKNOWLEDGMENT:
            return @"Acknowledgment (ACK)";
        case IC_RESET:
            return @"Reset (RES)";
        default:
            return [NSString stringWithFormat:@"Unknown: %i", cO.type];
    }
}

- (NSString *)getCodeDisplayStringForCoAPObject:(ICoAPMessage *)cO {
    switch (cO.code) {
        case IC_EMPTY:
            return @"Empty";
        case IC_CREATED:
            return @"Created";
        case IC_DELETED:
            return @"Deleted";
        case IC_VALID:
            return @"Valid";
        case IC_CHANGED:
            return @"Changed";
        case IC_CONTENT:
            return @"Content";
        case IC_BAD_REQUEST:
            return @"Bad Request";
        case IC_UNAUTHORIZED:
            return @"Unauthorized";
        case IC_BAD_OPTION:
            return @"Bad Option";
        case IC_FORBIDDEN:
            return @"Forbidden";
        case IC_NOT_FOUND:
            return @"Not Found";
        case IC_METHOD_NOT_ALLOWED:
            return @"Method Not Allowed";
        case IC_NOT_ACCEPTABLE:
            return @"Not Acceptable";
        case IC_PRECONDITION_FAILED:
            return @"Precondition Failed";
        case IC_REQUEST_ENTITY_TOO_LARGE:
            return @"Request Entity Too Large";
        case IC_UNSUPPORTED_CONTENT_FORMAT:
            return @"Unsupported Content Format";
        case IC_INTERNAL_SERVER_ERROR:
            return @"Internal Server Error";
        case IC_NOT_IMPLEMENTED:
            return @"Not Implemented";
        case IC_BAD_GATEWAY:
            return @"Bad Gateway";
        case IC_SERVICE_UNAVAILABLE:
            return @"Service Unavailable";
        case IC_GATEWAY_TIMEOUT:
            return @"Gateway Timeout";
        case IC_PROXYING_NOT_SUPPORTED:
            return @"Proxying Not Supported";
        default:
            return [NSString stringWithFormat:@"Unknown: %i", cO.code];
    }
}

@end
