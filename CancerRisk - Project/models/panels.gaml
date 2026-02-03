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
	list<string> actions <- ["build","delete","modify","clear"];
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
		if (action_type = 0){
			ask world {
				create building{
					location <- #user_location;
				}
			}
		}
	}
}
/* 
grid cell width: 10 height: 10 {
	rgb color <- #black ;
	int building <- -1;
	aspect default {
		if (building >= 0) {
			draw image_file(images[building]) size:{shape.width * 0.5,shape.height * 0.5} ;
		}
		 
	}
}
*/
grid button width:2 height:2 
{
	int id <- int(self);
	rgb bord_col<-#black;
	aspect normal {
		draw rectangle(shape.width * 0.8,shape.height * 0.8).contour + (shape.height * 0.01) color: bord_col border:#white;
		//draw image_file(images[id]) size:{shape.width * 0.5,shape.height * 0.5} ;
		draw string(actions[id]) color: #black;
	}
}

experiment panels type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display view type: opengl antialias: true{
			species building aspect: buil;
			event #mouse_down {ask simulation {do point_management;}}
		}
		display control_panel type: 2d{
			species button aspect: normal;
			event #mouse_down {ask simulation {do activate_act;}}  
		}
	}
}
