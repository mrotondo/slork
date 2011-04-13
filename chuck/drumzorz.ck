.7 => float startGain;
0 => int currentBeat;

// total number of measures in the loop
2 => int totalMeasures;
// total number of beats you want per measure
4 => int totalBeatsPerMeasure;
// total number of hits per beat availale (e.g. 4 for 16th notes, 3 for eighth triplets, 2 for eighth notes)
4 => int quantizationSize;
//initial tempo
145.0 => float tempo;
(60.0/tempo)::second => dur sampsPerBeat;
// compute gridsize
quantizationSize * totalBeatsPerMeasure * totalMeasures => int gridSize;

class Randrum
{
    SndBuf drum => Gain gain => dac;
    int hitsOn[gridSize];
    int randHitsOn[gridSize];
    float hitsGain[gridSize];
    float randHitsGain[gridSize];
    90.0 => float randThreshold;
    4.5 => float density;
    
    fun void setup( string _filename )
    {
        _filename => drum.read;
       drum.samples() => drum.pos;
    }
    
    fun void clear()
    {
        for (0 => int i; i < gridSize; i++) {
            0 => randHitsOn[i] => hitsOn[i] => hitsGain[i] 
            => randHitsGain[i];
        }
    }
    
    fun void playback()
    {
        while( true ) {
            for (0 => int i; i < gridSize; i++) {
                if (hitsOn[i] == 1) {
                    hitsGain[i] => drum.gain;
                    1.0 => drum.rate;
                    0 => drum.pos;
                    if (Math.rand2(0,100) < randThreshold) {
                        i + Math.rand2f(-1*density, density) $ int => int tempLocation;
                        if ( tempLocation < gridSize && tempLocation >= 0 && hitsOn[tempLocation] == 0) {
                            Math.floor(density) $ int => randHitsOn[tempLocation];
                            Math.rand2f(.1,.4)*hitsGain[i] => randHitsGain[tempLocation];
                        }
                    }
                }
                if (randHitsOn[i] > 0) {
                    randHitsGain[i] => drum.gain;
                    Math.rand2f(1 - randThreshold/1000, 1 + randThreshold/1000) => drum.rate;
                    0 => drum.pos;
                    1 -=> randHitsOn[i];
                    Math.floor(randThreshold * .01 * randHitsOn[i]) $ int => randHitsOn[i];
                }
                
                // advance time by the quantization size in samps
                sampsPerBeat/quantizationSize => now;
            }
        }
    }

};

Randrum kick,snare,hihat;
kick.setup("Documents/CCRMA/2009-2010/WinterQuarter/MUS220B/hw3/kick.wav");
snare.setup("Documents/CCRMA/2009-2010/WinterQuarter/MUS220B/hw3/snare.wav");
hihat.setup("Documents/CCRMA/2009-2010/WinterQuarter/MUS220B/hw3/hihat.wav");
[ 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0 ] @=> int kickPattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float kickGain[];
[ 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 ] @=> int snarePattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float snareGain[];
[ 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0 ] @=> int hihatPattern[];
[ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ] @=> float hihatGain[];
kickPattern @=> kick.hitsOn;
kickGain @=> kick.hitsGain;
snarePattern @=> snare.hitsOn;
snareGain @=> snare.hitsGain;
hihatPattern @=> hihat.hitsOn;
hihatGain @=> hihat.hitsGain;

spork ~ kick.playback();
spork ~ snare.playback();
spork ~ hihat.playback();

// "main" loop
while( true ) {
    1::day => now;
}