/**
* Name: Resident Species - Alternative Solution with Building Reassignment
* Author: TrungNguyen (enhanced by Claude)
* Description: ALTERNATIVE APPROACH - If resident gets stuck, assign them a new reachable building
*              This is useful if your road network has connectivity issues
*/

model resident_model

import "Inhabitant_base.gaml"
import "Cancer_Risk_Simulate_Modular.gaml"

// ==================== GLOBAL RISK PARAMETERS ====================
global {
	float PM_ref <- 100.0;
	float omega_pm <- 0.01;
	float theta_outdoor <- 1.0;
	float theta_indoor <- 0.3;
	float mask_effectiveness <- 0.6;
	float baseline_male_risk <- 0.2;
	float baseline_smoke_risk <- 0.85;
	float baseline_obese_risk <- 0.3;
	float baseline_family_risk <- 0.4;
	
	// ARRIVAL AND REASSIGNMENT PARAMETERS
	float arrival_distance_threshold <- 10.0;
	int max_stuck_steps <- 20;  // Reassign after stuck for 20 steps
	float reassignment_search_radius <- 200.0;  // Look for buildings within 200m
}

species resident parent: inhabitant_base skills: [moving] {
	
	// ==================== PERSONAL ATTRIBUTES ====================
	bool is_male <- flip(0.6);
	bool is_smoke <- flip(0.3);
	bool is_obese <- flip(0.3);
	bool is_family_history <- flip(0.125);
	bool is_wearmask <- flip(0.85);
	
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
	float base_emission_rate <- 2.0 + rnd(3.0);
	
	// ==================== SCHEDULE ====================
	int work_start_hour <- 6 + rnd(3);
	int work_end_hour;
	int work_duration <- 8;
	
	// ==================== INITIALIZATION ====================
	init {
		do initialize_home();
		do initialize_work();
		do initialize_schedule();
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
	
	action initialize_schedule {
		work_end_hour <- work_start_hour + work_duration;
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
	
	// ==================== MOVEMENT ====================
	
	reflex move when: target != nil and not is_inside_building {
		do calculate_emission();
		do move_towards_target();
		do emit_pollution();
		do check_if_stuck_and_reassign();  // NEW: Reassign if stuck
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
	
	// ==================== NEW: STUCK DETECTION WITH REASSIGNMENT ====================
	/**
	 * STRATEGY: If resident is stuck for too long, find a new reachable building
	 * 
	 * This helps when:
	 * - Road network has disconnected components
	 * - Target building is on an isolated island
	 * - Pathfinding algorithm can't find a route
	 */
//	action check_if_stuck_and_reassign {
//		float distance_moved <- location distance_to last_location;
//		
//		// Check if agent hasn't moved
//		if distance_moved < 0.1 {
//			stuck_counter <- stuck_counter + 1;
//			
//			// If stuck for max_stuck_steps, try reassignment
//			if stuck_counter >= max_stuck_steps {
//				write "Resident stuck for " + max_stuck_steps + " steps! Attempting reassignment...";
//				do reassign_to_nearest_reachable_building();
//			}
//		} else {
//			stuck_counter <- 0;  // Reset if moved
//		}
//		
//		last_location <- location;
//	}

	action check_if_stuck_and_reassign {
	    float distance_moved <- location distance_to last_location;
	    
	    // Kiểm tra nếu agent không di chuyển (hoặc di chuyển cực ít)
	    if distance_moved < 0.1 {
	        stuck_counter <- stuck_counter + 1;
	        
	        // Nếu bị tắc quá số bước quy định (max_stuck_steps)
	        if stuck_counter >= max_stuck_steps {
	            
	            // --- PHẦN GHI THÔNG TIN CHI TIẾT RA CONSOLE ---
	            string gender_str <- is_male ? "Nam" : "Nữ";
	            string status_str <- (is_smoke ? "Hút thuốc, " : "Không hút thuốc, ") + (is_obese ? "Béo phì" : "Cân đối");
	            
	            write "⚠️ CẢNH BÁO: Resident bị tắc đường!";
	            write "   - Tên định danh: " + name;
	            write "   - Đặc điểm: " + gender_str + " (" + status_str + ")";
	            write "   - Tọa độ hiện tại: " + location;
	            write "   - Đang cố gắng đến: " + (target_building = work_building ? "Cơ quan" : "Nhà");
	            write "   - Số lần đã đổi đích đến trước đó: " + reassignment_count;
	            write "👉 Hệ thống đang tìm tòa nhà thay đổi gần nhất...";
	            // ----------------------------------------------
	            
	            do reassign_to_nearest_reachable_building();
	        }
	    } else {
	        stuck_counter <- 0;  // Reset bộ đếm nếu agent có di chuyển
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
		
		// Remove current building and home building from candidates
		nearby_buildings <- nearby_buildings - home_building;
		
		if going_to_work {
			nearby_buildings <- nearby_buildings - work_building;
		}
		
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
			
			// Update target
			target <- any_location_in(nearest);
			target_building <- nearest;
			
			// Move to building and enter
			location <- target;
			do enter_building(target_building);
			
			target <- nil;
			target_building <- nil;
			stuck_counter <- 0;
		}
	}
	
	// ==================== ARRIVAL CHECK ====================
	action check_arrival {
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
		} else {
			theta <- theta_outdoor;
		}
		
		if is_wearmask {
			protect <- 1.0 - mask_effectiveness;
		} else {
			protect <- 1.0;
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
		float k <- 1.0;
		float b <- -5.0;
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
		rgb display_color <- get_display_color();
		
		draw pyramid(4) color: display_color;
		
		if is_male {
			draw sphere(2) at: location + {0, 0, 3} color: display_color;
		} else {
			draw cube(2.5) at: location + {0, 0, 3} color: display_color;
		}
	}
	
	aspect risk_view {
		rgb risk_color <- get_risk_color();
		
		draw pyramid(4) color: risk_color;
		
		if is_male {
			draw sphere(2) at: location + {0, 0, 3} color: risk_color;
		} else {
			draw cube(2.5) at: location + {0, 0, 3} color: risk_color;
		}
	}
}
