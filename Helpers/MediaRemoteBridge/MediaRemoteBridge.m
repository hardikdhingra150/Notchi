// MediaRemoteBridge: reads macOS's system-wide "Now Playing" (any app: Safari,
// Chrome, YouTube, Music, Spotify, Podcasts, VLC…) and sends play/pause/skip.
//
// Since macOS 15.4, MediaRemote only answers processes signed by Apple. So this
// library is loaded into /usr/bin/perl (an Apple binary) by notchi-nowplaying.pl,
// and streams one JSON object per line on stdout for Notchi to read.
// Same approach as the open-source mediaremote-adapter used by other notch apps.

#import <Foundation/Foundation.h>
#import <dlfcn.h>

typedef void (*MRGetInfo)(dispatch_queue_t, void (^)(NSDictionary *));
typedef void (*MRGetIsPlaying)(dispatch_queue_t, void (^)(BOOL));
typedef void (*MRGetPID)(dispatch_queue_t, void (^)(int));
typedef void (*MRRegister)(dispatch_queue_t);
typedef Boolean (*MRSend)(int, NSDictionary *);
typedef void (*MRSetElapsed)(double);

static void *mr(const char *name) {
    static void *h;
    if (!h) h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
    return h ? dlsym(h, name) : NULL;
}

static void emit(NSDictionary *obj) {
    NSData *d = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    if (!d) return;
    fwrite(d.bytes, 1, d.length, stdout);
    fputc('\n', stdout);
    fflush(stdout);
}

static NSUInteger lastArtHash;

static void refresh(void) {
    MRGetInfo getInfo = (MRGetInfo)mr("MRMediaRemoteGetNowPlayingInfo");
    MRGetIsPlaying getPlaying = (MRGetIsPlaying)mr("MRMediaRemoteGetNowPlayingApplicationIsPlaying");
    MRGetPID getPID = (MRGetPID)mr("MRMediaRemoteGetNowPlayingApplicationPID");
    if (!getInfo || !getPlaying || !getPID) { emit(@{@"error": @"MediaRemote unavailable"}); return; }
    dispatch_queue_t q = dispatch_get_main_queue();
    getInfo(q, ^(NSDictionary *info) {
        getPlaying(q, ^(BOOL playing) {
            getPID(q, ^(int pid) {
                NSMutableDictionary *o = [NSMutableDictionary dictionary];
                NSString *title = info[@"kMRMediaRemoteNowPlayingInfoTitle"];
                if (title.length == 0) { emit(@{@"empty": @YES}); return; }
                o[@"title"] = title;
                o[@"artist"] = info[@"kMRMediaRemoteNowPlayingInfoArtist"] ?: @"";
                o[@"album"] = info[@"kMRMediaRemoteNowPlayingInfoAlbum"] ?: @"";
                o[@"playing"] = @(playing);
                o[@"pid"] = @(pid);
                NSNumber *dur = info[@"kMRMediaRemoteNowPlayingInfoDuration"];
                NSNumber *el = info[@"kMRMediaRemoteNowPlayingInfoElapsedTime"];
                NSNumber *rate = info[@"kMRMediaRemoteNowPlayingInfoPlaybackRate"];
                NSDate *ts = info[@"kMRMediaRemoteNowPlayingInfoTimestamp"];
                if (dur) o[@"duration"] = dur;
                if (el) o[@"elapsed"] = el;
                if (rate) o[@"rate"] = rate;
                if ([ts isKindOfClass:[NSDate class]]) o[@"timestamp"] = @(ts.timeIntervalSince1970);
                NSData *art = info[@"kMRMediaRemoteNowPlayingInfoArtworkData"];
                if ([art isKindOfClass:[NSData class]] && art.length > 0) {
                    NSUInteger h = art.hash ^ art.length;
                    if (h != lastArtHash) { lastArtHash = h; o[@"artwork"] = [art base64EncodedStringWithOptions:0]; }
                    else o[@"artworkSame"] = @YES;
                } else {
                    lastArtHash = 0;
                }
                emit(o);
            });
        });
    });
}

// Called from perl. XS signature (interpreter, CV), which we ignore. Never returns.
void notchi_stream(void *interp, void *cv) {
    @autoreleasepool {
        MRRegister reg = (MRRegister)mr("MRMediaRemoteRegisterForNowPlayingNotifications");
        if (!reg) { emit(@{@"error": @"MediaRemote unavailable"}); exit(1); }
        reg(dispatch_get_main_queue());
        NSArray *names = @[
            @"kMRMediaRemoteNowPlayingInfoDidChangeNotification",
            @"kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification",
            @"kMRMediaRemoteNowPlayingApplicationDidChangeNotification",
            @"kMRMediaRemoteNowPlayingApplicationClientStateDidChange",
        ];
        for (NSString *n in names) {
            [[NSNotificationCenter defaultCenter] addObserverForName:n object:nil queue:nil usingBlock:^(NSNotification *note) { refresh(); }];
        }
        // stop when Notchi goes away (stdin closes)
        dispatch_source_t src = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, STDIN_FILENO, 0, dispatch_get_main_queue());
        dispatch_source_set_event_handler(src, ^{
            char buf[64];
            if (read(STDIN_FILENO, buf, sizeof buf) <= 0) exit(0);
        });
        dispatch_resume(src);
        refresh();
        [[NSRunLoop mainRunLoop] run];
    }
}

// Called from perl with NOTCHI_MR_COMMAND set: play, pause, toggle, next, previous, or seek (NOTCHI_MR_ARG seconds).
void notchi_command(void *interp, void *cv) {
    const char *c = getenv("NOTCHI_MR_COMMAND");
    if (!c) return;
    if (strcmp(c, "seek") == 0) {
        MRSetElapsed set = (MRSetElapsed)mr("MRMediaRemoteSetElapsedTime");
        const char *a = getenv("NOTCHI_MR_ARG");
        if (set && a) set(atof(a));
        return;
    }
    int cmd = -1;
    if (strcmp(c, "play") == 0) cmd = 0;
    else if (strcmp(c, "pause") == 0) cmd = 1;
    else if (strcmp(c, "toggle") == 0) cmd = 2;
    else if (strcmp(c, "next") == 0) cmd = 4;
    else if (strcmp(c, "previous") == 0) cmd = 5;
    MRSend send = (MRSend)mr("MRMediaRemoteSendCommand");
    if (send && cmd >= 0) send(cmd, nil);
}
