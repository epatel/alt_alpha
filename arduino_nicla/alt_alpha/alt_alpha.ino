#include "ArduinoBLE.h"
#include "Arduino_BHY2.h"
#include "Nicla_System.h"
#include "utility/HCI.h"

static void do_init();
static void do_idle();
static void do_record();
static void do_fetch();
static void do_live();
static void do_error();
static void BLE_update();
static void commandReceived(BLEDevice central, BLECharacteristic characteristic);
static void gotoState(short newState);

const float accelerometerFactor = 4096;
static float accelerometerXYZMagnitude();

#define LOGGING 0
#if LOGGING
#define log_init Serial.begin(115200)
#define log(str) Serial.println(str)
#else
#define log_init
#define log(str)
#endif

static Sensor airpressure(SENSOR_ID_BARO);
static SensorXYZ accelerometer(SENSOR_ID_ACC);

#define ENCODE_FORCE(_f) ((_f / 50.0) * 0xffff);
#define ENCODE_PRESSURE(_p) (((_p - 600.0) / 600.0) * 0xffff);

struct Sample
{
    unsigned short force;
    unsigned short airpressure;
};

struct FetchSample
{
    unsigned short index;
    Sample liveSample;
};

// echo phrase | xxd > UUID
// echo 0:UUID | xxd -r
static BLEService bleService("65706174-656C-2E61-6C70-68612E626C65");
static BLEByteCharacteristic commandCharacteristic("65706174-656C-2E62-6C65-2E636D642E2E", BLERead | BLEWrite);
static BLEByteCharacteristic stateCharacteristic("65706174-656C-2E62-6C65-2E7374617465", BLERead | BLENotify);
static BLECharacteristic liveCharacteristic("65706174-656C-2E62-6C65-2E6C6976652E", BLERead | BLENotify, sizeof(Sample));
static BLECharacteristic fetchCharacteristic("65706174-656C-2E62-6C65-2E6665746368", BLERead | BLENotify, sizeof(FetchSample));

// BLE state
enum
{
    ble_state_waiting_for_connection,
    ble_state_connected,
};

// Global state
enum
{
    state_init,   // 0
    state_idle,   // 1
    state_live,   // 2
    state_record, // 3
    state_fetch,  // 4
    state_error   // 5
};

// Commands
enum
{
    cmd_queryState,  // 0
    cmd_recordStart, // 1
    cmd_recordAbort, // 2
    cmd_recordFetch, // 3
    cmd_recordDone,  // 4
    cmd_liveStart,   // 5
    cmd_liveStop,    // 6
    cmd_error        // 7
};

static short state = state_init;
static short counter = 0;
#define MAX_SAMPLES 540
static Sample recording[MAX_SAMPLES];
static short recordingLen = 0;
#define LIVE_AVGLEN 50                       //  50 => 1 Hz
#define RECORD_AVGLEN 15                     //  10 => 5 Hz, 15 => 3.333 Hz
static short liveAvgLen = (LIVE_AVGLEN * 2); // *2 b/c command /2
static double avgForce;
static double avgAirpressure;
static short numAvgSamples = 0;

#define LEDS 0
#if LEDS
#define RED nicla::leds.setColor(red)
#define GREEN nicla::leds.setColor(green)
#define BLUE nicla::leds.setColor(blue)
#define OFF nicla::leds.setColor(off)
#else
#define RED
#define GREEN
#define BLUE
#define OFF
#endif

void setup()
{
    log_init;

    nicla::begin();
    nicla::leds.begin();
    BHY2.begin(NICLA_I2C, NICLA_AS_SHIELD);

    airpressure.begin();
    accelerometer.begin();

    if (!BLE.begin())
    {
        log("Starting BLE failed!");
        gotoState(state_error);
    }
    else
    {
        uint8_t addr[6] = {0};
        HCI.readBdAddr(addr);
        char name[16];
        sprintf(name, "AltAlpha_%d", (addr[4] << 8) + addr[5]);
        BLE.setLocalName(name);
        commandCharacteristic.setEventHandler(BLEWritten, commandReceived);
        BLE.setAdvertisedService(bleService);
        bleService.addCharacteristic(commandCharacteristic);
        bleService.addCharacteristic(stateCharacteristic);
        bleService.addCharacteristic(liveCharacteristic);
        bleService.addCharacteristic(fetchCharacteristic);
        BLE.addService(bleService);
        stateCharacteristic.writeValue(state);
        {
            Sample liveSample;
            liveSample.force = 0;
            liveSample.airpressure = 0;
            liveCharacteristic.writeValue(&liveSample, sizeof(liveSample));
        }
        {
            FetchSample fetchSample;
            fetchSample.index = 0;
            fetchSample.liveSample.force = 0;
            fetchSample.liveSample.airpressure = 0;
            fetchCharacteristic.writeValue(&fetchSample, sizeof(fetchSample));
        }
        BLE.advertise();
    }
}

void loop()
{
    static auto lastCheck = millis();
    BHY2.update();
    BLE_update();

    if (millis() - lastCheck >= 20)
    { // 20 ms == 50 Hz
        lastCheck = millis();
        switch (state)
        {
        case state_init:
            do_init();
            break;
        case state_idle:
            do_idle();
            break;
        case state_record:
            do_record();
            break;
        case state_fetch:
            do_fetch();
            break;
        case state_live:
            do_live();
            break;
        case state_error:
            do_error();
            break;
        }
    }
}

static void updateSamples()
{
    avgForce += accelerometerXYZMagnitude();
    avgAirpressure += airpressure.value();
    numAvgSamples++;
}

static void do_init()
{
    if (counter == 0)
    {
        RED;
    }
    if (counter == 20)
    {
        gotoState(state_idle);
    }
    else
    {
        counter++;
    }
}

static void do_idle()
{
    if (counter == 0)
    {
        BLUE;
        liveAvgLen = (LIVE_AVGLEN * 2); // *2 b/c command /2
    }
    counter++;
}

static void do_record()
{
    if (counter == 0)
    {
        recordingLen = 0;
        avgForce = 0;
        avgAirpressure = 0;
        numAvgSamples = 0;
    }
    if (recordingLen < MAX_SAMPLES)
    {
        updateSamples();
        if (!(counter % RECORD_AVGLEN))
        {
            GREEN;
            avgForce /= numAvgSamples;
            avgAirpressure /= numAvgSamples;
            recording[recordingLen].force = ENCODE_FORCE(avgForce);
            recording[recordingLen].airpressure =
                ENCODE_PRESSURE(avgAirpressure);
            recordingLen++;
            avgForce = 0;
            avgAirpressure = 0;
            numAvgSamples = 0;
        }
        else
        {
            OFF;
        }
    }
    else
    {
        RED;
    }
    counter++;
}

static void do_fetch()
{
    if (counter == 0)
    {
        counter++;
        BLUE;
    }
    recordingLen--;
    if (recordingLen >= 0)
    {
        FetchSample fetchSample;
        fetchSample.index = recordingLen;
        fetchSample.liveSample.force = recording[recordingLen].force;
        fetchSample.liveSample.airpressure =
            recording[recordingLen].airpressure;
        fetchCharacteristic.writeValue(&fetchSample, sizeof(fetchSample));
    }
    else
    {
        recordingLen = 0;
        gotoState(state_idle);
    }
}

static void do_live()
{
    if (counter == 0)
    {
        avgForce = 0;
        avgAirpressure = 0;
        numAvgSamples = 0;
    }
    updateSamples();
    if (!(counter % liveAvgLen) || liveAvgLen == 0)
    {
        GREEN;
        avgForce /= numAvgSamples;
        avgAirpressure /= numAvgSamples;
        Sample liveSample;
        liveSample.force = ENCODE_FORCE(avgForce);
        liveSample.airpressure = ENCODE_PRESSURE(avgAirpressure);
        liveCharacteristic.writeValue(&liveSample, sizeof(liveSample));
        avgForce = 0;
        avgAirpressure = 0;
        numAvgSamples = 0;
    }
    else
    {
        OFF;
    }
    counter++;
}

static void do_error()
{
    auto cycle = counter++ % 10;
    if (cycle > 6)
    {
        RED;
    }
    else
    {
        OFF;
    }
}

static float accelerometerXYZMagnitude()
{
    float x = accelerometer.x() / accelerometerFactor;
    float y = accelerometer.y() / accelerometerFactor;
    float z = accelerometer.z() / accelerometerFactor;
    return sqrtf(x * x + y * y + z * z);
}

static void BLE_update()
{
    static short ble_state = ble_state_waiting_for_connection;
    BLEDevice central = BLE.central();

    switch (ble_state)
    {
    case ble_state_waiting_for_connection:
        if (central)
        {
            ble_state = ble_state_connected;
            if (state != state_record)
            {
                gotoState(state_init);
            }
        }
        break;
    case ble_state_connected:
        if (!central)
        {
            ble_state = ble_state_waiting_for_connection;
            if (state != state_record)
            {
                gotoState(state_init);
            }
        }
        break;
    }
}

static void commandReceived(BLEDevice central,
                            BLECharacteristic characteristic)
{
    if (characteristic.valueLength() > 0)
    {
        switch (characteristic.value()[0])
        {
        case cmd_queryState:
            stateCharacteristic.writeValue(state);
            break;
        case cmd_recordStart:
            gotoState(state_record);
            break;
        case cmd_recordAbort:
            gotoState(state_idle);
            break;
        case cmd_recordFetch:
            gotoState(state_fetch);
            break;
        case cmd_recordDone:
            gotoState(state_idle);
            break;
        case cmd_liveStart:
            gotoState(state_live);
            liveAvgLen = liveAvgLen / 2;
            break;
        case cmd_liveStop:
            gotoState(state_idle);
            break;
        case cmd_error:
            gotoState(state_error);
            break;
        default:
            log(String("Unknown command: ") + characteristic.value()[0]);
        }
    }
}

void gotoState(short newState)
{
#if LOGGING
    char str[16];
    sprintf(str, "state: %d => %d", state, newState);
    log(str);
#endif
    if (newState != state)
    {
        stateCharacteristic.writeValue(newState);
    }
    state = newState;
    counter = 0;
}
