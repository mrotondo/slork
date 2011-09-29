// make HidIn and HidMsg
Hid hi;
HidMsg msg;

Noise foo => ADSR env => dac;
env.set(0::ms, 10::ms, 0, 0::day);
440 => float f;
//f => foo.freq;

// all joystick values are roughly normalized -1 to 1
float ax; // left joystick x axis
float ay; // left joystick y axis
float az; // left joystick z axis
float bx; // right joystick x axis
float by; // right joystick y axis
float bz; // right joystick z axis
0 => int fp;
float axprev;
float ayprev;
float azprev;
float bxprev;
float byprev;
float bzprev;

float vax;
float vay;
float vaz;
float vbx;
float vby;
float vbz;

class Drum
{
   // position of center point
   float x;
   float y;
   float z;
   float size; // length of a side
   int inside;
   
   SndBuf buffy => dac;
   
   fun void set(float _x, float _y, float _z, float _size, string _filename)
   {
       _filename => buffy.read;
       buffy.samples() => buffy.pos;
       _x => x; _y => y; _z => z, _size => size;
       false => inside;
   }

   
   fun void hitTest(float _x, float _y, float _z, float _vel)
   {
       if (_x > x - size/2.0 && _x < x + size/2.0 &&
           _y > y - size/2.0 && _y < y + size/2.0 &&
           _z > z - size/8.0 && _z < z + size/8.0)
       {
           if (!inside)
           {
               true => inside;
               ;//<<< "In the box!!", "" >>>;
               _vel * 50 => buffy.gain;
               0 => buffy.pos;

           }
       }
       else
           false => inside;
   }
   
};

class DrumPair
{
    Drum d1;
    Drum d2;
    fun void set(float _x, float _y, float _z, float _size, string _filename)
    {
        d1.set(_x,_y,_z,_size, _filename);
        d2.set(_x,_y,_z,_size, _filename);
    }
    fun void hitTest(float _x, float _y, float _z, float _vel)
    {
        d1.hitTest(_x,_y,_z,_vel);
        d2.hitTest(_x,_y,_z,_vel);
    }
};

1 => float heightScale;

DrumPair p1;
p1.set(0.136, -.029, -.631 * heightScale, .3, "!School/Spring/128/Kit/909 SNARE.wav");
p1.d2.set(-.0193, -.069, -.718 * heightScale, .3, "!School/Spring/128/Kit/909 SNARE.wav");

DrumPair p2;
p2.set(-.299, -.188, -.46 * heightScale, .3, "!School/Spring/128/Kit/HHCD0.WAV");
p2.d2.set(-.385, -.25, -.525 * heightScale, .3, "!School/Spring/128/Kit/HHCD0.WAV");


DrumPair p3;
p3.set(-.205, .401, -.552 * heightScale, .3, "!School/Spring/128/Kit/909 HIGH TOM.wav");
p3.d2.set(-.255, .431, -.626 * heightScale, .3, "!School/Spring/128/Kit/909 HIGH TOM.wav");

DrumPair p4;
p4.set(.242, .506, -.454 * heightScale, .3, "!School/Spring/128/Kit/909 MID TOM.wav");
p4.d2.set(.162, .438, -.527 * heightScale, .3, "!School/Spring/128/Kit/909 MID TOM.wav");


DrumPair p5;
p5.set(.6, .3, -.2 * heightScale, .3, "!School/Spring/128/Kit/909 LOW TOM.wav");

DrumPair p6;
p6.set(.9, .3, -.2 * heightScale, .3, "!School/Spring/128/Kit/909 RIDE.wav");

DrumPair p7;
p7.set(.3, .3, 0 * heightScale, .3, "!School/Spring/128/Kit/909 CRASH.wav");

Drum drumsL[0];
Drum drumsR[0];
drumsL << p1.d1;
drumsR << p1.d2;
drumsL << p2.d1;
drumsR << p2.d2;
drumsL << p3.d1;
drumsR << p3.d2;
drumsL << p4.d1;
drumsR << p4.d2;
drumsL << p5.d1;
drumsR << p5.d2;
drumsL << p6.d1;
drumsR << p6.d2;
drumsL << p7.d1;
drumsR << p7.d2;

SndBuf kick => dac;
"!School/Spring/128/Kit/909 KICK.wav" => kick.read;
kick.samples() => kick.pos;


// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open joystick 0, exit on fail
if( !hi.openJoystick( device ) ) me.exit();

<<< "joystick '" + hi.name() + "' ready", "" >>>;
spork ~GetJoystickInput();
spork ~ComputeRHVelocity();

while(true) {
    1::second => now;
}

fun void GetJoystickInput() {
  while( true )
  {
      // wait on HidIn as event
      hi => now;

      // messages received
      while( hi.recv( msg ) )
      {
          // dual joysticks axis motion
          if( msg.isAxisMotion() )
          {
              if( msg.which == 0 )
              {
                  ax => axprev;
                  msg.axisPosition => ax;
                  ax - axprev => vax;                     
              }
              else if( msg.which == 1 ) 
              {
                  ay => ayprev;
                  msg.axisPosition => ay;
                  ay - ayprev => vay;
              }
                  else if( msg.which == 2 ) 
              {
                  az => azprev;
                  msg.axisPosition*-1 => az;
                  az - azprev => vaz;
              }
              else if( msg.which == 3 )
              {
                  bx => bxprev;
                  msg.axisPosition => bx;
                  bx - bxprev => vbx;                     
              }
              else if( msg.which == 4 ) 
              {
                  by => byprev;
                  msg.axisPosition => by;
                  by - byprev => vby;
              }
              else if( msg.which == 5 ) 
              {
                  bz => bzprev;
                  msg.axisPosition*-1 => bz;
                  bz - bzprev => vbz;
              }
              
              if (vaz < 0)
              {
              for (0 => int i; i  < drumsL.size(); i++) 
                  drumsL[i].hitTest(ax, ay, az, Math.sqrt(vax*vax+vay*vay+vaz*vaz));
              }
              if (vbz < 0)
              {
              for (0 => int i;  i < drumsR.size(); i++) 
                  drumsR[i].hitTest(bx, by, bz, Math.sqrt(vbx*vbx+vby*vby+vbz*vbz));
              }
          }
          
          // footpedal message
          else if( msg.isButtonDown() )
          {
              1 => fp;
              <<< "footpedal depressed " + fp >>>;
              0 => kick.pos;
              <<< "ax", ax >>>;
              <<< "ay", ay >>>;
              <<< "az", az >>>;
              <<< "bx", bx >>>;
              <<< "by", by >>>;
              <<< "bz", bz >>>;
              
          }
        
          else if( msg.isButtonUp() )
          {
              0 => fp;
              <<< "footpedal released " + fp >>>;
          }
      }
  }
}

fun void ComputeRHVelocity() {
    while(true) {
        10::second => now;
    }
}