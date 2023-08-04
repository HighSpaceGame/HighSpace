local template = {}

template.text = [[
$Name: %s
$Class: SC Cain
$Team: %s
$Location: %f, %f, %f
$Orientation:
	1.000000, 0.000000, 0.000000,
	0.000000, 1.000000, 0.000000,
	0.000000, 0.000000, %f
$Cargo 1:  XSTR("Nothing", -1)
+Initial Velocity: 0
+Initial Hull: 100
+Subsystem: Pilot
+Subsystem: turret01
+Subsystem: turret02
+Subsystem: turret03
+Subsystem: turret04
+Subsystem: turret05
+Primary Banks: ( "ULTRA Anti-Fighter Beam" )
+Subsystem: turret06
+Primary Banks: ( "ULTRA Anti-Fighter Beam" )
+Subsystem: turret07
+Primary Banks: ( "ULTRA Anti-Fighter Beam" )
+Subsystem: turret08
+Subsystem: turret09
$Arrival Location: Hyperspace
$Arrival Cue: ( true )
$Departure Location: Hyperspace
$Departure Cue: ( false )
$Determination: 10
+Flags: ( )
+Flags2: ( )
+Respawn priority: 0
+Orders Accepted List: ( )
+Use Table Score:
+Score: 0
]]

function template.instantiate(name, team, x, y, z, heading)
    return string.format(template.text, name, team, x, y, z, heading)
end

return template