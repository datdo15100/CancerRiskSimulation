/**
* Name: Resident Species 
* Author: TrungNguyen
* Description: ALTERNATIVE APPROACH - If resident gets stuck, assign them a new reachable building
*              This is useful if your road network has connectivity issues
*/

model resident_model

import "Inhabitant_base.gaml"
import "Cancer_Risk_Simulate_Modular.gaml"

// ==================== GLOBAL RISK PARAMETERS ====================
global {
	// Risk formula parameters
	float PM_ref <- 150.0;
	float omega_pm <- 0.03;
	float theta_outdoor <- 1.0;
	float theta_indoor <- 0.3;
	float mask_effectiveness <- 0.6;

	// Baseline risk weights (input to sigmoid, not probabilities)
	float baseline_male_risk <- 0.3;
	float baseline_smoke_risk <- 0.6;
	float baseline_obese_risk <- 0.3;
	float baseline_family_risk <- 0.4;

	// Population spawn rates
	float male_rate <- 0.6;
	float smoke_rate <- 0.3;
	float obese_rate <- 0.3;
	float family_history_rate <- 0.125;
	float mask_rate <- 0.85;

	// Emission control
	float emission_multiplier <- 1.0;

	// Movement speed (m/s) - lower = visible movement at step=3600
	float resident_speed <- 5.0;

	// Arrival and reassignment
	float arrival_distance_threshold <- 10.0;
	int max_stuck_steps <- 20;
	float reassignment_search_radius <- 200.0;
}

species resident parent: inhabitant_base skills: [moving] {
	
	// ==================== PERSONAL ATTRIBUTES ====================
	bool is_male <- flip(male_rate);
	bool is_smoke <- flip(smoke_rate);
	bool is_obese <- flip(obese_rate);
	bool is_family_history <- flip(family_history_rate);
	bool is_wearmask <- flip(mask_rate);
	
	// ==================== RISK TRACKING ====================
	float baseline_risk <- 0.0;
	float cumulative_risk_score <- 0.0;
	float risk_probability <- 0.0;
	float pm_dose <- 0.0;
	float total_pm_exposure <- 0.0;
	float current_pm_zone <- 0.0;
	float theta <- theta_outdoor;
	float protect <- 1.0;
	
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
	point last_location <- nil;
	int stuck_counter <- 0;
	int reassignment_count <- 0;  // Track how many times reassigned
	
	// ==================== PM2.5 EMISSION ====================
	float emission_pm <- 0.0;
	float base_emission_rate <- 10.0 + rnd(10.0);  // 10-20 μg/m³/step for Hanoi pollution levels
	
	// ==================== SCHEDULE ====================
	int work_start_hour <- 6 + rnd(3);
	int work_duration <- 8;
	
	// ==================== INITIALIZATION ====================
	init {
		speed <- resident_speed;
		do initialize_home();
		do initialize_work();
		do calculate_baseline_risk();
		do enter_home();
		last_location <- location;
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
	
	action calculate_baseline_risk {
		baseline_risk <- 0.0;
		if is_male { baseline_risk <- baseline_risk + baseline_male_risk; }
		if is_smoke { baseline_risk <- baseline_risk + baseline_smoke_risk; }
		if is_obese { baseline_risk <- baseline_risk + baseline_obese_risk; }
		if is_family_history { baseline_risk <- baseline_risk + baseline_family_risk; }
	}
	
	action enter_home {
		current_building <- home_building;
		time_entered_building <- current_date;
		ask home_building {
			do add_resident(myself);
		}
	}
	
	// ==================== DAILY ROUTINE ====================
	
	reflex go_to_work when: current_date.hour = work_start_hour
							and target = nil
							and current_building = home_building {
		target <- work_location;
		target_building <- work_building;
		do exit_building();
	}
	
	reflex go_home when: current_building = work_building
						 and time_entered_building != nil
						 and target = nil
						 and (current_date - time_entered_building) >= work_duration#h {
		target <- home_location;
		target_building <- home_building;
		do exit_building();
	}
	
	// ==================== MOVEMENT ====================
	
	reflex move when: target != nil and not is_inside_building {
		do calculate_emission();
		do move_towards_target();
		do emit_pollution();
		do check_if_stuck_and_reassign();
		do check_arrival();
	}
	
	action calculate_emission {
		emission_pm <- emission_multiplier * base_emission_rate;
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
	
	// ==================== STUCK DETECTION WITH REASSIGNMENT ====================

	action check_if_stuck_and_reassign {
		float distance_moved <- location distance_to last_location;

		if distance_moved < 0.1 {
			stuck_counter <- stuck_counter + 1;

			if stuck_counter >= max_stuck_steps {
				string gender_str <- is_male ? "Nam" : "Nữ";
				string status_str <- (is_smoke ? "Hút thuốc, " : "Không hút thuốc, ") + (is_obese ? "Béo phì" : "Cân đối");

				write "⚠️ CẢNH BÁO: Resident bị tắc đường!";
				write "   - Tên: " + name;
				write "   - Đặc điểm: " + gender_str + " (" + status_str + ")";
				write "   - Tọa độ: " + location;
				write "   - Đích đến: " + (target_building = work_building ? "Cơ quan" : "Nhà");
				write "   - Số lần đổi đích: " + reassignment_count;

				do reassign_to_nearest_reachable_building();
			}
		} else {
			stuck_counter <- 0;
		}

		last_location <- location;
	}

	// ==================== BUILDING REASSIGNMENT ====================
	/**
	 * Find a new building that the resident can actually reach
	 * 
	 * Strategy:
	 * 1. Find all buildings within search radius
	 * 2. Pick the closest one that's not the current building
	 * 3. Update work_building and work_location
	 * 4. Set new target
	 */
	action reassign_to_nearest_reachable_building {
		// Determine which building type we're trying to reach
		bool going_to_work <- (target_building = work_building);
		
		// Find nearby buildings (within search radius)
		list<building> nearby_buildings <- building at_distance reassignment_search_radius;
		
		// Remove both home and work buildings from candidates (prevent home=work)
		nearby_buildings <- nearby_buildings - home_building - work_building;
		
		// If we found alternative buildings
		if length(nearby_buildings) > 0 {
			// Pick the closest one
			building new_building <- nearby_buildings closest_to self;
			
			if going_to_work {
				// Reassign work building
				write "Reassigning work building from " + work_building + " to " + new_building;
				work_building <- new_building;
				work_location <- any_location_in(new_building);
				target <- work_location;
				target_building <- work_building;
			} else {
				// Going home - reassign home building
				write "Reassigning home building from " + home_building + " to " + new_building;
				home_building <- new_building;
				home_location <- any_location_in(new_building);
				target <- home_location;
				target_building <- home_building;
			}
			
			reassignment_count <- reassignment_count + 1;
			stuck_counter <- 0;
			
		} else {
			// No alternative buildings found - force arrival at current location
			write "No alternative buildings found. Forcing arrival at nearest building.";
			do force_arrival_at_nearest_building();
		}
	}
	
	// ==================== EMERGENCY FALLBACK ====================
	/**
	 * Last resort: If no buildings in radius, just enter the closest building
	 */
	action force_arrival_at_nearest_building {
		building nearest <- building closest_to self;

		if nearest != nil {
			write "Emergency: Entering nearest building " + nearest;

			// Update building reference so schedule reflexes still work
			bool going_to_work <- (target_building = work_building);
			if going_to_work {
				work_building <- nearest;
				work_location <- any_location_in(nearest);
			} else {
				home_building <- nearest;
				home_location <- any_location_in(nearest);
			}

			// Move to building and enter
			location <- any_location_in(nearest);
			do enter_building(nearest);

			target <- nil;
			target_building <- nil;
			stuck_counter <- 0;
			reassignment_count <- reassignment_count + 1;
		}
	}
	
	// ==================== ARRIVAL CHECK ====================
	action check_arrival {
		if target = nil { return; }
		float distance_to_target <- location distance_to target;

		// Multiple arrival conditions
		bool arrived <- false;
		
		if distance_to_target <= arrival_distance_threshold or location = target {
			arrived <- true;
		}
		
		if arrived {
			emission_pm <- 0.0;
			location <- target;
			
			if target_building != nil {
				do enter_building(target_building);
				target_building <- nil;
			}
			
			target <- nil;
			stuck_counter <- 0;
		}
	}
	
	reflex zero_emission_inside when: is_inside_building {
		emission_pm <- 0.0;
	}
	
	// ==================== RISK CALCULATION ====================
	
	reflex update_risk {
		do update_exposure_factors();
		do get_current_pm_zone();
		do calculate_pm_dose();
		do update_cumulative_risk();
		do calculate_risk_probability();
	}
	
	action update_exposure_factors {
		if is_inside_building {
			theta <- theta_indoor;
			protect <- 1.0; // No mask indoors
		} else {
			theta <- theta_outdoor;
			protect <- is_wearmask ? (1.0 - mask_effectiveness) : 1.0;
		}
	}
	
	action get_current_pm_zone {
		pollution_grid current_cell <- pollution_grid(location);
		if current_cell != nil {
			current_pm_zone <- current_cell.pm25_level;
		} else {
			current_pm_zone <- 0.0;
		}
	}
	
	action calculate_pm_dose {
		float delta_time <- step / 3600.0;
		pm_dose <- current_pm_zone * delta_time * theta * protect;
		total_pm_exposure <- total_pm_exposure + pm_dose;
	}
	
	action update_cumulative_risk {
		float X_pm <- min(1.0, pm_dose / PM_ref);
		float risk_increment <- omega_pm * X_pm;
		cumulative_risk_score <- cumulative_risk_score + risk_increment;
	}
	
	action calculate_risk_probability {
		float k <- 2.0;
		float b <- -4.0;
		float z <- k * (cumulative_risk_score + baseline_risk) + b;
		risk_probability <- 1.0 / (1.0 + exp(-z));
		risk_probability <- max(0.0, min(1.0, risk_probability));
	}
	
	// ==================== BUILDING INTERACTION ====================
	
	action enter_building(building b) {
		is_inside_building <- true;
		current_building <- b;
		time_entered_building <- current_date;
		emission_pm <- 0.0;
		stuck_counter <- 0;
		
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
		stuck_counter <- 0;
	}
	
	// ==================== VISUALIZATION ====================
	
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
	
	rgb get_risk_color {
		if risk_probability < 0.2 {
			return #green;
		} else if risk_probability < 0.5 {
			return #yellow;
		} else if risk_probability < 0.8 {
			return #orange;
		} else {
			return #red;
		}
	}
	
	aspect default {
		rgb risk_color <- get_risk_color();
		if is_male {
			draw triangle(6) color: risk_color border: #black;
		} else {
			draw circle(3) color: risk_color border: #black;
		}
	}
}
