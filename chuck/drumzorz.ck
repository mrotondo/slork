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
orec.event("/drumcontrol,s,f,f") @=> OscEvent Drum_event;

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
    SndBuf drum => Gain g => dac;
    int hitsOn[gridSize];
    int randHitsOn[gridSize];
    float hitsGain[gridSize];
    float randHitsGain[gridSize];
    10.0 => float randThreshold;
    2.8 => float density;
    string myname;
    0 => int glitchOn;
    1.0 => float glitchLevel;
    1.0 => float baseRate;
    0 => int isIn;
    
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
            
            // if we have said this should be hit in our main pattern
            
            if ( glitchOn == 0 )
            {
                ((now/(sampsPerBeat/quantizationSize)) % gridSize) $ int  => int i;
                0.0 => float sendGain;
                0 => int send;
                
                if (hitsOn[i] == 1) {
                    1 => send;
                    hitsGain[i] => sendGain;
                    hitsGain[i] => drum.gain;
                    1.0 * baseRate => drum.rate;
                    if ( density < 3.0 ) 
                    {
                        if ( Math.rand2(0,100) / 33.0 < density )
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
                    baseRate * Math.rand2f(1 - randThreshold/1000, 1 + randThreshold/1000) => drum.rate;
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
            
            else if ( glitchOn == 1 )
            {
                //<<< glitchLevel >>>;
                Math.floor((sampsPerBeat/1::samp)/(quantizationSize))/glitchLevel => float sampsPerGlitch;
                for ( 0 => int j; j < glitchLevel; j++ )
                {
                    //0.4 => drum.gain;
                    0 => drum.pos;
                    sampsPerGlitch::samp => now;
                }
            }
            
            if ( glitchOn == 2 )
            {
                int i;
                if ( i % gridSize != 0 || isIn == 0 )
                {
                    ((now/(sampsPerBeat/quantizationSize)) % gridSize) $ int  => i;
                }
                
                else 
                {
                    1 => isIn;
                    ((now/(4.0*(sampsPerBeat/quantizationSize)/3.0)) % gridSize) $ int  => i;
                }
                0.0 => float sendGain;
                0 => int send;
                
                if (hitsOn[i] == 1) {
                    1 => send;
                    hitsGain[i] => sendGain;
                    hitsGain[i] => drum.gain;
                    1.0 * baseRate => drum.rate;
                    if ( density < 4.0 ) 
                    {
                        if ( Math.rand2(0,1000) / 250.0 < density )
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
                    baseRate * Math.rand2f(1 - randThreshold/1000, 1 + randThreshold/1000) => drum.rate;
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
                
                //now % (2.0*(sampsPerBeat/quantizationSize)/3.0) => dur mod;
                // advance time by the quantization size in samps
                //(2.0*(sampsPerBeat/quantizationSize)/3.0) - mod => dur wait;
                //wait => now;
                (4.0*(sampsPerBeat/quantizationSize)/3.0) => now;
            }
        }
    }
};

// Randrum setups
Randrum kick,snare,hihat,openhat,kickhard,snarehard,glitch,cym[4];
kick.setup("Documents/CCRMA/Slork/slork/chuck/jason/kickmed.wav", "kick");
snare.setup("Documents/CCRMA/Slork/slork/chuck/jason/snarerealdry.wav", "snare");
hihat.setup("Documents/CCRMA/Slork/slork/chuck/jason/hihatthin.wav", "hihat");
openhat.setup("Documents/CCRMA/Slork/slork/chuck/jason/hihatopen.wav", "hihat");
kickhard.setup("Documents/CCRMA/Slork/slork/chuck/jason/kickbig.wav", "kickhard");
snarehard.setup("Documents/CCRMA/Slork/slork/chuck/jason/snarehigh.wav", "snarehard");
cym[0].setup("Documents/CCRMA/Slork/slork/chuck/cym1.aiff", "cym1");
cym[1].setup("Documents/CCRMA/Slork/slork/chuck/cym2.aiff", "cym2");
cym[2].setup("Documents/CCRMA/Slork/slork/chuck/cym3.aiff", "cym3");
cym[3].setup("Documents/CCRMA/Slork/slork/chuck/cym4.aiff", "cym4");
glitch.setup("Documents/CCRMA/Slork/slork/chuck/snare.aiff", "glitch");
[ 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0 ] @=> int kickPattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float kickGain[];
[ 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 ] @=> int snarePattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float snareGain[];
[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 ] @=> int snareHardPattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float snareHardGain[];
[ 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0 ] @=> int hihatPattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float hihatGain[];
[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0 ] @=> int openhatPattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float openhatGain[];
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
openhatPattern @=> openhat.hitsOn;
openhatGain @=> openhat.hitsGain;
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
1.1 => snare.g.gain;
1.3 => snare.baseRate;
0.7 => hihat.baseRate;
0.9 => kickhard.g.gain;
0.7 => hihat.g.gain => openhat.g.gain;
0.9 => kickhard.baseRate;
0.4 => snarehard.g.gain;
0.6 => glitch.g.gain;
0.5 => snarehard.randThreshold;
0.5 => openhat.g.gain;

0 => int isGlitching;

// drum control listener
fun void getDrumControl()
{
    string s;
    float fx, fy;
    
    while (true)
    {
        Drum_event => now; 
        
        // grab the next message from the queue. 
        while( Drum_event.nextMsg() != 0 )
        {   
            Drum_event.getString() => s;
            Drum_event.getFloat()/10.0 => fx;
            Drum_event.getFloat()/200.0 => fy;
            //<<< s, f >>>;
            int x[0];
            1 => x["random"];
            2 => x["density"];
            3 => x["glitch"];
            4 => x["stutter"];
            if (x[s] == x["random"])
            { 
                fx*10.0 => fx;
                //<<< "random!", fx >>>;
                fx => kick.randThreshold;
                fx => snare.randThreshold;
                fx => hihat.randThreshold;
                fx => kickhard.randThreshold;
                fx => snarehard.randThreshold;
                fx => openhat.randThreshold;
                for ( 0 => int i; i < 4; i++ )
                {
                    fx => cym[i].randThreshold;
                }
            }
            else if (x[s] == x["density"])
            { 
                //<<< "density!", f >>>;
                fx => kick.density;
                fx => snare.density;
                fx => hihat.density;
                fx => kickhard.density;
                fx => snarehard.density;
                fx => openhat.density;
                for ( 0 => int i; i < 4; i++ )
                {
                    fx => cym[i].density;
                }
            }
            else if (x[s] == x["glitch"])
            { 
                
                if ( fx > 0 )
                {
                    
                    
                    if ( !isGlitching )
                    {
                        1 => isGlitching;
                        Math.rand() % 10 => int whichGlitch;
                        if ( whichGlitch == 0 ) 
                        {
                            1 => kick.glitchOn;
                        }
                        else if ( whichGlitch == 1 ) 1 => snare.glitchOn;
                        else if ( whichGlitch == 2 ) 1 => hihat.glitchOn;
                        else if ( whichGlitch == 3 ) 1 => openhat.glitchOn;
                        else if ( whichGlitch == 4 ) 1 => kickhard.glitchOn;
                        else if ( whichGlitch == 5 ) 1 => snarehard.glitchOn;
                        else if ( whichGlitch == 6 ) 
                        {
                            1 => snarehard.glitchOn;
                            1 => hihat.glitchOn;
                            1 => snare.glitchOn;
                        }
                        else if ( whichGlitch == 7 )
                        {
                            1 => snarehard.glitchOn;
                            1 => kick.glitchOn;
                            1 => snare.glitchOn;
                        }
                        else if ( whichGlitch == 8 ) 
                        {
                            1 => kickhard.glitchOn;
                            1 => openhat.glitchOn;
                            1 => kick.glitchOn;
                        }
                        else if ( whichGlitch == 9 ) 
                        {
                            1 => hihat.glitchOn;
                            1 => kick.glitchOn;
                            1 => snarehard.glitchOn;
                        }
                    }
                    for ( 0 => int i; i < 4; i++ )
                    {
                        1 => cym[i].glitchOn;
                    }
                    
                    fx => kick.glitchLevel;
                    fx => snare.glitchLevel;
                    fx => hihat.glitchLevel;
                    fx => openhat.glitchLevel;
                    fx => kickhard.glitchLevel;
                    fx => snarehard.glitchLevel;
                    for ( 0 => int i; i < 4; i++ )
                    {
                        fx => cym[i].glitchLevel;
                    }
                    
                    if ( kick.glitchOn ) fy => kick.drum.gain;
                    else if ( snare.glitchOn ) fy => snare.drum.gain;
                    else if ( hihat.glitchOn ) fy => hihat.drum.gain;
                    else if ( openhat.glitchOn ) fy => openhat.drum.gain;
                    else if ( kickhard.glitchOn ) fy => kickhard.drum.gain;
                    else if ( snarehard.glitchOn ) fy => snarehard.drum.gain;
                    for ( 0 => int i; i < 4; i++ )
                    {
                        fy => cym[i].drum.gain;
                    }
                    
                }
                else
                {
                    0 => isGlitching;
                    0 => kick.glitchOn => kick.isIn;
                    0 => snare.glitchOn => snare.isIn;
                    0 => hihat.glitchOn => hihat.isIn;
                    0 => openhat.glitchOn => openhat.isIn;
                    0 => kickhard.glitchOn => kickhard.isIn;
                    0 => snarehard.glitchOn => snarehard.isIn;
                    for ( 0 => int i; i < 4; i++ )
                    {
                        0 => cym[i].glitchOn => cym[i].isIn;
                    }
                }
                //<<< "glitch!", f >>>;
                //glitch.glitch(f);
            }
            else if (x[s] == x["stutter"])
            { 
                if ( fx > 0 )
                {
                    2 => kick.glitchOn;
                    2 => snare.glitchOn;
                    2 => hihat.glitchOn;
                    2 => openhat.glitchOn;
                    2 => kickhard.glitchOn;
                    2 => snarehard.glitchOn;
                    for ( 0 => int i; i < 4; i++ )
                    {
                        2 => cym[i].glitchOn;
                    }
                    
                    fx => kick.glitchLevel;
                    fx => snare.glitchLevel;
                    fx => hihat.glitchLevel;
                    fx => openhat.glitchLevel;
                    fx => kickhard.glitchLevel;
                    fx => snarehard.glitchLevel;
                    for ( 0 => int i; i < 4; i++ )
                    {
                        fx => cym[i].glitchLevel;
                    }                    
                }
                else
                {
                    0 => kick.glitchOn => kick.isIn;
                    0 => snare.glitchOn => snare.isIn;
                    0 => hihat.glitchOn => hihat.isIn;
                    0 => openhat.glitchOn => openhat.isIn;
                    0 => kickhard.glitchOn => kickhard.isIn;
                    0 => snarehard.glitchOn => snarehard.isIn;
                    for ( 0 => int i; i < 4; i++ )
                    {
                        0 => cym[i].glitchOn => cym[i].isIn;
                    }
                }
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
spork ~ openhat.playback();
spork ~ glitch.playback();

// these are some listeners
spork ~ getIP();
spork ~ getDrumControl();

for ( 0 => int i; i < 4; i++ )
{
    0.2 => cym[i].g.gain;
    1.0 => cym[i].randThreshold;
    //spork ~ cym[i].playback();
}

// "main" loop
while( true ) {
    1::day => now;
}