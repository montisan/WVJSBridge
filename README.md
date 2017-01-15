# WVJSBridge

<!--[![CI Status](http://img.shields.io/travis/Michael Waterfall/WVJSBridge.svg?style=flat)](https://travis-ci.org/Michael Waterfall/WVJSBridge)-->
[![Version](https://img.shields.io/cocoapods/v/WVJSBridge.svg?style=flat)](http://cocoapods.org/pods/WVJSBridge)
[![License](https://img.shields.io/cocoapods/l/WVJSBridge.svg?style=flat)](http://cocoapods.org/pods/WVJSBridge)
[![Platform](https://img.shields.io/cocoapods/p/WVJSBridge.svg?style=flat)](http://cocoapods.org/pods/WVJSBridge)

## Installation

WVJSBridge is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "WVJSBridge"
```

## Guide

### Step 1: 

```obj-c
    // Create `UIWebView` object, DONOT set webView.delegate.
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_webView];

    // Create WVJSBridge
    self.bridge = [[WVJSBridge alloc] initWithWebView:_webView bridgeName:@"hnBridge" delegate:self];

    // Register native methods for javascript to call
    [_bridge registerHandler:@"testObjcCallback" target:self selector:@selector(testObjcCallback:callback:)];
```

### Step 2:

```javascript
	// Call native method with javascript
    if(window.hnBridge)
    {
        ptBridge.testObjcCallback({
            // the params to delivery to the native
            data:{
                    param1:"parma1",
                    param2:"parma2"
            },
            callback:function(data){
                    // native callback function
            }
        });
    }

  	// Or:

    if(window.hnBridge)
    {
        ptBridge.send("testObjcCallback",{
            data:{
                    param1:"parma1",
                    param2:"parma2"
            },
            callback:function(data){
                    // native callback function
            }
        });
    }
```

### Step 3:
   
```obj-c 
    - (void)testObjcCallback:(id)data callback:(WVJBResponseCallback)cb
    {
        NSLog(@"Receive params(`NSDictionary` type) from javascript:%@",[data description]);
        if (cb)
        {
            // Return data to javascript
            cb(@{@"code":@(0)});

            // Return data to javascript asynchronously
            /*
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                // TO DO SOMETHINGS

                dispatch_async(dispatch_get_main_queue(), ^{
                    //Return data on main thread
                    cb(@{@"code":@(0)});
                });
            });
            */
        }
    }
```

## Author

hncoder, i@hncoder.com


## License

WVJSBridge is available under the MIT license. See the LICENSE file for more info.


## Notes

JavaScript bridge between native (iOS) and JavaScript, optimizing the WebViewJavascriptBridge(https://github.com/marcuswestin/WebViewJavascriptBridge).
