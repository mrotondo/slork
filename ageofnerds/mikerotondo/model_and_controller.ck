
// =======================================================================================
//
// Wequencer - Client's Model and Controller
//
// Jason Riggs
// jnriggs@stanford.edu
// http://slork.stanford.edu
//
// =======================================================================================


// ====================================================
//  Spork Stuff
// ====================================================

spork ~ serverTempoListener();
spork ~ keyboardControl();
spork ~ trackpadControl();


//====================================================
// Globals
//====================================================

// basenote range
60.0 + 6*12 => float kMaxBasenote;
60.0 - 4*12 => float kMinBasenote;
60.0 => float kDefaultBasenote;

// default envelope value
2 => int kDefaultEnvelope;
3 => int kDefaultTimbre; // 0 == sine, 1 == tri, 2 == square, 3 == saw
4 => int kMaxTimbres;

// server listener stuff
0 => int play;
int beat;
dur T_server;

// timbre
kDefaultTimbre => int timbre;

[ 
[2.0, 1.6, .75, 2.0],
[.001, 0.01, 0.0, 0.0],  
[.001, .1, 0.0, 0.0], 
[.001, .2, 0.0, 0.0], 
[.001, .4, 0.0, 0.0], 
[.1, .4, 0.0, 0.0], 
[.25, .1, .95, .25], 
[.5, .2, .9, .5], 
[1.0, .4, .85, 1.0], 
[1.5, .8, .8, 1.5] 
] @=> float envelopes[][];

envelopes[kDefaultEnvelope][0]::second => dur att;
envelopes[kDefaultEnvelope][1]::second => dur dec;
envelopes[kDefaultEnvelope][2] => float sus;
envelopes[kDefaultEnvelope][3]::second => dur rel;


// sequencer grid abstraction
/*
[
[null,null,null,null,null,null,null,null],
[null,null,null,null,null,null,null,null],
[null,null,null,null,null,null,null,null],
[null,null,null,null,null,null,null,null],
[null,null,null,null,null,null,null,null],
[null,null,null,null,null,null,null,null],
[null,null,null,null,null,null,null,null],
[null,null,null,null,null,null,null,null]
] @=> Client @ g_client_grid[][];
*/

// FOR CLIENT TEST ONLY, EVENTUALLY REPLACE WITH SERVER STUFF
8 => int g_k_num_rows;
8 => int g_k_num_cols;

0 => int g_player_row;
0 => int g_player_col;

// enable trackpad input (initially disabled)
1 => int trackpadEnabled;

0 => int g_SPL_column;

// basenote stuff
kDefaultBasenote => float basenote;

// sensitivity (instrument control)
.008 => float detuneSensitivity;
24.0 => float lpfSensitivity;

// keyboard thing
1 => int kKbdSpacebar;

// tempo range allowed (expressed as time between notes)
1000 => int kMaxTempo;
1 => int kMinTempo;


//====================================================
// OSC Receivers
//====================================================
OscRecv recv;
6449 => recv.port;
recv.listen();
recv.event( "/sync/dobeat, i, f" ) @=> OscEvent beat_event;


//====================================================
// OSC Senders
//====================================================

// OSC sender to supersaw instrument
OscSend send_to_instrument;
send_to_instrument.setHost("localhost", 7007);

// OSC sender for updating visualizer
OscSend send_to_visualizer;
send_to_visualizer.setHost("localhost", 7008);


//====================================================
// Func: serverTempoListener()
// Desc: listens to server for beats
//====================================================
fun void serverTempoListener() 
{
    while ( true )
    {
        beat_event => now;
        while( beat_event.nextMsg() != 0 )
        {
            beat_event.getInt() => beat;
            beat_event.getFloat()::second => T_server;
            doOneBeat();
        }
    }
}



//====================================================
// Func: playAnyExistingNotesAtCurrentPosition()
// Desc: plays this machines notes in current column
//====================================================
fun void playNotesAtCurrentPosition()
{
    for(0 => int i; i < g_k_num_rows; i++)
    {
        if(g_player_row == i && g_player_col == g_SPL_column)
        {
            60 => int note;
            
            // find note to play on pentatonic scale
            if     (g_player_row == 0) 60 => note;
            else if(g_player_row == 1) 62 => note;
            else if(g_player_row == 2) 64 => note;
            else if(g_player_row == 3) 67 => note;
            else if(g_player_row == 4) 69 => note;
            else if(g_player_row == 5) 72 => note;
            else if(g_player_row == 6) 74 => note;
            else if(g_player_row == 7) 76 => note;
            
            oscSendPlayNoteEvent(Std.mtof(note), 0.0, timbre, att/1::second, dec/1::second, sus, rel/1::second);
        }
    }
}


//====================================================
// Func: doOneBeat()
// Desc: Moves this client's sequencer by one beat
//====================================================
fun void doOneBeat()
{   
    // now move to next beat
    g_SPL_column++;
    if(g_SPL_column >= g_k_num_cols) 0 => g_SPL_column; // wrap
    
    // update visualizer
    send_to_visualizer.startMsg( "/sync/dobeat, i" );
    send_to_visualizer.addInt(g_SPL_column);
    
    // play new notes
    playNotesAtCurrentPosition();
}


// ====================================================
//  Keyboard Handling
// ====================================================

// the device number to open
0 => int keyboardNum;

// instantiate a HidIn object
Hid keyboardIn;
// structure to hold HID messages
HidMsg keyboardMsg;

// open keyboard
if( !keyboardIn.openKeyboard( keyboardNum ) ) me.exit();
// successful! print name of device
<<< "keyboard '", keyboardIn.name(), "' ready" >>>;

fun void keyboardControl() 
{
    while( true )
    {
        // wait on event
        keyboardIn => now;
        
        // get one or more messages
        while( keyboardIn.recv( keyboardMsg ) )
        {
            //<<< "Keyboard msg:", keyboardMsg.which >>>;
            
            // 0 == up, 1 == down, 2 == left, 3 == right
            
            // BUTTON DOWN EVENTS
            if(keyboardMsg.isButtonDown())
            {
                // left
                if(keyboardMsg.which == 80)
                {
                    if(g_player_col > 0) g_player_col--;
                    send_to_visualizer.startMsg( "/sync/playermoved, i" );
                    send_to_visualizer.addInt(2);
                }
                // right
                else if(keyboardMsg.which == 79)
                {
                    if(g_player_col < 7) g_player_col++;
                    send_to_visualizer.startMsg( "/sync/playermoved, i" );
                    send_to_visualizer.addInt(3);
                }
                // down
                else if(keyboardMsg.which == 81)
                {
                    if(g_player_row > 0) g_player_row--;
                    send_to_visualizer.startMsg( "/sync/playermoved, i" );
                    send_to_visualizer.addInt(0);
                }
                // up
                else if(keyboardMsg.which == 82)
                {
                    if(g_player_row < 7) g_player_row++;
                    send_to_visualizer.startMsg( "/sync/playermoved, i" );
                    send_to_visualizer.addInt(1);
                }
                
                // select envelope using 0 - 9 keys
                else if( keyboardMsg.which >= 30 && keyboardMsg.which <= 39 && keyboardMsg.isButtonDown() )
                {
                    setEnvelope(keyboardMsg.which);
                }
                
                // spacebar down to activate trackpad
                if( keyboardMsg.which == 44)
                {
                    // SPACEBAR DOWN
                }
                
               
            }
            else if(keyboardMsg.isButtonUp())
            {
                if( keyboardMsg.which == 44)
                {
                    // SPACEBAR UP
                }
            }
        }
    }
}


//====================================================
// Trackpad Handling
//====================================================

// the device number to open
0 => int trackpadNum;

// instantiate a HidIn object
Hid trackpadIn;
// structure to hold HID messages
HidMsg trackpadMsg;

// open mouse 0, exit on fail
if( !trackpadIn.openMouse( trackpadNum ) ) me.exit();
// successful! print name of device
<<< "mouse '", trackpadIn.name(), "' ready" >>>;

fun void trackpadControl()
{
    // infinite event loop
    while( true )
    {
        // wait on Hid as event
        trackpadIn => now;
        
        // messages received
        while( trackpadIn.recv( trackpadMsg ) )
        {
            // mouse motion
            if( trackpadMsg.isMouseMotion() )
            {
                // axis of motion
                if( trackpadMsg.deltaX )
                {
                    //<<< "mouse motion:", trackpadMsg.deltaX, "on x-axis" >>>;
                    //filterSweep(trackpadMsg.deltaX);
					if (trackpadEnabled)
					{
						//<<< "filter:", trackpadMsg.deltaX >>>;
						oscSendFilter(trackpadMsg.deltaX);
					}
                }
                else if( trackpadMsg.deltaY )
                {
                    //<<< "mouse motion:", trackpadMsg.deltaY, "on y-axis" >>>;
                    //detuneSpreader(trackpadMsg.deltaY);
					if (trackpadEnabled)
					{
						//<<< "detune:", trackpadMsg.deltaY >>>;
						oscSendDetune(trackpadMsg.deltaY);
					}
                }
            }
            
            // mouse button down
            else if( trackpadMsg.isButtonDown() )
            {
                //<<< "mouse button", trackpadMsg.which, "down" >>>;
            }
            
            // mouse button up
            else if( trackpadMsg.isButtonUp() )
            {
                //<<< "mouse button", trackpadMsg.which, "up" >>>;
            }
            
            // mouse wheel motion (requires chuck 1.2.0.8 or higher)
            else if( trackpadMsg.isWheelMotion() )
            {
                // axis of motion
                if( trackpadMsg.deltaX )
                {
                    //<<< "mouse wheel:", trackpadMsg.deltaX, "on x-axis" >>>;
                }            
                else if( trackpadMsg.deltaY )
                {
                    //<<< "mouse wheel:", trackpadMsg.deltaY, "on y-axis" >>>;
                }
            }
        }
    }
}


// timbre ("[" and ]")
fun void changeTimbre(int message)
{
    // "["
    if(message == 47)
    {
        // decrease timbre
        if(timbre > 0) timbre--;
        <<< "Current Timbre: ", timbre >>>;
    }
    
    // "]"
    if(message == 48)
    {
        // increase timbre
        if(timbre + 1 < kMaxTimbres) timbre++;
    	<<< "Current Timbre: ", timbre >>>;
    }
}

//====================================================
// Func: setEnvelope()
// Desc: set the envelope
//====================================================
fun void setEnvelope(int message)
{
    // find digit
    int digit;
    if(message == 39) 0 => digit;
    else (message - 30 + 1) => digit;
    
    // set envelope
    envelopes[digit][0]::second => att;
    envelopes[digit][1]::second => dec;
    envelopes[digit][2] => sus;
    envelopes[digit][3]::second => rel;
    
    <<< "Enevelope set: ", digit >>>;
}


//====================================================
// Func: oscSendFilter()
// Desc: send instrument a filter change message
//====================================================

fun void oscSendFilter(int change)
{
	send_to_instrument.startMsg("/inst/filter, i");
	send_to_instrument.addInt(change);
}


//====================================================
// Func: oscSendDetune()
// Desc: send instrument a detune change message
//====================================================

fun void oscSendDetune(int change)
{
	send_to_instrument.startMsg("/inst/detune, i");
	send_to_instrument.addInt(change);
}


//====================================================
// FUNC: oscSendPlayNoteEvent
// DESC: plays a note with the provided parameters.
//       (sends note info via osc to the supersaw)  
//====================================================
fun void oscSendPlayNoteEvent(float freq, float velocity, int timbre, float att, float dec, float sus, float rel)
{
	send_to_instrument.startMsg("/inst/play, f, f, i, f, f, f, f");
	send_to_instrument.addFloat(freq);
	send_to_instrument.addFloat(velocity);
	send_to_instrument.addInt(timbre);
	send_to_instrument.addFloat(att);
	send_to_instrument.addFloat(dec);
	send_to_instrument.addFloat(sus);
	send_to_instrument.addFloat(rel);
}


//====================================================
// Main Loop
//====================================================
while(true)
{
	50::ms => now;
}


