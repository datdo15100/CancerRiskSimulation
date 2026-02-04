/**
* Name: species
* Based on the internal empty template. 
* Author: thanhbinh
* Tags: 
*/


model entity

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
		draw circle(20#m) color: color border: #black;
	}
}

species road{
	aspect r0ad{
	draw shape color: #blue;
	}
}

species building{
	aspect buil{
		draw square(20#m) color: #pink;
	}
}
