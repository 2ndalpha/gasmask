/*
 * Tests for ApplicationController editor window behaviour.
 *
 * The editor window (Editor.xib) is loaded once and kept alive; openEditorWindow:/
 * closeEditorWindow: merely show/hide it.  We test this NIB-loading and flag
 * logic directly via a (Testing) category rather than calling openEditorWindow:
 * (which also calls showApplicationInDock, changing NSApp's activation policy and
 * breaking the XCTest host context).
 */

#import <XCTest/XCTest.h>
#import <Cocoa/Cocoa.h>
#import "ApplicationController.h"

/* Expose private internals for testing only */
@interface ApplicationController (Testing)
- (void)loadEditorNibForTesting;
- (void)closeEditorWindowForTesting;
- (NSWindow *)editorWindowForTesting;
@end

@implementation ApplicationController (Testing)

/**
 * Opens the editor window for testing without calling showApplicationInDock.
 *
 * If the NIB was already loaded (window exists but is hidden), we just set the
 * flag and return — exactly what openEditorWindow: does with the new design.
 * If the NIB has never been loaded, we load it now (first load only).
 *
 * NOTE: _editorWindow is __weak and KVC on __weak ivars is unreliable.
 * We check _editorNibTopLevelObjects (strong NSArray) instead.
 */
- (void)loadEditorNibForTesting
{
    id objects = [self valueForKey:@"_editorNibTopLevelObjects"];
    if (objects) {
        /* NIB already loaded; window may be hidden — just re-mark as opened */
        [self setValue:@YES forKey:@"editorWindowOpened"];
        return;
    }
    /* First-ever load */
    NSArray *topLevelObjects = nil;
    [[NSBundle mainBundle] loadNibNamed:@"Editor" owner:self topLevelObjects:&topLevelObjects];
    [self setValue:topLevelObjects forKey:@"_editorNibTopLevelObjects"];
    [self setValue:@YES forKey:@"editorWindowOpened"];
}

/**
 * Closes the editor window for testing WITHOUT calling setActivationPolicy:.
 * Calling setActivationPolicy: from inside XCTest disrupts the test runner
 * communication channel and causes silent test failures.
 */
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
    /* _editorWindow stays non-nil while _editorNibTopLevelObjects retains the array.
       KVC on __weak ivars is unreliable so we fall back to searching NSApp windows. */
    for (NSWindow *w in [NSApp windows]) {
        if ([[w frameAutosaveName] isEqualToString:@"editor_window"]) {
            return w;
        }
    }
    return nil;
}

@end

/* ---- helper ---- */
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

    /* Ensure editor is closed before each test.  closeEditorWindowForTesting
       hides the window without calling setActivationPolicy:, which would
       disrupt the XCTest runner communication channel. */
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
    XCTAssertTrue([self.controller editorWindowOpened],
                  @"editorWindowOpened must be YES after NIB is loaded/window is opened");
}

- (void)testLoadEditorNib_windowExistsAfterOpen
{
    [self.controller loadEditorNibForTesting];
    NSWindow *w = [self.controller editorWindowForTesting];
    XCTAssertNotNil(w, @"editorWindowForTesting must return a window after NIB is loaded");
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
    XCTAssertNotNil(found,
                    @"An NSWindow with frameAutosaveName 'editor_window' "
                    @"must be in [NSApp windows] after the NIB is loaded");
}

#pragma mark - close clears state

- (void)testCloseEditorWindow_clearsEditorWindowOpenedFlag
{
    [self.controller loadEditorNibForTesting];
    XCTAssertTrue([self.controller editorWindowOpened], @"precondition");

    [self.controller closeEditorWindowForTesting];

    XCTAssertFalse([self.controller editorWindowOpened],
                   @"editorWindowOpened must be NO after close");
}

- (void)testCloseEditorWindow_windowStillAccessibleAfterClose
{
    /* With the new design the NIB is NOT destroyed on close — the window
       stays alive (hidden) so it can be reused on the next open. */
    [self.controller loadEditorNibForTesting];
    [self.controller closeEditorWindowForTesting];
    runLoopDrain(0.05);

    XCTAssertFalse([self.controller editorWindowOpened], @"flag must be NO");
    NSWindow *w = [self.controller editorWindowForTesting];
    XCTAssertNotNil(w, @"window must still be accessible (hidden, not deallocated)");
}

#pragma mark - re-open after close

- (void)testReopenAfterClose_flagIsYes
{
    [self.controller loadEditorNibForTesting];
    [self.controller closeEditorWindowForTesting];
    runLoopDrain(0.05);
    XCTAssertFalse([self.controller editorWindowOpened], @"precondition: closed");

    [self.controller loadEditorNibForTesting];
    XCTAssertTrue([self.controller editorWindowOpened], @"editorWindowOpened must be YES after re-open");
}

- (void)testReopenAfterClose_windowAccessible
{
    [self.controller loadEditorNibForTesting];
    [self.controller closeEditorWindowForTesting];
    runLoopDrain(0.05);

    [self.controller loadEditorNibForTesting];
    NSWindow *w = [self.controller editorWindowForTesting];
    XCTAssertNotNil(w, @"Re-opening the editor must provide a window");
}

@end
