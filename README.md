iCoAP
=====

This project is an Objective-C implementation of the "Constrained Application Protocol" (CoAP) for Clients only.
The current version has besides the standard CoAP features the following additions:
* Observe
* Block transfer in responses (Block 2)

Since this project is quite new, any sort of constructive feedback is highly appreciated!


Getting Started
=====

* Copy all files included in the `iCoAP-Library_Files` folder to your X-Code project.
* Import the `iCoAPTransmission.h` to your Objective-C class (e.g. a standard ViewController).
* Create an ` iCoAPMessage` object  e.g. like: 

```objc
iCoAPMessage *cO = [[iCoAPMessage alloc] initAsRequestConfirmable:YES 
                                         requestMethod:GET 
                                         sendToken:YES 
                                         payload:@""];
```
  Alternatively you can use the standard `init` Method and set the required properties manually.

* Modify your Message, e.g. by adding Options like

```objc 
[cO addOptionNumber:URI_PATH withValue:@"well-known/core"];
```

* Initialize the `iCoAPTransmission` object and send your message to the desired destination. You can use the following method which performs a sending on initialization:

```objc 
iCoAPTransmission *transmission = 
          [[iCoAPTransmission alloc] initWithRegistrationAndSendRequestWithCoAPMessage:cO 
                                     toHost:@"4.coap.me" 
                                     port:5683 
                                     delegate:self];
```
  Alternatively you can use the standard `init` method, alter properties (optional, but don't forget to set the delegate) and send manually like:
```objc 
[transmission registerAndSendRequestWithCoAPMessage:cO toHost:@"4.coap.me" port:5683];
```

* Implement the delegate methods from the provided `iCoAPTransmissionDelegate` protocol.

Now you should be able to communicate.

Details and Examples:
====

For detailed information checkout the `iCoAP_Example` App, which provides a simple example of how to use the `iCoAP` Library.
Additionally, make sure to read the comments in both the `iCoAPTransmission.h` and the `iCoAPMessage.h` files. The available Category `NSString+hex.h` might also be of use by encoding values for the CoAP communication.


Used Libraries:
=====
 This version uses the public domain licensed CocoaAsyncSocket library 
 for UDP-socket networking.
 See more on https://github.com/robbiehanson/CocoaAsyncSocket
