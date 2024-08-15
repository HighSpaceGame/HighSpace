local template = {}

template.text = [[
$Name: %s
$Class: SF Manticore
$Team: %s
$Location: %f, %f, %f
$Orientation:
	1.000000, 0.000000, 0.000000,
	0.000000, 1.000000, 0.000000,
	0.000000, 0.000000, %s
+AI Class: General
$Cargo 1:  XSTR("Nothing", -1)
+Initial Velocity: 33
+Subsystem: Pilot
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
+Score: 12
]]

function template.instantiate(name, team, x, y, z, heading)
    local player_start = ""
    if name == "Alpha 1" then
        player_start = '"player-start" '
    end

    return string.format(template.text, name, team, x, y, z, heading, player_start)
end

return template