#import <Foundation/Foundation.h>
#import "BroadcastController.h"

NSString *const kRTCBroadcastManagerScreenSharingExtension = @"RTCScreenSharingExtension";

@interface BroadcastController (Private) <RPBroadcastActivityViewControllerDelegate>

@property (nonatomic, strong, nullable) RPBroadcastController *broadcastController;

@property (nonatomic) NSString *preferredExtension;

@end


@implementation BroadcastController

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)requestBroadcastWithCompletion:(BroadcastCompletion)completion {
    UIViewController * rootViewController = [self rootViewController];

    if(!rootViewController){
        NSError * notRootVCError = [NSError errorWithDomain:@"RPBroadcast"
                                                      code:-3
                                                   userInfo:@{NSLocalizedDescriptionKey : @"No rootViewController found."}];
        
        completion(notRootVCError);
        return;
    }
    
    self.broadcastCompletion = completion;
    
    [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithPreferredExtension:self.preferredExtension handler:^(RPBroadcastActivityViewController * _Nullable broadcastAVC, NSError * _Nullable error){
        
        if (error){
            if(self.broadcastCompletion){
                self.broadcastCompletion(error);
                self.broadcastCompletion = nil;
            }
            return;
        }
        
        if(!broadcastAVC){
            NSError * noBroadcastACVError = [NSError errorWithDomain:@"RPBroadcast"
                                                          code:-4
                                                       userInfo:@{NSLocalizedDescriptionKey : @"RPBroadcastActivityViewController is nil"}];
            completion(noBroadcastACVError);
            return;
        }
        
        broadcastAVC.delegate = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [rootViewController presentViewController:broadcastAVC animated: YES completion: nil];
        });
        
    }];
}

- (void)stopBroadcast {
    if(self.broadcastController.isBroadcasting){
        [self.broadcastController finishBroadcastWithHandler:^(NSError * _Nullable error) {
            if(error){
                NSLog(@"Failed to stop broadcast: %@", error.localizedDescription);
            } else {
                NSLog(@"Stop broadcast successfully");
                self.broadcastController = nil;
            }
        }];
    }
}

- (nullable UIViewController *)rootViewController {
    __block UIViewController *rootViewController = nil;
    
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        if (@available(iOS 13, *)){
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if(scene.activationState == UISceneActivationStateForegroundActive) {
                    keyWindow = scene.windows.firstObject;
                    if(keyWindow) {
                        break;
                    }
                }
            }
        } else {
            keyWindow = [UIApplication sharedApplication].keyWindow;
        }
        rootViewController = keyWindow.rootViewController;
    });
    
    return rootViewController;
}

- (NSString *)preferredExtension {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return infoDictionary[kRTCBroadcastManagerScreenSharingExtension];
}


#pragma mark - RPBroadcastActivityViewControllerDelegate

- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(nullable RPBroadcastController *)broadcastController error:(nullable NSError *)error {
    
    [broadcastActivityViewController dismissViewControllerAnimated:YES completion: ^{
        if(error){
            if(self.broadcastCompletion){
                self.broadcastCompletion(error);
                self.broadcastCompletion = nil;
            }
            return;
        }
        
        if(!broadcastController){
            if(self.broadcastCompletion){
                NSError * cancelError = [NSError errorWithDomain:@"RPBroadcast"
                                                              code:-5
                                                           userInfo:@{NSLocalizedDescriptionKey : @"Cancel error"}];
                self.broadcastCompletion(cancelError);
                self.broadcastCompletion = nil;
            }
            return;
        }
        
        self.broadcastController = broadcastController;
        
        [broadcastController startBroadcastWithHandler:^(NSError * _Nullable startError) {
            if(startError){
                NSLog(@"Failed to start broadcast: %@", startError.localizedDescription);
                if(self.broadcastCompletion){
                    self.broadcastCompletion(startError);
                    self.broadcastCompletion = nil;
                }
            } else {
                NSLog(@"Broadcast started successfully.");
                if(self.broadcastCompletion){
                    self.broadcastCompletion(nil);
                    self.broadcastCompletion = nil;
                }
            }
        }];
    }];
}


@end
