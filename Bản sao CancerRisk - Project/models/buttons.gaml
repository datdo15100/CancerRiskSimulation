/**
* Name: buttons
* Based on the internal empty template. 
* Author: thanhbinh
* Tags: 
*/


model buttons
import "entity.gaml"
import "scheduling.gaml"

/* Insert your model definition here */

global {
	string ACTION_HOME <- "home";
	string ACTION_WORK <- "work";
	string ACTION_KILL_BUILDING <- "kill_1b";
	string ACTION_KILL_ALL_HOUSES <- "kill_h";
	string ACTION_KILL_ALL_WORKPLACES <- "kill_w";
	string ACTION_KILL_ALL_BUILDINGS <- "kill_b";
	string chosen_btn_action <- "";
	
		init {
		// create 2 buttons with 2 given locations
		// button[0]
		create button {
      		color <- #grey;
      		btn_action <- ACTION_HOME;
      		location <- {400,200};
      	}
      	create button {
      		color <- #darkblue;
      		btn_action <- ACTION_WORK;
      		location <- {400,600};      		
      	}     
      	create button {
      		color <- #maroon;
      		btn_action <- ACTION_KILL_BUILDING;
      		location <- {400, 1000};
      	}
      	create button {
      		color <- #black;
      		btn_action <- ACTION_KILL_ALL_HOUSES;
      		location <- {800, 200};
      	}
      	create button {
      		color <- #black;
      		btn_action <- ACTION_KILL_ALL_WORKPLACES;
      		location <- {800, 600};
      	}
      	create button {
      		color <- #black;
      		btn_action <- ACTION_KILL_ALL_BUILDINGS;
      		location <- {800, 1000};
      	}
		
	}
	
	action create_custom_building {
		ask world {
				create building {
					location <- #user_location;
					shape <- square(50 #m);
					if not empty(road overlapping self) or not empty(building overlapping self) {
						do die;
					}

					if (chosen_btn_action != "") {
						is_working_place <- (chosen_btn_action = ACTION_WORK);
					}

					if (!is_working_place) {
						map input_values <- user_input_dialog([enter("Number", 1)]);
						int nb_people <- input_values["Number"] as int;
						create people number: nb_people {
							house <- myself;
							location <- any_location_in(house);
							working_place <- one_of(building where (each.is_working_place));
							target <- any_location_in(house);
						}

					} else {
						ask people {
							working_place <- one_of(building where (each.is_working_place));
						}

					}

				}

			}

		}
		
	action kill_one_building {
		ask world {
			ask building overlapping #user_location {
				ask people inside self {
					do die;
				}
				do die;
			}
		}
	}
	
	action kill_all_houses {
		ask world {
			ask building where (!each.is_working_place) {
				ask my_inhabitants {
					do die;
				}
				do die;
			}	
		}
	}
	
	action kill_all_workplaces {
		ask world {
			ask building where (each.is_working_place) {
				do die;
			}	
		}
	}
	
	action kill_all_buildings {
		ask world {
			ask building {
				ask my_inhabitants {
					do die;
				}
				do die;
			}	
		}
	}
	
	action activate_buttons {
		
			button b <- first(button overlapping (circle(1) at_location #user_location));
			ask b{
				ask button{bord_col <- #black;}
				if (b != nil){
					if (b.btn_action = chosen_btn_action){
						chosen_btn_action <- "";
						bord_col <- #green;
					} else {
						chosen_btn_action <- b.btn_action;
					}
			}
		}
	}
	
}

// Create button specie
species button {
	rgb color;
	rgb bord_col <- #black;
	geometry shape <- square (200#m);
	string btn_action ;
	
	aspect default {
		draw shape color: color border: bord_col ;
		draw (shape + 10) - shape color:(chosen_btn_action = btn_action) ? #red : # black;
		draw string(btn_action) at: location anchor: #center color: #white;
	}
}

experiment control_panel type: gui{
	output {
		display map type: opengl antialias: true {
			event #mouse_down {
				if chosen_btn_action = ACTION_KILL_BUILDING {
					ask simulation{do kill_one_building;}
				} else if chosen_btn_action = ACTION_KILL_ALL_HOUSES {
					ask simulation{do kill_all_houses;}
				} else if chosen_btn_action = ACTION_KILL_ALL_WORKPLACES {
					ask simulation{do kill_all_workplaces;}
				} else if chosen_btn_action = ACTION_KILL_ALL_BUILDINGS {
					ask simulation{do kill_all_buildings;}
				}  else {
					ask simulation{do create_custom_building;}
				}
				
			}	
			
			species building aspect: buil;
			species people aspect: ppl ;
		}
		display btns type: opengl axes: false antialias: true {
			species button aspect: default;
			event #mouse_down {ask simulation{do activate_buttons;}}	
		}
		display my_charts type: 2d {
			chart "Road Traffic Analysis" type: series x_label: "Time" y_label: "Metrics" {
				data "Max Drivers (Busiest Road)" value: max_drivers color: #orange;
				data "Total Drivers" value: total_drivers  color: #blue;
			}
		}
		
	}
}