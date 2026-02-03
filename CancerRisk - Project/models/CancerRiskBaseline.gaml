/**
* Name: CancerRiskBaseline
* Based on the internal skeleton template. 
* Author: thanhbinh
* Tags: 
*/

model CancerRiskBaseline
import "panels.gaml"
import "entity.gaml"
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
		create people number: 10{
			location <- any_location_in(one_of(building));
		}
	}
	action activate_act {
		button selected_but <- first(button overlapping (circle(1) at_location #user_location));
		if(selected_but != nil) {
			ask selected_but {
				ask button {bord_col<-#black;}
				if (action_type != id) {
					action_type<-id;
					bord_col<-#red;
				} else {
					action_type<- -1;
				}
				
			}
		}
	}
	/* 
	action cell_management {
		cell selected_cell <- first(cell overlapping (circle(1.0) at_location #user_location));
		if(selected_cell != nil) {
			ask selected_cell {
				building <- action_type;
				switch action_type {
					match 0 {color <- #red;}
					match 1 {color <- #white;}
					match 2 {color <- #yellow;}
					match 3 {color <- #black; building <- -1;}
				}
			}
		}
	}
	
	*/
	
}




experiment CancerRiskBaseline type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		
		display cancer type: 3d {
			species road aspect: r0ad;
			species building aspect: buil;
			species people aspect: ppl;
			//species home aspect:maison;
			//species workplace aspect: travaille;
		}
		display panels background:#black name:"Tools panel"  type:2d antialias:false{
			species button aspect:normal ;
			event #mouse_down {ask simulation {do activate_act;}}  
		}
	}
}
