@import XCTest;

#import "NSManagedObject+ANDYObjectIDs.h"

#import "User.h"

#import "DATAStack.h"

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)configureUserWithRemoteID:(NSNumber *)remoteID
                          localID:(NSString *)localID
                             name:(NSString *)name
                            block:(void (^)(User *user, NSManagedObjectContext *context))block
{
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Tests"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    [stack performInNewBackgroundContext:^(NSManagedObjectContext *context) {
        User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                   inManagedObjectContext:context];
        user.remoteID = remoteID;
        user.localID = localID;
        user.name = name;

        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"error saving: %@", error);
            abort();
        }

        if (block) {
            block (user, context);
        }
    }];

}

- (void)testDictionary
{
    [self configureUserWithRemoteID:@1 localID:nil name:@"Joshua" block:^(User *user, NSManagedObjectContext *context) {
        NSDictionary *dictionary = [NSManagedObject andy_dictionaryOfIDsAndFetchedIDsInContext:context
                                                                                 usingLocalKey:@"remoteID"
                                                                                 forEntityName:@"User"];
        XCTAssertNotNil(dictionary);
        XCTAssertTrue(dictionary.count == 1);
        XCTAssertEqualObjects(dictionary[@1], user.objectID);

        NSManagedObjectID *objectID = dictionary[@1];
        User *retreivedUser = (User *)[context objectWithID:objectID];
        XCTAssertEqualObjects(retreivedUser.remoteID, @1);
        XCTAssertEqualObjects(retreivedUser.name, @"Joshua");
    }];
}

- (void)testDictionaryStringLocalKey
{
    [self configureUserWithRemoteID:nil localID:@"100" name:@"Joshua" block:^(User *user, NSManagedObjectContext *context) {
        NSDictionary *dictionary = [NSManagedObject andy_dictionaryOfIDsAndFetchedIDsInContext:context
                                                                                 usingLocalKey:@"localID"
                                                                                 forEntityName:@"User"];

        XCTAssertNotNil(dictionary);
        XCTAssertTrue(dictionary.count == 1);
        XCTAssertEqualObjects(dictionary[@"100"], user.objectID);

        NSManagedObjectID *objectID = dictionary[@"100"];
        User *retreivedUser = (User *)[context objectWithID:objectID];
        XCTAssertEqualObjects(retreivedUser.localID, @"100");
        XCTAssertEqualObjects(retreivedUser.name, @"Joshua");
    }];
}

@end
