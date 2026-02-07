/**
* Name: Infrastructure
* Author: TrungNguyen
* Description: Buildings and roads with resident tracking
*/

model infrastructure_model

import "Infras_base.gaml"
import "Cancer_Risk_Simulate_Modular.gaml"

// ==================== BUILDING SPECIES ====================
species building parent: building_base {
	
	// ==================== RESIDENT TRACKING ====================
	list<resident> residents_inside <- [];
	
	// ==================== ACTIONS ====================
	action add_resident(resident r) {
		if not(residents_inside contains r) {
			add r to: residents_inside;
		}
	}
	
	action remove_resident(resident r) {
		remove r from: residents_inside;
	}
	
	// ==================== QUERIES ====================
	int get_occupancy {
		return length(residents_inside);
	}
	
	bool is_empty {
		return empty(residents_inside);
	}
}

// ==================== ROAD SPECIES ====================
species road parent: road_base {
	
	// ==================== TRAFFIC ATTRIBUTES ====================
	float capacity <- 1 + shape.perimeter / 30;
	int nb_drivers <- 0 update: count_nearby_residents();
	float speed_rate <- 1.0 update: calculate_speed_rate() min: 0.1;
	
	// ==================== TRAFFIC CALCULATIONS ====================
	int count_nearby_residents {
		return length(resident at_distance 1);
	}
	
	float calculate_speed_rate {
		return exp(-nb_drivers / capacity);
	}
	
	// ==================== QUERIES ====================
	bool is_congested {
		return speed_rate < 0.3;
	}
	
	float get_congestion_level {
		return 1.0 - speed_rate;
	}
}
