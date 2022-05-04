###############################################################################
####                          Edit this section                            ####
###############################################################################

[gcode_macro GlobalVariables]

# Location of the probe when docked.  
variable_dock_x: 200        # X location
variable_dock_z: 8.4      # Z location

# Side sweep servo
variable_servo_in_angle: 0
variable_servo_out_angle: 90

# Buidplate size
variable_buildplate_x: 235
variable_buildplate_y: 235

# What other way can you home the Z-Axis (prior to attaching the probe)? Use 3 ONLY if
# you can have the X-carriage and toolhead clear of the bed when the gantry is resting
# on the lower Z end blocks with the bed pushed all the way to the rear
variable_initial_homing: 3  # 1(none/probe only), 2(Z-max microswitch endstop), 3(Z-min microswitch endstop)
variable_buildplate_tab: 1  # 1 (center, home to 1/4X), 2 (left and/or right, home to 1/2X)

variable_dock_x_offset: 20  # The distance to move along x when docking/undocking the probe from the dock


# Travel and Dock speeds
variable_travel_speed: 9000 # 9000 Travel speed
variable_dock_speed: 6000   # 6000 Docking maneuvers speed

gcode:

###############################################################################
####                     Do not change the lines below                     ####
###############################################################################

[homing_override]
axes: xyz
gcode:
    LIGHTS_ON
    SET_GCODE_OFFSET Z=0
    query_probe
    do_Home

[gcode_macro do_Home]
gcode:
    GlobalVariables
    {% set dock_x = printer["gcode_macro GlobalVariables"].dock_x %}
    {% set dock_z = printer["gcode_macro GlobalVariables"].dock_z %}
    {% set travel_speed = printer["gcode_macro GlobalVariables"].travel_speed %}
    {% set initial_homing = printer["gcode_macro GlobalVariables"].initial_homing %}

    
    {% if printer.toolhead.homed_axes == 'xyz' %}
        G90
        G0 Z{ dock_z + 10} F{ travel_speed }                
        SERVO_OUT
        G28 X0 Y0
        
        Attach_probe
        PROBE_HOMING

	{% else %}
        SET_KINEMATIC_POSITION X={ dock_x } Z=0
        G90
        G0 Z{ dock_z + 10} F{ travel_speed }
        SERVO_OUT  
        G28 X0 Y0

        {% if printer.probe.last_query == 0 %}
            PROBE_HOMING
        {% endif %}

        {% if printer.probe.last_query == 1 %}
            {% if initial_homing == 1 %}
                RESPOND TYPE=error MSG="Please attach probe"
                M117 Please attach probe
            {% endif %}
            {% if initial_homing == 2 %}
                SENSORLESS_HOMING
            {% endif %}
            {% if initial_homing == 3 %}
                PROBELESS_HOMING
            {% endif %}
        {% endif %}
    {% endif %}
    SERVO_IN

[gcode_macro PROBELESS_HOMING]
gcode:
    GlobalVariables
    {% set dock_z = printer["gcode_macro GlobalVariables"].dock_z %}
    {% set travel_speed = printer["gcode_macro GlobalVariables"].travel_speed %}
    {% set home_x = printer["gcode_macro GlobalVariables"].buildplate_x %}
    {% set home_y = printer["gcode_macro GlobalVariables"].buildplate_y %}
    {% set probe_y_offset = printer.configfile.settings.probe.y_offset %}
    {% set y_min = printer.configfile.settings.stepper_y.position_min %}
    {% set initial_homing = printer["gcode_macro GlobalVariables"].initial_homing %}
    {% set buildplate_tab = printer["gcode_macro GlobalVariables"].buildplate_tab %}

    {% if initial_homing == 3 %}
            {% if buildplate_tab == 1 %}
                G0 X{ home_x / 4 } Y{ y_min  } F{ travel_speed }
            {% endif %}

            {% if buildplate_tab == 2 %}
                G0 X{ home_x / 2 } Y{ y_min  } F{ travel_speed }
            {% endif %}
    {% endif %}
    SERVO_OUT
    G28 Z0
    G0 Z{dock_z + 10} F{ travel_speed }
    Attach_probe
    Adjust_Z

[gcode_macro PROBE_HOMING]
gcode:
    Adjust_Z

[gcode_macro Adjust_Z]
gcode:
    GlobalVariables
    {% set travel_speed = printer["gcode_macro GlobalVariables"].travel_speed %}
    {% set home_x = printer["gcode_macro GlobalVariables"].buildplate_x %}
    {% set home_y = printer["gcode_macro GlobalVariables"].buildplate_y %}
    #{% set home_x = printer.configfile.config.stepper_x.position_max|int %}
    #{% set home_y = printer.configfile.config.stepper_y.position_max|int %}
    {% set probe_y_offset = printer.configfile.settings.probe.y_offset %}
    {% set z_max = printer.configfile.config.stepper_z.position_max %}
    {% set probe_offset_z = printer.configfile.config.probe.z_offset|float %}

    G0 X{ home_x / 2 } Y{ home_y / 2 - probe_y_offset } F { travel_speed }
    SET_KINEMATIC_POSITION Z={ z_max }
    PROBE PROBE_SPEED=10
    SET_KINEMATIC_POSITION Z={ probe_offset_z }
    G91
    G0 Z2 F{ travel_speed }
    G90
    PROBE PROBE_SPEED=5
    SET_KINEMATIC_POSITION Z={ probe_offset_z }
    G0 Z{ probe_offset_z + 3 } F{ travel_speed }

[gcode_macro SERVO_OUT]
gcode:
    GlobalVariables
    {% set servo_out_angle = printer["gcode_macro GlobalVariables"].servo_out_angle %}
    SET_SERVO SERVO=Magprobe ANGLE={servo_out_angle}

[gcode_macro SERVO_IN]
gcode:
    GlobalVariables
    {% set servo_in_angle = printer["gcode_macro GlobalVariables"].servo_in_angle %}
    SET_SERVO SERVO=Magprobe ANGLE={servo_in_angle}
    G4 P500
	SET_SERVO SERVO=Magprobe WIDTH=0

[gcode_macro Dock_probe]
gcode:
    query_probe
    do_Dock

[gcode_macro do_Dock]
gcode:
    {% if printer.probe.last_query == 1 %}
        RESPOND PREFIX= MSG="Probe is already docked!"
        M117 Probe is already docked!

    {% else %}
	    GlobalVariables
        {% set dock_x = printer["gcode_macro GlobalVariables"].dock_x %}
        {% set dock_z = printer["gcode_macro GlobalVariables"].dock_z %}
        {% set home_y = printer.configfile.config.stepper_y.position_max|int %}
        {% set dock_x_offset = printer["gcode_macro GlobalVariables"].dock_x_offset %}
        {% set travel_speed = printer["gcode_macro GlobalVariables"].travel_speed %}
        {% set dock_speed = printer["gcode_macro GlobalVariables"].dock_speed %}
        {% set probe_y_offset = printer.configfile.settings.probe.y_offset %}

        {% if printer.toolhead.homed_axes != 'xyz' %}
	        G28	# Home All Axes
	    {% endif %}

        G90
        G0 X{ dock_x - dock_x_offset } Z{ dock_z } F{ travel_speed }
        SERVO_OUT
        G4 P400
        G0 X{ dock_x } F{ dock_speed }
        G4 P300
        G0 X{ dock_x + dock_x_offset  } F{ dock_speed }
        SERVO_IN
        G0 X{ dock_x - dock_x_offset  } F{ travel_speed }
    {% endif %}

    verify_Docking

[gcode_macro verify_Docking]
gcode:
    query_probe
    safe_Dock

[gcode_macro safe_Dock]
gcode:
    {% if printer.probe.last_query != 1 %}
        M112
    {% endif %}

[gcode_macro Attach_probe]
gcode:
    query_probe
    do_Attach

[gcode_macro do_Attach]
gcode:
    {% if printer.probe.last_query == 0 %}
        RESPOND PREFIX= MSG="Probe is already attached!"
        M117 Probe is already attached!

    {% else %}
        GlobalVariables
        {% set dock_x = printer["gcode_macro GlobalVariables"].dock_x %}
        {% set dock_z = printer["gcode_macro GlobalVariables"].dock_z %}
        {% set dock_x_offset = printer["gcode_macro GlobalVariables"].dock_x_offset %}
        {% set travel_speed = printer["gcode_macro GlobalVariables"].travel_speed %}
        {% set dock_speed = printer["gcode_macro GlobalVariables"].dock_speed %}
        {% set home_y = printer.configfile.config.stepper_y.position_max|int %}
        {% set probe_y_offset = printer.configfile.settings.probe.y_offset %}

        {% if printer.toolhead.homed_axes != 'xyz' %}
	        G28	# Home All Axes
	    {% endif %}
        
        G90
        G0 X{ dock_x - dock_x_offset } Z{ dock_z +2 } F{ travel_speed }
        SERVO_OUT
        G4 P400
        G0 X{ dock_x } Z{ dock_z } F{ dock_speed }
        G4 P300
        G0 X{ dock_x - dock_x_offset } F{ dock_speed }
        SERVO_IN
    {% endif %}

[gcode_macro Park_toolhead]
gcode:
    query_probe
    do_Park

[gcode_macro do_Park]
gcode:
    
    {% if printer.toolhead.homed_axes != 'xyz' %}
	    G28	# Home All Axes
	{% endif %}
    
    GlobalVariables
    {% set dock_x = printer["gcode_macro GlobalVariables"].dock_x %}
    {% set dock_z = printer["gcode_macro GlobalVariables"].dock_z %}
    {% set dock_x_offset = printer["gcode_macro GlobalVariables"].dock_x_offset %}
    {% set dock_z_offset = printer["gcode_macro GlobalVariables"].dock_z_offset %}
    {% set travel_speed = printer["gcode_macro GlobalVariables"].travel_speed %}
    {% set dock_speed = printer["gcode_macro GlobalVariables"].dock_speed %}
    {% set home_y = printer.configfile.config.stepper_y.position_max|int %}
    {% set probe_y_offset = printer.configfile.settings.probe.y_offset %}
    {% set y_max = printer.configfile.config.stepper_y.position_max %}

    RESPOND PREFIX= MSG="Parking toolhead"

    {% if printer.probe.last_query == 0 %}
        G90
        G0 Z{ dock_z }
        G0 X{ dock_x } Y{ home_y / 2 - probe_y_offset } F{ dock_speed }

    {% else %}
        G91
        G0 Z10 F{ travel_speed } # Move toolhead up to prevent hitting printed parts
        G90
        G0 Y{ y_max } F{ travel_speed } # Move the bed to prevent hitting printed parts
        G0 X{ dock_x - dock_x_offset } F{ travel_speed }
        G0 X{ dock_x } F{ dock_speed }
    {% endif %}

#[gcode_macro BED_MESH_CALIBRATE]
#rename_existing: _BED_MESH_CALIBRATE
#gcode:
#    {% if printer.toolhead.homed_axes != 'xyz' %}
#        G28	# Home All Axes
#    {% endif %}
#
#    Attach_probe
#
#    _BED_MESH_CALIBRATE {% for p in params 
#           %}{'%s=%s' % (p, params[p])}{% 
#          endfor %}

#[gcode_macro SCREWS_TILT_CALCULATE]
#rename_existing: _SCREWS_TILT_CALCULATE
#gcode:
#    Attach_probe
#    _SCREWS_TILT_CALCULATE {% for p in params 
#           %}{'%s=%s' % (p, params[p])}{% 
#          endfor %}

[gcode_macro PROBE_CALIBRATE]
rename_existing: _PROBE_CALIBRATE
gcode:
    GlobalVariables
    {% set travel_speed = printer["gcode_macro GlobalVariables"].travel_speed %}
    {% set home_x = printer["gcode_macro GlobalVariables"].buildplate_x %}
    {% set home_y = printer["gcode_macro GlobalVariables"].buildplate_y %}
    {% set probe_x_offset = printer.configfile.settings.probe.x_offset %}
    {% set probe_y_offset = printer.configfile.settings.probe.y_offset %}

    {% if printer.toolhead.homed_axes != 'xyz' %}
        G28	# Home All Axes
    {% endif %}

    Attach_probe

    G0 X{ home_x / 2 - probe_x_offset } Y{ home_y / 2 - probe_y_offset } F { travel_speed }
    _PROBE_CALIBRATE


[gcode_macro PROBE_ACCURACY]
rename_existing: _PROBE_ACCURACY
gcode:
    GlobalVariables
    {% set travel_speed = printer["gcode_macro GlobalVariables"].travel_speed %}
    {% set home_x = printer["gcode_macro GlobalVariables"].buildplate_x %}
    {% set home_y = printer["gcode_macro GlobalVariables"].buildplate_y %}
    {% set probe_x_offset = printer.configfile.settings.probe.x_offset %}
    {% set probe_y_offset = printer.configfile.settings.probe.y_offset %}

    {% if printer.toolhead.homed_axes != 'xyz' %}
        G28	# Home All Axes
    {% endif %}

    Attach_probe

    G0 X{ home_x / 2 - probe_x_offset } Y{ home_y / 2 - probe_y_offset } F { travel_speed }
    _PROBE_ACCURACY {% for p in params 
           %}{'%s=%s' % (p, params[p])}{% 
          endfor %}

### Mini display menu         ###
### Thanks to CautiousLeopard ###
### Uncomment the next lines  ###

#[menu __main __quickdraw]
#type: list
#enable: {not printer.idle_timeout.state == "Printing"}
#name: Quickdraw

#[menu __main __quickdraw __dockprobe]
#type: command
#enable: {not printer.idle_timeout.state == "Printing"}
#name: Dock probe
#gcode: Dock_probe

#[menu __main __quickdraw __parktoolhead]
#type: command
#enable: {not printer.idle_timeout.state == "Printing"}
#name: Park toolhead
#gcode: Park_toolhead

#[menu __main __quickdraw __attachprobe]
#type: command
#enable: {not printer.idle_timeout.state == "Printing"}
#name: Attach Probe
#gcode: Attach_probe
    
[force_move]
enable_force_move: True