//
//  ICoAPMessage.h
//  iCoAP
//
//  Created by Wojtek Kordylewski on 18.06.13.


/*
 *  This class represents a CoAP-message in the iCoAP iOS library
 */



#import <Foundation/Foundation.h>





/*
 * Type with +4 value for version 
 */
typedef enum {
    IC_CONFIRMABLE = 4,
    IC_NON_CONFIRMABLE = 5,
    IC_ACKNOWLEDGMENT = 6,
    IC_RESET = 7
} ICoAPType;

typedef enum {
    IC_GET = 1,
    IC_POST = 2,
    IC_PUT = 3,
    IC_DELETE = 4
} ICoAPRequestMethod;

typedef enum {
    IC_EMPTY = 0,
    IC_CREATED = 65,
    IC_DELETED = 66,
    IC_VALID = 67,
    IC_CHANGED = 68,
    IC_CONTENT = 69,
    IC_BAD_REQUEST = 128,
    IC_UNAUTHORIZED = 129,
    IC_BAD_OPTION = 130,
    IC_FORBIDDEN = 131,
    IC_NOT_FOUND = 132,
    IC_METHOD_NOT_ALLOWED = 133,
    IC_NOT_ACCEPTABLE = 134,
    IC_PRECONDITION_FAILED = 140,
    IC_REQUEST_ENTITY_TOO_LARGE = 141,
    IC_UNSUPPORTED_CONTENT_FORMAT = 143,
    IC_INTERNAL_SERVER_ERROR = 160,
    IC_NOT_IMPLEMENTED = 161,
    IC_BAD_GATEWAY = 162,
    IC_SERVICE_UNAVAILABLE = 163,
    IC_GATEWAY_TIMEOUT = 164,
    IC_PROXYING_NOT_SUPPORTED = 165
} ICoAPResponseCode;

typedef enum {
    IC_IF_MATCH = 1,
    IC_URI_HOST = 3,
    IC_ETAG = 4,
    IC_IF_NONE_MATCH = 5,
    IC_OBSERVE = 6,
    IC_URI_PORT = 7,
    IC_LOCATION_PATH = 8,
    IC_URI_PATH = 11,
    IC_CONTENT_FORMAT = 12,
    IC_MAX_AGE = 14,
    IC_URI_QUERY = 15,
    IC_ACCEPT = 17,
    IC_LOCATION_QUERY = 20,
    IC_BLOCK2 = 23,
    IC_BLOCK1 = 27,
    IC_SIZE2 = 28,
    IC_PROXY_URI = 35,
    IC_PROXY_SCHEME = 39,
    IC_SIZE1 = 60
} ICoAPOption;


@interface ICoAPMessage : NSObject








#pragma mark - Properties








/*
 * 'isRequest': 
 *  Indicates if this object is a request (is set automatically).
 *  Only for orientation.
 */
@property (readwrite, nonatomic) BOOL isRequest;

/*
 * 'isTokenRequested':
 *  If set to YES, the object will be assigned a random token 
 *  upon passing it to a ICoAPExchange object
 */
@property (readwrite, nonatomic) BOOL isTokenRequested;

/*
 *  'usesHttpProxying':
 *  Tells whether this message is supposed to be sent as HTTP-message
 *  to a HTTP-Proxy (YES), or directly to a CoAP-Server as casual 
 *  CoAP-message (NO).
 */
@property (readwrite, nonatomic) BOOL usesHttpProxying;

/*
 *  'httpProxyHost':
 *  The HTTP-Proxy Host (optional).
 */
@property (copy) NSString *httpProxyHost;

/*
 *  'httpProxyPort':
 *  The HTTP-Proxy Port (optional).
 */
@property (readwrite, nonatomic) uint httpProxyPort;


/*
 *  'type':
 *  The CoAP Message Type
 */
@property (readwrite, nonatomic) uint type;

/*
 *  'code':
 *  The CoAP Message Code
 */
@property (readwrite, nonatomic) uint code;

/*
 *  'optionDict':
 *  Dictionary containing all options which belong to this message.
 *  The keys are the option numbers and the values are the respective
 *  option values
 */
@property (strong, nonatomic) NSMutableDictionary *optionDict;

/*
 *  'messageID':
 *  The CoAP Message ID
 */
@property (readwrite, nonatomic) uint messageID;

/*
 *  'token':
 *  the CoAP Message Token. Is set upon passing it to a
 *  ICoAPExchange object, if 'isTokenRequired is set to YES.
 */
@property (readwrite, nonatomic) uint token;

/*
 *  'payload':
 *  The CoAP Message Payload. Not encoded.
 */
@property (copy) NSString *payload;

/*
 *  'host':
 *  CoAP-Host of the CoAP-Message destination/origin.
 */
@property (copy) NSString *host;

/*
 *  'port':
 *  CoAP-Serverport of the CoAP-Message destination/origin.
 */
@property (readwrite, nonatomic) uint port;


/*
 *  'timestamp':
 *  The timestamp, the ICoAPMessage is sent or received.
 */
@property (strong, nonatomic) NSDate *timestamp;








#pragma mark - Methods








/*
 *  'init':
 *  Initialization
 */
- (id)init;

/*
 *  'initAsRequestConfirmable:requestMethod:sendToken:payload':
 *  Initialization with settings.
 */
- (id)initAsRequestConfirmable:(BOOL)con requestMethod:(uint)req sendToken:(BOOL)token payload:(NSString *)payload;

/*
 *  'addOption:withValue'
 *  Adds an option number and its value to the option dictionary.
 *
 *  The "key" of the dictionary: the number of the option.
 *
 *  The "value" of the dictionary: An NSMutableArray of option values
 *  coresponding to the "key" option number
 */
- (void)addOption:(uint)option withValue:(NSString *)value;

@end

