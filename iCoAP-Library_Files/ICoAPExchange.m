//
//  ICoAPExchange.m
//  iCoAP
//
//  Created by Wojtek Kordylewski on 25.06.13.


#import "ICoAPExchange.h"
#import "NSString+hex.h"

@interface ICoAPExchange ()
- (BOOL)setupUdpSocket;
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext;
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error;
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error;
- (void)noResponseExpected;
- (void)sendDidReceiveMessageToDelegateWithCoAPMessage:(ICoAPMessage *)coapMessage;
- (void)sendDidRetransmitMessageToDelegateWithCoAPMessage:(ICoAPMessage *)coapMessage;
- (void)sendFailWithErrorToDelegateWithError:(NSError *)error;
- (NSMutableData *)getHexDataFromString:(NSString *)string;
- (void)sendCircumstantialResponseWithMessageID:(uint)messageID token:(uint)token type:(CoAPType)type toAddress:(NSData *)address;
- (void)startSending;
- (void)performTransmissionCycle;
- (void)sendCoAPMessage;

@end

@implementation ICoAPExchange

#pragma mark - Init

- (id)initAndSendRequestWithCoAPMessage:(ICoAPMessage *)cO toHost:(NSString* )host port:(uint)port delegate:(id)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        [self sendRequestWithCoAPMessage:cO toHost:host port:port];
    }
    return self;
}

- (BOOL)setupUdpSocket {
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error;
    if (![self.udpSocket bindToPort:self.udpPort error:&error]) {
        return NO;
    }
    
    if (![self.udpSocket beginReceiving:&error]) {
        [self.udpSocket close];
        return NO;
    }
    return YES;
}

#pragma mark - Decode Message

- (ICoAPMessage *)decodeCoAPMessageFromData:(NSData *)data {
    NSString *hexString = [NSString stringFromDataWithHex:data];
    
    //Check if header exists:
    if ([hexString length] < 8) {
        return nil;
    }
    
    ICoAPMessage *cO = [[ICoAPMessage alloc] init];
    
    cO.isRequest = NO;
    
    //Check Version and type (first 4 bits)
    cO.type = strtol([[hexString substringWithRange:NSMakeRange(0, 1)] UTF8String], NULL, 16);
    if (CONFIRMABLE < cO.type > RESET) {
        return nil;
    }
    
    //Check Token length and save it.
    uint tokenLength = strtol([[hexString substringWithRange:NSMakeRange(1, 1)] UTF8String], NULL, 16); // in Bytes

    cO.token = strtol([[hexString substringWithRange:NSMakeRange(8, tokenLength * 2)] UTF8String], NULL, 16);
    
    //Code
    cO.code = strtol([[hexString substringWithRange:NSMakeRange(2, 2)] UTF8String], NULL, 16);
     
    //Message ID
    cO.messageID = strtol([[hexString substringWithRange:NSMakeRange(4, 4)] UTF8String], NULL, 16);
    
    //Options && Payload
    int optionIndex = 8 + (tokenLength * 2);
    int payloadStartIndex = optionIndex;
    uint prevOptionDelta = 0;
    
    
    //Check if Options and More exists
    BOOL isOptionLoopRunning = YES;
    
    while (isOptionLoopRunning) {
        if (optionIndex + 2 < [hexString length]) {
            uint optionDelta = strtol([[hexString substringWithRange:NSMakeRange(optionIndex, 1)] UTF8String], NULL, 16);
            uint optionLength = strtol([[hexString substringWithRange:NSMakeRange(optionIndex + 1, 1)] UTF8String], NULL, 16);
            
            if (optionDelta == kOptionDeltaPayloadIndicator) {
                //Payload should follow instead of Option_length. Verifying...
                if (optionLength != kOptionDeltaPayloadIndicator) {
                    return nil;
                }
                isOptionLoopRunning = NO;
                payloadStartIndex = optionIndex;
                continue;
            }
            
            uint extendedDelta = 0;
            int optionIndexOffset = 2; //marks the range between the beginning of the initial option byte and the end of the 'option delta' plus 'option lenght' extended bytes in hex steps (2 = 1 byte)
            
            if (optionDelta == k8bitIntForOption) {
                optionIndexOffset += 2;
            }
            else if (optionDelta == k16bitIntForOption) {
                optionIndexOffset += 4;
            }
            
            if (optionIndex + optionIndexOffset <= [hexString length]) {
                extendedDelta = strtol([[hexString substringWithRange:NSMakeRange(optionIndex + 2, optionIndexOffset - 2)] UTF8String], NULL, 16);
            }
            else {
                return nil;
            }
            
            //Verify Length
            int optionLengthExtendedOffsetIndex = optionIndexOffset;
            if (optionLength == k8bitIntForOption) {
                optionIndexOffset += 2;
            }
            else if (optionLength == k16bitIntForOption) {
                optionIndexOffset += 4;
            }
            else if (optionLength == kOptionDeltaPayloadIndicator) {
                return nil;
            }
            optionLength += strtol([[hexString substringWithRange:NSMakeRange(optionIndex + optionLengthExtendedOffsetIndex , optionIndexOffset - optionLengthExtendedOffsetIndex)] UTF8String], NULL, 16);

            
            if (optionIndex + optionIndexOffset + optionLength * 2 > [hexString length]) {
                return nil;
            }
            
            uint newOptionNumber = optionDelta + extendedDelta + prevOptionDelta;
            NSString *optVal;            
            
            if (newOptionNumber == BLOCK2 || newOptionNumber == ETAG || newOptionNumber == IF_MATCH) {
                optVal = [hexString substringWithRange:NSMakeRange(optionIndex + optionIndexOffset, optionLength * 2)];
            }
            else if (newOptionNumber == URI_PORT || newOptionNumber == CONTENT_FORMAT || newOptionNumber == MAX_AGE || newOptionNumber == ACCEPT || newOptionNumber == SIZE1 || newOptionNumber == OBSERVE) {
                optVal = [NSString stringWithFormat:@"%i", (int)strtol([[hexString substringWithRange:NSMakeRange(optionIndex + optionIndexOffset, optionLength * 2)] UTF8String], NULL, 16)];
            }
            else {
                optVal = [NSString stringFromHexString:[[hexString substringWithRange:NSMakeRange(optionIndex + optionIndexOffset, optionLength * 2)] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            }
            
            [cO addOption:newOptionNumber withValue:optVal];
            
            prevOptionDelta += optionDelta + extendedDelta;
            optionIndex += optionIndexOffset + optionLength * 2;
        }
        else {
            isOptionLoopRunning = NO;
            payloadStartIndex = optionIndex;
        }
    }
    
    //Payload, first check if payloadmarker exists
    if (payloadStartIndex + 2 < [hexString length]) {
        if ([cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", CONTENT_FORMAT]]) {
            NSMutableArray *values = [cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", CONTENT_FORMAT]];
            if ([[values objectAtIndex:0] intValue] == OCTET_STREAM || [[values objectAtIndex:0] intValue] == EXI) {
                cO.payload = [hexString substringFromIndex:payloadStartIndex + 2];
                return cO;
            }
        }
        cO.payload = [[NSString stringFromHexString:[hexString substringFromIndex:payloadStartIndex + 2]] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    return cO;
}

#pragma mark - Encode Message

- (NSData *)encodeDataFromCoAPMessage:(ICoAPMessage *)cO {
    NSMutableString *final = [[NSMutableString alloc] init];
    NSString *tokenAsString;
    
    if (cO.token == 0) {
        tokenAsString = @"";
    }
    else if (cO.token > 255) {
        tokenAsString = [NSString stringWithFormat:@"%04X", cO.token];
    }
    else {
        tokenAsString = [NSString stringWithFormat:@"%02X", cO.token];
    }

    [final appendString: [NSString stringWithFormat:@"%01X%01X%02X%04X%@", cO.type, [tokenAsString length] / 2, cO.code, cO.messageID, tokenAsString]];
    
    NSArray *sortedArray;
    sortedArray = [[cO.optionDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [a integerValue] > [b integerValue];
    }];
    
    uint previousDelta = 0;
    
    for (NSString* key in sortedArray) {
        NSMutableArray *valueArray = [cO.optionDict valueForKey:key];
        
        for (uint i = 0; i < [valueArray count]; i++) {
            uint delta = [key intValue] - previousDelta;
            uint length;
            NSString *valueForKey;
            
            if ([key intValue] == BLOCK2 || [key intValue] == ETAG || [key intValue] == IF_MATCH) {
                valueForKey = [valueArray objectAtIndex:i];
                length = [valueForKey length] / 2;
            }
            else if ([key intValue] == URI_PORT || [key intValue] == CONTENT_FORMAT || [key intValue] == MAX_AGE || [key intValue] == ACCEPT || [key intValue] == SIZE1) {
                if ([[valueArray objectAtIndex:i] length] == 0) {
                    valueForKey = @"";
                }
                else if ([[valueArray objectAtIndex:i] intValue] < 255) {
                    valueForKey = [NSString stringWithFormat:@"%02X", [[valueArray objectAtIndex:i] intValue]];
                }
                else if ([[valueArray objectAtIndex:i] intValue] <= 65535) {
                    valueForKey = [NSString stringWithFormat:@"%04X", [[valueArray objectAtIndex:i] intValue]];
                }
                else if ([[valueArray objectAtIndex:i] intValue] <= 16777215) {
                    valueForKey = [NSString stringWithFormat:@"%06X", [[valueArray objectAtIndex:i] intValue]];
                }
                else {
                    valueForKey = [NSString stringWithFormat:@"%08X", [[valueArray objectAtIndex:i] intValue]];
                }
                length = [valueForKey length] / 2;
            }
            else {
                valueForKey = [valueArray objectAtIndex:i];
                length = [valueForKey length];
            }
            
            NSString *extendedDelta = @"";
            NSString *extendedLength = @"";
            
            if (delta >= 269) {
                [final appendString:[NSString stringWithFormat:@"%01X", 14]];
                extendedDelta = [NSString stringWithFormat:@"%04X", delta - 269];
            }
            else if (delta >= 13) {
                [final appendString:[NSString stringWithFormat:@"%01X", 13]];
                extendedDelta = [NSString stringWithFormat:@"%02X", delta - 13];
            }
            else {
                [final appendString:[NSString stringWithFormat:@"%01X", delta]];
            }
            
            if (length >= 269) {
                [final appendString:[NSString stringWithFormat:@"%01X", 14]];
                extendedLength = [NSString stringWithFormat:@"%04X", length - 269];
            }
            else if (length >= 13) {
                [final appendString:[NSString stringWithFormat:@"%01X", 13]];
                extendedLength = [NSString stringWithFormat:@"%02X", length - 13];
            }
            else {
                [final appendString:[NSString stringWithFormat:@"%01X", length]];
            }
            
            [final appendString:extendedDelta];
            [final appendString:extendedLength];
            
            if ([key intValue] == BLOCK2 || [key intValue] == ETAG || [key intValue] == IF_MATCH || [key intValue] == URI_PORT || [key intValue] == CONTENT_FORMAT || [key intValue] == MAX_AGE || [key intValue] == ACCEPT || [key intValue] == SIZE1) {
                [final appendString:valueForKey];
            }
            else {
                [final appendString:[NSString hexStringFromString:valueForKey]];
            }
            
            previousDelta += delta;
        }

    }    
    
    //Payload encoded to UTF-8
    if ([cO.payload length] > 0) {
        if ([cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", CONTENT_FORMAT]]) {
            NSMutableArray *values = [cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", CONTENT_FORMAT]];
            if ([[values objectAtIndex:0] intValue] == OCTET_STREAM || [[values objectAtIndex:0] intValue] == EXI) {
                [final appendString:[NSString stringWithFormat:@"%02X%@", 255, cO.payload]];
                return [self getHexDataFromString:final];
            }
        }
        [final appendString:[NSString stringWithFormat:@"%02X%@", 255, [NSString hexStringFromString:cO.payload]]];
    }

    return [self getHexDataFromString:final];
}


#pragma mark - GCD Async UDP Socket Delegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    
    ICoAPMessage *cO = [self decodeCoAPMessageFromData:data];
    
    //Check if received data is a valid CoAP Message
    if (!cO) {
        return;
    }

    //Set Timestamp
    cO.timestamp = [NSDate date];
    
    //Check for spam and if Observe is Cancelled
    if ((cO.messageID != pendingCoAPMessageInTransmission.messageID && cO.token != pendingCoAPMessageInTransmission.token) || ([cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", OBSERVE]] && isObserveCancelled && cO.type != ACKNOWLEDGMENT)) {
        if (cO.type <= NON_CONFIRMABLE) {
            [self sendCircumstantialResponseWithMessageID:cO.messageID token:cO.token type:RESET toAddress:address];
        }
        return;
    }
    
    //Invalidate Timers: Resend- and Max-Wait Timer
    if (cO.type == ACKNOWLEDGMENT || cO.type == RESET || cO.type == NON_CONFIRMABLE) {
        [sendTimer invalidate];
        [maxWaitTimer invalidate];
    }

    if (!(cO.type == ACKNOWLEDGMENT && cO.code == EMPTY)) {
        _isMessageInTransmission = NO;
    }
    
    //Separate Response / Observe: Send ACK
    if (cO.type == CONFIRMABLE) {        
        [self sendCircumstantialResponseWithMessageID:cO.messageID token:cO.token type:ACKNOWLEDGMENT toAddress:address];
    }
    
    //Block Options: Only send a Block2 request when observe option is inactive:
    if ([cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", BLOCK2]] && ![cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", OBSERVE]]) {
        NSString *blockValue = [[cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", BLOCK2]] objectAtIndex:0];
        uint blockNum = strtol([[blockValue substringToIndex:[blockValue length] - 1] UTF8String], NULL, 16);
        uint blockTail = strtol([[blockValue substringFromIndex:[blockValue length] - 1] UTF8String], NULL, 16);
        
        if (blockTail > 7) {
            //More Flag is set
            ICoAPMessage *blockObject = [[ICoAPMessage alloc] init];
            blockObject.isRequest = YES;
            blockObject.type = CONFIRMABLE;
            blockObject.code = pendingCoAPMessageInTransmission.code;
            blockObject.messageID = pendingCoAPMessageInTransmission.messageID + 1;
            blockObject.token = pendingCoAPMessageInTransmission.token;
            blockObject.host = pendingCoAPMessageInTransmission.host;
            blockObject.port = pendingCoAPMessageInTransmission.port;
            blockObject.optionDict =  [[NSMutableDictionary alloc] init];
            for (id key in pendingCoAPMessageInTransmission.optionDict) {
                if (![key isEqualToString:[NSString stringWithFormat:@"%i", BLOCK2]]) {
                    [blockObject.optionDict setValue:[[NSMutableArray alloc] initWithArray:[pendingCoAPMessageInTransmission.optionDict valueForKey:key]] forKey:key];
                }
            }
            
            NSString *newBlockValue;
            
            if (blockNum >= 4095 ) {
                newBlockValue = [NSString stringWithFormat:@"%05X%01X", blockNum + 1, blockTail - 8];
            }
            else if (blockNum >= 15) {
                newBlockValue = [NSString stringWithFormat:@"%03X%01X", blockNum + 1, blockTail - 8];
            }
            else {
                newBlockValue = [NSString stringWithFormat:@"%01X%01X", blockNum + 1, blockTail - 8];
            }
            
            [blockObject addOption:BLOCK2 withValue:newBlockValue];
            
            pendingCoAPMessageInTransmission = blockObject;
            [self startSending];
        }
        else {
            _isMessageInTransmission = NO;
        }
    }
    
    //Check for Observe Option: If Observe Option is present, the message is only sent to the delegate if the order is correct.
    if ([cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", OBSERVE]] && cO.type != ACKNOWLEDGMENT) {
        uint currentObserveValue = strtol([[[cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", OBSERVE]] objectAtIndex:0] UTF8String], NULL, 16);
        if (currentObserveValue > observeOptionValue) {
            observeOptionValue = currentObserveValue;
            [self sendDidReceiveMessageToDelegateWithCoAPMessage:cO];
        }
    }
    else {
        //No Observe Option: Sending object to delegate
        [self sendDidReceiveMessageToDelegateWithCoAPMessage:cO];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    [self closeTransmission];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"UDP Socket could not send data." forKey:NSLocalizedDescriptionKey];
    [self sendFailWithErrorToDelegateWithError:[[NSError alloc] initWithDomain:kiCoAPErrorDomain code:UDP_SOCKET_ERROR userInfo:userInfo]];
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    [self closeTransmission];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"UDP Socket Closed" forKey:NSLocalizedDescriptionKey];
    [self sendFailWithErrorToDelegateWithError:[[NSError alloc] initWithDomain:kiCoAPErrorDomain code:UDP_SOCKET_ERROR userInfo:userInfo]];
}

#pragma mark - Delegate Method Calls

- (void)noResponseExpected {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No Response expected for recently sent CoAP Message" forKey:NSLocalizedDescriptionKey];

    [self sendFailWithErrorToDelegateWithError:[[NSError alloc] initWithDomain:kiCoAPErrorDomain code:NO_RESPONSE_EXPECTED userInfo:userInfo]];
    [self closeTransmission];
}

- (void)sendDidReceiveMessageToDelegateWithCoAPMessage:(ICoAPMessage *)coapMessage {
    if ([self.delegate respondsToSelector:@selector(iCoAPExchange:didReceiveCoAPMessage:)]) {
        [self.delegate iCoAPExchange:self didReceiveCoAPMessage:coapMessage];
    }
}

- (void)sendDidRetransmitMessageToDelegateWithCoAPMessage:(ICoAPMessage *)coapMessage {
    if ([self.delegate respondsToSelector:@selector(iCoAPExchange:didRetransmitCoAPMessage:number:finalRetransmission:)]) {
        retransmissionCounter == kMAX_RETRANSMIT ?
        [self.delegate iCoAPExchange:self didRetransmitCoAPMessage:pendingCoAPMessageInTransmission number:retransmissionCounter finalRetransmission:YES] :
        [self.delegate iCoAPExchange:self didRetransmitCoAPMessage:pendingCoAPMessageInTransmission number:retransmissionCounter finalRetransmission:NO];
    }
}

- (void)sendFailWithErrorToDelegateWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(iCoAPExchange:didFailWithError:)]) {
        [self.delegate iCoAPExchange:self didFailWithError:error];
    }
}

#pragma mark - Other Methods

- (NSMutableData *)getHexDataFromString:(NSString *)string {
    NSMutableData *commandData= [[NSMutableData alloc] init];
    unsigned char byteRepresentation;
    char byte_chars[3] = {'\0','\0','\0'};
    
    for (int i = 0; i < (string.length / 2); i++) {
        byte_chars[0] = [string characterAtIndex:i * 2];
        byte_chars[1] = [string characterAtIndex:i * 2 + 1];
        byteRepresentation = strtol(byte_chars, NULL, 16);
        [commandData appendBytes:&byteRepresentation length:1];
    }

    return commandData;
}

- (void)cancelObserve {
    isObserveCancelled = YES;
}

#pragma mark - Send Methods

- (void)sendCircumstantialResponseWithMessageID:(uint)messageID token:(uint)token type:(CoAPType)type toAddress:(NSData *)address {
    ICoAPMessage *ackObject = [[ICoAPMessage alloc] init];
    ackObject.isRequest = NO;
    ackObject.type = type;
    ackObject.messageID = messageID;
    
    NSData *send = [self encodeDataFromCoAPMessage:ackObject];
    [self.udpSocket sendData:send toAddress:address withTimeout:-1 tag:udpSocketTag];
    udpSocketTag++;
}

- (void)sendRequestWithCoAPMessage:(ICoAPMessage *)cO toHost:(NSString *)host port:(uint)port {
    cO.messageID = arc4random() % 65536;
    
    if ([cO isTokenRequested]) {
        cO.token = 1 + arc4random() % 65536;
    }
    
    cO.isRequest = YES;
    cO.host = host;
    cO.port = port;
    pendingCoAPMessageInTransmission = cO;
    
    if (!self.udpSocket && ![self setupUdpSocket]) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Failed to setup UDP Socket" forKey:NSLocalizedDescriptionKey];
        
        [self sendFailWithErrorToDelegateWithError:[[NSError alloc] initWithDomain:kiCoAPErrorDomain code:UDP_SOCKET_ERROR userInfo:userInfo]];
        return;
    }
    
    [self startSending];
}

- (void)startSending {
    [sendTimer invalidate];
    [maxWaitTimer invalidate];
    isObserveCancelled = NO;
    observeOptionValue = 0;
    _isMessageInTransmission = YES;
    
    pendingCoAPMessageInTransmission.timestamp = [NSDate date];
    
    if (pendingCoAPMessageInTransmission.type == CONFIRMABLE) {
        retransmissionCounter = 0;
        maxWaitTimer = [NSTimer scheduledTimerWithTimeInterval:kMAX_TRANSMIT_WAIT target:self selector:@selector(noResponseExpected) userInfo:nil repeats:NO];
        
        [self performTransmissionCycle];
    }
    else {
        [self sendCoAPMessage];
    }
}

- (void)performTransmissionCycle {
    [self sendCoAPMessage];
    if (retransmissionCounter != 0) {
        [self sendDidRetransmitMessageToDelegateWithCoAPMessage:pendingCoAPMessageInTransmission];
    }
    
    if (retransmissionCounter != kMAX_RETRANSMIT) {
        double timeout = kACK_TIMEOUT * pow(2.0, retransmissionCounter) * kACK_RANDOM_FACTOR;
        sendTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(performTransmissionCycle) userInfo:nil repeats:NO];
        retransmissionCounter++;
    }
}

- (void)sendCoAPMessage {
    NSData *send = [self encodeDataFromCoAPMessage:pendingCoAPMessageInTransmission];
    [self.udpSocket sendData:send toHost:pendingCoAPMessageInTransmission.host port:pendingCoAPMessageInTransmission.port withTimeout:-1 tag:udpSocketTag];
    udpSocketTag++;
}

- (void)closeTransmission {
    [self.udpSocket close];
    self.udpSocket = nil;
    [sendTimer invalidate];
    [maxWaitTimer invalidate];
    pendingCoAPMessageInTransmission = nil;
    _isMessageInTransmission = NO;
}

@end
