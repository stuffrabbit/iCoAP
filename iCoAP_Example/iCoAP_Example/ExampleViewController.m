//
//  ExampleViewController.m
//  iCoAP_Example
//
//  Created by Wojtek Kordylewski on 26.07.13.


#import "ExampleViewController.h"
#import "NSString+hex.h"

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

#pragma mark - iCoAP Transmission Delegate

- (void)iCoAPTransmission:(iCoAPTransmission *)transmission didReceiveCoAPMessage:(iCoAPMessage *)coapMessage {
    //If empty ACK Message received: Indicator for Seperate Message and don't hide activity indicator

    if (coapMessage.code != 0) {
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
        [optString appendString:@" Value: "];
        [optString appendString:[coapMessage.optionDict valueForKey:key]];
        [optString appendString:@"\n"];
    }
    
    NSLog(@"---------------------------");
    NSLog(@"---------------------------");
    

    if (transmission == iTrans) {
        [self.textView setText:[NSString stringWithFormat:@"(%i) Message from: %@\n\nType: %@\nResponseCode: %@\n%@\nMessageID: %i\nToken: %i\nPayload: '%@'\n\n%@", count, dateString, typeString, codeString, optString , coapMessage.messageID, coapMessage.token, [NSString stringFromHexString:coapMessage.payload], self.textView.text]];
        
    }
    
    NSLog(@"\nMessage: %@\n\nType: %@\nResponseCode: %@\nOption: %@\nMessageID: %i\nToken: %i\nPayload: '%@'", dateString, typeString, codeString, optString, coapMessage.messageID, coapMessage.token, [NSString stringFromHexString:coapMessage.payload] );
    NSLog(@"---------------------------");
    NSLog(@"---------------------------");
    
    // did you receive the expected message? then it is recommended to use the closeTransmission method
    // unless more messages are expected, like e.g. block message, or observe.
    
    //          [iTrans closeTransmission];


}

- (void)iCoAPTransmission:(iCoAPTransmission *)transmission didFailWithErrorCode:(iCoAPTransmissionErrorCode)error {
    if (error == UDP_SOCKET_ERROR || error == NO_RESPONSE_EXPECTED) {
        [self.textView setText:@"Failed..."];
        self.activityIndicator.hidden = YES;
    }
}

#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self onTapSend:self];
    return YES;
}

#pragma mark - Action

- (IBAction)onTapSend:(id)sender {
    // Create iCoAPMessage first. You can alternatively use the standard 'init' method
    // and set all properties manually
    iCoAPMessage *cO = [[iCoAPMessage alloc] initAsRequestConfirmable:YES requestMethod:GET sendToken:YES payload:@""];
    [cO addOptionNumber:URI_PATH withValue:self.textField.text];

    // add more Options here if required e.g. observe
    // [cO addOptionNumber:OBSERVE withValue:@""];
    
    
    // finally initialize the iCoAPTransmission Object. You can alternatively use the standard 'init' method
    // and set all properties manually.
    // coap.me is a test coap server you can use. Note that it might be offline from time to time.
    if (iTrans == nil) {
        iTrans = [[iCoAPTransmission alloc] initWithRegistrationAndSendRequestWithCoAPMessage:cO toHost:@"4.coap.me" port:5683 delegate:self];
    }
    else {
        // Make sure to always close transmission before you send a new message. If you want to sent multiple message
        // simultaneously simply initialize a new iCoAPTransmission object
        [iTrans closeTransmission];
        [iTrans registerAndSendRequestWithCoAPMessage:cO toHost:@"4.coap.me" port:5683];
    }

    self.activityIndicator.hidden = NO;
}

#pragma mark - Display Helper

- (NSString *)getOptionDisplayStringForCoAPOptionDelta:(uint)delta {
    switch (delta) {
        case IF_MATCH:
            return @"If Match";
        case URI_HOST:
            return @"URI Host";
        case ETAG:
            return @"ETAG";
        case IF_NONE_MATCH:
            return @"If None Match";
        case URI_PORT:
            return @"URI Port";
        case LOCATION_PATH:
            return @"Location Path";
        case URI_PATH:
            return @"URI Path";
        case CONTENT_FORMAT:
            return @"Content Format";
        case MAX_AGE:
            return @"Max Age";
        case URI_QUERY:
            return @"URI Query";
        case ACCEPT:
            return @"Accept";
        case LOCATION_QUERY:
            return @"Location Query";
        case PROXY_URI:
            return  @"Proxy URI";
        case PROXY_SCHEME:
            return @"Proxy Scheme";
        case BLOCK2:
            return @"Block 2";
        case BLOCK1:
            return @"Block 1";
        case OBSERVE:
            return @"Observe";
        default:
            return [NSString stringWithFormat:@"Unknown: %i", delta];
    }
}

- (NSString *)getTypeDisplayStringForCoAPObject:(iCoAPMessage *)cO {
    switch (cO.type) {
        case CONFIRMABLE:
            return @"Confirmable (CON)";
        case NON_CONFIRMABLE:
            return @"Non Confirmable (NON)";
        case ACKNOWLEDGMENT:
            return @"Acknowledgment (ACK)";
        case RESET:
            return @"Reset (RES)";
        default:
            return [NSString stringWithFormat:@"Unknown: %i", cO.type];
    }
}

- (NSString *)getCodeDisplayStringForCoAPObject:(iCoAPMessage *)cO {
    switch (cO.code) {
        case EMPTY:
            return @"Empty";
        case CREATED:
            return @"Created";
        case DELETED:
            return @"Deleted";
        case VALID:
            return @"Valid";
        case CHANGED:
            return @"Changed";
        case CONTENT:
            return @"Content";
        case BAD_REQUEST:
            return @"Bad Request";
        case UNAUTHORIZED:
            return @"Unauthorized";
        case BAD_OPTION:
            return @"Bad Option";
        case FORBIDDEN:
            return @"Forbidden";
        case NOT_FOUND:
            return @"Not Found";
        case METHOD_NOT_ALLOWED:
            return @"Method Not Allowed";
        case NOT_ACCEPTABLE:
            return @"Not Acceptable";
        case PRECONDITION_FAILED:
            return @"Precondition Failed";
        case REQUEST_ENTITY_TOO_LARGE:
            return @"Request Entity Too Large";
        case UNSUPPORTED_CONTENT_FORMAT:
            return @"Unsupported Content Format";
        case INTERNAL_SERVER_ERROR:
            return @"Internal Server Error";
        case NOT_IMPLEMENTED:
            return @"Not Implemented";
        case BAD_GATEWAY:
            return @"Bad Gateway";
        case SERVICE_UNAVAILABLE:
            return @"Service Unavailable";
        case GATEWAY_TIMEOUT:
            return @"Gateway Timeout";
        case PROXYING_NOT_SUPPORTED:
            return @"Proxying Not Supported";
        default:
            return [NSString stringWithFormat:@"Unknown: %i", cO.code];
    }
}

@end
