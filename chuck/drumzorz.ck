.7 => float startGain;
0 => int currentBeat;

// total number of measures in the loop
2 => int totalMeasures;
// total number of beats you want per measure
4 => int totalBeatsPerMeasure;
// total number of hits per beat availale (e.g. 4 for 16th notes, 3 for eighth triplets, 2 for eighth notes)
4 => int quantizationSize;
//initial tempo
144.0 => float tempo;
(44100*60.0/tempo)::samp => dur sampsPerBeat;
// compute gridsize
quantizationSize * totalBeatsPerMeasure * totalMeasures => int gridSize;
// OSC sender
OscSend xmit;
xmit.setHost("192.168.176.226", 9998);
// create our OSC receiver
OscRecv orec;
// port 9999
9999 => orec.port;
// start listening (launch thread)
orec.listen();
orec.event("/IP,s") @=> OscEvent IP_event;
orec.event("/drumcontrol,s,f") @=> OscEvent Drum_event;

// IP listener
fun void getIP()
{
    while (true)
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
}



// class for randrumly generated drums
class Randrum
{
    SndBuf drum => Gain gain => dac;
    int hitsOn[gridSize];
    int randHitsOn[gridSize];
    float hitsGain[gridSize];
    float randHitsGain[gridSize];
    10.0 => float randThreshold;
    1.8 => float density;
    string myname;
    0 => int glitchOn;
    1.0 => float glitchLevel;
    
    // setup the filepath for the sample as well as a unique name
    fun void setup( string _filename, string _name )
    {
        _filename => drum.read;
        _name => myname;
        drum.samples() => drum.pos;
    }
    
    // clear out everything in that player
    fun void clear()
    {
        for (0 => int i; i < gridSize; i++) {
            0 => randHitsOn[i] => hitsOn[i] => hitsGain[i] 
            => randHitsGain[i];
        }
    }
    
    fun void glitch(float f)
    {
        if ( f < 0.0 ) 0 => glitchOn;
        else 1 => glitchOn;
        
        Math.ceil(f) => glitchLevel;
    }
    
    // shred for playback
    fun void playback()
    {
        // main loop
        while( true ) {
            // go through all of the spots in the gridsize
            //for (0 => int i; i < gridSize; i++) {
            ((now/(sampsPerBeat/quantizationSize)) % 16) $ int  => int i;
            0.0 => float sendGain;
            0 => int send;
            // if we have said this should be hit in our main pattern
            
            if ( glitchOn == 0 )
            {
                if (hitsOn[i] == 1) {
                    1 => send;
                    hitsGain[i] => sendGain;
                    hitsGain[i] => drum.gain;
                    1.0 => drum.rate;
                    if ( density < 2.0 ) 
                    {
                        if ( Math.rand2(0,100) / 50.0 < density )
                        { 
                            0 => drum.pos;
                        }
                        else 0 => send;
                    }
                    else 0 => drum.pos;
                    // possibly allow random sample to be added on
                    if (Math.rand2(0,100) < randThreshold) {
                        i + Math.rand2f(-1*density, density) $ int => int tempLocation;
                        if ( tempLocation < gridSize && tempLocation >= 0 && hitsOn[tempLocation] == 0) {
                            Math.floor(density) $ int => randHitsOn[tempLocation];
                            Math.rand2f(.1,.4)*hitsGain[i] => randHitsGain[tempLocation];
                        }
                    }
                }
                // handle the case that a random sample got triggered in the previous run
                if (randHitsOn[i] > 0) {
                    1 => send;
                    randHitsGain[i] => sendGain;
                    randHitsGain[i] => drum.gain;
                    Math.rand2f(1 - randThreshold/1000, 1 + randThreshold/1000) => drum.rate;
                    0 => drum.pos;
                    1 -=> randHitsOn[i];
                    Math.floor(randThreshold * .01 * randHitsOn[i]) $ int => randHitsOn[i];
                }
                
                // send OSC if there's been a hit
                if ( send == 1 )
                {
                    xmit.startMsg("/drum, s, f");
                    xmit.addString( myname );
                    xmit.addFloat(sendGain); 
                }
                
                now % (sampsPerBeat/quantizationSize) => dur mod;
                // advance time by the quantization size in samps
                (sampsPerBeat/quantizationSize) - mod => dur wait;
                wait => now;
            }
            
            else
            {
                //<<< glitchLevel >>>;
                Math.floor((sampsPerBeat/1::samp)/(quantizationSize))/glitchLevel => float sampsPerGlitch;
                for ( 0 => int j; j < glitchLevel; j++ )
                {
                    0 => drum.pos;
                    sampsPerGlitch::samp => now;
                }
            }
            //}
        }
    }
    
};

// Randrum setups
Randrum kick,snare,hihat,kickhard,snarehard,glitch,cym[4];
kick.setup("Documents/CCRMA/Slork/slork/chuck/kick.aiff", "kick");
snare.setup("Documents/CCRMA/Slork/slork/chuck/snare.aiff", "snare");
hihat.setup("Documents/CCRMA/Slork/slork/chuck/hihat.aiff", "hihat");
kickhard.setup("Documents/CCRMA/Slork/slork/chuck/kickbig.aiff", "kickhard");
snarehard.setup("Documents/CCRMA/Slork/slork/chuck/snarebig.aiff", "snarehard");
cym[0].setup("Documents/CCRMA/Slork/slork/chuck/cym1.aiff", "cym1");
cym[1].setup("Documents/CCRMA/Slork/slork/chuck/cym2.aiff", "cym2");
cym[2].setup("Documents/CCRMA/Slork/slork/chuck/cym3.aiff", "cym3");
cym[3].setup("Documents/CCRMA/Slork/slork/chuck/cym4.aiff", "cym4");
glitch.setup("Documents/CCRMA/Slork/slork/chuck/snare.aiff", "glitch");
[ 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0 ] @=> int kickPattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float kickGain[];
[ 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 ] @=> int snarePattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float snareGain[];
[ 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 ] @=> int snareHardPattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float snareHardGain[];
[ 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0 ] @=> int hihatPattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float hihatGain[];
[ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 ] @=> int kickHardPattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float kickHardGain[];
[ 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0 ] @=> int cym1Pattern[];
[ 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0 ] @=> int cym2Pattern[];
[ 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0 ] @=> int cym3Pattern[];
[ 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0 ] @=> int cym4Pattern[];
kickPattern @=> kick.hitsOn;
kickGain @=> kick.hitsGain;
snarePattern @=> snare.hitsOn;
snareGain @=> snare.hitsGain;
snareHardPattern @=> snarehard.hitsOn;
snareHardGain @=> snarehard.hitsGain;
hihatPattern @=> hihat.hitsOn;
hihatGain @=> hihat.hitsGain;
kickHardPattern @=> kickhard.hitsOn;
kickHardGain @=> kickhard.hitsGain;
cym1Pattern @=> cym[0].hitsOn;
kickHardGain @=> cym[0].hitsGain;
cym2Pattern @=> cym[1].hitsOn;
kickHardGain @=> cym[1].hitsGain;
cym3Pattern @=> cym[2].hitsOn;
kickHardGain @=> cym[2].hitsGain;
cym4Pattern @=> cym[3].hitsOn;
kickHardGain @=> cym[3].hitsGain;
0.2 => kickhard.gain.gain;
0.1 => snarehard.gain.gain;
0.6 => glitch.gain.gain;
0.5 => snarehard.randThreshold;

// drum control listener
fun void getDrumControl()
{
    string s;
    float f;
    
    while (true)
    {
        Drum_event => now; 
        
        // grab the next message from the queue. 
        while( Drum_event.nextMsg() != 0 )
        {   
            Drum_event.getString() => s;
            Drum_event.getFloat()/10.0 => f;
            //<<< s, f >>>;
            int x[0];
            1 => x["random"];
            2 => x["density"];
            3 => x["glitch"];
            if (x[s] == x["random"])
            { 
                f*10.0 => f;
                //<<< "random!", f >>>;
                f => kick.randThreshold;
                f => snare.randThreshold;
                f => hihat.randThreshold;
                f => kickhard.randThreshold;
                f => snarehard.randThreshold;
                for ( 0 => int i; i < 4; i++ )
                {
                    f => cym[i].randThreshold;
                }
            }
            else if (x[s] == x["density"])
            { 
                //<<< "density!", f >>>;
                f => kick.density;
                f => snare.density;
                f => hihat.density;
                f => kickhard.density;
                f => snarehard.density;
                for ( 0 => int i; i < 4; i++ )
                {
                    f => cym[i].density;
                }
            }
            else if (x[s] == x["glitch"])
            { 
                if ( f > 0 )
                {
                    //1 => kick.glitchOn;
                    1 => snare.glitchOn;
                    1 => hihat.glitchOn;
                    1 => kickhard.glitchOn;
                    1 => snarehard.glitchOn;
                    for ( 0 => int i; i < 4; i++ )
                    {
                        1 => cym[i].glitchOn;
                    }
                    
                    f => kick.glitchLevel;
                    f => snare.glitchLevel;
                    f => hihat.glitchLevel;
                    f => kickhard.glitchLevel;
                    f => snarehard.glitchLevel;
                    for ( 0 => int i; i < 4; i++ )
                    {
                        f => cym[i].glitchLevel;
                    }
                    
                }
                else
                {
                    0 => kick.glitchOn;
                    0 => snare.glitchOn;
                    0 => hihat.glitchOn;
                    0 => kickhard.glitchOn;
                    0 => snarehard.glitchOn;
                    for ( 0 => int i; i < 4; i++ )
                    {
                        0 => cym[i].glitchOn;
                    }
                }
                //<<< "glitch!", f >>>;
                glitch.glitch(f);
            }
        }
    }
}

// spork all playback shreds
spork ~ kick.playback();
spork ~ kickhard.playback();
spork ~ snare.playback();
spork ~ snarehard.playback();
spork ~ hihat.playback();
spork ~ glitch.playback();

// these are some listeners
spork ~ getIP();
spork ~ getDrumControl();

for ( 0 => int i; i < 4; i++ )
{
    0.2 => cym[i].gain.gain;
    1.0 => cym[i].randThreshold;
    //spork ~ cym[i].playback();
}

// "main" loop
while( true ) {
    1::day => now;
}