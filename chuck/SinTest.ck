// create our OSC receiver
OscRecv orec;
// port 9999
9999 => orec.port;
// start listening (launch thread)
orec.listen();
// sin osc for goofy testing
PulseOsc s => Gain g => dac;
0.1 => g.gain;

orec.event("/freq,f") @=> OscEvent freq_event; 
orec.event("/cutoff,f") @=> OscEvent cutoff_event; 

while ( true )
{ 
    freq_event => now; // wait for events to arrive.
    
    // grab the next message from the queue. 
    while( freq_event.nextMsg() != 0 )
    {   
        
        freq_event.getFloat() => float f;
        f => s.freq;
        <<< f >>>;
    }

    cutoff_event => now; // wait for events to arrive.
    
    // grab the next message from the queue. 
    while( cutoff_event.nextMsg() != 0 )
    {   
        
        cutoff_event.getFloat() => float f;
        f => s.width;
        <<< f >>>;
    }
    
    <<< "-----" >>>;
}
