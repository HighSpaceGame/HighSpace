local template = {}

template.text = [[
$Name: %s
$Class: GTF Myrmidon
$Team: %s
$Location: %f, %f, %f
$Orientation:
	1.000000, 0.000000, 0.000000,
	0.000000, 1.000000, 0.000000,
	0.000000, 0.000000, %s
+AI Class: General
$Cargo 1:  XSTR("Nothing", -1)
+Initial Velocity: 0
+Initial Hull: 100
+Subsystem: Pilot
+Primary Banks: ( "Subach HL-7" "Akheton SDG" )
+Secondary Banks: ( "Tempest" "Tempest" "Tempest")
$Arrival Location: Hyperspace
$Arrival Cue: ( false )
$Departure Location: Hyperspace
$Departure Cue: ( false )
$Determination: 10
+Flags: ( "cargo-known" %s)
+Flags2: ( )
+Respawn priority: 0
+Use Table Score:
+Score: 8
]]

function template.instantiate(name, team, x, y, z, heading)
    local player_start = ""
    if name == "Alpha 1" then
        player_start = '"player-start" '
    end

    return string.format(template.text, name, team, x, y, z, heading, player_start)
end

return template