//-----------------------------------------------------------------------------
// name: mo_thread.h
// desc: defines for threads
//
// authors: Ge Wang (ge@ccrma.stanford.edu)
//    date: Fall 2009
//    version: 0.2
//
// Stanford Mobile Phone Orchestra
//     http://mopho.stanford.edu/
//-----------------------------------------------------------------------------
#ifndef __MO_THREAD_H__
#define __MO_THREAD_H__

#include "mo_def.h"
#include <pthread.h>

#define THREAD_TYPE
typedef pthread_t THREAD_HANDLE;
typedef void * THREAD_RETURN;
typedef void * (*THREAD_FUNCTION)(void *);
typedef pthread_mutex_t MUTEX;


//-----------------------------------------------------------------------------
// name: struct MoThread
// desc: ...
//-----------------------------------------------------------------------------
struct MoThread
{
public:
    MoThread();
    ~MoThread();

public:
    // begin execution of the thread routine
    // the thread routine can be passed an argument via ptr
    bool start( THREAD_FUNCTION routine, void * ptr = NULL );

    // wait the specified number of milliseconds for the thread to terminate
    bool wait( long milliseconds = -1 );
    
    // set priority
    bool setPriority( long priority );
    
public:
    // set current thread priority
    static bool setSelfPriority( long priority );

public:
    // test for a thread cancellation request.
    static void test( );
    
    // clear
    void clear() { thread = 0; }

protected:
    THREAD_HANDLE thread;
};




//-----------------------------------------------------------------------------
// name: struct MoMutex
// desc: ...
//-----------------------------------------------------------------------------
struct MoMutex
{
public:
    MoMutex();
    ~MoMutex();

public:
    void acquire( );
    void release(void);

protected:
    MUTEX mutex;
};




#endif
