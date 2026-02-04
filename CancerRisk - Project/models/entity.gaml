/**
* Name: species
* Based on the internal empty template. 
* Author: thanhbinh
* Tags: 
*/

// Create entities
model entity
import "scheduling.gaml"

/* Insert your model definition here */
species zone{
	string zone_type;
}

species people {
	// People's skin colors :))
	rgb color <- rnd_color(255);
	// Baseline factors:
	int age <- rnd(90);
	string sex <- (flip(0.5) ? "male" : "female"); 
	float BMI <- rnd(100, 300) / 10;
	bool smoking <- false;
	bool has_cancer_b4 <- false;
	float risk_family <- 0.0;
	float risk_sex <- 0.0;
	float risk_age <- 0.0;
	float risk_chance_baselines <- risk_family * risk_sex * risk_age;
	// Behavioral factors:
	float outdoor_rate <- rnd(100)/100;
	float mask_usage <- rnd(100)/100;
	
	// Overall risk chance:
	float risk_chance_total <- 0.0;
	point target;

	int start_work <- rnd(min_work_start, max_work_start) ;
    int end_work <- rnd(min_work_end, max_work_end) ;
    float speed <- rnd(min_speed, max_speed);
    string objective <- "resting"; 

	building house;
	building working_place;
	bool at_home <- true;
	init {
		if (age > 18){
			bool smoking <- (flip(0.5) ? true : false);	
		} 
	}
	reflex go_to_work{
		
	}
	reflex return_home{
		
	}
	reflex becoming_cancer{
		
	}
	aspect ppl{
		draw circle(5#m) color: color border: #black;
	}
}

species road{
	aspect r0ad{
	draw shape color: #blue;
	}
}

species building{
	int height;
	bool is_working_place;
	list<people> my_inhabitants;
	
	aspect buil {
		draw shape color: is_working_place ? #darkblue : #gray;
	}
	
}
