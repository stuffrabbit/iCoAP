iCoAP
=====

This project is an Objective-C implementation of the "Constrained Application Protocol" (CoAP) for Clients.


Getting Started
=====

1. Copy all files included in the "iCoAP-Library files" folder to your X-Code project.
2. Import the `iCoAPTransmission.h` to the Objective-C class (e.g. a standard ViewController).
3. Create an ` iCoAPMessage`  e.g. like: 

```objc
iCoAPMessage *cO = [[iCoAPMessage alloc] initAsRequestConfirmable:YES 
                                         requestMethod:GET 
                                         sendToken:YES 
                                         payload:@""];
```

4. Modify your Message, e.g. by adding Options like

```objc 
[cO addOptionNumber:URI_PATH withValue:self.textField.text];
```

5. Initialize the `iCoAPTransmission` object and send your message to the desired destination. You can use the method 

```objc 
iCoAPTransmission *transmission = 
          [[iCoAPTransmission alloc] initWithRegistrationAndSendRequestWithCoAPMessage:cO 
                                     toHost:@"4.coap.me" 
                                     port:5683 
                                     delegate:self];
```
