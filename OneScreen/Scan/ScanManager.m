//
//  ScanManager.m
//
//  Created by Igor Ishchenko on 12/20/13.
//  Copyright (c) 2013 Igor Ishchenko All rights reserved.
//

#import "ScanManager.h"

#ifdef TEST_FLIGHT_ENGAGED
#import "TestFlight.h"
#endif

static const int kPackageID = 0xDEB93390;

@interface ScanManager ()

@property (nonatomic, retain) CBCentralManager *bluetoothCentralManager;

- (void)showAlertWithTitle:(NSString*)title description:(NSString*)description;

@end

@implementation ScanManager

- (id)init {
    return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id<ScanManagerDelegate>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
        _bluetoothCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }

    return self;
}

- (void)startScan {
    [[self bluetoothCentralManager] scanForPeripheralsWithServices:nil
                                                           options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];

    if ([[self delegate] respondsToSelector:@selector(scanManagerDidStartScanning:)]) {
        [[self delegate] scanManagerDidStartScanning:self];
        NSLog(@"Started scan");
    }

}

- (void)stopScan {
    [[self bluetoothCentralManager] stopScan];
    NSLog(@"Stopped scan");
}

- (void)restartScan {
    [self stopScan];
    [self startScan];
    NSLog(@"Restarted scan");

}

#pragma mark - Bluetooth

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    NSString *stateDescription;

    switch ([central state]) {
        case CBCentralManagerStateResetting:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStateResetting %d ", central.state];
            break;
        case CBCentralManagerStateUnsupported:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStateUnsupported %d ", central.state];
            [self showAlertWithTitle:@"Error"
                         description:@"This device does not support Bluetooth low energy."];
            break;
        case CBCentralManagerStateUnauthorized:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStateUnauthorized %d ", central.state];
            [self showAlertWithTitle:@"Unauthorized!"
                         description:@"This app is not authorized to use Bluetooth low energy.\n\nAuthorize in Settings > Bluetooth."];
            break;
        case CBCentralManagerStatePoweredOff:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStatePoweredOff %d ", central.state];
            [self showAlertWithTitle:@"Powered Off"
                         description:@"Bluetooth is currently powered off.\n\nPower ON the bluetooth in Settings > Bluetooth."];
            break;
        case CBCentralManagerStatePoweredOn:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStatePoweredOn %d ", central.state];
            [self startScan];
            break;
        case CBCentralManagerStateUnknown:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStateUnknown %d ", central.state];
            break;
        default:
            stateDescription = [NSString stringWithFormat:@"CBCentralManager Undefined %d ", central.state];
            break;
    }

    NSLog(@"centralManagerDidUpdateState:[%@]",stateDescription);

#ifdef TEST_FLIGHT_ENGAGED
#ifdef TEST_FLIGHT_CHECKPOINTS_ENABLED
#ifdef TEST_FLIGHT_HEAVY_DEBUG_ENABLED
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"WagnerDMiOS:centralManagerDidUpdateState:%@:%@",
                                [[Context getInstance] getValue:UNIQUE_DEVICE_ID_KEY],
                                stateDescription]];
    NSLog(@"%@",[NSString stringWithFormat:@"WagnerDMiOS:centralManagerDidUpdateState:%@:%@",
                 [[Context getInstance] getValue:UNIQUE_DEVICE_ID_KEY],
                 stateDescription]);
#endif
#endif
#endif
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
#ifdef TEST_FLIGHT_ENGAGED
#ifdef TEST_FLIGHT_CHECKPOINTS_ENABLED
#ifdef TEST_FLIGHT_HEAVY_DEBUG_ENABLED
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"WagnerDMiOS:didDiscoverPeripheral:%@:name=[%@]",
                                [[Context getInstance] getValue:UNIQUE_DEVICE_ID_KEY],
                                peripheral.name]];
    NSLog(@"%@",[NSString stringWithFormat:@"WagnerDMiOS:didDiscoverPeripheral:%@:name=[%@]",
                 [[Context getInstance] getValue:UNIQUE_DEVICE_ID_KEY],
                 peripheral.name]);
#endif
#endif
#endif


    //NSString *name = [advertisementData valueForKey:CBAdvertisementDataLocalNameKey];
    NSData *manufacturedData = [advertisementData valueForKey:CBAdvertisementDataManufacturerDataKey];
    //NSDictionary *serviceDict = [advertisementData valueForKey:CBAdvertisementDataServiceDataKey];
    //NSArray *serviceUUIDsArray = [advertisementData valueForKey:CBAdvertisementDataServiceUUIDsKey];
    //NSArray *overflowServiceUUIDsArray = [advertisementData valueForKey:CBAdvertisementDataOverflowServiceUUIDsKey];
    //NSNumber *transmitPower = [advertisementData valueForKey:CBAdvertisementDataTxPowerLevelKey];

    NSMutableData* dataToParse = nil;
    NSInteger offset;
    NSDictionary *sensorData;

    if (manufacturedData) {
        if(![[manufacturedData subdataWithRange:NSMakeRange(0, 4)] isEqualToData:
             [NSData dataWithBytes:&kPackageID length:4]])
        {
            NSLog(@"Third party package was received.");
            if (self.delegate)
                [self.delegate scanManager:self didFindElseDevice:nil];
            return;
        }

        dataToParse = (NSMutableData*)manufacturedData;
        offset = 0;

        SensorReadingParser *parser = [[SensorReadingParser alloc] init];
        sensorData = [parser parseData:dataToParse  withOffset:offset];

    }
    else {
        ///note, that uuid1 is 128-bit uuid that contain first 16 bytes according to the specification: 3-bytes flag, length byte and so on.
        ///uuid2(which is 16-bit uuid) contains last byte of S2T field and battery level byte. This is where specification order is violated.
        ///Last 3 uuids contains full Serial number order.
        NSArray* uuidsArray = advertisementData[CBAdvertisementDataServiceUUIDsKey];

        CBUUID* uuid1 = [uuidsArray firstObject];

        UInt32 packageID = kPackageID;
        ///uuid comes right after flag, length and dataType bytes.
        if(![[[uuid1 data] subdataWithRange:NSMakeRange(5, 4)] isEqualToData:
             [NSData dataWithBytes:&packageID length:4]])
        {
            NSLog(@"Third party package was received.");
            if (self.delegate)
                [self.delegate scanManager:self didFindElseDevice:nil];
            return;
        }

        CBUUID* uuid2 = uuidsArray[1];
        CBUUID* uuid3 = uuidsArray[2];
        CBUUID* uuid4 = uuidsArray[3];
        CBUUID* uuid5 = uuidsArray[4];

        NSData* firstPackage = [uuid1 data];
        NSData* secondPackage = [uuid2 data];
        NSMutableData* serialData = [NSMutableData dataWithData:[uuid3 data]];
        [serialData appendData:[uuid4 data]];
        [serialData appendData:[uuid5 data]];

        dataToParse = [NSMutableData dataWithData:firstPackage];
        [dataToParse appendData:[secondPackage subdataWithRange:NSMakeRange(0, 1)]];
        [dataToParse appendData:serialData];
        [dataToParse appendData:[secondPackage subdataWithRange:NSMakeRange(1, 1)]];
        offset = 5;

        EmulatorReadingParser *parser = [[EmulatorReadingParser alloc] init];
        sensorData = [parser parseData:dataToParse  withOffset:offset];
    }

#ifndef RELEASE
    NSString * outputString = @"";
    NSLog(@"%@",outputString);
    for (int ix=offset; ix<dataToParse.length; ix++) {
        unsigned char c;
        [dataToParse getBytes:&c range:NSMakeRange(ix, 1)];
        outputString = [outputString stringByAppendingFormat:@"%02X ",c];
    }
    NSLog(@"Debug output sensor data: %@",outputString);
#endif

    [[self delegate] scanManager:self
                   didFindSensor:sensorData];
}

- (void)showAlertWithTitle:(NSString *)title description:(NSString *)description {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:description
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    
    [alert performSelectorOnMainThread:@selector(show)
                            withObject:nil
                         waitUntilDone:YES];
}

@end
