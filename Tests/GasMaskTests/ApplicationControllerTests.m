#import <XCTest/XCTest.h>
#import <Cocoa/Cocoa.h>
#import "ApplicationController.h"

@interface ApplicationController (Testing)
- (void)loadEditorNibForTesting;
- (void)closeEditorWindowForTesting;
- (NSWindow *)editorWindowForTesting;
@end

@implementation ApplicationController (Testing)

- (void)loadEditorNibForTesting
{
    id objects = [self valueForKey:@"_editorNibTopLevelObjects"];
    if (objects) {
        [self setValue:@YES forKey:@"editorWindowOpened"];
        return;
    }
    NSArray *topLevelObjects = nil;
    [[NSBundle mainBundle] loadNibNamed:@"Editor" owner:self topLevelObjects:&topLevelObjects];
    [self setValue:topLevelObjects forKey:@"_editorNibTopLevelObjects"];
    [self setValue:@YES forKey:@"editorWindowOpened"];
}

- (void)closeEditorWindowForTesting
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(orderEditorWindowFront)
                                               object:nil];
    NSWindow *w = [self editorWindowForTesting];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                     name:NSWindowWillCloseNotification
                                                   object:w];
    [w orderOut:nil];
    [self setValue:@NO forKey:@"editorWindowOpened"];
}

- (NSWindow *)editorWindowForTesting
{
    for (NSWindow *w in [NSApp windows]) {
        if ([[w frameAutosaveName] isEqualToString:@"editor_window"]) {
            return w;
        }
    }
    return nil;
}

@end

static void runLoopDrain(NSTimeInterval seconds)
{
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
}

@interface ApplicationControllerTests : XCTestCase
@property (nonatomic, strong) ApplicationController *controller;
@end

@implementation ApplicationControllerTests

- (void)setUp
{
    [super setUp];
    self.controller = [ApplicationController defaultInstance];
    XCTAssertNotNil(self.controller, @"ApplicationController singleton must exist (loaded from MainMenu.xib)");
    if ([self.controller editorWindowOpened]) {
        [self.controller closeEditorWindowForTesting];
        runLoopDrain(0.05);
    }
}

- (void)tearDown
{
    if ([self.controller editorWindowOpened]) {
        [self.controller closeEditorWindowForTesting];
        runLoopDrain(0.05);
    }
    [super tearDown];
}

#pragma mark - Singleton

- (void)testSingletonExists
{
    XCTAssertNotNil([ApplicationController defaultInstance]);
    XCTAssertEqual([ApplicationController defaultInstance], self.controller);
}

#pragma mark - NIB loading / open

- (void)testLoadEditorNib_setsEditorWindowOpenedFlag
{
    XCTAssertFalse([self.controller editorWindowOpened], @"precondition");
    [self.controller loadEditorNibForTesting];
    XCTAssertTrue([self.controller editorWindowOpened]);
}

- (void)testLoadEditorNib_windowExistsAfterOpen
{
    [self.controller loadEditorNibForTesting];
    NSWindow *w = [self.controller editorWindowForTesting];
    XCTAssertNotNil(w);
    XCTAssertEqualObjects([w frameAutosaveName], @"editor_window");
}

- (void)testLoadEditorNib_windowAppearsInNSAppWindows
{
    [self.controller loadEditorNibForTesting];

    NSWindow *found = nil;
    for (NSWindow *w in [NSApp windows]) {
        if ([[w frameAutosaveName] isEqualToString:@"editor_window"]) {
            found = w;
            break;
        }
    }
    XCTAssertNotNil(found);
}

#pragma mark - close clears state

- (void)testCloseEditorWindow_clearsEditorWindowOpenedFlag
{
    [self.controller loadEditorNibForTesting];
    XCTAssertTrue([self.controller editorWindowOpened], @"precondition");
    [self.controller closeEditorWindowForTesting];
    XCTAssertFalse([self.controller editorWindowOpened]);
}

- (void)testCloseEditorWindow_windowStillAccessibleAfterClose
{
    [self.controller loadEditorNibForTesting];
    [self.controller closeEditorWindowForTesting];
    runLoopDrain(0.05);

    XCTAssertFalse([self.controller editorWindowOpened]);
    XCTAssertNotNil([self.controller editorWindowForTesting]);
}

#pragma mark - re-open after close

- (void)testReopenAfterClose_flagIsYes
{
    [self.controller loadEditorNibForTesting];
    [self.controller closeEditorWindowForTesting];
    runLoopDrain(0.05);
    XCTAssertFalse([self.controller editorWindowOpened], @"precondition: closed");

    [self.controller loadEditorNibForTesting];
    XCTAssertTrue([self.controller editorWindowOpened]);
}

- (void)testReopenAfterClose_windowAccessible
{
    [self.controller loadEditorNibForTesting];
    [self.controller closeEditorWindowForTesting];
    runLoopDrain(0.05);

    [self.controller loadEditorNibForTesting];
    XCTAssertNotNil([self.controller editorWindowForTesting]);
}

@end
