//
//  Helper.m
//  AllAbout
//
//  Created by Uday Kiran Ailapaka on 09/03/16.
//  Copyright © 2016 Uday Kiran Ailapaka. All rights reserved.
//

#import "Helper.h"
#import "ModelCoordinator.h"
#import <UIKit/UIKit.h>

@implementation Helper
{
    ModelCoordinator *modelCoordinator;
}

- (id)init {
    if (self = [super init]) {
        modelCoordinator = [[ModelCoordinator alloc] init];
        _dataTask = nil;
        _downloadPhotoTask = nil;
    }
    return self;
}

/*
    Fetch Data from DataBase Local
 */
- (void)fetchDataFromDB:(void (^)(NSArray *))completionBlock {
    completionBlock([modelCoordinator fetchData]);
}

/*
    Fetch data from service
 */
- (void)fetchDataFromService:(void (^)(NSArray *))completionBlock {
    
    NSURL *aboutURL = [[NSURL alloc] initWithString:@"https://dl.dropboxusercontent.com/u/746330/facts.json"];
    
    NSURLSessionConfiguration *sessionConfig=[NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session=[NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    self.dataTask=[session dataTaskWithURL:aboutURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil ) {
            NSError *jsonError = nil;
            NSString *str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            NSData *objectData = [str dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&jsonError];
            if (jsonError) {
                NSLog(@"error is %@", [jsonError localizedDescription]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock([modelCoordinator fetchData]);
                });
                // Handle Error and return
            } else {
                NSArray *details = [json objectForKey:@"rows"];
                NSString *country = [json objectForKey:@"title"];
                
                [modelCoordinator saveToDBDetails:(NSArray *)details withCountry:country];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock([modelCoordinator fetchData]);
                });
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock([modelCoordinator fetchData]);
            });
        }
        
    }];
    [self.dataTask resume];
    
}

/*
    Downloads images from service
 */
- (void)fetchImageWithURLString:(NSString *)urlString completionHandler:( void (^)(UIImage *))completionBlock {
    NSURL *photoURL = [[NSURL alloc] initWithString:urlString];
    self.downloadPhotoTask = [[NSURLSession sharedSession]
                              downloadTaskWithURL:photoURL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                  
                                  UIImage *downloadedImage = [UIImage imageWithData:
                                                              [NSData dataWithContentsOfURL:location]];
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      completionBlock(downloadedImage);
                                  });
                              }];
    
    [self.downloadPhotoTask resume];
}

/*
    Cancel already resumed service
 */
- (void)cancelDataTask {
    [self.dataTask cancel];
    [self.downloadPhotoTask cancel];
}

@end
