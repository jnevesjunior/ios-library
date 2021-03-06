
#import "UAInAppMessage+Internal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Util methods for in-app message events.
 */
@interface UAInAppMessageEventUtils : NSObject

/**
 * Creates common event data for dispaly and resolution events.
 *
 *
 * @param messageID The message ID.
 * @param source The message source.
 * @param campaigns The campaigns info.
 * @return In-app message event data.
 */
+ (NSMutableDictionary *)createDataWithMessageID:(NSString *)messageID
                                          source:(UAInAppMessageSource)source
                                       campaigns:(nullable NSDictionary  *)campaigns;

@end

NS_ASSUME_NONNULL_END

