class FeedborkListener
{
    OscEvent @ event;
    
    fun void init(OscRecv orec, string event_name, string event_type)
    {
        orec.event("/" + event_name + "," + event_type) @=> event;
    }
    
    fun void go()
    {
        while (true)
        {
            event => now;
            
            while (event.nextMsg() != 0)
            {
                handleEvent();
            }
        }
    }
    
    fun void handleEvent()
    {
    }
}

class FloatListener extends FeedborkListener
{    
    fun void init(OscRecv orec, string event_name)
    {
        orec.event("/" + event_name + ",f") @=> event;
    }
}

// Create mapping listeners here!!

// create our OSC receiver
OscRecv orec;
// port 9999
9999 => orec.port;
// start listening (launch thread)
orec.listen();
// sin osc for goofy testing
//PulseOsc s => Gain g => dac;
//0.1 => g.gain;

orec.event("/IP,s") @=> OscEvent IP_event;
OscSend xmit;
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
spork ~ getIP();

FloatListener centroid_x_listener;
centroid_x_listener.init(orec, "centroid_x");
spork ~ centroid_x_listener.go() @=> Shred @ centroid_x_shred;

FloatListener centroid_y_listener;
centroid_y_listener.init(orec, "centroid_y");
spork ~ centroid_y_listener.go() @=> Shred @ centroid_y_shred;

while(true)
{
    day => now;
}