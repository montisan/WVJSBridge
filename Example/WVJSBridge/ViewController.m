//
//  ViewController.m
//  WVJSBridge
//
//  Created by hncoder on 2017/1/9.
//  Copyright © 2017年 hncoder. All rights reserved.
//

#import "ViewController.h"
#import "WVJSBridge.h"

@interface ViewController ()<UIWebViewDelegate>

@property (nonatomic, strong) WVJSBridge *bridge;
@property (nonatomic, strong) UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create `UIWebView` object firstly.
    // NOTE: Don't set webView.delegate
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_webView];
    
    // Create `WVJSBridge` object and bind webview secondly.
    self.bridge = [[WVJSBridge alloc] initWithWebView:_webView bridgeName:@"hnBridge" delegate:self];
    
    // Register native methods for javascript to call.
    [_bridge registerHandler:@"testObjcCallback" target:self selector:@selector(testObjcCallback:callback:)];
    
    // Load web page url.
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.hncoder.com/"]]];
}

- (void)testObjcCallback:(id)data callback:(WVJBResponseCallback)cb
{
    // `data` is kind of NSDictionary object.
    NSLog(@"Receive data from web page:%@",[data description]);
    
    // Return data to javascript.
    if (cb)
    {
        cb(@{@"code":@(0)});
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
