/**
* Name: CancerRiskBaseline
* Based on the internal skeleton template. 
* Author: Do Thanh Dat, Nguyen Dang Trung and Nguyen Thanh Binh
* Tags: 
*/


model CancerRiskBaseline
import "panels.gaml"
import "entity.gaml"
import "scheduling.gaml"
global {
	
	/** Insert the global definitions, variables and actions here */
	// Will be used as a parameter
	int action_type <- -1;	
	int air_pollution_rate <- 67;
	int n0_homes <- 67;
	int n0_work <- 67;
	file shapefile_buildings <- file("../includes/building_polygon.shp");
	file shapefile_roads <- file("../includes/highway_line.shp");
	geometry shape <- envelope(shapefile_roads);
	init {
		create road from: shapefile_roads;
		
	}
	
	
}




experiment CancerRiskBaseline type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		
		display cancer type: 3d {
			species road aspect: r0ad;
			species building aspect: buil;
			species people aspect: ppl;
			event #mouse_down {ask simulation {do point_management;}}
		}
		display panels  type:2d {
			species button aspect:normal ;
			event #mouse_down {ask simulation {do activate_act;}}  
		}
	}
}
