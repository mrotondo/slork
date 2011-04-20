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

spork ~ Scenes.startPiece() @=> Shred @ scenes_shred;
me.yield();
<<< "BPM in feedbork is: " + Scenes.bpm >>>;

MelodyVoice voice;
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

// Collapse these down into one listener for two floats
0 => int manual_note_choice;
class NotePitchListener extends FloatListener
{
    fun void handleEvent()
    {
        event.getFloat() => float f;
		f < 0.5 => manual_note_choice;
    }
}

class NoteTriggerListener extends FloatListener
{
    fun void handleEvent()
    {
        event.getFloat() => float f;
		voice.ChooseNextNote(manual_note_choice, f);
    }
}

ReverbListener reverb_listener;
reverb_listener.init(orec, "centroid_x");
spork ~ reverb_listener.go() @=> Shred @ reverb_shred;

HPFFreqListener hpf_freq_listener;
hpf_freq_listener.init(orec, "centroid_y");
spork ~ hpf_freq_listener.go() @=> Shred @ hpf_freq_shred;

NotePitchListener note_pitch_listener;
note_pitch_listener.init(orec, "tap_x");
spork ~ note_pitch_listener.go() @=> Shred @ note_pitch_shred;

NoteTriggerListener note_trigger_listener;
note_trigger_listener.init(orec, "tap_y");
spork ~ note_trigger_listener.go() @=> Shred @ note_trigger_shred;

1::minute / (Scenes.bpm * 8) => dur eighth_note_duration;
now => time start_offset;

while(true) {
	for (0 => int i; i < 8; i++) {
		voice.PlayNextNote();
		eighth_note_duration => now;
	}
}