//
//  iCoAPTransmission.h
//  iCoAP
//
//  Created by Wojtek Kordylewski on 25.06.13.


/*
 *  This class represents a client-sided CoAP transmission of the
 *  iCoAP iOS library.
 
 *  It is recommended to use new iCoAPTransmission objects if 
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
#import "iCoAPMessage.h"




#define k8bitIntForOption                   13
#define k16bitIntForOption                  14
#define kOptionDeltaPayloadIndicator        15

#define kMAX_RETRANSMIT                     4
#define kACK_TIMEOUT                        2.0
#define kACK_RANDOM_FACTOR                  1.5
#define kMAX_TRANSMIT_WAIT                  93.0




typedef enum {
    MAX_RETRANSMIT_REACHED,     //  The pending iCoAPMessage will not be retransmitted
    NO_RESPONSE_EXPECTED,       //  MAX_WAIT time expired and no response is expected
    UDP_SOCKET_ERROR            //  UDP Socket setup/bind failed
}iCoAPTransmissionErrorCode;





@interface iCoAPTransmission : NSObject<GCDAsyncUdpSocketDelegate> {
    long udpSocketTag;
    iCoAPMessage *pendingCoAPMessageInTransmission;
    NSTimer *sendTimer;
    NSTimer *maxWaitTimer;
    int retransmissionCounter;
    
    int observeOptionValue;
    BOOL isObserveCancelled;
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








#pragma mark - Accessible Methods








/*
 *  'initWithRegistrationAndSendRequestWithCoAPMessage:toHost:port:delegate':
 *   Initializer with embedded message sending.
 */
- (id)initWithRegistrationAndSendRequestWithCoAPMessage:(iCoAPMessage *)cO toHost:(NSString* )host port:(uint)port delegate:(id)delegate;

/*
 *  'registerAndSendRequestWithCoAPMessage:toHost:port':
 *  Starts the sending of the given iCoAPMessage to the destination 'host' and
 *  'port'.
 */
- (void)registerAndSendRequestWithCoAPMessage:(iCoAPMessage *)cO toHost:(NSString *)host port:(uint)port ;

/*
 *  'cancelObserve':
 *  Cancels an Observe subscription (if available).
 */
- (void)cancelObserve;

/*
 *  'closeTransmission':
 *  Closes the current transmission and Udp Socket.
 *  Should always be called, if a transmission is (expected to be) finished.
 */
- (void)closeTransmission;

/*
 *  'decodeCoAPMessageFromData':
 *  Decodes the given 'data' to an iCoAPMessage object.
 */
- (iCoAPMessage *)decodeCoAPMessageFromData:(NSData *)data;

/*
 *  'encodeDataFromCoAPMessage':
 *  Encodes the given iCoAPMessage to a ready-to-send NSData.
 */
- (NSData *)encodeDataFromCoAPMessage:(iCoAPMessage *)cO;

@end







#pragma mark - Delegate Protocol Definition







@protocol iCoAPTransmissionDelegate <NSObject>
@optional

/*
 *  'iCoAPTransmission:didFailWithErrorCode:':
 *  Informs the delegate that an 'iCoAPTransmissionErrorCode' has occured.
 */
- (void)iCoAPTransmission:(iCoAPTransmission *)transmission didFailWithErrorCode:(iCoAPTransmissionErrorCode)error;

/*
 *  'iCoAPTransmission:didReceiveCoAPMessage:':
 *  Informs the delegate that a valid iCoAPMessage was received.
 */
- (void)iCoAPTransmission:(iCoAPTransmission *)transmission didReceiveCoAPMessage:(iCoAPMessage *)coapMessage;


@end
