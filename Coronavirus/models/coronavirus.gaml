/***
* Name: coronavirus
* Author: Gamaliel Palomo
* Description: Modelo que permite conocer el impacto de la cultura, educación, forma de vida de la población en méxico en el patrón de dispersión del vírus.
* El modelo considera agentes que son personas, estas personas tienen comportamientos que se rigen dependiendo de ciertas variables como el nivel socio-economico. 
* Las personas con una alta necesidad de realizar actividades económicas se verán más motivadas a salir de casa en el caso de una emergencia epidemiológica.
* Las personas tienen diversos estados relacionados con el vírus: Suceptible, Infectado y Recuperado, basado en el bien conocido modelo SIR.
* El modelo calcula las probabilidades de transición de estado de los agentes de manera individual y general, teniendo la ventaja de ser valores dinámicos con lo que 
* pueden hacerse estimaciones más cercanas a la realidad.
* La base de la transmisión del virus es el contacto, contacto directo entre una persona infectada y una susceptible.
* El modelo puede simular tres escenarios de tiempo: corto, mediano y largo plazo donde se expone el comprotamiento de la enfermedad en la rutina de las 
* personas diariamente. Mediano plazo considera una semana con una escala de espacio mayor. Largo plazo simula el comportamiento de la
* ciudad y de sus servicios y actividad económica en un lapso de un mes.
* Tags: Tag1, Tag2, TagN
***/

model coronavirus

/* Insert your model definition here */

global{
	//scenario
	string scenario; //short, mid and long term
	file roads_shp <- file("../includes/gis/roads.shp");
	
	//virus behavior related variables
	int susceptible <- 0 update: length(people where(each.status=0));
	int infected <- 0 update: length(people where(each.status=1));
	int recovered <- 0 update: length(people where(each.status=2));
	list<rgb> status_color <- [#green,#red,#blue];
	float beta parameter: "beta" category:"SIR parameters"<- 0.5 min:0.0 max:1.0;
	float kappa parameter: "kappa" category:"SIR parameters"<- 0.5 min:0.0 max:1.0;
	float mu parameter: "mu" category:"SIR parameters"<- 0.1 min:0.0 max:1.0;
	
	//general variables
	geometry shape <- envelope(roads_shp);
	graph road_network;
	map<road, float> weight_map;
	init{
		step <- 60.0; 
		create road from:roads_shp;
		weight_map <- road as_map(each::each.shape.perimeter);
		road_network <- as_edge_graph(road) with_weights weight_map;
		create people number:1000;
		ask one_of(people){status<-1;}
	}
}
species people skills:[moving] parallel:100{
	//Mobility
	point target;
	float speed <- 1.4;
	//Virus
	int status; //0:susceptible; 1:Infected; 2:Recovered
	
	init{
		location <- any_location_in(one_of(road));
		target <- any_location_in(one_of(road));
		status <- 0; 
	}
	
	reflex mobility{
		if target = location{
			target<-any_location_in(one_of(road));
		}
		do goto target:target on:road_network;
	}
	reflex virus{
		if status = 1{
			list<people> near_people <- people at_distance(2);
			if near_people != nil{
				loop contact over:near_people{
					ask contact{
						if rnd(100)/100 < beta{status <- 1;}
					}
				}
			}			
		}
	}
	user_command "infect"{
		status <- 1;
	}
	aspect default{
		draw circle(15) color:status_color[status];
	}
}
species road{
	aspect default{
		draw shape color:#gray;
	}
}
experiment short_term{
	init{
		scenario <- "short";	
	}
	output{
		layout #split;
		display main background:#black type:opengl{
			species road aspect:default;
			species people aspect:default;
			overlay position: { 10, 10 } size: { 0.1,0.1 } background: # black border: #black rounded: true{
                float y <- 30#px;
               	draw ".:-0123456789" at: {0#px,0#px} color:#black font: font("SansSerif", 20, #plain);
                draw "Infected: " +  length(people where (each.status=1)) at: { 40#px, y + 10#px } color: #white font: font("SansSerif", 15, #plain);
               // draw "Men: " +  length(men) at: { 40#px, y + 30#px } color: #white font: font("SansSerif", 20, #plain);
               //draw "Time: "+  current_date at:{ 40#px, y + 50#px} color:#white font:font("SansSerif",20, #plain);
               // draw "Sunlight: "+ sunlight at:{ 40#px, y + 70#px} color:#white font:font("SansSerif",20, #plain);
            }
		}
		display chart background:#black type:java2D{
			chart "Global status" type: series x_label: "time"{
				data "Susceptible" value: susceptible color: status_color[0] marker: false style: line;
				data "Infected" value: infected color: status_color[1] marker: false style: line;
				data "Recovered" value: recovered color: status_color[2] marker: false style: line;
			}
		}
	}
}