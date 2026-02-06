/**
* Name: Model1
* Based on the internal skeleton template. 
* Author: admin_ptaillandie
* Tags: 
*/

model Model1

global {
	file shapefile_buildings <- file("../includes/building_polygon.shp");
	file shapefile_roads <- file("../includes/highway_line.shp");
	geometry shape <- envelope(shapefile_roads);
	graph road_network;
	float step <- 10#s;
	map<road,float> new_weights;
	
	init {
		create building from: shapefile_buildings with:(height::int(read("HEIGHT")));
		
		create road from: shapefile_roads;
		
		create inhabitant number: 1000{
       		location <- any_location_in(one_of(building));
      	}
		road_network <- as_edge_graph(road);
	}
	
	reflex update_speed {
		new_weights <- road as_map (each::each.shape.perimeter / each.speed_rate);
	}
	
	
}



species building {
	int height;
	aspect default {
		draw shape color: #gray;
	}
	aspect threeD {
		draw shape color: #gray depth: height texture: ["../includes/roof.png","../includes/texture5.jpg"];
	}
}

species road {
	float capacity <- 1 + shape.perimeter/10;
	int nb_drivers <- 0 update: length(inhabitant at_distance 1);
	float speed_rate <- 1.0 update:  exp(-nb_drivers/capacity) min: 0.1;
	aspect default {
		draw (shape + 3 * speed_rate) color: #red;
	}
}


species inhabitant skills: [moving]{
	point target;
	rgb color <- rnd_color(255);
	float proba_leave <- 0.05; 
	float speed <- 5 #km/#h;


	aspect threeD{
		draw pyramid(4) color: color;
		draw sphere(1.0) at: location + {0,0,4} color: color;
	}

	aspect default {
		draw circle(5) color: color;
	}
	
	reflex leave when: (target = nil) and (flip(proba_leave)) {
		target <- any_location_in(one_of(building));
	}
	
	reflex move when: target != nil {
		do goto target: target on: road_network move_weights:new_weights ;
		if (location = target) {
			target <- nil;
		}	
	}
	
}

experiment traffic_3D type: gui {
	
	output {
		display map type: 3d axes: false background: #black{
			image "../includes/satelitte.png" refresh: false transparency: 0.2;
			species building aspect: threeD refresh: false;
			species inhabitant aspect: threeD;
		
		}
	}
}


experiment traffic type: gui {
	float minimum_cycle_duration <- 0.05;
	output {
		display map {
			species building ;
			species road ;
			species inhabitant ;
		}
	}
}
