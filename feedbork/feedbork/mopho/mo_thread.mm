//-----------------------------------------------------------------------------
// name: mo_thread.cpp
// desc: wrapper threads
//
// authors: Ge Wang (ge@ccrma.stanford.edu)
//    date: October 2009
//    version: 0.2
//
// Stanford Mobile Phone Orchestra
//     http://mopho.stanford.edu/
//-----------------------------------------------------------------------------
#include "mo_thread.h"
#include <iostream>




//-----------------------------------------------------------------------------
// name: MoThread()
// desc: ...
//-----------------------------------------------------------------------------
MoThread::MoThread( )
{
    thread = 0;
}




//-----------------------------------------------------------------------------
// name: ~MoThread()
// desc: ...
//-----------------------------------------------------------------------------
MoThread::~MoThread( )
{
    if( thread != 0 )
    {
        pthread_cancel(thread);
        pthread_join(thread, NULL);
    }
}




//-----------------------------------------------------------------------------
// name: start()
// desc: ...
//-----------------------------------------------------------------------------
bool MoThread::start( THREAD_FUNCTION routine, void * ptr )
{
    bool result = false;
    
    if( pthread_create( &thread, NULL, *routine, ptr ) == 0 )
        result = true;

    return result;
}




//-----------------------------------------------------------------------------
// name: wait()
// desc: ...
//-----------------------------------------------------------------------------
bool MoThread::wait( long milliseconds )
{
    bool result = false;
    
    pthread_cancel(thread);
    pthread_join(thread, NULL);

    return result;
}




//-----------------------------------------------------------------------------
// name: test()
// desc: ...
//-----------------------------------------------------------------------------
void MoThread :: test( )
{
    pthread_testcancel();
}




//-----------------------------------------------------------------------------
// name: MoMutex()
// desc: ...
//-----------------------------------------------------------------------------
MoMutex::MoMutex( )
{
    pthread_mutex_init(&mutex, NULL);
}




//-----------------------------------------------------------------------------
// name: MoMutex()
// desc: ...
//-----------------------------------------------------------------------------
MoMutex::~MoMutex( )
{
    pthread_mutex_destroy( &mutex );
}




//-----------------------------------------------------------------------------
// name: acquire()
// desc: ...
//-----------------------------------------------------------------------------
void MoMutex::acquire( )
{
    pthread_mutex_lock(&mutex);
}




//-----------------------------------------------------------------------------
// name: unlock()
// desc: ...
//-----------------------------------------------------------------------------
void MoMutex::release( )
{
    pthread_mutex_unlock(&mutex);
}




//-----------------------------------------------------------------------------
// name: setPriority()
// desc: ...
//-----------------------------------------------------------------------------
bool setPriority( pthread_t thread, long priority )
{
    struct sched_param param;
    int policy;
    
    // log
    std::cerr << "[mopho]: setting thread priority to: " << priority << "..." << std::endl;
    
    // get for thread
    if( pthread_getschedparam( thread, &policy, &param) ) 
        goto doh;
    
    // priority
    param.sched_priority = priority;
    // policy
    policy = SCHED_RR;
    // set for thread
    if( pthread_setschedparam( thread, policy, &param ) )
        goto doh;
    
    return true;
    
doh:
    // log
    std::cerr << "[mopho]: failed to set thread priority!" << std::endl;
    
    return false;
}




//-----------------------------------------------------------------------------
// name: setPriority()
// desc: ...
//-----------------------------------------------------------------------------
bool MoThread::setPriority( long priority )
{
    return ::setPriority( thread, priority );
}




//-----------------------------------------------------------------------------
// name: setSelfPriority()
// desc: ...
//-----------------------------------------------------------------------------
bool MoThread::setSelfPriority( long priority )
{
    return ::setPriority( pthread_self(), priority );
}