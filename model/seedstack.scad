$fn=100;

// All units in mm

pt=0.35;
thickness=2.45;

box_width=120;
box_height=55;

drain_outer_d=7;
drain_inner_d=4;
drain_h=9;
drain_p=13.5;

syphon_tip_outer_d=12;
syphon_tip_height=6;
syphon_skirt_outer_d=22;
syphon_skirt_height=10;

syphon_slot_width=1;
syphon_thickness=1;
syphon_tube_outer_d=12;
syphon_tube_inner_d=9.5;
// stg_d=2.3; // This will be friction tight to the point where removal becomes impossile
stg_d=2.1;

lid_hole_d=34;

module rounded_square(dim, corners=[10,10,10,10], center=false)
{
	w=dim[0];
	h=dim[1];

	if (center)
	{
		translate([-w/2, -h/2])
		rounded_square_(dim, corners=corners);
	}
	else
	{
		rounded_square_(dim, corners=corners);
	}
}

module rounded_square_(dim, corners, center=false)
{
	w=dim[0];
	h=dim[1];
	render()
	{
		difference()
		{
			square([w,h]);

			if (corners[0])
			square([corners[0], corners[0]]);

			if (corners[1])
			translate([w-corners[1],0])
			square([corners[1], corners[1]]);

			if (corners[2])
			translate([0,h-corners[2]])
			square([corners[2], corners[2]]);

			if (corners[3])
			translate([w-corners[3], h-corners[3]])
			square([corners[3], corners[3]]);
		}

		if (corners[0])
		translate([corners[0], corners[0]])
		intersection()
		{
			circle(r=corners[0]);
			translate([-corners[0], -corners[0]])
			square([corners[0], corners[0]]);
		}

		if (corners[1])
		translate([w-corners[1], corners[1]])
		intersection()
		{
			circle(r=corners[1]);
			translate([0, -corners[1]])
			square([corners[1], corners[1]]);
		}

		if (corners[2])
		translate([corners[2], h-corners[2]])
		intersection()
		{
			circle(r=corners[2]);
			translate([-corners[2], 0])
			square([corners[2], corners[2]]);
		}

		if (corners[3])
		translate([w-corners[3], h-corners[3]])
		intersection()
		{
			circle(r=corners[3]);
			square([corners[3], corners[3]]);
		}
	}
}

module rounded_square_adapter(steps, thickness, height,
	   s_dim, s_oRadius, s_iRadius,
	   e_dim, e_oRadius, e_iRadius)
{
	// Calculate interpolation steps.
	extrude_length = height / steps;
	w_s = (e_dim[0] - s_dim[0]) / steps;
	l_s = (e_dim[1] - s_dim[1]) / steps;
	ir_s = (e_iRadius - s_iRadius) / steps;
	or_s = (e_oRadius - s_oRadius) / steps;

	// Starting stuff
	w = s_dim[0];
	l = s_dim[1];
	ir = s_iRadius;
	or = s_oRadius;

	// Join together a whole bunch of extrusions
	union()
	{
		for (i=[0:steps])
		{
			// Move up to the next step
			translate([0,0,i*extrude_length])

			// Extrude one section
			linear_extrude(
				height = extrude_length,
				center = true)

			// Create a hollow rounded rect
			// Add the interpolation to each variable
			difference()
			{
				rounded_square(
					[w + (w_s*i), l + (l_s*i)],
					[or + (or_s*i),or + (or_s*i),or + (or_s*i),or + (or_s*i)],
					true);
				rounded_square(
					[w + (w_s*i) - (thickness*2), l + (l_s*i) - (thickness*2)],
					[ir + (ir_s*i),ir + (ir_s*i),ir + (ir_s*i),ir + (ir_s*i)],
					true);
			}
		}
	}
}


module shape(cut=0)
{
	module sidelobes()
	{
		translate([0,0,45])rotate([90,0,0])linear_extrude(height=box_width/2-thickness+0.9)rounded_square(
			[32,60],
			[5,5,5,5], true);
		translate([34.5,0,45])rotate([90,0,0])linear_extrude(height=box_width/2-thickness+0.9)rounded_square(
			[15,60],
			[5,5,5,5], true);
		translate([-34.5,0,45])rotate([90,0,0])linear_extrude(height=box_width/2-thickness+0.9)rounded_square(
			[15,60],
			[5,5,5,5], true);
	}

	difference()
	{
		linear_extrude(height=box_height)rounded_square(
			[box_width,box_width],
			[15,15,15,15], true);

		union()
		{
			// Upper Box Cut
			union()
			{
				grid(ah=2,pt=0.2);

				sidelobes();
				mirror([0,1,0])sidelobes();
				rotate([0,0,90])
				{
					sidelobes();
					mirror([0,1,0])sidelobes();
				}

				translate([0,0,thickness+2])linear_extrude(height=box_height+2)rounded_square(
				[box_width-thickness*2,box_width-thickness*2],
				[13,13,13,13], true);
			}

			// Lower Box Cut
			if (cut==0)
			{
			translate([0,0,thickness-0.05])linear_extrude(height=11)rounded_square(
				[box_width-thickness*2,box_width-thickness*2],
				[13,13,13,13], true);
			}
			// Bottom Reinforcement
			translate([0,0,-4.5])difference()
			{
				linear_extrude(height=10)rounded_square(
					[box_width+0.1,box_width+0.1],
					[13,13,13,13], true);
				translate([0,0,thickness])linear_extrude(height=box_height+2)rounded_square(
					[box_width-thickness,box_width-thickness],
					[14,14,14,14], true);
			}
		}
	}

	// Adapter
	translate([0,0,1.5])rounded_square_adapter(30, thickness/2+0.15, 4,
		[box_width-thickness*2+0.4,box_width-thickness*2+0.4], 13, 13,
		[box_width,box_width], 15, 13);
}


module structures()
{
	difference()
	{
		// Bottom Spacer Grid
		rotate([0,0,45])union()for(x=[-sqrt(pow(box_width,2)*2)/2+thickness*4:3.2:sqrt(pow(box_width,2)*2)/2-thickness*4+2])
		{
			translate([x,0,thickness+1])
			cube(size=[thickness/2,sqrt(pow(box_width,2)*2)-thickness*5,thickness],center=true);
		}

		union()
		{
			// Syphon Footer Cut
			union()translate([-box_width/2+thickness+drain_p,box_width/2-thickness-drain_p+0.1,-1])rotate([0,0,-4])cylinder(h=drain_h+5,d=syphon_skirt_outer_d+3.65,$fn=10,center=true);

			// Bottom Spacer Grid outside Cut
			difference()
			{
				cube(size=[250,250,100],center=true);
				translate([0,0,thickness])linear_extrude(height=box_height+2)rounded_square(
					[box_width-thickness,box_width-thickness],
					[14,14,14,14], true);
			}

			// Rounded Square Waterflow Cut
			difference()
			{
				linear_extrude(height=box_height)rounded_square(
					[box_width-thickness,box_width-thickness],
					[13,13,13,13], true);
				translate([0,0,-1])linear_extrude(height=box_height+2)rounded_square(
					[box_width-thickness-7,box_width-thickness-7],
					[11,11,11,11], true);
			}
		}
	}

	// Draintube
	translate([-box_width/2+thickness+drain_p,box_width/2-thickness-drain_p,(drain_h/2)+thickness])difference()
	{
		cylinder(h=drain_h,d=drain_outer_d,center=true);
		union()
		{
			translate([0,0,-1])cylinder(h=drain_h+5,d=drain_inner_d,center=true);
			translate([0,0,drain_h-5.5])cylinder(h=4,d1=drain_inner_d,d2=drain_outer_d-1,center=true);
		}
	}
}

module grid(ah=0,pt=0)
{
	// Upper
	translate([0,box_width/2-box_width/3.33-thickness,box_height/2+ah])cube(size=[box_width-thickness+pt,1.5+pt,box_height-10],center=true);
	translate([0,-box_width/2+box_width/3.33+thickness,box_height/2+ah])cube(size=[box_width-thickness+pt,1.5+pt,box_height-10],center=true);
	// Lower (with Handle)
	translate([box_width/2-box_width/3.33-thickness,0,box_height/2+ah])cube(size=[1.5+pt,box_width-thickness+pt,box_height-10],center=true);
	translate([-box_width/2+box_width/3.33+thickness,0,box_height/2+ah])cube(size=[1.5+pt,box_width-thickness+pt,box_height-10],center=true);
}

module syphon()
{
	difference()
	{
		union()
		{
			// Outer Skirt
			difference()
			{
				translate([0,0,syphon_skirt_height/2])cylinder(h=syphon_skirt_height, d1=syphon_skirt_outer_d, d2=syphon_tip_outer_d, center=true);
				union()
				{
					translate([0,0,syphon_skirt_height/2-0.1])cylinder(h=syphon_skirt_height+0.1, d1=syphon_skirt_outer_d-2, d2=syphon_tip_outer_d-1, center=true);
					for(x=[0:45:360])
					{
						rotate([0,0,x])translate([9,0,0])cube(size=[5,1,15],center=true);
					}
					translate([0,0,syphon_skirt_height/2+syphon_tip_height/2])cylinder(h=drain_h,d=syphon_tube_inner_d, center=true);
				}
			}

			// Inner Tube
			difference()
			{
				translate([0,0,syphon_skirt_height/2+syphon_tip_height/2])cylinder(h=syphon_skirt_height+syphon_tip_height,d=syphon_tube_outer_d, center=true);
				translate([0,0,syphon_skirt_height/2+syphon_tip_height/2-1])cylinder(h=drain_h+7,d=syphon_tube_inner_d, center=true);
			}

			// Tube Guides
			for(x=[0:120:360])
			{
				rotate([0,0,x])translate([4.5,0,drain_h])cylinder(h=drain_h+3,d=stg_d,center=true);
			}
		}

		// Bottom Cuts
		translate([0,0,-syphon_skirt_height/2+1.1])rotate([90,0,0])cylinder(h=syphon_skirt_height+syphon_tip_height,d=syphon_tube_inner_d, center=true);
		translate([0,0,-syphon_skirt_height/2+1.1])rotate([90,0,90])cylinder(h=syphon_skirt_height+syphon_tip_height,d=syphon_tube_inner_d, center=true);
	}

}

module container()
{
	difference()
	{
		shape();
		union()
		{
			translate([0,0,51])scale([1.0015,1.0015,1])shape(cut=1);
		// Draintube Hole
		translate([-box_width/2+thickness+drain_p,box_width/2-thickness-drain_p,drain_h/2])cylinder(h=drain_h+thickness+10,d=drain_inner_d,center=true);
	}
	}
	structures();
}

module lid()
{
	knob_h=9;
	difference()
	{
		translate([0,0,51])scale([1.0015,1.0015,1])shape();
		translate([0,0,box_height+51/2+5])cube(size=[box_width+5,box_width+5,box_height],center=true);
		translate([0,0,box_height/2])cylinder(d=lid_hole_d,h=box_height);
	}

	$difference()
	{
		translate([0,0,box_height-thickness])linear_extrude(height=knob_h)rounded_square(
		[box_width/2,box_width/2],
		[10,10,10,10], true);
		translate([0,0,box_height+knob_h-thickness*2])linear_extrude(height=knob_h)rounded_square(
			[box_width/2-thickness*2,box_width/2-thickness*2],
			[8,8,8,8], true);
	}


	//translate([-30,-30,box_height+knob_h/2-2])linear_extrude(height=knob_h,center=true)import("seedstack-lid-handle.dxf");
	translate([-42,-53,box_height])linear_extrude(height=thickness,center=true)import("seedstack-lid-text.dxf");

}

module bottom()
{
	difference()
	{
		linear_extrude(height=15)rounded_square(
			[box_width,box_width],
			[15,15,15,15], true);
		translate([0,0,11])scale([1.0015,1.0015,1])shape(cut=1);
	}
}

module brim(small=0)
{
	tr=box_width/2-10;
	color("red")
	{
	if(small==0)
	{
	translate([tr,tr,0])cylinder(r=30,h=0.2,center=true);
	translate([tr,-tr,0])cylinder(r=30,h=0.2,center=true);
	translate([-tr,tr,0])cylinder(r=30,h=0.2,center=true);
	translate([-tr,-tr,0])cylinder(r=30,h=0.2,center=true);
	}
	//cube(size=[box_width+10,box_width+10,0.2],center=true);
	linear_extrude(height=0.35)rounded_square(
		[box_width+10,box_width+10],
		[15,15,15,15], true);
	difference()
	{
		linear_extrude(height=10)rounded_square(
			[box_width+5,box_width+5],
			[15,15,15,15], true);
		translate([0,0,-1])linear_extrude(height=12)rounded_square(
			[box_width+4.65,box_width+4.65],
			[15,15,15,15], true);
	}
	}
}

module camlid()
{
	lid();

	difference()
	{
		difference()
		{
			translate([0,0,box_height-4])brim(small=1);
			translate([0,0,box_height+7.5])cube(size=[150,150,10],center=true);
		}
		translate([0,0,box_height-4])linear_extrude(height=5)rounded_square(
			[box_width-thickness+pt+0.05,box_width-thickness+pt+0.05],
			[14.1,14.1,14.1,14.1], true);


	}
}

// Select a module to render

//lid();
camlid();
//container();
//bottom();
//grid();
//translate([-box_width/2+thickness+drain_p,box_width/2-thickness-drain_p,0])syphon();
//brim();
