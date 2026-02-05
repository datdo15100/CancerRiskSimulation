/**
* Name: CancerRiskBaseline
* Based on the internal skeleton template. 
* Author: Do Thanh Dat, Nguyen Dang Trung and Nguyen Thanh Binh
* Tags: 
*/


model CancerRiskBaseline

import "entity.gaml"
import "scheduling.gaml"
global {
	
	/** Insert the global definitions, variables and actions here */
	// Will be used as a parameter
	// int action_type <- -1;	
	file shapefile_buildings <- file("../includes/building_polygon.shp");
	file shapefile_roads <- file("../includes/highway_line.shp");
	geometry shape <- envelope(shapefile_roads);
	init {
		create road from: shapefile_roads;
		create building from: shapefile_buildings{
			is_working_place <- (flip(0.5) ? true:false);
		}
		create people number: 1000{
			location <- any_location_in(one_of(building where(!each.is_working_place)));
			working_place <- one_of(building where(each.is_working_place));
			target <- any_location_in(one_of(building where(!each.is_working_place)));
		}
		road_network <- as_edge_graph(road);
		
	}
	
	reflex update_speed{
		road_weights <- road as_map(each::each.shape.perimeter/each.speed_rate);
	}
	// Clock!
	reflex write_sim_info{
		write current_date;
		write "-------------------------";
	}
}




experiment CancerRiskBaseline type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		
		display cancer type: 3d {
			species road aspect: asp_road;
			species building aspect: buil;
			species people aspect: ppl;
		//	event #mouse_down {ask simulation {do point_management;}}
		}
		/* 
		display panels  type:2d {
			species button aspect:normal ;
			event #mouse_down {ask simulation {do activate_act;}}  
		}
		*/
	}
}
