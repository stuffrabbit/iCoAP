iCoAP
=====

This project is an Objective-C implementation of the "Constrained Application Protocol" (CoAP) for Clients.


Getting Started
=====

1. Copy all files included in the "iCoAP-Library files" folder to your X-Code project.
2. Import the `iCoAPTransmission.h` to the Objective-C class (e.g. a standard ViewController).
3. Create an `iCoAPMessage` (e.g. like `iCoAPMessage *cO = [[iCoAPMessage alloc] initAsRequestConfirmable:YES requestMethod:GET sendToken:YES payload:@""];`)
4. Modify your Message, e.g. by adding Options like 
```ruby
[cO addOptionNumber:URI_PATH withValue:self.textField.text];
```
5. Initialize the `iCoAPTransmission` object and send your message to the desired destination. You can use the method 
 `iCoAPTransmission *transmission = [[iCoAPTransmission alloc] initWithRegistrationAndSendRequestWithCoAPMessage:cO toHost:@"ns.tzi.org" port:61616 delegate:self];`
