//
//  LROAuth2Client.m
//  LROAuth2Client
//
//  Created by Luke Redpath on 14/05/2010.
//  Copyright 2010 LJR Software Limited. All rights reserved.
//

#import "LROAuth2Client.h"
#import "NSURL+QueryInspector.h"
#import "LROAuth2AccessToken.h"
#import "LRURLRequestOperation.h"
#import "NSDictionary+QueryString.h"

#pragma mark -

@implementation LROAuth2Client {
  NSOperationQueue *_networkQueue;
}

@synthesize clientID;
@synthesize clientSecret;
@synthesize redirectURL;
@synthesize cancelURL;
@synthesize userURL;
@synthesize tokenURL;
@synthesize delegate;
@synthesize accessToken;
@synthesize debug;

- (id)initWithClientID:(NSString *)_clientID 
                secret:(NSString *)_secret 
           redirectURL:(NSURL *)url;
{
  if (self = [super init]) {
    clientID = [_clientID copy];
    clientSecret = [_secret copy];
    redirectURL = [url copy];
    requests = [[NSMutableArray alloc] init];
    debug = NO;
    _networkQueue = [[NSOperationQueue alloc] init];
  }
  return self;
}

- (void)dealloc;
{
    [_networkQueue cancelAllOperations];
    //[super dealloc];
}

#pragma mark -
#pragma mark Authorization

- (NSURLRequest *)userAuthorizationRequestWithParameters:(NSDictionary *)additionalParameters;
{
  NSDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@"auth" forKey:@"action"];
    [params setValue:@"authorize" forKey:@"step"];
    [params setValue:clientID forKey:@"client_id"];
    [params setValue:@"token" forKey:@"response_type"];
    [params setValue:@"xyz" forKey:@"state"];
    

    
  if (additionalParameters) {
        for (NSString *key in additionalParameters) {
        [params setValue:[additionalParameters valueForKey:key] forKey:key];
        }
    }
    NSURL *fullURL = [NSURL URLWithString:[[self.userURL absoluteString] stringByAppendingFormat:@"?%@", [params stringWithFormEncodedComponents]]];
    //NSURL *fullURL = [NSURL URLWithString:@"http://dev.socialdashboard.com/oauth2/authorize/?client_id=6f8fca846337921ee0c9&response_type=code"];
    NSMutableURLRequest *authRequest = [NSMutableURLRequest requestWithURL:fullURL];
    [authRequest setHTTPMethod:@"POST"];

    return [authRequest copy];
}

- (void)verifyAuthorizationWithAccessCode:(NSString *)accessCode;
{
  @synchronized(self) {
    if (isVerifying) return; // don't allow more than one auth request
    
    isVerifying = YES;
    
    NSDictionary *params = [NSMutableDictionary dictionary];
      [params setValue:@"refresh_token" forKey:@"grant_type"];
      [params setValue:clientID forKey:@"client_id"];
      [params setValue:clientSecret forKey:@"client_secret"];
      [params setValue:[redirectURL absoluteString] forKey:@"redirect_uri"];
      [params setValue:accessToken.refreshToken forKey:@"refresh_token"];

    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.tokenURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[[params stringWithFormEncodedComponents] dataUsingEncoding:NSUTF8StringEncoding]];
    
    LRURLRequestOperation *operation = [[LRURLRequestOperation alloc] initWithURLRequest:request];

    __unsafe_unretained id blockOperation = operation;

    [operation setCompletionBlock:^{
      [self handleCompletionForAuthorizationRequestOperation:blockOperation];
    }];
      
    [_networkQueue addOperation:operation];
  }
}

- (void)refreshAccessToken:(LROAuth2AccessToken *)_accessToken;
{
  accessToken = _accessToken;
  
  NSDictionary *params = [NSMutableDictionary dictionary];
  [params setValue:@"refresh_token" forKey:@"grant_type"];
  [params setValue:clientID forKey:@"client_id"];
  [params setValue:clientSecret forKey:@"client_secret"];
  [params setValue:[redirectURL absoluteString] forKey:@"redirect_uri"];
  [params setValue:_accessToken.refreshToken forKey:@"refresh_token"];
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.tokenURL];
  [request setHTTPMethod:@"POST"];
  [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
  [request setHTTPBody:[[params stringWithFormEncodedComponents] dataUsingEncoding:NSUTF8StringEncoding]];
  
  LRURLRequestOperation *operation = [[LRURLRequestOperation alloc] initWithURLRequest:request];
  
  __unsafe_unretained id blockOperation = operation;
  
  [operation setCompletionBlock:^{
    [self handleCompletionForAuthorizationRequestOperation:blockOperation];
  }];
  
  [_networkQueue addOperation:operation];
}

- (void)handleCompletionForAuthorizationRequestOperation:(LRURLRequestOperation *)operation
{
  NSHTTPURLResponse *response = (NSHTTPURLResponse *)operation.URLResponse;
  
  if (response.statusCode == 200) {
    NSError *parserError;
    NSDictionary *authData = [NSJSONSerialization JSONObjectWithData:operation.responseData options:0 error:&parserError];
    
    if (authData == nil) {
      // try and decode the response body as a query string instead
      NSString *responseString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding] ;
      authData = [NSDictionary dictionaryWithFormEncodedString:responseString];
    }
    if ([authData objectForKey:@"access_token"] == nil) {
      NSAssert(NO, @"Unhandled parsing failure");
    }
    if (accessToken == nil) {
      accessToken = [[LROAuth2AccessToken alloc] initWithAuthorizationResponse:authData];
      if ([self.delegate respondsToSelector:@selector(oauthClientDidReceiveAccessToken:)]) {
        [self.delegate oauthClientDidReceiveAccessToken:self];
      } 
    } else {
      [accessToken refreshFromAuthorizationResponse:authData];
      if ([self.delegate respondsToSelector:@selector(oauthClientDidRefreshAccessToken:)]) {
        [self.delegate oauthClientDidRefreshAccessToken:self];
      }
    }
  }
  else {
    if (operation.connectionError) {
      NSLog(@"Connection error: %@", operation.connectionError);
    }
  }
}

@end

@implementation LROAuth2Client (UIWebViewIntegration)

- (void)authorizeUsingWebView:(UIWebView *)webView;
{
  [self authorizeUsingWebView:webView additionalParameters:nil];
}

- (void)authorizeUsingWebView:(UIWebView *)webView additionalParameters:(NSDictionary *)additionalParameters;
{
    [webView loadRequest:[self userAuthorizationRequestWithParameters:additionalParameters]];
    [webView setDelegate:self];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    //NSURL* url = [request URL];
  if ([[request.URL absoluteString] hasPrefix:[self.redirectURL absoluteString]]) {
    [self extractAccessCodeFromCallbackURL:request.URL];

    return NO;
  } else if (self.cancelURL && [[request.URL absoluteString] hasPrefix:[self.cancelURL absoluteString]]) {
    if ([self.delegate respondsToSelector:@selector(oauthClientDidCancel:)]) {
      [self.delegate oauthClientDidCancel:self];
    }
    
    return NO;
  }
  
  if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
    return [self.delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
  }
  
  return YES;
}

/**
 * custom URL schemes will typically cause a failure so we should handle those here
 */
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
  
#if __IPHONE_OS_VERSION_MAX_ALLOWED <= __IPHONE_3_2
  NSString *failingURLString = [error.userInfo objectForKey:NSErrorFailingURLStringKey];
#else
  NSString *failingURLString = [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
#endif
  
  if ([failingURLString hasPrefix:[self.redirectURL absoluteString]]) {
    [webView stopLoading];
    [self extractAccessCodeFromCallbackURL:[NSURL URLWithString:failingURLString]];
  } else if (self.cancelURL && [failingURLString hasPrefix:[self.cancelURL absoluteString]]) {
    [webView stopLoading];
    if ([self.delegate respondsToSelector:@selector(oauthClientDidCancel:)]) {
      [self.delegate oauthClientDidCancel:self];
    }
  }
  
  if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
    [self.delegate webView:webView didFailLoadWithError:error];
  }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
  if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
    [self.delegate webViewDidStartLoad:webView];
  }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
    [self.delegate webViewDidFinishLoad:webView];
  }
}

- (void)extractAccessCodeFromCallbackURL:(NSURL *)callbackURL;
{
    //NSURL * url = [NSURL URLWithString:@"http://auth-finished.invalid/?access_token=c33e83dff9276b005d9b3611db969e582400c619&expires_in=2592000&token_type=bearer&state=xyz"];
    NSString *accessCode = [self getAccessTokenFromURL:callbackURL];
   
    if ([self.delegate respondsToSelector:@selector(oauthClientDidExtractAccessToken:)]) {
        [self.delegate oauthClientDidExtractAccessToken:accessCode];
    }
  /*
  if ([self.delegate respondsToSelector:@selector(oauthClientDidReceiveAccessCode:)]) {
    [self.delegate oauthClientDidReceiveAccessCode:self];
  }
  [self verifyAuthorizationWithAccessCode:accessCode];
   */
}

//extract access token from callback url
-(NSString*)getAccessTokenFromURL:(NSURL*)url
{
    NSString* str_token, *str_url;
    int index = 0, length, start_index = 0, end_index = 0;
    str_url = [url absoluteString];
    length = (int)[[url absoluteString] length];
    //str_url = url get
    for(index = 0; index< length; index++)
    {
        unichar ch = [str_url characterAtIndex:index];
        if(ch == '=')
        {
            start_index = index+1;
            break;
        }
    }
    for(index = start_index; index < length; index++)
    {
        unichar ch = [str_url characterAtIndex:index];
        if(ch == '&')
        {
            end_index = index;
            break;
        }
    }
    str_token = [str_url substringWithRange:NSMakeRange(start_index, end_index - start_index)];
    return str_token;
}

@end
