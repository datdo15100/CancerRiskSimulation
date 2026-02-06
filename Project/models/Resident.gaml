/**
* Name: Resident Species
* Author: TrungNguyen (modularized by Claude)
* Description: Resident agents with gender-based visualization, movement, and PM emission
*/

model resident_model

import "Inhabitant_base.gaml"

species resident parent: inhabitant_base skills: [moving] {
	
	// ==================== PERSONAL ATTRIBUTES ====================
	bool is_male <- flip(0.6);  // 60% male, 40% female
	
	// ==================== LOCATION ATTRIBUTES ====================
	point home_location;
	point work_location;
	building home_building;
	building work_building;
	
	// ==================== STATE ATTRIBUTES ====================
	bool is_inside_building <- true;
	building current_building <- nil;
	date time_entered_building <- nil;
	
	// ==================== MOVEMENT ATTRIBUTES ====================
	point target <- nil;
	building target_building <- nil;
	
	// ==================== PM2.5 EMISSION ATTRIBUTES ====================
	float emission_pm <- 0.0;
	float base_emission_rate <- 2.0 + rnd(3.0);  // 2-5 μg/m³ per step
	
	// ==================== SCHEDULE ATTRIBUTES ====================
	int work_start_hour <- 6 + rnd(3);  // 6-9 AM
	int work_end_hour;
	int work_duration <- 8;  // 8 hours
	
	// ==================== INITIALIZATION ====================
	init {
		do initialize_home();
		do initialize_work();
		do initialize_schedule();
		do enter_home();
	}
	
	action initialize_home {
		home_building <- one_of(building);
		home_location <- any_location_in(home_building);
		location <- home_location;
	}
	
	action initialize_work {
		work_building <- one_of(building);
		loop while: work_building = home_building {
			work_building <- one_of(building);
		}
		work_location <- any_location_in(work_building);
	}
	
	action initialize_schedule {
		work_end_hour <- work_start_hour + work_duration;
	}
	
	action enter_home {
		current_building <- home_building;
		time_entered_building <- current_date;
		ask home_building {
			do add_resident(myself);
		}
	}
	
	// ==================== DAILY ROUTINE REFLEXES ====================
	
	reflex go_to_work when: current_date.hour = work_start_hour 
							and current_date.minute = 0
							and target = nil
							and current_building = home_building {
		target <- work_location;
		target_building <- work_building;
		do exit_building();
	}
	
	reflex go_home when: current_building = work_building 
						 and time_entered_building != nil
						 and (current_date - time_entered_building) >= work_duration#h {
		target <- home_location;
		target_building <- home_building;
		do exit_building();
	}
	
	// ==================== MOVEMENT & EMISSION ====================
	
	reflex move when: target != nil and not is_inside_building {
		do calculate_emission();
		do move_towards_target();
		do emit_pollution();
		do check_arrival();
	}
	
	action calculate_emission {
		emission_pm <- base_emission_rate * speed * step / 10.0;
	}
	
	action move_towards_target {
		do goto target: target on: road_network move_weights: road_weights;
	}
	
	action emit_pollution {
		pollution_grid current_cell <- pollution_grid(location);
		if current_cell != nil {
			ask current_cell {
				pm25_level <- pm25_level + myself.emission_pm;
			}
		}
	}
	
	action check_arrival {
		if location = target {
			emission_pm <- 0.0;
			if target_building != nil {
				do enter_building(target_building);
				target_building <- nil;
			}
			target <- nil;
		}
	}
	
	reflex zero_emission_inside when: is_inside_building {
		emission_pm <- 0.0;
	}
	
	// ==================== BUILDING INTERACTION ====================
	
	action enter_building(building b) {
		is_inside_building <- true;
		current_building <- b;
		time_entered_building <- current_date;
		emission_pm <- 0.0;
		
		ask b {
			do add_resident(myself);
		}
	}
	
	action exit_building {
		if current_building != nil {
			ask current_building {
				do remove_resident(myself);
			}
			current_building <- nil;
			time_entered_building <- nil;
		}
		is_inside_building <- false;
	}
	
	// ==================== HELPER FUNCTIONS ====================
	
	rgb get_display_color {
		if is_inside_building {
			if current_building = home_building {
				return #orange;
			} else if current_building = work_building {
				return #blue;
			} else {
				return #green;
			}
		} else {
			return #yellow;
		}
	}
	
	// ==================== VISUALIZATION ====================
	
	aspect default {
		rgb display_color <- get_display_color();
		
		// Draw pyramid (body) - common for both genders
		draw pyramid(4) color: display_color;
		
		// Draw head - different for male and female
		if is_male {
			// Male: sphere head
			draw sphere(2) at: location + {0, 0, 3} color: display_color;
		} else {
			// Female: cube head
			draw cube(2.5) at: location + {0, 0, 3} color: display_color;
		}
	}
}
