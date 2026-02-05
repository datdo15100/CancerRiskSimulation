/**
* Name: TrafficGIS - Integrated with PM2.5 Emissions
* Author: trungnd (improved by Claude)
* Description: Inhabitants emit PM2.5 while traveling, affecting cloud pollution levels
*/

model Cancer_Risk_Simulate

import "./Infras_base.gaml"
import "./Inhabitant_base.gaml"
import "./PM_fog.gaml"
import "date_time.gaml"

global {

	float step <- 10;
	float dept <- rnd(250.0);
	
	file shapefile_buildings <- file("../includes/building_polygon.shp");
	file shapefile_roads <- file("../includes/highway_line.shp");
	
	map<road,float> road_weights;
	geometry shape <- envelope(shapefile_roads);
	
    date starting_date <- date("2023-10-01 06:00:00");
	
	// ========== PM EMISSION GLOBAL TRACKING ==========
	float total_traffic_pm_emission <- 0.0 update: sum(inhabitant collect each.emission_pm);
	int inhabitants_traveling <- 0 update: length(inhabitant where not(each.is_inside_building));
	
	graph road_network;
	
	//creation of buildings, roads, and inhabitants.
	init{
		create building from: shapefile_buildings with:(height:int(read("HEIGHT")))
		;
		create road from: shapefile_roads;
		create inhabitant number: 100{
			location <- any_location_in(one_of(building));
		}
		road_network <- as_edge_graph(road);
	}
	reflex update_speed{
		road_weights <- road as_map(each::each.shape.perimeter/each.speed_rate);
	}
}

grid plot height:50#m width: 50#m{
	float pollution_rate <- 0.0;
	
} 

species building parent: building_base{
	// Track inhabitants inside this building
	list<inhabitant> inhabitants_inside <- [];
	
	// Add an inhabitant to this building
	action add_inhabitant(inhabitant i) {
		if not(inhabitants_inside contains i) {
			add i to: inhabitants_inside;
		}
	}
	
	// Remove an inhabitant from this building
	action remove_inhabitant(inhabitant i) {
		remove i from: inhabitants_inside;
	}
}

species road parent: road_base{
	float capacity <- 1 + shape.perimeter/30;
	int nb_drivers <- 0 update: length(inhabitant at_distance 1);
	float speed_rate <- 1.0 update: exp(-nb_drivers/capacity) min: 0.1;
}

species inhabitant parent: inhabitant_base  skills: [moving]{
	
	// ========== LOCATION VARIABLES ==========
    point home_location;
    point work_location;
    building home_building;
    building work_building;
    
    // ========== STATE VARIABLES ==========
    bool is_inside_building <- true;      // Is inhabitant currently inside a building?
    building current_building <- nil;      // Which building are they in?
    date time_entered_building <- nil;     // When did they enter current building?
    
    // ========== MOVEMENT VARIABLES ==========
	point target <- nil;                   // Where are they going?
	building target_building <- nil;       // Which building are they targeting?
	
	// ========== PM2.5 EMISSION ==========
	float emission_pm <- 0.0;              // Current PM2.5 emission (μg/m³ per step)
	float base_emission_rate <- 2.0 + rnd(3.0);  // Base emission: 2-5 μg/m³ per step when moving
	
	// ========== SCHEDULE CONFIGURATION ==========
	int work_start_hour <- 6 + rnd(3);     // Work starts between 6-9 AM (randomized per inhabitant)
	int work_end_hour;                     // Calculated: work_start_hour + 8 hours
	int work_duration <- 8;                // 8 hours of work
	
	// ========== INITIALIZATION ==========
	init {
        // Assign home building and location
        home_building <- one_of(building);
        home_location <- any_location_in(home_building);
        location <- home_location;
        
        // Assign work building (must be different from home)
        work_building <- one_of(building);
        loop while: work_building = home_building { 
        	work_building <- one_of(building); 
        }
        work_location <- any_location_in(work_building);
        
        // Calculate when work ends
        work_end_hour <- work_start_hour + work_duration;
        
        // Start simulation with inhabitant at home
        current_building <- home_building;
        time_entered_building <- current_date;
        ask home_building {
        	do add_inhabitant(myself);
        }
        
        write name + " initialized: Home at " + home_building + ", Work at " + work_building + 
              ", Work hours: " + work_start_hour + ":00 to " + work_end_hour + ":00" +
              ", Base emission: " + base_emission_rate + " μg/m³";
    }
	
	// ========== REFLEX 1: GO TO WORK (Every day at work_start_hour) ==========
    reflex go_to_work when: current_date.hour = work_start_hour 
    						and current_date.minute = 0  // Only trigger at the exact hour
    						and target = nil             // Not already moving
    						and current_building = home_building {  // Currently at home
        
        // Set work as target
        target <- work_location;
        target_building <- work_building;
        
        // Exit home
        do exit_building();
        
        write name + " is leaving home for work at " + current_date + " (hour " + current_date.hour + ")";
    }
    
    // ========== REFLEX 2: GO HOME (Every day after work_duration hours at work) ==========
    reflex go_home when: current_building = work_building 
    					 and time_entered_building != nil
    					 and (current_date - time_entered_building) >= work_duration#h {
        
        // Set home as target
        target <- home_location;
        target_building <- home_building;
        
        // Exit work
        do exit_building();
        
        write name + " finished work after " + work_duration + " hours, going home at " + current_date;
    }
    
	// ========== REFLEX 3: MOVE TOWARDS TARGET + EMIT PM2.5 ==========
	reflex move when: target != nil and not is_inside_building {
		// Calculate PM emission based on movement
		emission_pm <- base_emission_rate * speed * step / 10.0;
		
		// Move on road network
		do goto target: target on: road_network move_weights: road_weights;
		
		// Emit PM to nearby clouds
		list<cloud> nearby_clouds <- cloud at_distance 50;
		if not empty(nearby_clouds) {
			ask nearby_clouds {
				// Add traffic PM emission to cloud
				traffic_pm_level <- traffic_pm_level + myself.emission_pm;
			}
		}
		
		// Check if reached target
		if location = target {
			// Stop emitting PM
			emission_pm <- 0.0;
			
			// Enter the target building
			if target_building != nil {
				do enter_building(target_building);
				target_building <- nil;
			}
			target <- nil;
		}
	}
	
	// ========== REFLEX 4: ZERO EMISSION WHEN INSIDE ==========
	reflex zero_emission_inside when: is_inside_building {
		emission_pm <- 0.0;
	}
	
	// ========== ACTION: ENTER A BUILDING ==========
	action enter_building(building b) {
		is_inside_building <- true;
		current_building <- b;
		time_entered_building <- current_date;
		emission_pm <- 0.0;  // Stop emitting when inside
		
		// Register with building
		ask b {
			do add_inhabitant(myself);
		}
		
		string building_type <- (current_building = home_building) ? "HOME" : "WORK";
		write name + " ENTERED " + building_type + " at " + current_date + 
		      " (hour " + current_date.hour + ":" + current_date.minute + ")";
	}
	
	// ========== ACTION: EXIT A BUILDING ==========
	action exit_building {
		if current_building != nil {
			string building_type <- (current_building = home_building) ? "HOME" : "WORK";
			
			// Unregister from building
			ask current_building {
				do remove_inhabitant(myself);
			}
			
			write name + " EXITED " + building_type + " at " + current_date + 
			      " (stayed for " + (current_date - time_entered_building) + ")";
			
			current_building <- nil;
			time_entered_building <- nil;
		}
		is_inside_building <- false;
	}
	
	// ========== VISUALIZATION ==========
	aspect asp_inhabitant{
		// Color coding:
		// GREEN = Inside building
		// YELLOW = Moving/traveling
		// BLUE = At work
		// ORANGE = At home
		
		rgb display_color;
		
		if is_inside_building {
			if current_building = home_building {
				display_color <- #orange;  // Orange when at home
			} else if current_building = work_building {
				display_color <- #blue;    // Blue when at work
			} else {
				display_color <- #green;   // Green for other buildings
			}
		} else {
			display_color <- #yellow;      // Yellow when traveling (emitting PM)
		}
		
		draw pyramid(4) color: display_color;
		draw sphere(2) at: location + {0,0,3} color: display_color;
	}
}


species pm_clound parent: cloud {}

species pm_balls parent: ball {}

experiment Cancer_Risk_Simulate type: gui {
	parameter 'Create groups?' var: create_group <- true;
	parameter 'Create clouds?' var: create_cloud <- true;
	
	
	output {
		display view type: 3d axes: false background: #white{
//			image "../includes/satelitte.png" refresh: false transparency: 0.2;
			//grid plot border: #green;
			
			
			species ball aspect: default transparency: 0.5;
			species group aspect: default transparency: 0.5 {
				species ball_in_group;
			}
			
			
			species cloud aspect: default {
				species group_delegation transparency: 0.9 {
					species ball_in_cloud;
					species ball_in_group;
				}

			}		
			species ball;
			species group;
			species cloud;

			species building aspect: asp_building; 			
			species road aspect: asp_road;
			species inhabitant aspect: asp_inhabitant;
		}
		
		
		display "Clock and Statistics" type: 2d {
            graphics "TimeInfo" {
                // Time display
                draw rectangle(250, 80) at: {130, 50} color: rgb(40, 40, 40, 150) border: #white;
                draw string(string(current_date.hour) + ":" + string(current_date.minute) + ":" + string(current_date.second)) 
                     at: {20, 70} color: #yellow font: font("Arial", 18, #bold);
                
                // Statistics display
                int at_home <- length(inhabitant where (each.current_building = each.home_building));
                int at_work <- length(inhabitant where (each.current_building = each.work_building));
                int traveling <- length(inhabitant where not(each.is_inside_building));
                
                draw rectangle(450, 180) at: {230, 210} color: rgb(40, 40, 40, 150) border: #white;
                draw string("At Home: " + at_home) at: {20, 150} color: #orange font: font("Arial", 14, #bold);
                draw string("At Work: " + at_work) at: {20, 175} color: #blue font: font("Arial", 14, #bold);
                draw string("Traveling: " + traveling) at: {20, 200} color: #yellow font: font("Arial", 14, #bold);
                draw string("Total PM Emission: " + (int(total_traffic_pm_emission)) + " μg/m³") 
                	at: {20, 225} color: #red font: font("Arial", 14, #bold);
                draw string("Clouds: " + length(cloud)) at: {20, 250} color: #lightgreen font: font("Arial", 14, #bold);
            }
        }
        
        // Detailed monitors
		monitor "Current Date" value: current_date;
		monitor "Current Hour" value: current_date.hour;
        monitor "Inhabitants at HOME" value: length(inhabitant where (each.current_building = each.home_building)) color: #orange;
        monitor "Inhabitants at WORK" value: length(inhabitant where (each.current_building = each.work_building)) color: #blue;
        monitor "Inhabitants TRAVELING" value: length(inhabitant where not(each.is_inside_building)) color: #yellow;
        monitor "Total Traffic PM Emission" value: total_traffic_pm_emission color: #red;
        monitor "Number of Clouds" value: length(cloud) color: #lightgreen;
        monitor "Average Cloud PM2.5" value: (length(cloud) > 0) ? mean(cloud collect each.pm25_density) : 0.0 color: #purple;

	}
}
