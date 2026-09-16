#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

%ctor {
    @autoreleasepool {
        NSLog(@"[TADEV2] dylib loaded into %@ / %@",
              NSProcessInfo.processInfo.processName,
              NSBundle.mainBundle.bundleIdentifier);

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW,
                          (int64_t)(2.0 * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{

            UIAlertController *alert =
                [UIAlertController
                    alertControllerWithTitle:@"TAdev2 INJECTED"
                    message:[NSString stringWithFormat:
                        @"Process: %@\nBundle: %@",
                        NSProcessInfo.processInfo.processName,
                        NSBundle.mainBundle.bundleIdentifier]
                    preferredStyle:UIAlertControllerStyleAlert];

            [alert addAction:
                [UIAlertAction actionWithTitle:@"OK"
                                         style:UIAlertActionStyleDefault
                                       handler:nil]];

            UIWindow *window = nil;

            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *ws = (UIWindowScene *)scene;

                    for (UIWindow *w in ws.windows) {
                        if (w.isKeyWindow) {
                            window = w;
                            break;
                        }
                    }
                }
                if (window) break;
            }

            UIViewController *vc = window.rootViewController;

            while (vc.presentedViewController) {
                vc = vc.presentedViewController;
            }

            if (vc) {
                [vc presentViewController:alert
                                 animated:YES
                               completion:nil];
            }
        });
    }
}
