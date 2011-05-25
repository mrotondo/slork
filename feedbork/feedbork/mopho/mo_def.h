//-----------------------------------------------------------------------------
// name: mo_def.h
// desc: MoPhO API for accelerometer
//
// authors: Ge Wang (ge@ccrma.stanford.edu)
//          Nick Bryan
//          Jieun Oh
//          Jorge Hererra
//
//    date: Fall 2009
//    version: 0.2
//
// Stanford Mobile Phone Orchestra
//     http://mopho.stanford.edu/
//-----------------------------------------------------------------------------
#ifndef __MO_DEF_H__
#define __MO_DEF_H__

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

// pi
#define ONE_PI (3.14159265358979323846)
#define TWO_PI (2.0 * ONE_PI)
#define SQRT2  (1.41421356237309504880)

// safe object deletion
#define SAFE_DELETE(x) { delete x; x = NULL; }
#define SAFE_DELETE_ARRAY(x) { delete [] x; x = NULL; }

// mo stuff
#define SAMPLE Float32

#ifdef __cplusplus
extern "C"
{
#endif

static void mo_log(const char *s, ...)
{
    va_list ap;
    va_start(ap, s);
    
    NSString *str = [[NSString alloc] initWithCString:s];
    
    NSLogv(str, ap);
    
    [str release];
    
    va_end(ap);
}
    
#ifdef __cplusplus
}
#endif

#endif
