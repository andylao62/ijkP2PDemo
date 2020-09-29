

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocalStreamManager : NSObject

//+ (instancetype)shared;
+ (void)readStreamFromFile:(NSString *)filePath callBack:(void(^)(NSData *streamData, NSInteger width, NSInteger height))callBack;

+ (void)destroy;
@end

NS_ASSUME_NONNULL_END
