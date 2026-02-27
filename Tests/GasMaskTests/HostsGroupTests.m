#import <XCTest/XCTest.h>
#import "HostsGroup.h"

@interface HostsGroupTests : XCTestCase
@end

@implementation HostsGroupTests

- (void)testInitWithName
{
    HostsGroup *group = [[HostsGroup alloc] initWithName:@"Local"];
    XCTAssertNotNil(group);
    XCTAssertEqualObjects([group name], @"Local");
}

- (void)testDefaultState
{
    HostsGroup *group = [[HostsGroup alloc] initWithName:@"Local"];
    XCTAssertTrue([group online]);
    XCTAssertFalse([group synchronizing]);
    XCTAssertTrue([group isGroup]);
    XCTAssertFalse([group leaf]);
    XCTAssertFalse([group selectable]);
}

- (void)testSetSynchronizingTogglesState
{
    HostsGroup *group = [[HostsGroup alloc] initWithName:@"Remote"];
    XCTAssertFalse([group synchronizing]);
    [group setSynchronizing:YES];
    XCTAssertTrue([group synchronizing]);
    [group setSynchronizing:NO];
    XCTAssertFalse([group synchronizing]);
}

- (void)testSetSynchronizingPostsNotification
{
    HostsGroup *group = [[HostsGroup alloc] initWithName:@"Remote"];
    XCTestExpectation *exp = [self expectationWithDescription:@"notification posted"];

    id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:SynchronizingStatusChangedNotification
                    object:group
                     queue:nil
                usingBlock:^(NSNotification *note) {
                    [exp fulfill];
                }];

    [group setSynchronizing:YES];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

- (void)testSetSynchronizingSameValueDoesNotPostNotification
{
    HostsGroup *group = [[HostsGroup alloc] initWithName:@"Remote"];
    __block BOOL notified = NO;
    id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:SynchronizingStatusChangedNotification
                    object:group
                     queue:nil
                usingBlock:^(NSNotification *note) {
                    notified = YES;
                }];

    [group setSynchronizing:NO]; // same value — should not fire
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertFalse(notified);
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

- (void)testSetOnlineTogglesState
{
    HostsGroup *group = [[HostsGroup alloc] initWithName:@"Local"];
    XCTAssertTrue([group online]);
    [group setOnline:NO];
    XCTAssertFalse([group online]);
    [group setOnline:YES];
    XCTAssertTrue([group online]);
}

- (void)testSetOnlinePostsUpdateNotification
{
    HostsGroup *group = [[HostsGroup alloc] initWithName:@"Local"];
    XCTestExpectation *exp = [self expectationWithDescription:@"update notification"];

    id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:HostsNodeNeedsUpdateNotification
                    object:group
                     queue:nil
                usingBlock:^(NSNotification *note) {
                    [exp fulfill];
                }];

    [group setOnline:NO];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

- (void)testDescriptionIsName
{
    HostsGroup *group = [[HostsGroup alloc] initWithName:@"MyGroup"];
    XCTAssertEqualObjects([group description], @"MyGroup");
}

@end
