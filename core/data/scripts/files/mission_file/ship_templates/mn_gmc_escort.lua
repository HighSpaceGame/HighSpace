local template = {}

template.text = [[
$Name: %s
$Class: GMC Escort
$Team: %s
$Location: %f, %f, %f
$Orientation:
	1.000000, 0.000000, 0.000000,
	0.000000, 1.000000, 0.000000,
	0.000000, 0.000000, %f
$Cargo 1:  XSTR("Nothing", -1)
+Initial Velocity: 0
+Initial Hull: 100
+Initial Shields: 100
+Subsystem: Pilot
+Subsystem: turret01a
+Subsystem: turret02a
+Subsystem: turret03a
+Subsystem: turret04a
$Arrival Location: Hyperspace
$Arrival Cue: ( true )
$Departure Location: Hyperspace
$Departure Cue: ( false )
$Determination: 10
+Flags: ( "cargo-known" "no-shields" )
+Flags2: ( )
+Respawn priority: 0
+Orders Accepted List: ( "attack ship" )
+Use Table Score:
+Score: 0
]]

function template.instantiate(name, team, x, y, z, heading)
    return string.format(template.text, name, team, x, y, z, heading)
end

return template