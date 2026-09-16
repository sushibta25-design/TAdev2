#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <sys/socket.h>
#import <dlfcn.h>
#import <substrate.h>
#import <unistd.h>

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
            [data writeToFile:path atomically:YES];
        } else {
            NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
            if (fh) {
                [fh seekToEndOfFile];
                [fh writeData:data];
                [fh closeFile];
            }
        }
    }
    NSLog(@"[TADEV2] %@", msg);
}

static BOOL TAIsRTSPSocket(int fd) {
    struct sockaddr_storage ss;
    socklen_t slen = sizeof(ss);
    if (getpeername(fd, (struct sockaddr *)&ss, &slen) != 0) return NO;

    if (ss.ss_family == AF_INET) {
        struct sockaddr_in *a = (struct sockaddr_in *)&ss;
        return ntohs(a->sin_port) == 554;
    }
    if (ss.ss_family == AF_INET6) {
        struct sockaddr_in6 *a6 = (struct sockaddr_in6 *)&ss;
        return ntohs(a6->sin6_port) == 554;
    }
    return NO;
}

static void TALogRTSPBytes(NSString *direction, int fd, const void *buf, size_t len) {
    if (!buf || len == 0 || !TAIsRTSPSocket(fd)) return;

    size_t cap = MIN(len, (size_t)8192);
    NSData *data = [NSData dataWithBytes:buf length:cap];
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if (s.length) {
        NSString *clean = [s stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
        clean = [clean stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n\n"];
        TALog(@"RTSP %@ fd=%d len=%zu\n%@", direction, fd, len, clean);
    } else {
        TALog(@"RTSP %@ fd=%d len=%zu [binary/non-UTF8]", direction, fd, len);
    }
}

%hook NSMutableURLRequest
- (void)setURL:(NSURL *)url {
    TALog(@"REQUEST setURL=%@", url ? url.absoluteString : @"(null)");
    %orig;
}
%end

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                           completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    TALog(@"NSURLSession DATA method=%@ url=%@",
          request.HTTPMethod ?: @"GET",
          request.URL.absoluteString ?: @"(null)");
    return %orig;
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url
                       completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    TALog(@"NSURLSession URL=%@", url.absoluteString ?: @"(null)");
    return %orig;
}
%end

static int (*orig_connect)(int, const struct sockaddr *, socklen_t);
static ssize_t (*orig_send)(int, const void *, size_t, int);
static ssize_t (*orig_recv)(int, void *, size_t, int);
static ssize_t (*orig_write)(int, const void *, size_t);
static ssize_t (*orig_read)(int, void *, size_t);

static int ta_connect(int sockfd, const struct sockaddr *addr, socklen_t len) {
    if (addr) {
        char ip[INET6_ADDRSTRLEN] = {0};
        int port = 0;

        if (addr->sa_family == AF_INET) {
            const struct sockaddr_in *a = (const struct sockaddr_in *)addr;
            if (inet_ntop(AF_INET, &(a->sin_addr), ip, sizeof(ip))) {
                port = ntohs(a->sin_port);
                TALog(@"CONNECT IPv4 %s:%d fd=%d", ip, port, sockfd);
            }
        } else if (addr->sa_family == AF_INET6) {
            const struct sockaddr_in6 *a6 = (const struct sockaddr_in6 *)addr;
            if (inet_ntop(AF_INET6, &(a6->sin6_addr), ip, sizeof(ip))) {
                port = ntohs(a6->sin6_port);
                TALog(@"CONNECT IPv6 %s:%d fd=%d", ip, port, sockfd);
            }
        }
    }
    return orig_connect(sockfd, addr, len);
}

static ssize_t ta_send(int fd, const void *buf, size_t len, int flags) {
    TALogRTSPBytes(@"SEND", fd, buf, len);
    return orig_send(fd, buf, len, flags);
}

static ssize_t ta_recv(int fd, void *buf, size_t len, int flags) {
    ssize_t n = orig_recv(fd, buf, len, flags);
    if (n > 0) TALogRTSPBytes(@"RECV", fd, buf, (size_t)n);
    return n;
}

static ssize_t ta_write(int fd, const void *buf, size_t len) {
    TALogRTSPBytes(@"WRITE", fd, buf, len);
    return orig_write(fd, buf, len);
}

static ssize_t ta_read(int fd, void *buf, size_t len) {
    ssize_t n = orig_read(fd, buf, len);
    if (n > 0) TALogRTSPBytes(@"READ", fd, buf, (size_t)n);
    return n;
}

%ctor {
    @autoreleasepool {
        TALog(@"TAdev2 V3 loaded process=%@ bundle=%@",
              [NSProcessInfo processInfo].processName ?: @"(null)",
              [NSBundle mainBundle].bundleIdentifier ?: @"(null)");

        MSHookFunction((void *)&connect, (void *)&ta_connect, (void **)&orig_connect);
        MSHookFunction((void *)&send, (void *)&ta_send, (void **)&orig_send);
        MSHookFunction((void *)&recv, (void *)&ta_recv, (void **)&orig_recv);
        MSHookFunction((void *)&write, (void *)&ta_write, (void **)&orig_write);
        MSHookFunction((void *)&read, (void *)&ta_read, (void **)&orig_read);
    }
}
