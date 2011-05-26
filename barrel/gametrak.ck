// make HidIn and HidMsg
Hid hi;
HidMsg msg;

// TODO: differentiate instruments' channels
NoiseDrum r_instrument;
NoiseDrum l_instrument;

1 => r_instrument.isKick;
0 => l_instrument.isKick;

RunningAverage r_average_y_velocity;
RunningAverage l_average_y_velocity;
0.2 => float r_y_velocity_threshold;
0.2 => float l_y_velocity_threshold;

-0.5 => float r_y_position_threshold;
-0.5 => float l_y_position_threshold;

// all joystick values are roughly normalized -1 to 1
float ax; // left joystick x axis
float ay; // left joystick y axis
float az; // left joystick z axis
float bx; // right joystick x axis
float by; // right joystick y axis
float bz; // right joystick z axis
0 => int fp;

// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open joystick 0, exit on fail
if( !hi.openJoystick( device ) ) me.exit();

<<< "joystick '" + hi.name() + "' ready", "" >>>;
spork ~GetGameTrakInput();

// main loop
while(true) {
    1::second => now;
}

fun void GetGameTrakInput() {
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
                    msg.axisPosition => ax;
                    
                    r_instrument.setModulation( ax );
                }
                else if( msg.which == 1 ) 
                {
                    ay => float prev_ay;
                    msg.axisPosition => ay;
                    ay - prev_ay => float diff;
                    
                    if (ay > r_y_position_threshold && prev_ay <= r_y_position_threshold)
                    {
                        spork ~ r_instrument.play(Math.fabs(diff));
                    }
                    
                    //r_average_y_velocity.add_element(diff);
                    //r_average_y_velocity.average() => float avg;
                    //if (avg > r_y_velocity_threshold)
                    //{
                    //    <<<diff>>>;
                    //    spork ~ r_instrument.play(diff);
                    //}
                }
                else if( msg.which == 2 ) 
                {
                    msg.axisPosition*-1 => az;
                    
                    1.0 / ((az + 2) * 12) => r_y_velocity_threshold;
                    
                    -0.5 + (az * 0.5 + 0.5) * 0.25 => r_y_position_threshold;
                    //<<< r_y_position_threshold >>>;
                    
                    r_instrument.setFrequency( 1 - ((az + 1) / 2));
                    
                }
                else if( msg.which == 3 ) 
                {
                    msg.axisPosition => bx;
                    
                    l_instrument.setModulation( bx );
                }
                else if( msg.which == 4 ) 
                {
                    by => float prev_by;
                    msg.axisPosition => by;
                    by - prev_by => float diff;
                    
                    if (by > l_y_position_threshold && prev_by <= l_y_position_threshold)
                    {
                        spork ~ l_instrument.play(Math.fabs(diff));    
                    }
                    
                    //l_average_y_velocity.add_element(diff);
                    //l_average_y_velocity.average() => float avg;
                    //if (avg > l_y_velocity_threshold)
                    //{
                    //    <<<diff>>>;
                    //    spork ~ l_instrument.play(diff);
                    //}
                }
                else if( msg.which == 5 ) 
                {
                    msg.axisPosition*-1 => bz;

                    1.0 / ((bz + 2) * 12) => l_y_velocity_threshold;
                    
                    -0.5 + (az * 0.5 + 0.5) * 0.25 => l_y_position_threshold;
                    
                    l_instrument.setFrequency( 1 - ((bz + 1) / 2));

                }
            }
            
            // footpedal message
            else if( msg.isButtonDown() )
            {
                1 => fp;
		
                <<< "footpedal depressed " + fp >>>;
            }
            
            else if( msg.isButtonUp() )
            {
                0 => fp;
                <<< "footpedal released " + fp >>>;
            }
        }
    }
}