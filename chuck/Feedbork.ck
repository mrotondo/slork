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

// create our OSC receiver
OscRecv orec;
// port 9999
9999 => orec.port;
// start listening (launch thread)
orec.listen();

// OMG Make sure you add melody.ck before you add this file!
MelodyVoice voice;
spork ~ voice.Play() @=> Shred @ voice_shred;

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

class HPFFreqListener extends FloatListener
{
    fun void handleEvent()
    {
		
        event.getFloat() => float f;

		voice.SetHPFFreq(Math.max(10, -1000 + 3300 * f));
    }
}

class ReverbListener extends FloatListener
{
    fun void handleEvent()
    {
		
        event.getFloat() => float f;

		voice.SetReverbMix(f);
    }
}

ReverbListener centroid_x_listener;
centroid_x_listener.init(orec, "centroid_x");
spork ~ centroid_x_listener.go() @=> Shred @ centroid_x_shred;

HPFFreqListener centroid_y_listener;
centroid_y_listener.init(orec, "centroid_y");
spork ~ centroid_y_listener.go() @=> Shred @ centroid_y_shred;

while(true)
{
    day => now;
}