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

- (void)lookupSSN:(NSString *)ssn accessToken:(NSString *)accessToken {
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
                                   [[self delegate] serverGatewaydidFailLookup:self];
                                   return;
                               }
                               
                               NSString *responseString = [[NSString alloc] initWithData:data
                                                                                encoding:NSUTF8StringEncoding];
                               SBJSON *parser = [[SBJSON alloc] init];
                               NSDictionary *dict = [parser objectWithString:responseString];
                               
                               NSLog(@"sn: %@", serialNumber);
                               
                               [[self delegate] serverGateway:self
                                              didFinishLookup:dict
                                                       forSSN:serialNumber];
                           }];
}

- (void)uploadDataFileContents:(NSData *)data
                    atFilePath:(NSString *)filePath
                   accessToken:(NSString *)accessToken
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
                                   [[self delegate] serverGatewaydidFailUpload:self withError:error];
                                   return;
                               }
                               
                               
                               
                               [[self delegate] serverGateway:self didFinishUploadingFile:nil];
                           }];
}


- (void)loginWithUsername:(NSString *)username password: (NSString*)password {

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

                               [[self delegate] serverGatewayDidExtractAccessToken:accessToken];
                               }
                               else {
                                   [[self delegate]serverGatewayDidFailExtractAccessToken:accessToken];
                               }
                           }];
}

- (void)storeData:(NSDictionary *)data accessToken:(NSString *)access {
    NSString *ssn = data[kDataSensorSerialKey];
    NSNumber *rh = data[kDataRhKey];
    NSNumber *temp = data[kDataTempKey];
    NSString *salt_name = data[kDataSaltSolutionKey];
    NSString *date = data[kDataDateKey];
    
    NSString *getString = [NSString stringWithFormat:@"action=mod_reports_api&method=upload_cal_check&access_token=%@&ssn=%@&rh=%d&temp=%d&salt_name=%@&date=%@", access, ssn, [rh intValue], [temp intValue], [salt_name urlencode], [date urlencode]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kServerURL, getString];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [request setURL:url];
    
    [request setHTTPMethod:@"GET"];
    
    NSLog(@"request : %@", url);
    
    NSDictionary *storingData = data;
    
    //__block NSString *serialNumber = [ssn copy];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!response) {
                                   [[self delegate] serverGatewayDidStore:storingData withResponse:nil];
                                   NSLog(@"store failed : %@", connectionError);
                                   return;
                               }
                               
                               NSString *responseString = [[NSString alloc] initWithData:data
                                                                                encoding:NSUTF8StringEncoding];
                               SBJSON *parser = [[SBJSON alloc] init];
                               NSDictionary *dict = [parser objectWithString:responseString];
                               
                               NSLog(@"response for storeData: %@", dict);
                               
                               [[self delegate] serverGatewayDidStore:storingData withResponse:dict];
                           }];
}

- (void)retrieveData:(NSString *)ssn first:(BOOL)first accessToken:(NSString *)access {
    
    NSString *getString = [NSString stringWithFormat:@"action=mod_reports_api&method=get_cal_check&access_token=%@&ssn=%@", access, ssn];
    if (first)
        getString = [NSString stringWithFormat:@"%@&oldest=true", getString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kServerURL, getString];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [request setURL:url];
    
    [request setHTTPMethod:@"GET"];
    
    //__block NSString *serialNumber = [ssn copy];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!response) {
                                   [[self delegate] serverGatewayDidRetrieve:ssn data:nil];
                                   return;
                               }
                               
                               NSString *responseString = [[NSString alloc] initWithData:data
                                                                                encoding:NSUTF8StringEncoding];
                               SBJSON *parser = [[SBJSON alloc] init];
                               NSDictionary *dict = [parser objectWithString:responseString];
                               
                               NSLog(@"response for retrieveData: %@", dict);
                               
                               if (!first)
                                   [[self delegate] serverGatewayDidRetrieve:ssn data:dict];
                               else
                                   [[self delegate] serverGatewayDidRetrieveFirst:ssn data:dict];
                           }];
}


@end
