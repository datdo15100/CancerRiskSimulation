/**
* Name: panels
* Based on the internal skeleton template. 
* Author: thanhbinh
* Tags: 
*/

model panels
import "entity.gaml"
global {
	string ACTION_BUILD <- "building";
	list<string> actions <- ["build a \n house","build a \n working place","delete","clear"];
	/** Insert the global definitions, variables and actions here */
	int action_type <- -1;
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
	action point_management{
		// Make a house with people in there
		if (action_type = 0){
			ask world {
				create building{
					location <- #user_location;
					shape <- square(50#m);
					is_working_place <- false;
					if not empty(road overlapping self) or not empty(building overlapping self) {
							write "ERROR: Building overlaps with road or other buildings. Creation canceled.";
							do die;
						} else {
							map input_values <- user_input_dialog([enter("Number of inhabitants", 1)]);
								int nb_people <- int(input_values["Number of inhabitants"]);
								create people number: nb_people {
									house <- myself;
									location <- any_location_in(house);
									working_place <- one_of(building where (each.is_working_place));
									target <- any_location_in(house);
								}
						}
				}
			}
		}
		// Make a working place 
		if (action_type = 1){
			create building{
				location <- #user_location;
				shape <- triangle(50#m);
				is_working_place <- true;
			}
		}
		// Delete building
		if (action_type = 2){
			
		}
		// Delete EVERYTHING!
		if (action_type = 3){
			
		}
	}
}

grid button width:2 height:2 
{
	int id <- int(self);
	rgb bord_col<-#black;
	aspect normal {
		draw rectangle(shape.width * 0.8,shape.height * 0.8).contour + (shape.height * 0.01) color: bord_col border:#white;
		draw string(actions[id]) color: #black;
	}
}

experiment panels type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display view type: opengl antialias: true{
			species building aspect: buil;
			species people aspect: ppl;
			event #mouse_down {ask simulation {do point_management;}}
		}
		display control_panel type: 2d{
			species button aspect: normal;
			event #mouse_down {ask simulation {do activate_act;}}  
		}
	}
}
