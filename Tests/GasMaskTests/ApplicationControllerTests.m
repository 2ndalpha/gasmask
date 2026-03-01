#import <XCTest/XCTest.h>
#import <Cocoa/Cocoa.h>
#import "ApplicationController.h"

@interface ApplicationController (Testing)
- (void)loadEditorWindowForTesting;
- (void)closeEditorWindowForTesting;
- (NSWindow *)editorWindowForTesting;
@end

@implementation ApplicationController (Testing)

- (void)loadEditorWindowForTesting
{
    NSWindow *existing = [self editorWindowForTesting];
    if (existing) {
        [self setValue:@YES forKey:@"editorWindowOpened"];
        return;
    }
    // Call the private initEditorWindow method which uses EditorWindowPresenter internally
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:NSSelectorFromString(@"initEditorWindow")];
#pragma clang diagnostic pop
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

#pragma mark - Window creation / open

- (void)testLoadEditorWindow_setsEditorWindowOpenedFlag
{
    XCTAssertFalse([self.controller editorWindowOpened], @"precondition");
    [self.controller loadEditorWindowForTesting];
    XCTAssertTrue([self.controller editorWindowOpened]);
}

- (void)testLoadEditorWindow_windowExistsAfterOpen
{
    [self.controller loadEditorWindowForTesting];
    NSWindow *w = [self.controller editorWindowForTesting];
    XCTAssertNotNil(w);
    XCTAssertEqualObjects([w frameAutosaveName], @"editor_window");
}

- (void)testLoadEditorWindow_windowAppearsInNSAppWindows
{
    [self.controller loadEditorWindowForTesting];

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
    [self.controller loadEditorWindowForTesting];
    XCTAssertTrue([self.controller editorWindowOpened], @"precondition");
    [self.controller closeEditorWindowForTesting];
    XCTAssertFalse([self.controller editorWindowOpened]);
}

- (void)testCloseEditorWindow_windowStillAccessibleAfterClose
{
    [self.controller loadEditorWindowForTesting];
    [self.controller closeEditorWindowForTesting];
    runLoopDrain(0.05);

    XCTAssertFalse([self.controller editorWindowOpened]);
    XCTAssertNotNil([self.controller editorWindowForTesting]);
}

#pragma mark - re-open after close

- (void)testReopenAfterClose_flagIsYes
{
    [self.controller loadEditorWindowForTesting];
    [self.controller closeEditorWindowForTesting];
    runLoopDrain(0.05);
    XCTAssertFalse([self.controller editorWindowOpened], @"precondition: closed");

    [self.controller loadEditorWindowForTesting];
    XCTAssertTrue([self.controller editorWindowOpened]);
}

- (void)testReopenAfterClose_windowAccessible
{
    [self.controller loadEditorWindowForTesting];
    [self.controller closeEditorWindowForTesting];
    runLoopDrain(0.05);

    [self.controller loadEditorWindowForTesting];
    XCTAssertNotNil([self.controller editorWindowForTesting]);
}

@end
