iCoAP
=====

This project is an Objective-C implementation of the "Constrained Application Protocol" (CoAP) for Clients only.
The current version has besides the standard CoAP features the following additions:
* Observe
* Block transfer in responses (Block 2)

Do you want more features or a server implementation? Checkout my new project [SwiftCoAP](https://github.com/stuffrabbit/SwiftCoAP) - a client and server implementation of CoAP in Apple's beautiful new programming language *Swift*, with more functionality than iCoAP (Block1, Caching, etc.).

Getting Started
=====

* Copy all files included in the `iCoAP-Library_Files` folder to your X-Code project.
* Import the `ICoAPExchange.h` to your Objective-C class (e.g. a standard ViewController).
* Create an ` ICoAPMessage` object  e.g. like: 

```objc
ICoAPMessage *cO = [[ICoAPMessage alloc] initAsRequestConfirmable:YES 
                                         requestMethod:GET 
                                         sendToken:YES 
                                         payload:@""];
```
  Alternatively you can use the standard `init` Method and set the required properties manually.

* Modify your Message, e.g. by adding Options like

```objc 
[cO addOption:URI_PATH withValue:@".well-known"];
[cO addOption:URI_PATH withValue:@"core"];
```
Options are saved in an NSMutable Dictionary, where each dictionary "key" represents an option number and the matching dictionary "values" consist of NSMutableArrays of the corresponding option values.

* Initialize the `ICoAPExchange` object and send your message to the desired destination. You can use the following method which performs a sending on initialization:

```objc 
ICoAPExchange *exchange = 
          [[ICoAPExchange alloc] initAndSendRequestWithCoAPMessage:cO 
                                     toHost:@"4.coap.me" 
                                     port:5683 
                                     delegate:self];
```
  Alternatively you can use the standard `init` method, alter properties (optional, but don't forget to set the delegate) and send manually like:
```objc 
[exchange sendRequestWithCoAPMessage:cO toHost:@"4.coap.me" port:5683];
```

* Implement the delegate methods from the provided `ICoAPExchangeDelegate` protocol.

Now you should be able to communicate.


HTTP-Proxying:
====
It is possible to send a CoAP-Message via a HTTP-Proxy. You just have to set the following Properties after creating a CoAP-Message
```objc
CoAPMessage *message = 
    [[ICoAPMessage alloc] initAsRequestConfirmable:YES 
                                      requestMethod:GET
                                      sendToken:YES 
                                      payload:@""];
[message setUsesHttpProxying:YES];
[message setHttpProxyHost:@"localhost"];
[message setHttpProxyPort:5683];
```

The Options of the CoAP-Message are sent in the HTTP-Header. It is required that the Proxy returns the CoAP-Type in the Header of HTTP-Response as well. The respective Header-Field is `COAP_TYPE`.
The Request-URI has the following Format: `http://proxyHost:proxyPort/coapHost:coapPort`
An Example: Sending your message to the CoAP-Server `coap.me` with the Port `5683` via a HTTP-Proxy located at `localhost:9292`, lets the iCoAP-Library compose the following Request-URI: `http://localhost:9292/coap.me:5683`

Details and Examples:
====

For detailed information checkout the `iCoAP_Example` App, which provides a simple example of how to use the `iCoAP` Library.
Additionally, make sure to read the comments in both the `ICoAPExchange.h` and the `ICoAPMessage.h` files. The available Category `NSString+hex.h` might also be of use by encoding values for the CoAP communication.


Used Libraries:
=====
 This version uses the public domain licensed CocoaAsyncSocket library 
 for UDP-socket networking.
 [Click here](https://github.com/robbiehanson/CocoaAsyncSocket) for more information
