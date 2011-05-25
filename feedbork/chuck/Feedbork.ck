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

class IntListener extends FeedborkListener
{    
    fun void init(OscRecv orec, string event_name)
    {
        orec.event("/" + event_name + ",i") @=> event;
    }
}

class PointListener extends FeedborkListener
{
    fun void init(OscRecv orec, string event_name)
    {
        orec.event("/" + event_name + ",f f") @=> event;
    }	
}

// create our OSC receiver for messages from the iPad
OscRecv orec;
// port 9999
9999 => orec.port;
// start listening (launch thread)
orec.listen();

// create our OSC receiver for messages from the time server
OscRecv time_orec;
// port 9997
9997 => time_orec.port;
// start listening (launch thread)
time_orec.listen();

OscEvent @ now_event;
time_orec.event("/now, i") @=> now_event;

<<< "BPM in feedbork is: " + Scenes.bpm >>>;

Bass voice;
spork ~ voice.updateParams() @=> Shred @ voice_shred;

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


// Melody modifying gesture listeners
class HPFFreqListener extends FloatListener
{
    fun void handleEvent()
    {
        event.getFloat() => float f;
		//voice.SetHPFFreq(Math.max(10, f / 10000 - 1000));
    }
}

class BrightnessListener extends FloatListener
{
    fun void handleEvent()
    {
        event.getFloat() => float f;
		voice.setBrightness(f);
    }
}

class NoteStartListener extends PointListener
{
    fun void handleEvent()
    {
        event.getFloat() => float x;
        event.getFloat() => float y;
		x < 0.5 => int manual_note_choice;
		voice.setStartPoint(x, y);
		voice.ChooseNextNote(manual_note_choice, y);
		voice.PlayNextNote();
    }
}

class NoteModListener extends PointListener
{
	fun void handleEvent()
	{
        event.getFloat() => float x;
        event.getFloat() => float y;
		voice.setDistortion(x);
		voice.setModDepth(y);
		voice.setModRate(y);
	}
}

class NoteStopListener extends PointListener
{
    fun void handleEvent()
    {
        event.getFloat() => float x;
        event.getFloat() => float y;
		voice.StopPlayingNote();
    }
}

class KeyListener extends IntListener
{
    fun void handleEvent()
    {
        event.getInt() => int i;
		voice.SetKey(i);
    }
}

// ReverbListener reverb_listener;
// reverb_listener.init(orec, "centroid_x");
// spork ~ reverb_listener.go() @=> Shred @ reverb_shred;

BrightnessListener brightness_listener;
brightness_listener.init(orec, "brightness");
spork ~ brightness_listener.go();

NoteStartListener note_start_listener;
note_start_listener.init(orec, "bassTouchBegan");
spork ~ note_start_listener.go();

NoteModListener note_mod_listener;
note_mod_listener.init(orec, "bassTouchMoved");
spork ~ note_mod_listener.go();

NoteStopListener note_stop_listener;
note_stop_listener.init(orec, "bassTouchEnded");
spork ~ note_stop_listener.go();

KeyListener key_listener;
key_listener.init(orec, "chord");
spork ~ key_listener.go();

1::minute / (Scenes.bpm * 8) => dur eighth_note_duration;
now => time start_offset;

while(true) {
	for (0 => int i; i < 8; i++) {
		eighth_note_duration => now;
	}
}