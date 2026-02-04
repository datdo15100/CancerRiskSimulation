/**
* Name: scheduling
* Based on the internal skeleton template. 
* Author: thanhbinh
* Tags: 
*/

// Scheduling for work - rest cycle

model scheduling

global {
	/** Insert the global definitions, variables and actions here */
	date starting_date <- date("2026-01-29-00-00-00");
    int min_work_start <- 6;
    int max_work_start <- 8;
    int min_work_end <- 16; 
    int max_work_end <- 20; 
    float min_speed <- 1.0 #km / #h;
    float max_speed <- 5.0 #km / #h; 
}

experiment scheduling type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
	}
}
