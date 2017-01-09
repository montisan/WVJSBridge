//
//  WVJSCoreBridge.h
//  WVJSBridge
//
//  Created by hncoder on 2017/1/9.
//  Copyright © 2017年 hncoder. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kCustomProtocolScheme @"wvjbscheme"
#define kQueueHasMessage      @"__WVJB_QUEUE_MESSAGE__"

#if defined __MAC_OS_X_VERSION_MAX_ALLOWED
#import <WebKit/WebKit.h>
#define WVJB_PLATFORM_OSX
#define WVJB_WEBVIEW_TYPE WebView
#define WVJB_WEBVIEW_DELEGATE_TYPE NSObject
#elif defined __IPHONE_OS_VERSION_MAX_ALLOWED
#import <UIKit/UIWebView.h>
#define WVJB_PLATFORM_IOS
#define WVJB_WEBVIEW_TYPE UIWebView
#define WVJB_WEBVIEW_DELEGATE_TYPE NSObject<UIWebViewDelegate>
#endif

typedef void (^WVJBResponseCallback)(id responseData);
typedef void (^WVJBHandler)(NSString*handlerName, id data, WVJBResponseCallback responseCallback);

@interface WVJSCoreBridge : WVJB_WEBVIEW_DELEGATE_TYPE

+ (instancetype)bridgeForWebView:(WVJB_WEBVIEW_TYPE*)webView handler:(WVJBHandler)handler;
+ (instancetype)bridgeForWebView:(WVJB_WEBVIEW_TYPE*)webView webViewDelegate:(WVJB_WEBVIEW_DELEGATE_TYPE*)webViewDelegate handler:(WVJBHandler)handler;
+ (instancetype)bridgeForWebView:(WVJB_WEBVIEW_TYPE*)webView webViewDelegate:(WVJB_WEBVIEW_DELEGATE_TYPE*)webViewDelegate handler:(WVJBHandler)handler resourceBundle:(NSBundle*)bundle;
+ (void)enableLogging;

- (void)registerHandler:(NSString*)handlerName handler:(WVJBHandler)handler;


@end
