//
//  OSReportManager.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/16/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSReportManager.h"
#import "NSDate+String.h"
#import "OSModelManager.h"
#import "OSCertificationManager.h"
#import "OSSaltSolutionManager.h"

#define STR(string) (string) ? (string) : @""

#define A4PAPER_WIDTH_IN_PORTRATE  1240.0f
#define A4PAPER_HEIGHT_IN_PORTRATE   1753.0f

#define kBorderInset            20.0
#define kBorderWidth            1.0
#define kMarginInset            10.0
#define kLineWidth              1.0

static NSString * const kLabelKey = @"label";
static NSString * const kDescriptionKey = @"description";
static NSString * const kNewLineKey = @"newLineSeparator";
static NSString * const kFontSizeKey = @"fontSize";

static CGFloat const kHeaderHeight = 110.f;
static CGFloat const kRowHeight = 40.0f;


#define kReportDataSensorKey        @"Serial Number"
#define kreportDataSensorNameKey    @"Name/Location"
#define kReportDataLastCalDateKey   @"Last Cal Date"
#define kReportDataSaltKey          @"Salt"
#define kReportDataRhKey            @"RH (%)"
#define kReportDataTempKey          @"Temp (F)"
#define kReportDataCalCertDueKey    @"Cal Cert Due"

#define kReportDataAmbRhKey         @"Amb RH (%)"
#define kReportDataAmbTempKey       @"Amb Temp (F)"


static OSReportManager *_sharedReportManager = nil;

@interface OSReportManager ()
{
    CGSize pageSize;
}

@end

@implementation OSReportManager

+ (OSReportManager *)sharedInstance
{
    if (_sharedReportManager == nil)
        _sharedReportManager = [[OSReportManager alloc] init];
    return _sharedReportManager;
}

+ (NSString *)getDocumentDirectory {
    
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return documentsDirectory;
}

#pragma mark - report for sensor inventory
- (NSString *)createPdfForSensors:(NSArray *)arraySsn
{
    NSDate * aDate = [NSDate date];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.pdf", @"Report(SensorInventory)", [aDate toStringWithFormat:@"MM_dd_HH_mm_ss"]];
    NSString * fullPDFPath = [[OSReportManager getDocumentDirectory] stringByAppendingPathComponent:fileName];
    
    NSString *dateStr = [NSString stringWithFormat:@"%@",[aDate toStringWithFormat:kDateFormat]];
    
    NSArray *arrayReportData = [self reportDataWithSensors:arraySsn];
    
    // Opent the PDF context
    pageSize = CGSizeMake(A4PAPER_WIDTH_IN_PORTRATE, A4PAPER_HEIGHT_IN_PORTRATE);
    UIGraphicsBeginPDFContextToFile(fullPDFPath, CGRectZero, nil);
    
    NSInteger currentPage = 0;
    
    CGFloat yPos = 0.0;
    
    // render first page
    // commented-2014-12-19, Tim required to remove first page
    //[self renderFirstPageForSensors:dateStr];
    //[self drawPageNumber:currentPage++ + 1];
    
    // render contents page
    BOOL isStart = YES;
    
//    for (int i = 0; i < [arrayReportData count]; i++) {
//        
        //if (isStart == YES) {
            
            // draw header.
            [self renderHeader];
            isStart = NO;
            yPos = kHeaderHeight;
        //}
    
        int m = 0;
        int count = (int)[arrayReportData count];
        //isStart = NO;
        while (m < count) {
            
            if (isStart == YES)
            {
                [self drawPageNumber:currentPage++ + 1];
                
                [self renderHeader];
                yPos = kHeaderHeight;
                
                isStart = NO;
            }
            
            CGFloat remains = [self heightRemains:yPos];
            int remainRows = remains / kRowHeight - 1;
            
            
            if (remainRows <= count - m) {
                isStart = YES;
            }
            
            if (remainRows <= 0)
                continue;
            
            if (remainRows > count - m)
                remainRows = count - m;
            
            [self renderRowsForSensors:yPos data:arrayReportData startIndex:m count:remainRows];
            yPos += (remainRows + 1) * kRowHeight;
            m += remainRows;
        }
        
//    }
    
    if (yPos > kHeaderHeight)
        [self drawPageNumber:currentPage++ + 1];
    
    // Close the PDF context and write the contents out.
    UIGraphicsEndPDFContext();
    
    //NSNumber *fileSize = [self getFileSizeWithFilePath:fullPDFPath];
    
    if (self.delegate)
        [[self delegate] didFinishGeneratingReport];
    
    return fullPDFPath;
}


- (NSArray *)reportDataWithSensors:(NSArray *)arraySensors
{
    NSMutableArray *arrayReportData = [[NSMutableArray alloc] init];
    for (NSString *ssn in arraySensors) {
        CDSensor *sensor = [[OSModelManager sharedInstance] getSensorForSerial:ssn];
        CDCalCheck *lastCalCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:ssn];
        // check dummy one
        if (lastCalCheck != nil && [[OSSaltSolutionManager sharedInstance] isDefaultSolution:lastCalCheck.salt_name])
            lastCalCheck = nil;
        
        CDCalCheck *firstCalCheck = [[OSModelManager sharedInstance] getFirstCalCheckForSensor:ssn];
        CDCalibrationDate *cdCalibrationDate = [[OSModelManager sharedInstance] getCalibrationDateForSensor:ssn];
        
        NSMutableDictionary *reportData = [[NSMutableDictionary alloc] init];
        
        // serial number
        [reportData setObject:sensor.ssn forKey:kReportDataSensorKey];
        
        // sensor name
        NSString *strSensor = @"";
        if (sensor != nil)
        {
            if (sensor.name != nil && sensor.name.length > 0)
                strSensor = sensor.name;
        }
        [reportData setObject:strSensor forKey:kreportDataSensorNameKey];
        
        // last cal date
        NSString *strLastCalCheck = @"";
        if (lastCalCheck != nil)
            strLastCalCheck = [lastCalCheck.date toStringWithFormat:kShortDateFormat];
        else
        {
            if (cdCalibrationDate != nil && cdCalibrationDate.calibrationDate != nil)
                strLastCalCheck = [cdCalibrationDate.calibrationDate toStringWithFormat:kShortDateFormat];
        }
        [reportData setObject:strLastCalCheck forKey:kReportDataLastCalDateKey];
        
        // salt
        NSString *strSalt = @"";
        if (lastCalCheck != nil)
            strSalt = lastCalCheck.salt_name;
        [reportData setObject:strSalt forKey:kReportDataSaltKey];
        
        // rh
        NSString *strRh = @"";
        if (lastCalCheck != nil)
            strRh = [NSString stringWithFormat:@"%.1f", [lastCalCheck.rh floatValue]];
        [reportData setObject:strRh forKey:kReportDataRhKey];
        
        // temp
        NSString *strTemp = @"";
        if (lastCalCheck != nil)
            strTemp = [NSString stringWithFormat:@"%.1f", [lastCalCheck.temp floatValue]];
        [reportData setObject:strTemp forKey:kReportDataTempKey];
        
        // cal cert due
        NSDate *calCertDue = nil;
        NSDate *firstCalCheckDate = nil;
        if (firstCalCheck != nil)
            firstCalCheckDate = firstCalCheck.date;
        
        NSDate *calibrationDate = nil;
        if (cdCalibrationDate != nil)
            calibrationDate = cdCalibrationDate.calibrationDate;
        
        calCertDue = [OSCertificationManager earlierRecertificationDate:calibrationDate firstCalCheckDate:firstCalCheckDate];
        
        NSString *strCalCertDue = @"";
        if (calCertDue != nil)
            strCalCertDue = [calCertDue toStringWithFormat:kShortDateFormat];
        
        [reportData setObject:strCalCertDue forKey:kReportDataCalCertDueKey];
        
        [arrayReportData addObject:reportData];
        
    }
    return arrayReportData;
}

- (void)renderFirstPageForSensors:(NSString *)dateStr {
    
    UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, pageSize.width, pageSize.height), nil);
    //[self drawImage];
    /*
     CGRect previousRect = {{kBorderInset + kMarginInset+50, kBorderInset + kMarginInset + 150.0}, {0, 0}};
     
     NSArray *strings = @[
     @{kLabelKey: @"Job Name:",                   kDescriptionKey: STR(self.job.jobName),                               kFontSizeKey: @24.f},
     @{kLabelKey: @"Date:",              kDescriptionKey: STR(dateStr),                                 kFontSizeKey: @24.f}
     ];
     
     for (NSDictionary *row in strings) {
     previousRect =[self drawLabel:row[kLabelKey]
     details:row[kDescriptionKey]
     origin:CGPointMake(previousRect.origin.x, previousRect.size.height + previousRect.origin.y + 10)
     fontSize:[row[kFontSizeKey] floatValue]
     newLineSeparator:[row[kNewLineKey] boolValue]];
     }
     */
    
    if (YES) {
        //[self drawLogoImage];
        /*
         [self drawTextWithLeftAllignment:@"Certified By Wagner Meters"
         withFrame:CGRectMake(kBorderInset + kMarginInset+150, kBorderInset + kMarginInset + 850.0,400 , 80)
         withFont:[UIFont systemFontOfSize:24.0f]];
         */
    }
}


- (void) renderRowsForSensors:(CGFloat)ypos data:(NSArray *)data startIndex:(long)startIndex count:(long)count {
    
    CGFloat xOrigin = 100;
    CGFloat yOrigin = ypos;
    CGFloat arrayColumnWidth[] = {160, 170, 160, 100, 100, 130, 160};
    int numberOfColumns = 7;
    
    // table header
    [self drawTableAt:CGPointMake(xOrigin, yOrigin)
        withRowHeight:kRowHeight
       andColumnWidth:arrayColumnWidth
          andRowCount:1
       andColumnCount:numberOfColumns];
    
    NSArray *labels = @[kReportDataSensorKey,
                        kreportDataSensorNameKey,
                        kReportDataLastCalDateKey,
                        kReportDataSaltKey,
                        kReportDataRhKey,
                        kReportDataTempKey,
                        kReportDataCalCertDueKey
                        ];

    CGFloat fLeft = 0;
    for (int i = 0; i < [labels count]; i++) {
        [self drawText:labels[i]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10,
                                  arrayColumnWidth[i] - 20,
                                  80)
              withFont:[UIFont boldSystemFontOfSize:18.0f]];
        fLeft += arrayColumnWidth[i];
    }
    
    yOrigin += kRowHeight;
    
    
    [self drawTableAt:CGPointMake(xOrigin, yOrigin)
        withRowHeight:kRowHeight
       andColumnWidth:arrayColumnWidth
          andRowCount:(int)count
       andColumnCount:numberOfColumns];
    
    for (int i = (int)startIndex; i < (int)startIndex + count; i++) {
        UIFont *textFont = [UIFont systemFontOfSize:14.0f];
        
        NSDictionary *reportData = [data objectAtIndex:i];
        
        // sensor
        int column = 0;
        CGFloat fLeft = 0;
        [self drawText:reportData[kReportDataSensorKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // sensor name
        column++;
        [self drawText:reportData[kreportDataSensorNameKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // last cal date
        column++;
        [self drawText:reportData[kReportDataLastCalDateKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // salt
        column++;
        [self drawText:reportData[kReportDataSaltKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // rh
        column++;
        [self drawText:reportData[kReportDataRhKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // temp
        column++;
        [self drawText:reportData[kReportDataTempKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // cal cert due
        column++;
        [self drawText:reportData[kReportDataCalCertDueKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
    }
}

#pragma mark - report for job
- (NSString *)createPdfForJob:(NSString *)jobUid
{
    CDJob *job = [[OSModelManager sharedInstance] getJobWithUid:jobUid];
    if (job == nil)
        return nil;
    
    NSDate * aDate = [NSDate date];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.pdf", @"Report(Job)", [aDate toStringWithFormat:@"MM_dd_HH_mm_ss"]];
    NSString * fullPDFPath = [[OSReportManager getDocumentDirectory] stringByAppendingPathComponent:fileName];
    
    NSString *dateStr = [NSString stringWithFormat:@"%@",[aDate toStringWithFormat:kDateFormat]];
    
    NSArray *arrayReportData = [self reportDataWithJob:jobUid];
    
    // Opent the PDF context
    pageSize = CGSizeMake(A4PAPER_WIDTH_IN_PORTRATE, A4PAPER_HEIGHT_IN_PORTRATE);
    UIGraphicsBeginPDFContextToFile(fullPDFPath, CGRectZero, nil);
    
    NSInteger currentPage = 0;
    
    CGFloat yPos = 0.0;
    
    // render first page
    [self renderFirstPageForJob:job dateStr:dateStr];
    [self drawPageNumber:currentPage++ + 1];
    
    // render contents page
    BOOL isStart = YES;
    
    //    for (int i = 0; i < [arrayReportData count]; i++) {
    //
    //if (isStart == YES) {
        
        // draw header.
        [self renderHeader];
        isStart = NO;
        yPos = kHeaderHeight;
    //}
    
    int m = 0;
    int count = (int)[arrayReportData count];
    //isStart = NO;
    while (m < count) {
        
        if (isStart == YES)
        {
            [self drawPageNumber:currentPage++ + 1];
            
            [self renderHeader];
            yPos = kHeaderHeight;
            
            isStart = NO;
        }
        
        CGFloat remains = [self heightRemains:yPos];
        int remainRows = remains / kRowHeight - 1;
        
        
        if (remainRows <= count - m) {
            isStart = YES;
        }
        
        if (remainRows <= 0)
            continue;
        
        if (remainRows > count - m)
            remainRows = count - m;
        
        [self renderRowsForJob:yPos data:arrayReportData startIndex:m count:remainRows];
        yPos += (remainRows + 1) * kRowHeight;
        m += remainRows;
    }
    
    //    }
    
    if (yPos > kHeaderHeight)
        [self drawPageNumber:currentPage++ + 1];
    
    // Close the PDF context and write the contents out.
    UIGraphicsEndPDFContext();
    
    //NSNumber *fileSize = [self getFileSizeWithFilePath:fullPDFPath];
    
    if (self.delegate)
        [[self delegate] didFinishGeneratingReport];
    
    return fullPDFPath;
}

- (NSArray *)reportDataWithJob:(NSString *)jobUid
{
    NSMutableArray *arrayReportData = [[NSMutableArray alloc] init];
    
    NSMutableArray *arraySensors = [[OSModelManager sharedInstance] getSensorSerialsForJob:jobUid];
    for (NSString *ssn in arraySensors) {
        CDReading *reading = [[OSModelManager sharedInstance] getLastReadingForSensor:ssn ofJob:jobUid];
        CDCalCheck *calCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:reading.ssn];
        // check dummy one
        if (calCheck != nil && [[OSSaltSolutionManager sharedInstance] isDefaultSolution:calCheck.salt_name])
            calCheck = nil;
        
        CDSensor *sensor = [[OSModelManager sharedInstance] getSensorForSerial:reading.ssn];
        CDCalibrationDate *cdCalibrationDate = [[OSModelManager sharedInstance] getCalibrationDateForSensor:reading.ssn];
        
        NSMutableDictionary *dicReport = [[NSMutableDictionary alloc] init];
        
        // sensor
        [dicReport setObject:reading.ssn forKey:kReportDataSensorKey];
        
        // sensor name
        NSString *strSensor = @"";
        if (sensor != nil)
        {
            if (sensor.name != nil && sensor.name.length > 0)
                strSensor = sensor.name;
        }
        [dicReport setObject:strSensor forKey:kreportDataSensorNameKey];
        
        // last cal check
        NSString *strLastCalCheck = @"";
        if (calCheck != nil && calCheck.date != nil)
            strLastCalCheck = [calCheck.date toStringWithFormat:kShortDateFormat];
        else
        {
            if (cdCalibrationDate != nil && cdCalibrationDate.calibrationDate != nil)
                strLastCalCheck = [cdCalibrationDate.calibrationDate toStringWithFormat:kShortDateFormat];
        }
        [dicReport setObject:strLastCalCheck forKey:kReportDataLastCalDateKey];
        
        // rh
        NSString *strRh = [NSString stringWithFormat:kFormatForRh, [reading.rh floatValue]];
        [dicReport setObject:strRh forKey:kReportDataRhKey];
        
        // temp
        NSString *strTemp = [NSString stringWithFormat:kFormatForTemp, [reading.temp floatValue]];
        [dicReport setObject:strTemp forKey:kReportDataTempKey];
        
        // amb rh
        NSString *strAmbRh = [NSString stringWithFormat:kFormatForAmbRh, [reading.ambRh floatValue]];
        [dicReport setObject:strAmbRh forKey:kReportDataAmbRhKey];
        
        // amb temp
        NSString *strAmbTemp = [NSString stringWithFormat:kFormatForAmbTemp, [reading.ambTemp floatValue]];
        [dicReport setObject:strAmbTemp forKey:kReportDataAmbTempKey];
        
        [arrayReportData addObject:dicReport];
    }

    return arrayReportData;
}

- (void)renderFirstPageForJob:(CDJob *)job dateStr:(NSString *)dateStr {
    
    UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, pageSize.width, pageSize.height), nil);
    //[self drawImage];
    
     CGRect previousRect = {{kBorderInset + kMarginInset+50, kBorderInset + kMarginInset + 150.0}, {0, 0}};
     
     NSArray *strings = @[
     @{kLabelKey: @"Job Name:",
       kDescriptionKey: STR(job.name),
       kFontSizeKey: @24.f},
     @{kLabelKey: @"Date:",
       kDescriptionKey: STR(dateStr),
       kFontSizeKey: @24.f}
     ];
     
     for (NSDictionary *row in strings) {
         previousRect =[self drawLabel:row[kLabelKey]
                               details:row[kDescriptionKey]
                                origin:CGPointMake(previousRect.origin.x, previousRect.size.height + previousRect.origin.y + 10)
                              fontSize:[row[kFontSizeKey] floatValue]
                      newLineSeparator:[row[kNewLineKey] boolValue]];
     }
    
    
    if (YES) {
        //[self drawLogoImage];
        /*
         [self drawTextWithLeftAllignment:@"Certified By Wagner Meters"
         withFrame:CGRectMake(kBorderInset + kMarginInset+150, kBorderInset + kMarginInset + 850.0,400 , 80)
         withFont:[UIFont systemFontOfSize:24.0f]];
         */
    }
}


- (void) renderRowsForJob:(CGFloat)ypos data:(NSArray *)data startIndex:(long)startIndex count:(long)count {
    
    CGFloat xOrigin = 100;
    CGFloat yOrigin = ypos;
    CGFloat arrayColumnWidth[] = {160, 160, 160, 100, 120, 150, 150};
    int numberOfColumns = 7;
    
    // table header
    [self drawTableAt:CGPointMake(xOrigin, yOrigin)
        withRowHeight:kRowHeight
       andColumnWidth:arrayColumnWidth
          andRowCount:1
       andColumnCount:numberOfColumns];
    
    NSArray *labels = @[kReportDataSensorKey,
                        kreportDataSensorNameKey,
                        kReportDataLastCalDateKey,
                        kReportDataRhKey,
                        kReportDataTempKey,
                        kReportDataAmbRhKey,
                        kReportDataAmbTempKey
                        ];
    
    CGFloat fLeft = 0;
    for (int i = 0; i < [labels count]; i++) {
        [self drawText:labels[i]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10,
                                  arrayColumnWidth[i] - 20,
                                  80)
              withFont:[UIFont boldSystemFontOfSize:18.0f]];
        fLeft += arrayColumnWidth[i];
    }
    
    yOrigin += kRowHeight;
    
    
    [self drawTableAt:CGPointMake(xOrigin, yOrigin)
        withRowHeight:kRowHeight
       andColumnWidth:arrayColumnWidth
          andRowCount:(int)count
       andColumnCount:numberOfColumns];
    
    for (int i = (int)startIndex; i < (int)startIndex + count; i++) {
        UIFont *textFont = [UIFont systemFontOfSize:14.0f];
        
        NSDictionary *reportData = [data objectAtIndex:i];
        
        // sensor
        int column = 0;
        CGFloat fLeft = 0;
        [self drawText:reportData[kReportDataSensorKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // sensor name
        column++;
        [self drawText:reportData[kreportDataSensorNameKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // last cal date
        column++;
        [self drawText:reportData[kReportDataLastCalDateKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // salt
        column++;
        [self drawText:reportData[kReportDataRhKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // rh
        column++;
        [self drawText:reportData[kReportDataTempKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // temp
        column++;
        [self drawText:reportData[kReportDataAmbRhKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
        
        // cal cert due
        column++;
        [self drawText:reportData[kReportDataAmbTempKey]
             withFrame:CGRectMake(xOrigin + 10 + fLeft,
                                  yOrigin + 10 + (kRowHeight * (i - startIndex)),
                                  arrayColumnWidth[column] - 20,
                                  30)
              withFont:textFont
           placeholder:@""];
        fLeft += arrayColumnWidth[column];
    }
}


#pragma mark - utilities

- (CGRect)drawLabel:(NSString*)label
            details:(NSString*)details
             origin:(CGPoint)origin
           fontSize:(CGFloat)fontSize
   newLineSeparator:(BOOL)newLineSeparator
{
    
    UIFont *labelFont = [UIFont boldSystemFontOfSize:fontSize];
    UIFont *detailsFont = [UIFont systemFontOfSize:fontSize];
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          labelFont, NSFontAttributeName,
                                          nil];

    
    CGSize labelSize = [label boundingRectWithSize:CGSizeMake(700, 300)
                                           options:NSStringDrawingUsesDeviceMetrics attributes:attributesDictionary context:nil].size;
    
    CGRect labelFrame = {origin, labelSize};
    
    attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          detailsFont, NSFontAttributeName,
                                          nil];

    CGSize detailsSize = [details boundingRectWithSize:CGSizeMake(300, 100)
                                               options:NSStringDrawingUsesDeviceMetrics
                                               attributes:attributesDictionary context:nil].size;
    
    CGRect detailsFrame = {{0, 0}, detailsSize};
    CGRect totalFrame = {origin, {0, 0}};
    
    if (newLineSeparator) {
        detailsFrame.origin.x = origin.x;
        detailsFrame.origin.y = origin.y + labelSize.height + 10;
        
        totalFrame.size.width = MAX(labelSize.width, detailsSize.width);
        totalFrame.size.height = labelSize.height + detailsSize.height + 10;
    }
    else {
        detailsFrame.origin.x = origin.x + labelSize.width + 10;
        detailsFrame.origin.y = origin.y;
        
        totalFrame.size.width = labelSize.width + detailsSize.width + 10;
        totalFrame.size.height = MAX(labelSize.height, detailsSize.height);
    }
    
    [self drawText:label withFrame:labelFrame withFont:labelFont];
    [self drawText:details withFrame:detailsFrame withFont:detailsFont];
    
    return totalFrame;
}

- (void) drawImage {
    
    //UIImage * demoImage = [UIImage imageNamed:@"wagner_pdf_image.png"];
    UIImage * demoImage = [UIImage imageNamed:@"ReportLogo"];
    [demoImage drawInRect:CGRectMake( (pageSize.width - demoImage.size.width - 50), 40, demoImage.size.width, demoImage.size.height)];
}

- (void) drawLogoImage {
    
    //UIImage * demoImage = [UIImage imageNamed:@"wagner_pdf_logo.png"];
    UIImage * demoImage = [UIImage imageNamed:@"ReportLogoBottomCenter"];
    float scale = 4.0;
    float imageWidth = demoImage.size.width / scale;
    float imageHeight = demoImage.size.height / scale;
    
    [demoImage drawInRect:CGRectMake(pageSize.width / 2.0 - imageWidth / 2.0 , pageSize.height - imageHeight - kBorderInset - kMarginInset - 200/*pagenumber*/, demoImage.size.width / 5.0, demoImage.size.height / 5.0)];
}

- (void)drawPageNumber:(NSInteger)pageNumber {
    
    NSString* pageNumberString = [NSString stringWithFormat:@"Page %d", (int)pageNumber];
    UIFont* theFont = [UIFont systemFontOfSize:16];
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          theFont, NSFontAttributeName,
                                          nil];
    
    CGSize pageNumberStringSize = [pageNumberString boundingRectWithSize:pageSize
                                                                 options:NSStringDrawingUsesDeviceMetrics attributes:attributesDictionary context:nil].size;
    
    CGRect stringRenderingRect = CGRectMake(kBorderInset,
                                            pageSize.height - 80.0,
                                            pageSize.width - 2*kBorderInset,
                                            pageNumberStringSize.height);
    
    
    //add alignment
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          theFont, NSFontAttributeName,
                            paragraphStyle, NSParagraphStyleAttributeName,
                                          nil];

    
    [pageNumberString drawInRect:stringRenderingRect withAttributes:attributesDictionary];
}

- (void)renderHeader {
    UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, pageSize.width, pageSize.height), nil);
    
    //UIFont *font = [UIFont systemFontOfSize:12.0f];
    /*
    NSString *strHeader = [NSString stringWithFormat:@"Job: %@ \t\t Location: %@", job.jobName, loc.locName];
    CGFloat width = [CommonMethods widthOfString:strHeader withFont:font] + 20;
    
    [self drawText:strHeader
         withFrame:CGRectMake(50, 60, width, 20)
          withFont:font];
    
    */
    
    CGPoint from = CGPointMake(40, 90);
    CGPoint to = CGPointMake(pageSize.width - 80, 90);
    
    [self drawLineFromPoint:from toPoint:to];
}

- (void) drawText:(NSString*)textToDraw
        withFrame:(CGRect)renderingRect
         withFont:(UIFont*)font
{
    
    [self drawText:textToDraw
         withFrame:renderingRect
          withFont:font
       placeholder:@""];
}

- (void) drawText:(NSString*)textToDraw
        withFrame:(CGRect)renderingRect
         withFont:(UIFont*)font
      placeholder:(NSString*)placeholder
{
    
    if (textToDraw == nil) {
        textToDraw = placeholder;
    }
    CGContextRef    currentContext = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(currentContext, 0.0, 0.0, 0.0, 1.0);
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName,
                                          nil];
    
    [textToDraw drawInRect:renderingRect withAttributes:attributesDictionary];
//     drawInRect:renderingRect
//                  withFont:font
//             lineBreakMode:NSLineBreakByWordWrapping
//                 alignment:NSTextAlignmentCenter];
    
}

-(void)drawLineFromPoint:(CGPoint)from toPoint:(CGPoint)to {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {0.2, 0.2, 0.2, 0.3};
    CGColorRef color = CGColorCreate(colorspace, components);
    
    CGContextSetStrokeColorWithColor(context, color);
    
    CGContextMoveToPoint(context, from.x, from.y);
    CGContextAddLineToPoint(context, to.x, to.y);
    
    CGContextStrokePath(context);
    CGColorSpaceRelease(colorspace);
    CGColorRelease(color);
    
}

-(void)drawTableAt:(CGPoint)origin
     withRowHeight:(int)rowHeight
    andColumnWidth:(CGFloat*)arrayColumnWidth
       andRowCount:(int)numberOfRows
    andColumnCount:(int)numberOfColumns

{
    for (int i = 0; i <= numberOfRows; i++) {
        
        CGFloat width = 0;
        for (int j = 0; j < numberOfColumns; j++) {
            width += arrayColumnWidth[j];
        }
        
        int newOrigin = origin.y + (rowHeight*i);
        
        CGPoint from = CGPointMake(origin.x, newOrigin);
        CGPoint to = CGPointMake(origin.x + width, newOrigin);
        
        [self drawLineFromPoint:from toPoint:to];
    }
    
    CGFloat fLeft = 0;
    for (int i = 0; i <= numberOfColumns; i++) {
        
        int newOrigin = origin.x + fLeft;
        
        CGPoint from = CGPointMake(newOrigin, origin.y);
        CGPoint to = CGPointMake(newOrigin, origin.y +(numberOfRows*rowHeight));
        
        [self drawLineFromPoint:from toPoint:to];
        
        if (i < numberOfColumns)
            fLeft += arrayColumnWidth[i];
    }
}

- (BOOL) isInPage:(CGFloat)ypos {
    if (ypos >= A4PAPER_HEIGHT_IN_PORTRATE-120)
        return NO;
    return YES;
}

- (CGFloat) heightRemains:(CGFloat)ypos {
    return A4PAPER_HEIGHT_IN_PORTRATE-120-ypos;
}

@end
