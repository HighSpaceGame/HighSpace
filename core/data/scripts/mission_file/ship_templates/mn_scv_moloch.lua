local template = {}

template.text = [[
$Name: %s
$Class: SCv Moloch
$Team: %s
$Location: %f, %f, %f
$Orientation:
	1.000000, 0.000000, 0.000000,
	0.000000, 1.000000, 0.000000,
	0.000000, 0.000000, %f
$Cargo 1:  XSTR("Nothing", -1)
+Initial Velocity: 33
+Initial Hull: 100
+Initial Shields: 100
+Subsystem: Pilot
+Subsystem: turret01
+Subsystem: turret02
+Subsystem: turret03
+Subsystem: turret04
+Subsystem: turret05
+Subsystem: turret06
+Subsystem: turret07
+Subsystem: turret08
+Subsystem: turret09
+Subsystem: turret10
+Subsystem: turret11
+Subsystem: turret12
+Subsystem: turret13
+Subsystem: turret14
+Subsystem: turret15
+Subsystem: turret16
$Arrival Location: Hyperspace
$Arrival Cue: ( true )
$Departure Location: Hyperspace
$Departure Cue: ( false )
$Determination: 10
+Flags: ( "no-shields" )
+Flags2: ( )
+Respawn priority: 0
+Orders Accepted List: ( )
+Use Table Score:
+Score: 440
]]

function template.instantiate(name, team, x, y, z, heading)
    return string.format(template.text, name, team, x, y, z, heading)
end

return template