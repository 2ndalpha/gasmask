#import <XCTest/XCTest.h>
#import "Node.h"

@interface NodeTests : XCTestCase
@end

@implementation NodeTests

- (void)testDefaultInitialization
{
    Node *node = [[Node alloc] init];
    XCTAssertNotNil(node);
    XCTAssertNotNil(node.children);
    XCTAssertEqual(node.children.count, 0u);
    XCTAssertTrue(node.leaf);
    XCTAssertFalse(node.isGroup);
    XCTAssertTrue(node.selectable);
}

- (void)testSetChildren
{
    Node *node = [[Node alloc] init];
    Node *child1 = [[Node alloc] init];
    Node *child2 = [[Node alloc] init];
    node.children = @[child1, child2];
    XCTAssertEqual(node.children.count, 2u);
    XCTAssertEqualObjects(node.children[0], child1);
    XCTAssertEqualObjects(node.children[1], child2);
}

- (void)testSetLeaf
{
    Node *node = [[Node alloc] init];
    node.leaf = NO;
    XCTAssertFalse(node.leaf);
    node.leaf = YES;
    XCTAssertTrue(node.leaf);
}

- (void)testSetIsGroup
{
    Node *node = [[Node alloc] init];
    node.isGroup = YES;
    XCTAssertTrue(node.isGroup);
}

- (void)testSetSelectable
{
    Node *node = [[Node alloc] init];
    node.selectable = NO;
    XCTAssertFalse(node.selectable);
}

@end
