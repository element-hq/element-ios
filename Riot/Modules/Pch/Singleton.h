// .h
#define singleton_interface(class) + (instancetype)shared##class; \
+ (void)froceDealloc;\

// .m
#define singleton_implementation(class) \
static class *_instance; \
static dispatch_once_t onceToken; \
\
+ (id)allocWithZone:(struct _NSZone *)zone \
{ \
    dispatch_once(&onceToken, ^{ \
        _instance = [super allocWithZone:zone]; \
    }); \
\
    return _instance; \
} \
\
+ (instancetype)shared##class \
{ \
    if (_instance == nil) { \
        _instance = [[class alloc] init]; \
    } \
\
    return _instance; \
} \
+ (void)froceDealloc{ \
   _instance = nil; \
    onceToken = 0; \
}
