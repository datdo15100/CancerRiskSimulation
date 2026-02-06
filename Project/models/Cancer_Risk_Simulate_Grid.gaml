/**
* Name: TrafficGIS - Grid-Based PM2.5 with Diffusion
* Author: trungnd (improved by Claude)
* Description: PM2.5 simulation using grid diffusion instead of clouds
*              - 50x50 grid for pollution tracking
*              - 10% decay every hour
*              - Diffusion at each step
*              - Chart tracking PM2.5 over time
*/

model Cancer_Risk_Simulate

import "./Infras_base.gaml"
import "./Inhabitant_base.gaml"
//import "./PM_fog_integrated.gaml"  // COMMENTED OUT - Using grid instead of clouds
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
	
	// ========== GRID-BASED PM2.5 STATISTICS ==========
	float avg_pm25 <- 0.0 update: mean(pollution_grid collect each.pm25_level);
	float max_pm25 <- 0.0 update: max(pollution_grid collect each.pm25_level);
	float min_pm25 <- 0.0 update: min(pollution_grid collect each.pm25_level);
	
	graph road_network;
	
	//creation of buildings, roads, and inhabitants.
	init{
		create building from: shapefile_buildings with:(height:int(read("HEIGHT")));
		create road from: shapefile_roads;
		create inhabitant number: 5000{
			location <- any_location_in(one_of(building));
		}
		road_network <- as_edge_graph(road);
	}
	
	reflex update_speed{
		road_weights <- road as_map(each::each.shape.perimeter/each.speed_rate);
	}
	
	// ========== DIFFUSION REFLEX: Spread PM2.5 across grid ==========
	reflex pm25_diffusion {
		// Diffuse PM2.5 pollution across the grid
		diffuse var: pm25_level on: pollution_grid proportion: 0.6;
		// proportion: 0.6 means 60% of pollution spreads to neighbors, 40% stays in cell
	}
}

// ========== POLLUTION GRID: 50x50 cells tracking PM2.5 ==========
grid pollution_grid width: 50 height: 50 neighbors: 8 {
	
	// ========== PM2.5 LEVEL (using grid_value built-in) ==========
	float pm25_level <- 0.0;
	float grid_value <- pm25_level update: pm25_level;  // Built-in variable for elevation/mesh
	
	// ========== HOURLY DECAY: 10% pollution disappears every hour ==========
	int last_decay_hour <- 0;
	reflex hourly_decay when: current_date.hour != last_decay_hour {
		pm25_level <- pm25_level * 0.9;  // 10% decay
		last_decay_hour <- current_date.hour;
	}
	
	// ========== COLOR BASED ON PM2.5 LEVEL (WHO Air Quality scale) ==========
	rgb color <- get_pm25_color() update: get_pm25_color();
	
	rgb get_pm25_color {
		if pm25_level <= 12.0 {
			// Good: Green
			return rgb(0, 255, 0, 200);
		} 
		else if pm25_level <= 35.0 {
			// Moderate: Yellow
			float ratio <- (pm25_level - 12.0) / (35.0 - 12.0);
			return rgb(255 * ratio, 255, 0, 200);
		}
		else if pm25_level <= 55.0 {
			// Unhealthy for Sensitive: Orange
			float ratio <- (pm25_level - 35.0) / (55.0 - 35.0);
			return rgb(255, 255 * (1 - ratio * 0.35), 0, 200);
		}
		else if pm25_level <= 150.0 {
			// Unhealthy: Red
			float ratio <- (pm25_level - 55.0) / (150.0 - 55.0);
			return rgb(255, 165 * (1 - ratio), 0, 200);
		}
		else if pm25_level <= 250.0 {
			// Very Unhealthy: Purple
			float ratio <- (pm25_level - 150.0) / (250.0 - 150.0);  // FIXED
			return rgb(255 - 126 * ratio, 0, 128 * ratio, 200);
		}
		else {
			// Hazardous: Maroon
			return rgb(128, 0, 128, 200);
		}
	}
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
    bool is_inside_building <- true;
    building current_building <- nil;
    date time_entered_building <- nil;
    
    // ========== MOVEMENT VARIABLES ==========
	point target <- nil;
	building target_building <- nil;
	
	// ========== PM2.5 EMISSION ==========
	float emission_pm <- 0.0;
	float base_emission_rate <- 2.0 + rnd(3.0);
	
	// ========== SCHEDULE CONFIGURATION ==========
	int work_start_hour <- 6 + rnd(3);
	int work_end_hour;
	int work_duration <- 8;
	
	// ========== INITIALIZATION ==========
	init {
        home_building <- one_of(building);
        home_location <- any_location_in(home_building);
        location <- home_location;
        
        work_building <- one_of(building);
        loop while: work_building = home_building { 
        	work_building <- one_of(building); 
        }
        work_location <- any_location_in(work_building);
        
        work_end_hour <- work_start_hour + work_duration;
        
        current_building <- home_building;
        time_entered_building <- current_date;
        ask home_building {
        	do add_inhabitant(myself);
        }
    }
	
	// ========== REFLEX 1: GO TO WORK ==========
    reflex go_to_work when: current_date.hour = work_start_hour 
    						and current_date.minute = 0
    						and target = nil
    						and current_building = home_building {
        target <- work_location;
        target_building <- work_building;
        do exit_building();
    }
    
    // ========== REFLEX 2: GO HOME ==========
    reflex go_home when: current_building = work_building 
    					 and time_entered_building != nil
    					 and (current_date - time_entered_building) >= work_duration#h {
        target <- home_location;
        target_building <- home_building;
        do exit_building();
    }
    
	// ========== REFLEX 3: MOVE + EMIT PM2.5 TO GRID ==========
	reflex move when: target != nil and not is_inside_building {
		// Calculate PM emission
		emission_pm <- base_emission_rate * speed * step / 10.0;
		
		// Move on road network
		do goto target: target on: road_network move_weights: road_weights;
		
		// ========== EMIT PM TO GRID CELL ==========
		pollution_grid current_cell <- pollution_grid(location);
		if current_cell != nil {
			ask current_cell {
				pm25_level <- pm25_level + myself.emission_pm;
			}
		}
		
		// Check if reached target
		if location = target {
			emission_pm <- 0.0;
			
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
	
	// ========== ACTION: ENTER BUILDING ==========
	action enter_building(building b) {
		is_inside_building <- true;
		current_building <- b;
		time_entered_building <- current_date;
		emission_pm <- 0.0;
		
		ask b {
			do add_inhabitant(myself);
		}
	}
	
	// ========== ACTION: EXIT BUILDING ==========
	action exit_building {
		if current_building != nil {
			ask current_building {
				do remove_inhabitant(myself);
			}
			current_building <- nil;
			time_entered_building <- nil;
		}
		is_inside_building <- false;
	}
	
	// ========== VISUALIZATION ==========
	aspect asp_inhabitant{
		rgb display_color;
		
		if is_inside_building {
			if current_building = home_building {
				display_color <- #orange;
			} else if current_building = work_building {
				display_color <- #blue;
			} else {
				display_color <- #green;
			}
		} else {
			display_color <- #yellow;
		}
		
		draw pyramid(4) color: display_color;
		draw sphere(2) at: location + {0,0,3} color: display_color;
	}
}

experiment Cancer_Risk_Simulate type: gui {
	
	output {
		
		// ========== 3D DISPLAY WITH POLLUTION GRID (MESH) ==========
		display "3D View with PM2.5 Grid" type: 3d axes: false background: #white {
			
			// Display pollution grid as mesh (elevated based on PM2.5 level)
			grid pollution_grid elevation: grid_value * 0.5 triangulation: true transparency: 0.3;
			
			species building aspect: asp_building; 			
			species road aspect: asp_road;
			species inhabitant aspect: asp_inhabitant;
		}
		
		// ========== 2D TOP-DOWN VIEW OF POLLUTION GRID ==========
		display "2D Pollution Map" type: 2d {
			grid pollution_grid;
			species building aspect: asp_building transparency: 0.5; 			
			species road aspect: asp_road transparency: 0.5;
			species inhabitant aspect: asp_inhabitant;
		}
		
		// ========== PM2.5 TIME SERIES CHART ==========
		display "PM2.5 Over Time" type: 2d {
			chart "PM2.5 Levels (μg/m³)" type: series size: {1.0, 0.5} position: {0, 0} {
				data "Average PM2.5" value: avg_pm25 color: #blue marker: false thickness: 2;
				data "Max PM2.5" value: max_pm25 color: #red marker: false thickness: 2;
				data "Min PM2.5" value: min_pm25 color: #green marker: false thickness: 1;
			}
			
			chart "Traffic Activity" type: series size: {1.0, 0.5} position: {0, 0.5} {
				data "Inhabitants Traveling" value: inhabitants_traveling color: #orange marker: false thickness: 2;
				data "Total PM Emission" value: total_traffic_pm_emission color: #purple marker: false thickness: 2;
			}
		}
		
		// ========== STATISTICS DISPLAY ==========
		display "Clock and Statistics" type: 2d {
            graphics "TimeInfo" {
                // Time display
                draw rectangle(250, 80) at: {130, 50} color: rgb(40, 40, 40, 150) border: #white;
                draw string(string(current_date.hour) + ":" + string(current_date.minute) + ":" + string(current_date.second)) 
                     at: {20, 70} color: #yellow font: font("Arial", 18, #bold);
                
                // Population statistics
                int at_home <- length(inhabitant where (each.current_building = each.home_building));
                int at_work <- length(inhabitant where (each.current_building = each.work_building));
                int traveling <- length(inhabitant where not(each.is_inside_building));
                
                draw rectangle(450, 230) at: {230, 230} color: rgb(40, 40, 40, 150) border: #white;
                draw string("At Home: " + at_home) at: {20, 150} color: #orange font: font("Arial", 14, #bold);
                draw string("At Work: " + at_work) at: {20, 175} color: #blue font: font("Arial", 14, #bold);
                draw string("Traveling: " + traveling) at: {20, 200} color: #yellow font: font("Arial", 14, #bold);
                
                // PM2.5 statistics
                draw string("Avg PM2.5: " + (int(avg_pm25)) + " μg/m³") 
                	at: {20, 230} color: #lightblue font: font("Arial", 14, #bold);
                draw string("Max PM2.5: " + (int(max_pm25)) + " μg/m³") 
                	at: {20, 255} color: #red font: font("Arial", 14, #bold);
                draw string("Total Emission: " + (int(total_traffic_pm_emission)) + " μg/m³") 
                	at: {20, 280} color: #purple font: font("Arial", 14, #bold);
            }
        }
        
        // ========== DETAILED MONITORS ==========
		monitor "Current Date" value: current_date;
		monitor "Current Hour" value: current_date.hour;
        monitor "Inhabitants at HOME" value: length(inhabitant where (each.current_building = each.home_building)) color: #orange;
        monitor "Inhabitants at WORK" value: length(inhabitant where (each.current_building = each.work_building)) color: #blue;
        monitor "Inhabitants TRAVELING" value: inhabitants_traveling color: #yellow;
        monitor "Average PM2.5 (Grid)" value: avg_pm25 color: #blue;
        monitor "Max PM2.5 (Grid)" value: max_pm25 color: #red;
        monitor "Min PM2.5 (Grid)" value: min_pm25 color: #green;
        monitor "Total Traffic PM Emission" value: total_traffic_pm_emission color: #purple;

	}
}
