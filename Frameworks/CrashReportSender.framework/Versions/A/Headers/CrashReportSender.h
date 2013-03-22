/*
 * Author: Andreas Linde <mail@andreaslinde.de>
 *         Kent Sutherland
 *
 * Copyright (c) 2009 Andreas Linde & Kent Sutherland. All rights reserved.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Cocoa/Cocoa.h>

#define CRASHREPORTSENDER_MAX_CONSOLE_SIZE 50000

typedef enum CrashAlertType {
	CrashAlertTypeSend = 0,
	CrashAlertTypeFeedback = 1,
} CrashAlertType;

typedef enum CrashReportStatus {
	CrashReportStatusFailureVersionDiscontinued = -30,          // This app version is set to discontinued, no new crash reports accepted by the server
	CrashReportStatusFailureXMLSenderVersionNotAllowed = -21,   // XML: Sender ersion string contains not allowed characters, only alphanumberical including space and . are allowed
	CrashReportStatusFailureXMLVersionNotAllowed = -20,         // XML: Version string contains not allowed characters, only alphanumberical including space and . are allowed
	CrashReportStatusFailureSQLAddSymbolicateTodo = -18,        // SQL for adding a symoblicate todo entry in the database failed
	CrashReportStatusFailureSQLAddCrashlog = -17,               // SQL for adding crash log in the database failed
	CrashReportStatusFailureSQLAddVersion = -16,                // SQL for adding a new version in the database failed
	CrashReportStatusFailureSQLCheckVersionExists = -15,        // SQL for checking if the version is already added in the database failed
	CrashReportStatusFailureSQLAddPattern = -14,                // SQL for creating a new pattern for this bug and set amount of occurrances to 1 in the database failed
	CrashReportStatusFailureSQLCheckBugfixStatus = -13,         // SQL for checking the status of the bugfix version in the database failed
	CrashReportStatusFailureSQLUpdatePatternOccurances = -12,   // SQL for updating the occurances of this pattern in the database failed
	CrashReportStatusFailureSQLFindKnownPatterns = -11,         // SQL for getting all the known bug patterns for the current app version in the database failed
	CrashReportStatusFailureSQLSearchAppName = -10,             // SQL for finding the bundle identifier in the database failed
	CrashReportStatusFailureInvalidPostData = -3,               // the post request didn't contain valid data
	CrashReportStatusFailureInvalidIncomingData = -2,           // incoming data may not be added, because e.g. bundle identifier wasn't found
	CrashReportStatusFailureDatabaseNotAvailable = -1,          // database cannot be accessed, check hostname, username, password and database name settings in config.php
	CrashReportStatusUnknown = 0,
	CrashReportStatusAssigned = 1,
	CrashReportStatusSubmitted = 2,
	CrashReportStatusAvailable = 3,
} CrashReportStatus;

@class CrashReportSenderUI;

// This protocol is used to send the image updates
@protocol CrashReportSenderDelegate <NSObject>

@required

- (void) showMainApplicationWindow;				// Invoked once the modal sheets are gone

@optional

- (NSString *) crashReportUserID;				// Return the userid the crashreport should contain, empty by default
- (NSString *) crashReportContact;				// Return the contact value (e.g. email) the crashreport should contain, empty by default
@end

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
@interface CrashReportSender : NSObject
#else
@interface CrashReportSender : NSObject<NSXMLParserDelegate>
#endif
{
	CrashReportStatus	_serverResult;
	int					_statusCode;
	NSMutableString		*_contentOfProperty;

	id					_delegate;
	NSURL				*_submissionURL;
	NSString			*_companyName;

	NSString			*_crashFile;
	
	CrashReportSenderUI *_crashReportSenderUI;
}

+ (CrashReportSender *)sharedCrashReportSender;

- (void) sendCrashReportToURL:(NSURL *)submissionURL delegate:(id)delegate companyName:(NSString *)companyName;

- (void) cancelReport;
- (void) sendReport:(NSString *)xml;
- (void) postXML:(NSTimer *) timer;

- (NSString *) applicationName;
- (NSString *) applicationVersionString;
- (NSString *) applicationVersion;

@end

@interface CrashReportSenderUI : NSWindowController 
{
	IBOutlet NSTextField	*descriptionTextField;
	IBOutlet NSTextView		*crashLogTextView;

	IBOutlet NSTextField	*noteText;

	IBOutlet NSButton		*showButton;
	IBOutlet NSButton		*hideButton;
	IBOutlet NSButton		*cancelButton;
	IBOutlet NSButton		*submitButton;
	
	CrashReportSender	*_delegate;
	
	NSString			*_xml;
	
	NSString			*_crashFile;
	NSString			*_companyName;
	NSString			*_applicationName;
	
	NSMutableString		*_consoleContent;
	NSString			*_crashLogContent;
	
	BOOL showComments;
	BOOL showDetails;
}

- (id)init:(id)delegate crashFile:(NSString *)crashFile companyName:(NSString *)companyName applicationName:(NSString *)applicationName;

- (void) askCrashReportDetails;

- (IBAction) cancelReport:(id)sender;
- (IBAction) submitReport:(id)sender;
- (IBAction) showDetails:(id)sender;
- (IBAction) hideDetails:(id)sender;
- (IBAction) showComments:(id)sender;

- (BOOL)showComments;
- (void)setShowComments:(BOOL)value;

- (BOOL)showDetails;
- (void)setShowDetails:(BOOL)value;

@end