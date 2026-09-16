#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <arpa/inet.h>
#import <netdb.h>
#import <sys/socket.h>
#import <dlfcn.h>

static NSString *TAPath(void) {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/TAdev2_network.txt"];
}

static void TALog(NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);

    NSString *line = [NSString stringWithFormat:@"%@ %@\n", [NSDate date], msg];
    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];

    NSString *path = TAPath();

    @synchronized([NSFileManager class]) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [data writeToFile:path atomically
