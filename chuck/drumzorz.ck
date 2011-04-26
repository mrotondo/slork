// TODO: Figure out ranges of sounds that we like from TweakyDrum and NoiseDrum, and set them up in the right places
// TODO: Slew the parameters of the drums from section to section
// TODO: Figure out some nice effects to lay on top of the drums, or modulations of their parameters
// TODO: Add a real kick in with the synth drums in sections where we want to get SERIOUS BUSINESS
// TODO: Make the gain of the tweaky- and noise-drums settable so that the randomizer can emphasize/de-emphasize different beats

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

now % (totalBeatsPerMeasure * totalMeasures * sampsPerBeat) => dur offset;

// class for randrumly generated drums
class Randrum
{
    //SndBuf drum => Gain g => dac;
	TweakyDrum drum;
	
    int hitsOn[gridSize];
    int randHitsOn[gridSize];
    float hitsGain[gridSize];
    float randHitsGain[gridSize];
    
    //10.0 => float randThreshold;
    0.0 => float randThreshold;
    
    2.8 => float density;
    string myname;
    0 => int glitchOn;
    1.0 => float glitchLevel;
    1.0 => float baseRate;
    0 => int isIn;
    
    // setup the filepath for the sample as well as a unique name
    fun void setup( string _filename, string _name )
    {
		drum.randomize();
        //_filename => drum.read;
        _name => myname;
        //drum.samples() => drum.pos;
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
                (((now - offset)/(sampsPerBeat/quantizationSize)) % gridSize) $ int  => int i;
                1.0 => float sendGain;
                0 => int send;
                
                if (hitsOn[i] == 1) {
                    1 => send;
                    hitsGain[i] => sendGain;
                    //hitsGain[i] => drum.gain;
                    //1.0 * baseRate => drum.rate;
                    if ( density < 3.0 ) 
                    {
                        if ( Math.rand2(0,100) / 33.0 < density )
                        { 
                            //0 => drum.pos;
							spork ~ drum.play();
                        }
                        else 0 => send;
                    }
                    else
					{
						//0 => drum.pos;
						spork ~ drum.play();
					}
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
                    //randHitsGain[i] => drum.gain;
                    //baseRate * Math.rand2f(1 - randThreshold/1000, 1 + randThreshold/1000) => drum.rate;
                    //0 => drum.pos;
					spork ~ drum.play();
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
                
                (now - offset) % (sampsPerBeat/quantizationSize) => dur mod;
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
                    //0 => drum.pos;
					spork ~ drum.play();
                    sampsPerGlitch::samp => now;
                }
            }
            
            if ( glitchOn == 2 )
            {
                int i;
                if ( i % gridSize != 0 || isIn == 0 )
                {
                    (((now - offset)/(sampsPerBeat/quantizationSize)) % gridSize) $ int  => i;
                }
                
                else 
                {
                    1 => isIn;
                    (((now - offset)/(4.0*(sampsPerBeat/quantizationSize)/3.0)) % gridSize) $ int  => i;
                }
                0.0 => float sendGain;
                0 => int send;
                
                if (hitsOn[i] == 1) {
                    1 => send;
                    hitsGain[i] => sendGain;
                    //hitsGain[i] => drum.gain;
                    //1.0 * baseRate => drum.rate;
                    if ( density < 4.0 ) 
                    {
                        if ( Math.rand2(0,1000) / 250.0 < density )
                        { 
                            //0 => drum.pos;
							spork ~ drum.play();
                        }
                        else 0 => send;
                    }
                    else
					{
						//0 => drum.pos;
						spork ~ drum.play();
					}
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
                    //randHitsGain[i] => drum.gain;
                    //baseRate * Math.rand2f(1 - randThreshold/1000, 1 + randThreshold/1000) => drum.rate;
                    //0 => drum.pos;
					spork ~ drum.play();
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
Randrum kick,snare,hihat,kickhard,openhat,snarehard,glitch;
"jason/" => string path;
kick.setup(path+"kickmed.wav", "kick");
snare.setup(path+"snarerealdry.wav", "snare");
hihat.setup(path+"hihatthin.wav", "hihat");
kickhard.setup(path+"kickbig.wav", "kickhard");
snarehard.setup(path+"snarehigh.wav", "snarehard");
openhat.setup(path+"hihatopen.wav","openhat");
glitch.setup("snare.aiff", "glitch");
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

// 1.1 => snare.g.gain;
// 1.3 => snare.baseRate;
// 0.7 => hihat.baseRate;
// 0.9 => kickhard.g.gain;
// 0.7 => hihat.g.gain => openhat.g.gain;
// 0.9 => kickhard.baseRate;
// 0.4 => snarehard.g.gain;
// 0.6 => glitch.g.gain;
// 0.5 => snarehard.randThreshold;
// 0.5 => openhat.g.gain;

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
                    
                    fx => kick.glitchLevel;
                    fx => snare.glitchLevel;
                    fx => hihat.glitchLevel;
                    fx => openhat.glitchLevel;
                    fx => kickhard.glitchLevel;
                    fx => snarehard.glitchLevel;
                    
                    //if ( kick.glitchOn ) fy => kick.drum.gain;
                    //else if ( snare.glitchOn ) fy => snare.drum.gain;
                    //else if ( hihat.glitchOn ) fy => hihat.drum.gain;
                    //else if ( openhat.glitchOn ) fy => openhat.drum.gain;
                    //else if ( kickhard.glitchOn ) fy => kickhard.drum.gain;
                    //else if ( snarehard.glitchOn ) fy => snarehard.drum.gain;
                    
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
                    
                    fx => kick.glitchLevel;
                    fx => snare.glitchLevel;
                    fx => hihat.glitchLevel;
                    fx => openhat.glitchLevel;
                    fx => kickhard.glitchLevel;
                    fx => snarehard.glitchLevel;
                }
                else
                {
                    0 => kick.glitchOn => kick.isIn;
                    0 => snare.glitchOn => snare.isIn;
                    0 => hihat.glitchOn => hihat.isIn;
                    0 => openhat.glitchOn => openhat.isIn;
                    0 => kickhard.glitchOn => kickhard.isIn;
                    0 => snarehard.glitchOn => snarehard.isIn;
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

fun void updateParams()
{   
    Scenes.current_scene.kickPattern @=> kick.hitsOn;
    Scenes.current_scene.snarePattern @=> snare.hitsOn;
    Scenes.current_scene.snareHardPattern @=> snarehard.hitsOn;
    Scenes.current_scene.hihatPattern @=> hihat.hitsOn;
    Scenes.current_scene.openhatPattern @=> openhat.hitsOn;
    Scenes.current_scene.kickHardPattern @=> kickhard.hitsOn;
    
    Scenes.current_scene.drumRandomness => float fx;
    
    fx => kick.randThreshold;
    fx => snare.randThreshold;
    fx => hihat.randThreshold;
    fx => kickhard.randThreshold;
    fx => snarehard.randThreshold;
    fx => openhat.randThreshold;
}

// "main" loop
while( true ) {
	//updateParams(); // WHY does this give us null pointer exception
    1::second => now;
}