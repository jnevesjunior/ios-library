/* Copyright Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAInboxMessageData+Internal.h"

#import "UAAirshipMessageCenterCoreImport.h"

#define kUACoreDataStoreName @"Inbox-%@.sqlite"
#define kUACoreDataDirectory @"UAInbox"
#define kUAInboxDBEntityName @"UAInboxMessage"

@class UARuntimeConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 * Manager class for the Rich Push CoreData store. Use this class
 * to add, delete, fetch and update messages in the database.
 */
@interface UAInboxStore : NSObject


///---------------------------------------------------------------------------------------
/// @name Inbox Database Manager Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method for automation store.
 *
 * @param storeName The store name.
 * @param inMemory Whether to use an in-memory database. If `NO` the store will default to SQLite.

 * @return Automation store.
 */
+ (instancetype)storeWithName:(NSString *)storeName inMemory:(BOOL)inMemory;

/**
 * Factory method for automation store.
 *
 * @param storeName The store name.
 * @return Automation store.
 */
+ (instancetype)storeWithName:(NSString *)storeName;

/**
 * Fetches messages with a specified predicate on the background context.
 *
 * @param predicate An NSPredicate querying a subset of messages.
 * @param completionHandler An optional completion handler called when the fetch is complete.
 */
- (void)fetchMessagesWithPredicate:(nullable NSPredicate *)predicate
                 completionHandler:(void(^)(NSArray<UAInboxMessageData *>*messages))completionHandler;

/**
 * Deletes a list of message IDs.
 *
 * @param messageIDs The list of message IDs to delete.
 */
- (void)deleteMessagesWithIDs:(NSArray<NSString *> *)messageIDs;

/**
 * Updates the inbox store with the array of messages.
 *
 * @param messages An array of messages.
 * @param completionHandler The completion handler with the sync result.
 *
 */
- (void)syncMessagesWithResponse:(NSArray *)messages
               completionHandler:(void(^)(BOOL))completionHandler;


/**
 * Waits for the store to become idle and then returns. Used by Unit Tests.
 */
- (void)waitForIdle;

/**
 * Shuts down the store and prevents any subsequent interaction with the managed context. Used by Unit Tests.
 */
- (void)shutDown;

@end

NS_ASSUME_NONNULL_END
