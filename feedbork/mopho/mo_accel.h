//-----------------------------------------------------------------------------
// name: mo_accel.h
// desc: MoPhO API for accelerometer
//
// authors: Nick Bryan
//          Jieun Oh
//          Jorge Herrera
//          Ge Wang
//
//    date: Fall 2009
//    version: 0.2
//
// Stanford Mobile Phone Orchestra
//     http://mopho.stanford.edu/
//-----------------------------------------------------------------------------
#ifndef __MO_ACCEL_H__
#define __MO_ACCEL_H__

#include "mo_def.h"
#include <vector>


@interface AccelDelegate : NSObject <UIAccelerometerDelegate>
{ }
@end


// type definition for accelerometer callback function
typedef void (* MoAccelCallback)( double x, double y, double z, void * data );


//-----------------------------------------------------------------------------
// name: class MoAccel
// desc: accelerometer stuff (singleton)
//-----------------------------------------------------------------------------
class MoAccel
{
public: // setting values
    
    // set the global update interval
    static void setUpdateInterval( double seconds );
    // get the global update interval
    static double getUpdateInterval();

public: // getting values

    // returns current (x,y,z) values (for polling)
    static void getXYZ( double & px, double & py, double & pz );
    // returns current (x) value (for polling)
    static double getX();
    // returns current (y) value (for polling)
    static double getY();
    // returns current (z) value (for polling)
    static double getZ();

public: // callbacks
    
    // register a callback to be invoked on subsequent updates
    static void addCallback( const MoAccelCallback & callback, void * data );
    // unregister a callback
    static void removeCallback( const MoAccelCallback & callback );
    static const double MAX_ACCEL_RATE;

public:
    // this should be called on new values (UIAccelerometerDelegate)
    static void update( double x, double y, double z );

private:
    // check if one time set up is needed
    static void checkSetup();

    // current values;
    static double m_x;
    static double m_y;
    static double m_z;

    // update interval
    static double m_updateInterval;

    // accelerometer Delegate
    static AccelDelegate * accelDelegate;

    // queue of callbacks
    static std::vector<MoAccelCallback> m_clients;
    static std::vector<void *> m_clientData;
    // TODO: update the add and remove functions with the void * data
};


#endif
