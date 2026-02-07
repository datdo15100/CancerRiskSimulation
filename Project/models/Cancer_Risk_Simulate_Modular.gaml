/**
* Name: Cancer Risk Simulation - Grid-Based PM2.5
* Author: TrungNguyen
* Description: Modular PM2.5 simulation with grid diffusion
*              - Clean, organized code structure
*              - Gender-based resident visualization (60% male, 40% female)
*              - 50x50 pollution grid with diffusion
*              - 10% hourly decay
*              - Real-time charts and statistics
*              - Cancer risk probability tracking
*/

model Cancer_Risk_Simulate

// ==================== IMPORTS ====================
import "Infrastructure.gaml"
import "Resident_WithRisk.gaml"
import "PollutionGrid.gaml"

// ==================== GLOBAL CONFIGURATION ====================
global {
	
	// ==================== SIMULATION PARAMETERS ====================
	float step <- 60 #sec;  // 1 minute - visible movement
	date starting_date <- date("2023-10-01 06:00:00");
	
	// ==================== SPATIAL DATA ====================
	file shapefile_buildings <- file("../includes/building_polygon.shp");
	file shapefile_roads <- file("../includes/highway_line.shp");
	geometry shape <- envelope(shapefile_roads);
	
	// ==================== NETWORK ====================
	graph road_network;
	map<road, float> road_weights;
	
	// ==================== POPULATION PARAMETERS ====================
	int initial_population <- 3000;

	// ==================== SCENARIO (for batch experiments) ====================
	// 0=Baseline, 1=Unhealthy Lifestyle, 2=Clean Air
	int scenario <- 0;

	// ==================== STATISTICS (AUTO-UPDATED) ====================
	
	// Resident statistics
	float total_traffic_pm_emission <- 0.0 update: calculate_total_emission();
	int residents_traveling <- 0 update: count_traveling_residents();
	int residents_at_home <- 0 update: count_residents_at_home();
	int residents_at_work <- 0 update: count_residents_at_work();
	
	// PM2.5 statistics
	float avg_pm25 <- 0.0 update: mean(pollution_grid collect each.pm25_level);
	float max_pm25 <- 0.0 update: max(pollution_grid collect each.pm25_level);
	float min_pm25 <- 0.0 update: min(pollution_grid collect each.pm25_level);
	
	// Gender statistics
	int male_count <- 0 update: length(resident where each.is_male);
	int female_count <- 0 update: length(resident where not(each.is_male));
	
	// ==================== RISK STATISTICS ====================
	float avg_risk_probability <- 0.0 update: mean(resident collect each.risk_probability);
	float max_risk_probability <- 0.0 update: max(resident collect each.risk_probability);
	float min_risk_probability <- 0.0 update: min(resident collect each.risk_probability);
	
	// Risk categories
	int low_risk_count <- 0 update: length(resident where (each.risk_probability < 0.2));
	int medium_risk_count <- 0 update: length(resident where (each.risk_probability >= 0.2 and each.risk_probability < 0.5));
	int high_risk_count <- 0 update: length(resident where (each.risk_probability >= 0.5 and each.risk_probability < 0.8));
	int very_high_risk_count <- 0 update: length(resident where (each.risk_probability >= 0.8));
	
	// ==================== INITIALIZATION ====================
	init {
		do apply_scenario();
		do create_infrastructure();
		do create_population();
		do initialize_network();
	}

	action apply_scenario {
		switch scenario {
			match 1 {
				// Unhealthy Lifestyle: high smoke, high obesity, low mask
				smoke_rate <- 0.8;
				obese_rate <- 0.6;
				mask_rate <- 0.1;
			}
			match 2 {
				// Clean Air: no PM2.5 emission
				emission_multiplier <- 0.0;
			}
		}
	}
	
	action create_infrastructure {
		create building from: shapefile_buildings with: [height::int(read("HEIGHT"))];
		create road from: shapefile_roads;
	}
	
	action create_population {
		create resident number: initial_population {
			location <- any_location_in(one_of(building));
		}
	}
	
	action initialize_network {
		road_network <- as_edge_graph(road);
	}
	
	// ==================== SIMULATION REFLEXES ====================

	reflex update_road_weights {
		road_weights <- road as_map(each::each.shape.perimeter / each.speed_rate);
	}

	// Track last diffusion hour to run diffusion only once per hour
	int last_diffusion_hour <- -1;

	reflex pm25_diffusion when: current_date.hour != last_diffusion_hour {
		diffuse var: pm25_level on: pollution_grid proportion: 0.6;
		last_diffusion_hour <- current_date.hour;
	}
	
	// ==================== STATISTICS CALCULATIONS ====================
	
	float calculate_total_emission {
		return sum(resident collect each.emission_pm);
	}
	
	int count_traveling_residents {
		return length(resident where not(each.is_inside_building));
	}
	
	int count_residents_at_home {
		return length(resident where (each.current_building = each.home_building));
	}
	
	int count_residents_at_work {
		return length(resident where (each.current_building = each.work_building));
	}
}

// ==================== EXPERIMENT ====================
experiment Cancer_Risk_Simulate type: gui {
	
	// ==================== EXPERIMENT PARAMETERS ====================

	// Simulation
	parameter "Initial Population" var: initial_population min: 100 max: 10000 category: "Simulation";
	parameter "Simulation Step (seconds)" var: step min: 60 max: 3600 category: "Simulation";
	parameter "Resident Speed (m/s)" var: resident_speed min: 0.1 max: 5.0 category: "Simulation";

	// Population Rates (applied at init only)
	parameter "Male Rate" var: male_rate min: 0.0 max: 1.0 category: "Population";
	parameter "Smoke Rate" var: smoke_rate min: 0.0 max: 1.0 category: "Population";
	parameter "Obese Rate" var: obese_rate min: 0.0 max: 1.0 category: "Population";
	parameter "Family History Rate" var: family_history_rate min: 0.0 max: 1.0 category: "Population";
	parameter "Mask Wearing Rate" var: mask_rate min: 0.0 max: 1.0 category: "Population";

	// Risk Weights
	parameter "Baseline Male Risk" var: baseline_male_risk min: 0.0 max: 2.0 category: "Risk";
	parameter "Baseline Smoke Risk" var: baseline_smoke_risk min: 0.0 max: 2.0 category: "Risk";
	parameter "Baseline Obese Risk" var: baseline_obese_risk min: 0.0 max: 2.0 category: "Risk";
	parameter "Baseline Family Risk" var: baseline_family_risk min: 0.0 max: 2.0 category: "Risk";
	parameter "PM Weight (W_pm)" var: omega_pm min: 0.001 max: 0.1 category: "Risk";
	parameter "PM Reference" var: PM_ref min: 50.0 max: 500.0 category: "Risk";

	// Environment
	parameter "Emission Multiplier" var: emission_multiplier min: 0.0 max: 5.0 category: "Environment";
	parameter "Mask Effectiveness" var: mask_effectiveness min: 0.0 max: 1.0 category: "Environment";
	
	// ==================== OUTPUT DISPLAYS ====================
	output {
		
		// ==================== 3D VIEW WITH PM2.5 MESH ====================
		// Uncomment to enable 3D view
//		display "3D View" type: 3d axes: false background: #white {
//			grid pollution_grid elevation: grid_value * 0.5 triangulation: true transparency: 0.3;
//			species building aspect: asp_building;
//			species road aspect: asp_road;
//			species resident aspect: default;
//		}
		
		// ==================== 2D POLLUTION MAP ====================
		display "Pollution Map" type: 2d {
			grid pollution_grid;
			species building aspect: asp_building transparency: 0.5;
			species road aspect: asp_road transparency: 0.5;
			species resident aspect: default;
		}
		
		// ==================== PM2.5 & RISK ANALYSIS (UPDATED!) ====================
		display "PM2.5 Analysis" type: 2d {
			// PM2.5 Levels Chart
			chart "PM2.5 Levels (μg/m³)" type: series size: {1.0, 0.33} position: {0, 0} {
				data "Average PM2.5" value: avg_pm25 color: #blue marker: false thickness: 2;
				data "Max PM2.5" value: max_pm25 color: #red marker: false thickness: 2;
				data "Min PM2.5" value: min_pm25 color: #green marker: false thickness: 1;
			}
			
			// Traffic Activity Chart
			chart "Traffic Activity" type: series size: {1.0, 0.33} position: {0, 0.33} {
				data "Residents Traveling" value: residents_traveling color: #orange marker: false thickness: 2;
				data "Total PM Emission" value: total_traffic_pm_emission color: #purple marker: false thickness: 2;
			}
			
			// Risk Probability Chart
			chart "Cancer Risk Probability" type: series size: {1.0, 0.34} position: {0, 0.66} {
				data "Average Risk" value: avg_risk_probability color: #blue marker: false thickness: 2;
				data "Max Risk" value: max_risk_probability color: #red marker: false thickness: 2;
				data "Min Risk" value: min_risk_probability color: #green marker: false thickness: 1;
			}
		}
		
		// ==================== RISK DISTRIBUTION DISPLAY ====================
		display "Risk Distribution" type: 2d {
			// Risk Categories Bar Chart
			chart "Risk Categories" type: histogram size: {1.0, 0.5} position: {0, 0} {
				data "Low Risk (<20%)" value: low_risk_count color: #green;
				data "Medium Risk (20-50%)" value: medium_risk_count color: #yellow;
				data "High Risk (50-80%)" value: high_risk_count color: #orange;
				data "Very High Risk (>80%)" value: very_high_risk_count color: #red;
			}
			
			// Risk Probability Distribution
			chart "Risk Probability Distribution" type: series size: {1.0, 0.5} position: {0, 0.5} {
				data "Low Risk Count" value: low_risk_count color: #green marker: false thickness: 2;
				data "Medium Risk Count" value: medium_risk_count color: #yellow marker: false thickness: 2;
				data "High Risk Count" value: high_risk_count color: #orange marker: false thickness: 2;
				data "Very High Risk Count" value: very_high_risk_count color: #red marker: false thickness: 2;
			}
		}
		
		// ==================== STATISTICS DASHBOARD ====================
		display "Dashboard" type: 2d {
			graphics "Statistics" {
				// Time panel
				draw rectangle(250, 80) at: {130, 50} color: rgb(40, 40, 40, 200) border: #white;
				draw string(string(current_date.hour) + ":" + string(current_date.minute) + ":" + string(current_date.second))
					at: {20, 70} color: #yellow font: font("Arial", 18, #bold);
				
				// Population panel
				draw rectangle(450, 380) at: {230, 300} color: rgb(40, 40, 40, 200) border: #white;
				
				draw string("POPULATION DISTRIBUTION") at: {20, 140} color: #white font: font("Arial", 12, #bold);
				draw string("At Home: " + residents_at_home) at: {20, 165} color: #orange font: font("Arial", 14);
				draw string("At Work: " + residents_at_work) at: {20, 190} color: #blue font: font("Arial", 14);
				draw string("Traveling: " + residents_traveling) at: {20, 215} color: #yellow font: font("Arial", 14);
				
				draw string("GENDER DISTRIBUTION") at: {20, 245} color: #white font: font("Arial", 12, #bold);
				draw string("Male (60%): " + male_count) at: {20, 270} color: #lightblue font: font("Arial", 14);
				draw string("Female (40%): " + female_count) at: {20, 295} color: #pink font: font("Arial", 14);
				
				draw string("PM2.5 STATISTICS") at: {20, 325} color: #white font: font("Arial", 12, #bold);
				draw string("Avg: " + (int(avg_pm25)) + " μg/m³") at: {20, 350} color: #lightblue font: font("Arial", 14);
				draw string("Max: " + (int(max_pm25)) + " μg/m³") at: {20, 375} color: #red font: font("Arial", 14);
				draw string("Total Emission: " + (int(total_traffic_pm_emission)) + " μg/m³")
					at: {20, 400} color: #purple font: font("Arial", 14);
				
				// Risk Statistics Panel
				draw string("CANCER RISK STATISTICS") at: {20, 430} color: #white font: font("Arial", 12, #bold);
				draw string("Avg Risk: " + (with_precision(avg_risk_probability * 100, 2)) + "%") 
					at: {20, 455} color: #lightblue font: font("Arial", 14);
				draw string("Max Risk: " + (with_precision(max_risk_probability * 100, 2)) + "%") 
					at: {20, 480} color: #red font: font("Arial", 14);
			}
		}
		
		// ==================== MONITORS ====================
		monitor "Current Date" value: current_date color: #white;
		monitor "Current Hour" value: current_date.hour color: #yellow;
		
		monitor "Residents at Home" value: residents_at_home color: #orange;
		monitor "Residents at Work" value: residents_at_work color: #blue;
		monitor "Residents Traveling" value: residents_traveling color: #yellow;
		
		monitor "Male Residents" value: male_count color: #lightblue;
		monitor "Female Residents" value: female_count color: #pink;
		
		monitor "Average PM2.5" value: avg_pm25 color: #blue;
		monitor "Max PM2.5" value: max_pm25 color: #red;
		monitor "Min PM2.5" value: min_pm25 color: #green;
		monitor "Total PM Emission" value: total_traffic_pm_emission color: #purple;
		
		// Risk Monitors
		monitor "Average Risk Probability" value: avg_risk_probability color: #blue;
		monitor "Max Risk Probability" value: max_risk_probability color: #red;
		monitor "Low Risk Residents" value: low_risk_count color: #green;
		monitor "Medium Risk Residents" value: medium_risk_count color: #yellow;
		monitor "High Risk Residents" value: high_risk_count color: #orange;
		monitor "Very High Risk Residents" value: very_high_risk_count color: #red;
	}
}

// ==================== BATCH EXPERIMENTS ====================
// Scenario 0 (Baseline): Default population, normal emission
// Scenario 1 (Unhealthy Lifestyle): 80% smoke, 60% obese, 10% mask, normal emission
// Scenario 2 (Clean Air): Default population, emission = 0
experiment Batch_Scenarios type: batch repeat: 1 until: (cycle >= 2000) {
	parameter "Scenario" var: scenario among: [0, 1, 2];
}
