//
//  CTBaseService.m
//  CTNetworking
//
//  Created by xiaojing.shi on 2019/4/26.
//  Copyright © 2019 casa. All rights reserved.
//

#import "CTBaseService.h"

@interface CTBaseService ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) AFHTTPRequestSerializer *httpRequestSerializer;
@property (nonatomic, strong) AFJSONRequestSerializer *jsonRequestSerializer;

@end

@implementation CTBaseService

@synthesize apiEnvironment;

#pragma mark - public methods
- (NSURLRequest *)requestWithParams:(NSDictionary *)params methodName:(NSString *)methodName
                        requestType:(CTAPIManagerRequestType)requestType
                 requestContentType:(CTAPIManagerRequestContentType)requestContentType
{
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", self.baseURL, methodName];
    NSString *reqTypeStr = CTAPIManagerRequestTypeStringForType(requestType);
    
    AFHTTPRequestSerializer *requestSerializer = self.httpRequestSerializer;
    if (requestContentType == CTAPIManagerRequestContentTypeApplicationJson) {
        requestSerializer = self.jsonRequestSerializer;
    }
    
    if (requestContentType == CTAPIManagerRequestContentTypeMultipartFormData) {
        NSMutableURLRequest *request = [requestSerializer multipartFormRequestWithMethod:reqTypeStr
                                                                               URLString:urlString
                                                                              parameters:params
                                                               constructingBodyWithBlock:nil
                                                                                   error:nil];
        return request;
    } else {
        NSMutableURLRequest *request = [requestSerializer requestWithMethod:reqTypeStr
                                                                  URLString:urlString
                                                                 parameters:params
                                                                      error:nil];
        return request;
    }
    
    return nil;
}

//@param files 本地文件地址字典 地址可以为单个或数组 @{@"nameKey": @"filePath", @"nameKey" @[@"filePath", ...]}
- (NSURLRequest *)uploadRequestWithParams:(NSDictionary *)params methodName:(NSString *)methodName
                              requestType:(CTAPIManagerRequestType)requestType
                       requestContentType:(CTAPIManagerRequestContentType)requestContentType
                                    files:(NSDictionary *)files
{
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", self.baseURL, methodName];
    NSString *reqTypeStr = CTAPIManagerRequestTypeStringForType(requestType);
    
    AFHTTPRequestSerializer *requestSerializer = self.httpRequestSerializer;
    if (requestContentType == CTAPIManagerRequestContentTypeApplicationJson) {
        requestSerializer = self.jsonRequestSerializer;
    }
    
    NSMutableURLRequest *request =
    [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:reqTypeStr URLString:urlString parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        if ([files count]) {
            [files enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([obj isKindOfClass:[NSArray class]]) {
                    for (NSString *fileUrl in obj) {
                        NSData *fileData = [[NSData alloc] initWithContentsOfFile:fileUrl];
                        NSString *fileName = [fileUrl lastPathComponent];
                        [formData appendPartWithFileData:fileData
                                                    name:key
                                                fileName:fileName
                                                mimeType:@""];
                    }
                } else if ([obj isKindOfClass:[NSString class]]) {
                    NSData *fileData = [[NSData alloc] initWithContentsOfFile:obj];
                    NSString *fileName = [obj lastPathComponent];
                    [formData appendPartWithFileData:fileData
                                                name:key
                                            fileName:fileName
                                            mimeType:@""];
                }
            }];
        }
        
    } error:nil];
    
    return request;
}

- (NSDictionary *)resultWithResponseObject:(id)responseObject response:(NSURLResponse *)response request:(NSURLRequest *)request error:(NSError **)error
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    if (*error || !responseObject) {
        return result;
    }
    
    if ([responseObject isKindOfClass:[NSData class]]) {
        result[kCTApiProxyValidateResultKeyResponseString] = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        result[kCTApiProxyValidateResultKeyResponseObject] = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:NULL];
    } else {
        //这里的kCTApiProxyValidateResultKeyResponseString是用作打印日志用的，实际使用时可以把实际类型的对象转换成string用于日志打印
        //        result[kCTApiProxyValidateResultKeyResponseString] = responseObject;
        result[kCTApiProxyValidateResultKeyResponseObject] = responseObject;
    }
    
    return result;
}

- (BOOL)handleCommonErrorWithResponse:(CTURLResponse *)response manager:(CTAPIBaseManager *)manager errorType:(CTAPIManagerErrorType)errorType
{
    return YES;
}

#pragma mark - getters and setters
- (NSURL *)baseURL
{
//    if (self.apiEnvironment == CTServiceAPIEnvironmentRelease) {
//        return @"https://gateway.marvel.com:443/v1";
//    }
//    if (self.apiEnvironment == CTServiceAPIEnvironmentDevelop) {
//        return @"https://gateway.marvel.com:443/v1";
//    }
//    if (self.apiEnvironment == CTServiceAPIEnvironmentReleaseCandidate) {
//        return @"https://gateway.marvel.com:443/v1";
//    }
    return nil;
}

- (AFHTTPSessionManager *)sessionManager {
    if (_sessionManager == nil) {
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL];
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        //AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        //_sessionManager.securityPolicy = securityPolicy;
        
        AFJSONResponseSerializer *jsonRespS = [AFJSONResponseSerializer serializer];
        jsonRespS.removesKeysWithNullValues = YES;
        AFHTTPResponseSerializer *httpRespS = [AFHTTPResponseSerializer serializer];
        AFCompoundResponseSerializer *compoundSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[jsonRespS, httpRespS]];
        _sessionManager.responseSerializer = compoundSerializer;
    }
    return _sessionManager;
}

- (CTServiceAPIEnvironment)apiEnvironment
{
    return CTServiceAPIEnvironmentDevelop;
}

- (AFHTTPRequestSerializer *)httpRequestSerializer
{
    if (_httpRequestSerializer == nil) {
        _httpRequestSerializer = [AFHTTPRequestSerializer serializer];
    }
    return _httpRequestSerializer;
}

- (AFJSONRequestSerializer *)jsonRequestSerializer {
    if (_jsonRequestSerializer == nil) {
        _jsonRequestSerializer = [AFJSONRequestSerializer serializer];
    }
    return _jsonRequestSerializer;
}

@end
