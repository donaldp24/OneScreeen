//
//  ServerGateway.m
//
//  Created by Igor Ishchenko on 12/20/13.
//  Copyright (c) 2013 Igor Ishchenko All rights reserved.
//

#import "ServerGateway.h"
#import "SBJSON.h"
#import "NSString+UrlEncoding.h"

static NSString * const kServerURL = @"http://f2170reports.com/index.php?";
static NSString * const kMultipartBoundary = @"-------------111";

static NSString * const kErrorKey = @"error";
static NSString * const kErrorDescriptionKey = @"error_description";

static NSString * const kErrorDomain = @"DMIOSNETWORKERROR";

@implementation ServerGateway

- (void)lookupSSN:(NSString *)ssn accessToken:(NSString *)accessToken complete:(void (^)(NSDictionary *, NSString *))block {
    NSString *getString = [NSString stringWithFormat:@"action=mod_reports_api&method=ssn_lookup&access_token=%@&ssn=%@",accessToken,ssn];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kServerURL, getString];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [request setURL:url];
    
    [request setHTTPMethod:@"GET"];
    
    __block NSString *serialNumber = [ssn copy];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!response) {
                                   block(nil, serialNumber);
                                   return;
                               }
                               
                               NSString *responseString = [[NSString alloc] initWithData:data
                                                                                encoding:NSUTF8StringEncoding];
                               SBJSON *parser = [[SBJSON alloc] init];
                               NSDictionary *dict = [parser objectWithString:responseString];
                               
                               NSLog(@"sn: %@", serialNumber);
                               
                               block(dict, serialNumber);
                           }];
}

- (void)uploadDataFileContents:(NSData *)data
                    atFilePath:(NSString *)filePath
                   accessToken:(NSString *)accessToken
                      complete:(void (^)(NSError *))block
{
    NSString *fileName = [filePath lastPathComponent];
    NSString *paramString = [NSString stringWithFormat:@"action=mod_reports_api&method=upload&access_token=%@", accessToken];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kServerURL, paramString]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kMultipartBoundary];
	[request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
	NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", kMultipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileName]] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-type: application/octet-stream\r\n\r\n" dataUsingEncoding: NSUTF8StringEncoding]];
	[body appendData:data];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", kMultipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@", @"target_rh"  , @"90"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", kMultipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody: body];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               NSString *responseString = [[NSString alloc] initWithData:data
                                                                                 encoding:NSUTF8StringEncoding];
                               
                               NSLog(@"RECEIVED DATA : %@", responseString);
                               
                               SBJSON *parser = [[SBJSON alloc] init];
                               NSDictionary *dict = [parser objectWithString:responseString];
                               
                               if (!response || dict[kErrorKey]) {
                                   
                                   NSError *error = [NSError errorWithDomain:kErrorDomain
                                                                        code:GatewayErrorInvalidGrant
                                                                    userInfo:@{NSLocalizedDescriptionKey: dict[kErrorDescriptionKey]}];
                                   block(error);
                                   return;
                               }
                               block(nil);
                           }];
}


- (void)loginWithUsername:(NSString *)username password: (NSString*)password complete:(void (^)(NSString *))block {

    NSString * authRequestURL = [NSString stringWithFormat:@"%@%@", kServerURL, @"action=auth&step=token"];
    //    NSString * username = @"ishiwata";
    //    NSString * password = @"Ishiwata1";
    NSString * paramString = [NSString stringWithFormat:@"grant_type=password&client_id=mainapp&client_secret=a5722d862fbb013facf471a4ff6f6893&username=%@&password=%@", username, password ];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", authRequestURL]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];

    NSString *contentType = @"application/x-www-form-urlencoded";
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];

    NSMutableData *body = [NSMutableData data];
    [body appendData:[paramString dataUsingEncoding: NSUTF8StringEncoding]];
    [request setHTTPBody:body];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

                               //NSError * error = nil;

                               SBJSON *parser = [[SBJSON alloc] init];
                               NSDictionary *dict = [parser objectWithString:responseString];
                               NSString * accessToken = [dict valueForKey:@"access_token"];

                               NSLog(@"RECEIVED DATA : %@", responseString);
                               NSLog(@"ACCESS TOKEN : %@", accessToken);
                               if(accessToken) {
                                   block(accessToken);
                               }
                               else {
                                   block(nil);
                               }
                           }];
}

- (void)storeCalCheck:(NSString *)ssn rh:(int)rh temp:(int)temp salt_name:(NSString *)salt_name date:(NSString *)date accessToken:(NSString *)access complete:(void (^)(BOOL))block {

    NSString *getString = [NSString stringWithFormat:@"action=mod_reports_api&method=upload_cal_check&access_token=%@&ssn=%@&rh=%d&temp=%d&salt_name=%@&date=%@", access, ssn, rh, temp, [salt_name urlencode], [date urlencode]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kServerURL, getString];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [request setURL:url];
    
    [request setHTTPMethod:@"GET"];
    
    NSLog(@"request : %@", url);
    
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!response) {
                                   block(NO);
                                   NSLog(@"store failed : %@", connectionError);
                                   return;
                               }
                               
                               NSString *responseString = [[NSString alloc] initWithData:data
                                                                                encoding:NSUTF8StringEncoding];
                               SBJSON *parser = [[SBJSON alloc] init];
                               NSDictionary *dict = [parser objectWithString:responseString];
                               
                               NSLog(@"response for storeData: %@", dict);
                               
                               NSNumber *success = [dict objectForKey:@"success"];
                               block([success boolValue]);
                           }];
}

- (void)retrieveCalCheck:(NSString *)ssn first:(BOOL)first accessToken:(NSString *)access complete:(void (^)(NSDictionary *))block {
    
    NSString *getString = [NSString stringWithFormat:@"action=mod_reports_api&method=get_cal_check&access_token=%@&ssn=%@", access, ssn];
    if (first)
        getString = [NSString stringWithFormat:@"%@&oldest=true", getString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kServerURL, getString];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [request setURL:url];
    
    [request setHTTPMethod:@"GET"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!response) {
                                   block(nil);
                                   return;
                               }
                               
                               NSString *responseString = [[NSString alloc] initWithData:data
                                                                                encoding:NSUTF8StringEncoding];
                               SBJSON *parser = [[SBJSON alloc] init];
                               NSDictionary *dict = [parser objectWithString:responseString];
                               
                               NSLog(@"response for retrieveData: %@", dict);
                               
                               block(dict);

                           }];
}


@end
