//
//  ICoAPExchange.h
//  iCoAP
//
//  Created by Wojtek Kordylewski on 25.06.13.


/*
 *  This class represents a client-sided CoAP data exchange of the
 *  iCoAP iOS library.
 
 *  It is recommended to use new ICoAPExchange objects if
 *  a pending CoAP Message is in transmission and responses are
 *  still expected.
 
 *  Version 1.0
 
 *  Special Features:
 *          - Observe
 *          - Block transfer in responses (BLOCK 2)
 
 
 
 *  This version uses the public domain licensed CocoaAsyncSocket library 
 *  for UDP-socket networking.
 *  See more on https://github.com/robbiehanson/CocoaAsyncSocket
 */



#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"
#import "ICoAPMessage.h"




#define k8bitIntForOption                   13
#define k16bitIntForOption                  14
#define kOptionDeltaPayloadIndicator        15

#define kMAX_RETRANSMIT                     4
#define kACK_TIMEOUT                        2.0
#define kACK_RANDOM_FACTOR                  1.5
#define kMAX_TRANSMIT_WAIT                  93.0

#define kMaxObserveOptionValue              8388608
#define kMaxNotificationDelayTime           128.0

#define kProxyCoAPTypeIndicator             @"COAP_TYPE"    //Type of Response is sent in HTTP Header

#define kiCoAPErrorDomain                   @"iCoAPErrorDomain"


typedef enum {
    IC_RESPONSE_TIMEOUT,            //  MAX_WAIT time expired and no response is expected
    IC_UDP_SOCKET_ERROR,            //  UDP Socket setup/bind failed
    IC_PROXYING_ERROR               //  Error during Proxying
} ICoAPExchangeErrorCode;


typedef enum {
    IC_PLAIN = 0,
    IC_LINK_FORMAT = 40,
    IC_XML = 41,
    IC_OCTET_STREAM = 42,
    IC_EXI = 47,
    IC_JSON = 50,
    IC_CBOR = 60
} ICoAPKnownContentFormats;


@interface ICoAPExchange : NSObject<GCDAsyncUdpSocketDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    uint randomMessageId;
    uint randomToken;
    
    long udpSocketTag;
    ICoAPMessage *pendingCoAPMessageInTransmission;
    NSTimer *sendTimer;
    NSTimer *maxWaitTimer;
    int retransmissionCounter;
    
    int observeOptionValue;
    NSDate *recentNotificationDate;
    BOOL isObserveCancelled;
    
    /*
     HTTP Proxying
    */
    NSMutableURLRequest *urlRequest;
    NSURLConnection *urlConnection;
    NSMutableData *urlData;
    
    ICoAPMessage *proxyCoAPMessage;
    
    NSArray *supportedOptions;
}







#pragma mark - Properties







@property (weak, nonatomic) id delegate;

/*
 *  'udpSocket':
 *  The GCDAsyncUdpSocket see https://github.com/robbiehanson/CocoaAsyncSocket
 *  for documentation of the library.
 */
@property (strong, nonatomic) GCDAsyncUdpSocket *udpSocket;

/*
 *  'udpPort':
 *  The udpPort for listening. (Optional)
 */
@property (readwrite, nonatomic) uint udpPort;

/*
 *  'isMessageInTransmission':
 *  Indicates if a ICoAPMessage is currently in transmission and 
 *  if a successive message is expected.
 *  E.g. no response was is received yet, or an empty ACK message indicated a separate response,
 *  or a Block2 message with more-bit set indicated successive
 *  Block2 messages.
 */
@property (readonly, nonatomic) BOOL isMessageInTransmission;






#pragma mark - Accessible Methods






/*
 *  'init':
 *  Initialization
 */
- (id)init;

/*
 *  'initAndSendRequestWithCoAPMessage:toHost:port:delegate':
 *   Initializer with embedded message sending.
 */
- (id)initAndSendRequestWithCoAPMessage:(ICoAPMessage *)cO toHost:(NSString* )host port:(uint)port delegate:(id)delegate;

/*
 *  'sendRequestWithCoAPMessage:toHost:port':
 *  Starts the sending of the given ICoAPMessage to the destination 'host' and
 *  'port'.
 */
- (void)sendRequestWithCoAPMessage:(ICoAPMessage *)cO toHost:(NSString *)host port:(uint)port;

/*
 *  'cancelObserve':
 *  Cancels an Observe subscription (if available).
 */
- (void)cancelObserve;

/*
 *  'closeExchange':
 *  Closes the current exchange and Udp Socket.
 *  Should always be called, if a transmission is (expected to be) finished.
 */
- (void)closeExchange;

/*
 *  'decodeCoAPMessageFromData':
 *  Decodes the given 'data' to an ICoAPMessage object.
 */
- (ICoAPMessage *)decodeCoAPMessageFromData:(NSData *)data;

/*
 *  'encodeDataFromCoAPMessage':
 *  Encodes the given ICoAPMessage to a ready-to-send NSData.
 */
- (NSData *)encodeDataFromCoAPMessage:(ICoAPMessage *)cO;

@end







#pragma mark - Delegate Protocol Definition







@protocol ICoAPExchangeDelegate <NSObject>
@optional

/*
 *  'iCoAPExchange:didReceiveCoAPMessage:':
 *  Informs the delegate that a valid ICoAPMessage was received.
 */
- (void)iCoAPExchange:(ICoAPExchange *)exchange didReceiveCoAPMessage:(ICoAPMessage *)coapMessage;

/*
 *  'iCoAPExchange:didFailWithError:':
 *  Informs the delegate that an error has occured. The error code matches the defined
 *  'ICoAPExchangeErrorCode'.
 */
- (void)iCoAPExchange:(ICoAPExchange *)exchange didFailWithError:(NSError *)error;

/*
 *  'iCoAPExchange:didRetransmitCoAPMessage:number:finalRetransmission:':
 *  Informs the delegate that the pending ICoAPMessage is about to be retransmitted.
 *  'final' indicates whether this was the last retransmission (MAX_RETRANSMIT reached), 
 *  whereas 'number' represents the number of performed retransmissions.
 */
- (void)iCoAPExchange:(ICoAPExchange *)exchange didRetransmitCoAPMessage:(ICoAPMessage *)coapMessage number:(uint)number finalRetransmission:(BOOL)final;

@end
