#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN



@interface BroadcastController : NSObject <RPBroadcastActivityViewControllerDelegate>

typedef void(^BroadcastCompletion)(NSError * _Nullable error);

@property (nonatomic, copy, nullable) BroadcastCompletion broadcastCompletion;

- (void)requestBroadcastWithCompletion:(BroadcastCompletion)completion;

- (void)stopBroadcast;

@end

NS_ASSUME_NONNULL_END

