#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString * const TAProbePath = @"/var/mobile/TAdev2_probe.txt";

static void TALog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSString *line = [NSString stringWithFormat:
                      @"%@ %@\n",
                      [NSDate date],
                      msg];

    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];

    NSFileManager *fm = [NSFileManager defaultManager];

    if (![fm fileExistsAtPath:TAProbePath]) {
        [data writeToFile:TAProbePath atomically:YES];
    } else {
        NSFileHandle *fh =
            [NSFileHandle fileHandleForWritingAtPath:TAProbePath];

        if (fh) {
            [fh seekToEndOfFile];
            [fh writeData:data];
            [fh closeFile];
        }
    }

    NSLog(@"[TADEV2] %@", msg);
}

%ctor {
    @autoreleasepool {
        TALog(@"================================");
        TALog(@"TAdev2 PROBE V2 LOADED");
        TALog(@"Process = %@", NSProcessInfo.processInfo.processName);
        TALog(@"Bundle  = %@", NSBundle.mainBundle.bundleIdentifier);
        TALog(@"BundlePath = %@", NSBundle.mainBundle.bundlePath);
        TALog(@"Home = %@", NSHomeDirectory());

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW,
                          (int64_t)(3.0 * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{

                TALog(@"App alive after 3 seconds");

                UIApplication *app = UIApplication.sharedApplication;

                TALog(@"UIApplication = %@", app);

                for (UIScene *scene in app.connectedScenes) {
                    TALog(@"Scene = %@ state=%ld",
                          scene,
                          (long)scene.activationState);
                }
            });
    }
}
