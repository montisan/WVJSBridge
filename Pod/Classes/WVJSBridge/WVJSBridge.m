//
//  WVJSBridge.m
//  WVJSBridge
//
//  Created by hncoder on 2017/1/9.
//  Copyright © 2017年 hncoder. All rights reserved.
//

#import "WVJSBridge.h"

@implementation PTWVJSHandler

+ (instancetype)jsHandlerWithName:(NSString *)name target:(id)target selector:(SEL)selector
{
    if(name.length == 0 || target == nil || selector == nil)
    {
        return nil;
    }
    
    if(![target respondsToSelector:selector])
    {
        return nil;
    }
    
    PTWVJSHandler *handler = [[PTWVJSHandler alloc] init];
    handler.name = name;
    handler.target = target;
    handler.selector = selector;
    
    return handler;
    
}

@end

@interface WVJSBridge()

@property (nonatomic, strong) WVJSCoreBridge *bridge;

@property (nonatomic, copy) NSString *jsBridgeName;

@property (nonatomic, strong) WVJB_WEBVIEW_TYPE *webView;

@property (nonatomic, strong) NSMutableDictionary *jsHanlders;

@property (nonatomic, strong) NSString *jsBridgeEvent;

@property (nonatomic, strong) NSString *jsBridgeObject;

@property (nonatomic, strong) NSString *commonJSInterface;


@end

@implementation WVJSBridge

- (id)initWithWebView:(WVJB_WEBVIEW_TYPE*)webView bridgeName:(NSString *)name delegate:(WVJB_WEBVIEW_DELEGATE_TYPE *)delegate
{
    self = [super init];
    if (self)
    {
        
        self.webView = webView;
        
        self.bridge = [WVJSCoreBridge bridgeForWebView:webView webViewDelegate:self handler:^(NSString *handlerName, id data, WVJBResponseCallback responseCallback) {
            // Do nothing
        }];
        
        self.jsBridgeName = name;
        if (self.jsBridgeName.length == 0)
        {
            self.jsBridgeName = @"jsBridge";
        }
        
        self.jsHanlders = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (BOOL)registerHandler:(NSString*)name target:(id)target selector:(SEL)selector
{
    BOOL registered = NO;
    
    PTWVJSHandler *jsHandler =  [PTWVJSHandler jsHandlerWithName:name target:target selector:selector];
    
    if (jsHandler)
    {
        [_jsHanlders setObject:jsHandler forKey:jsHandler.name];
        
        [_bridge registerHandler:name handler:^(NSString *handlerName, id data, WVJBResponseCallback responseCallback) {
            
            PTWVJSHandler *hander = [_jsHanlders objectForKey:handlerName];
            
            if (hander != nil)
            {
                [self callHandler:hander data:data callBack:responseCallback];
            }
            
        }];
        
        registered = YES;
    }
    
    
    return registered;
}

#pragma mark -

- (void)initJSBridge
{
    NSString *jsBridgeObjectStr = [self jsStringOfJSBridgeObject];
    
    NSString* jsInterfaces = [self jsStringOfAllJSInterfaces];
    
    NSString* initJSBridgeJavascript = [NSString stringWithFormat:@"%@%@",jsBridgeObjectStr,jsInterfaces];
    
    [_webView stringByEvaluatingJavaScriptFromString:initJSBridgeJavascript];
    
    [_webView stringByEvaluatingJavaScriptFromString:[self jsBridgeEvent]];
    
}

#define JSBRIDGEEVENT @"(function(){if(window.$$EventDispatched == undefined && window.$$ != undefined){var readyEvent = document.createEvent('Events');readyEvent.initEvent('$$Ready');readyEvent.bridge = $$;window.dispatchEvent(readyEvent); window.$$EventDispatched=1;}})();"
- (NSString *)jsBridgeEvent
{
    if (!_jsBridgeEvent)
    {
        _jsBridgeEvent = [JSBRIDGEEVENT stringByReplacingOccurrencesOfString:@"$$" withString:self.jsBridgeName];
    }
    
    return _jsBridgeEvent;
}

#define COMMONJSINTERFACE @"if(window.$$.send==undefined){window.$$.send=function(a,b){WVJSCoreBridge.callHandler(a,b)}};"
- (NSString *)commonJSInterface
{
    if (!_commonJSInterface)
    {
        _commonJSInterface = [COMMONJSINTERFACE stringByReplacingOccurrencesOfString:@"$$" withString:self.jsBridgeName];
    }
    
    return _commonJSInterface;
}

#define JSBRIDGEOBJECT @"(function(){if (window.$$ == undefined) { window.$$ = new Object();}})();"
- (NSString *)jsStringOfJSBridgeObject
{
    if (!_jsBridgeObject)
    {
        _jsBridgeObject = [JSBRIDGEOBJECT stringByReplacingOccurrencesOfString:@"$$" withString:self.jsBridgeName];
    }
    
    return _jsBridgeObject;
}

- (NSString*)jsStringOfAllJSInterfaces
{
    NSMutableString* jsInterfacesStr = [NSMutableString stringWithString:@"(function(){"];
    
    NSArray* jsHandlers = [self.jsHanlders allValues];
    
    for(PTWVJSHandler* handler in jsHandlers)
    {
        if (handler)
        {
            [jsInterfacesStr appendString:[self jsStringOfJSInterfaceForHandler:handler]];
        }
    }
    
    [jsInterfacesStr appendString:[self commonJSInterface]];
    
    [jsInterfacesStr appendString:@"})();"];
    
    return jsInterfacesStr;
}

- (NSString *)jsStringOfJSInterfaceForHandler:(PTWVJSHandler *)handler
{
    NSString* name = handler.name;
    
    NSMutableString* jsInterfaceStr = [NSMutableString stringWithFormat:@"if (window.%@.%@ == undefined) {", self.jsBridgeName,name];
    
    NSMutableString* jsFunctionHeader = [NSMutableString stringWithFormat:@"function (data)"];
    
    
    NSString* jsFunctionBody = [NSString stringWithFormat:@"{WVJSCoreBridge.callHandler('%@',data);}", name];
    
    NSString* jsFunctionDef = [jsFunctionHeader stringByAppendingString: jsFunctionBody];
    [jsInterfaceStr appendFormat:@"window.%@.%@ = %@;", self.jsBridgeName, name, jsFunctionDef];
    [jsInterfaceStr appendString:@"}"];
    
    return jsInterfaceStr;
}

- (void)callHandler:(PTWVJSHandler*)handler data:(id)data callBack:(WVJBResponseCallback)cb
{
    id target =  handler.target;
    if (target)
    {
        SEL selector = handler.selector;
        
        NSMethodSignature * sig = [[target class]
                                   instanceMethodSignatureForSelector:selector];
        
        NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setTarget: target];
        [invocation setSelector: selector];
        
        if ([data isKindOfClass:[NSString class]] || [data isKindOfClass:[NSDictionary class]])
        {
            [invocation setArgument: &data atIndex: 2];
        }
        
        if (cb != NULL)
        {
            [invocation setArgument:&cb atIndex:3];
        }
        
        [invocation retainArguments];
        [invocation invoke];
    }
    
}

#if defined WVJB_PLATFORM_OSX
- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame
{
    [self initJSBridge];
    
    if (_delegate && [_delegate respondsToSelector:@selector(webView:didFinishLoadForFrame:)]) {
        [_delegate webView:webView didFinishLoadForFrame:frame];
    }
}

- (void)webView:(WebView *)webView didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    
    if (_delegate && [_delegate respondsToSelector:@selector(webView:didFailLoadWithError:forFrame:)]) {
        [_delegate webView:webView didFailLoadWithError:error forFrame:frame];
    }
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
    if (_delegate && [_delegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:request:frame:decisionListener:)]) {
        [_delegate webView:webView decidePolicyForNavigationAction:actionInformation request:request frame:frame decisionListener:listener];
    }
}

- (void)webView:(WebView *)webView didCommitLoadForFrame:(WebFrame *)frame {
    
    if (_delegate && [_delegate respondsToSelector:@selector(webView:didCommitLoadForFrame:)]) {
        [_delegate webView:webView didCommitLoadForFrame:frame];
    }
}

- (NSURLRequest *)webView:(WebView *)webView resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
    
    if (_delegate && [_delegate respondsToSelector:@selector(webView:resource:willSendRequest:redirectResponse:fromDataSource:)]) {
        return [_delegate webView:webView resource:identifier willSendRequest:request redirectResponse:redirectResponse fromDataSource:dataSource];
    }
    
    return request;
}

#elif defined WVJB_PLATFORM_IOS

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([_delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)])
    {
        return [_delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    return YES;
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewDidStartLoad:)])
    {
        [_delegate webViewDidStartLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (_delegate && [_delegate respondsToSelector:@selector(webView:didFailLoadWithError:)])
    {
        [_delegate webView:webView didFailLoadWithError:error];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self initJSBridge];
    
    if (_delegate && [_delegate respondsToSelector:@selector(webViewDidFinishLoad:)])
    {
        [_delegate webViewDidFinishLoad:webView];
    }
}

#endif

@end

