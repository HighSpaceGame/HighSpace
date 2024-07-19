local template = {}

template.text = [[
$Name: %s
$Class: SD Demon
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
+Subsystem: turret01-base
+Subsystem: turret02-base
+Subsystem: turret03a-base
+Subsystem: turret04-base
+Subsystem: turret05-base
+Subsystem: turret06a-base
+Subsystem: turret07a-base
+Subsystem: turret08-base
+Subsystem: turret09-base
+Subsystem: turret10-base
+Subsystem: turret11-base
+Subsystem: turret12-base
+Subsystem: turret13-base
+Subsystem: turret14-base
+Subsystem: turret15-base
+Subsystem: turret16-base
+Subsystem: turret17-base
+Subsystem: turret18-base
+Subsystem: turret19-base
+Subsystem: turret20-base
+Subsystem: turret21-base
+Subsystem: turret22
+Subsystem: turret23
+Subsystem: turret24
+Subsystem: turret25
+Subsystem: turret26
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