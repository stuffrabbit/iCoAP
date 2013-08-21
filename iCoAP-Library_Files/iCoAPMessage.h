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
    CONFIRMABLE = 4,
    NON_CONFIRMABLE = 5,
    ACKNOWLEDGMENT = 6,
    RESET = 7
} CoAPType;

typedef enum {
    GET = 1,
    POST = 2,
    PUT = 3,
    DELETE = 4
} CoAPRequestMethod;

typedef enum {
    EMPTY = 0,
    CREATED = 65,
    DELETED = 66,
    VALID = 67,
    CHANGED = 68,
    CONTENT = 69,
    BAD_REQUEST = 128,
    UNAUTHORIZED = 129,
    BAD_OPTION = 130,
    FORBIDDEN = 131,
    NOT_FOUND = 132,
    METHOD_NOT_ALLOWED = 133,
    NOT_ACCEPTABLE = 134,
    PRECONDITION_FAILED = 140,
    REQUEST_ENTITY_TOO_LARGE = 141,
    UNSUPPORTED_CONTENT_FORMAT = 143,
    INTERNAL_SERVER_ERROR = 160,
    NOT_IMPLEMENTED = 161,
    BAD_GATEWAY = 162,
    SERVICE_UNAVAILABLE = 163,
    GATEWAY_TIMEOUT = 164,
    PROXYING_NOT_SUPPORTED = 165
} CoAPResponseCode;

typedef enum {
    IF_MATCH = 1,
    URI_HOST = 3,
    ETAG = 4,
    IF_NONE_MATCH = 5,
    OBSERVE = 6,
    URI_PORT = 7,
    LOCATION_PATH = 8,
    URI_PATH = 11,
    CONTENT_FORMAT = 12,
    MAX_AGE = 14,
    URI_QUERY = 15,
    ACCEPT = 17,
    LOCATION_QUERY = 20,
    BLOCK2 = 23,
    BLOCK1 = 27,
    PROXY_URI = 35,
    PROXY_SCHEME = 39,
    SIZE1 = 60
} CoAPOption;

typedef enum {
    PLAIN = 0,
    LINK_FORMAT = 40,
    XML = 41,
    OCTET_STREAM = 42,
    EXI = 47,
    JSON = 50
} SupportedContentFormats;


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
 *  The destination host.
 */
@property (copy) NSString *host;

/*
 *  'port':
 *  The destination port.
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

