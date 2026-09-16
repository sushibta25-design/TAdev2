#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <arpa/inet.h>
#import <netdb.h>
#import <sys/socket.h>
#import <dlfcn.h>
#import <substrate.h>

static NSString *TAPath(void) {
    return [NSHomeDirectory() stringByAppendingPathComponent:
            @"Documents/TAdev2_network.txt"];
}

static void TALog(NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);

    NSString *msg =
        [[NSString alloc] initWithFormat:fmt arguments:args];

    va_end(args);

    NSString *line =
        [NSString stringWithFormat:@"%@ %@\n",
         [NSDate date],
         msg];

    NSData *data =
        [line dataUsingEncoding:NSUTF8StringEncoding];

    NSString *path = TAPath();

    @synchronized([NSFileManager class]) {

        if (![[NSFileManager defaultManager]
              fileExistsAtPath:path]) {

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
    }

    NSLog(@"[TADEV2] %@", msg);
}


%hook NSMutableURLRequest

- (void)setURL:(NSURL *)url {

    TALog(@"REQUEST setURL=%@",
          url ? url.absoluteString : @"(null)");

    %orig;
}

%end


%hook NSURLSession

- (NSURLSessionDataTask *)
dataTaskWithRequest:(NSURLRequest *)request
completionHandler:
    (void (^)(NSData *,
              NSURLResponse *,
              NSError *))completionHandler {

    TALog(@"NSURLSession DATA method=%@ url=%@",
          request.HTTPMethod ?: @"GET",
          request.URL.absoluteString ?: @"(null)");

    return %orig;
}


- (NSURLSessionDataTask *)
dataTaskWithURL:(NSURL *)url
completionHandler:
    (void (^)(NSData *,
              NSURLResponse *,
              NSError *))completionHandler {

    TALog(@"NSURLSession URL=%@",
          url.absoluteString ?: @"(null)");

    return %orig;
}

%end


static int (*orig_connect)(
    int,
    const struct sockaddr *,
    socklen_t
);


static int ta_connect(
    int sockfd,
    const struct sockaddr *addr,
    socklen_t len
) {

    if (addr) {

        char ip[INET6_ADDRSTRLEN] = {0};
        int port = 0;

        if (addr->sa_family == AF_INET) {

            const struct sockaddr_in *a =
                (const struct sockaddr_in *)addr;

            inet_ntop(
                AF_INET,
                &(a->sin_addr),
                ip,
                sizeof(ip)
            );

            port = ntohs(a->sin_port);

            TALog(@"CONNECT IPv4 %s:%d",
                  ip,
                  port);

        } else if (addr->sa_family == AF_INET6) {

            const struct sockaddr_in6 *a6 =
                (
