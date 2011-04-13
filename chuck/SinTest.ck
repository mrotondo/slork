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
orec.event("/IP,s") @=> OscEvent IP_event; 
OscSend xmit;
spork ~ getIP();

while ( true )
{ 
    //freq_event => now; // wait for events to arrive.
    
    // grab the next message from the queue. 
    //while( freq_event.nextMsg() != 0 )
    //{   
        
    //    freq_event.getFloat() => float f;
    //    f => s.freq;
    //    <<< f >>>;
    //}
    
    //cutoff_event => now; // wait for events to arrive.
    
    // grab the next message from the queue. 
    //while( cutoff_event.nextMsg() != 0 )
    //{   
        
    //    cutoff_event.getFloat() => float f;
    //    f => s.width;
    //    <<< f >>>;
    //} 
         
    xmit.startMsg("test, i");
    xmit.addInt(10);
    
    1::second => now;
}

fun void getIP()
{
    IP_event => now; 
    string s;
    // grab the next message from the queue. 
    while( IP_event.nextMsg() != 0 )
    {   
        IP_event.getString() => s;
    }
    <<< s >>>;
    xmit.setHost(s, 9998);
}
    