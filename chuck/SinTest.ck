// create our OSC receiver
OscRecv orec;
// port 9999
9999 => orec.port;
// start listening (launch thread)
orec.listen();
// sin osc for goofy testing
SinOsc s => Gain g => dac;
0.1 => g.gain;

orec.event("/test,f") @=> OscEvent rate_event; 

while ( true )
{ 
    rate_event => now; // wait for events to arrive.
    
    // grab the next message from the queue. 
    while( rate_event.nextMsg() != 0 )
    {   
        
        rate_event.getFloat() => float f;
        f => s.freq;
        <<< f >>>;
    }
}
