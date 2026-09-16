#import <Foundation/Foundation.h>

static NSString *const TADEVLogPath = @"/var/mobile/TAdev2.log";

static void TADEVLog(NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSString *line = [NSString stringWithFormat:@"%@ %@\n", [NSDate date], msg];
    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:TADEVLogPath]) [data writeToFile:TADEVLogPath atomically:YES];
    else {
        NSFileHandle *h = [NSFileHandle fileHandleForWritingAtPath:TADEVLogPath];
        [h seekToEndOfFile]; [h writeData:data]; [h closeFile];
    }
}

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    TADEVLog(@"[HTTP] %@ %@", request.HTTPMethod ?: @"GET", request.URL.absoluteString ?: @"");
    return %orig;
}
%end

%hook NSURLSessionTask
- (void)resume {
    NSURLRequest *r = self.currentRequest ?: self.originalRequest;
    if (r.URL) TADEVLog(@"[TASK] %@", r.URL.absoluteString);
    %orig;
}
%end

%ctor {
    @autoreleasepool {
        TADEVLog(@"[START] process=%@ bundle=%@", NSProcessInfo.processInfo.processName, NSBundle.mainBundle.bundleIdentifier);
    }
}
