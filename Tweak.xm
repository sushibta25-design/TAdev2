#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *TAGetLogPath(void) {
    NSString *home = NSHomeDirectory();
    NSString *docs = [home stringByAppendingPathComponent:@"Documents"];

    [[NSFileManager defaultManager]
        createDirectoryAtPath:docs
        withIntermediateDirectories:YES
        attributes:nil
        error:nil];

    return [docs stringByAppendingPathComponent:@"TAdev2_probe.txt"];
}

static void TALog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg =
        [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSString *path = TAGetLogPath();

    NSString *line =
        [NSString stringWithFormat:@"%@ %@\n",
         [NSDate date], msg];

    NSData *data =
        [line dataUsingEncoding:NSUTF8StringEncoding];

    NSFileManager *fm =
        [NSFileManager defaultManager];

    if (![fm fileExistsAtPath:path]) {
        [data writeToFile:path atomically:YES];
    } else {
        NSFileHandle *fh =
            [NSFileHandle fileHandleForWritingAtPath:path];

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
        TALog(@"TAdev2 PROBE V3 LOADED");

        TALog(@"Process=%@",
              NSProcessInfo.processInfo.processName);

        TALog(@"Bundle=%@",
              NSBundle.mainBundle.bundleIdentifier);

        TALog(@"BundlePath=%@",
              NSBundle.mainBundle.bundlePath);

        TALog(@"HOME=%@",
              NSHomeDirectory());

        TALog(@"LOG=%@",
              TAGetLogPath());

        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                (int64_t)(5 * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{

                TALog(@"PROBE ALIVE AFTER 5 SECONDS");

                UIApplication *app =
                    UIApplication.sharedApplication;

                TALog(@"UIApplication=%@", app);

                for (UIScene *scene in app.connectedScenes) {
                    TALog(@"Scene=%@ state=%ld",
                          scene,
                          (long)scene.activationState);
                }
            });
    }
}
