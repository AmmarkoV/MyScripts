// Dimensions
tolerance = 0.1;
camera_width = 71.8 + tolerance;
camera_height = 50.8 + tolerance;
camera_depth = 29 + tolerance;        // Body only
lens_depth = 4.6;
lens_diameter = 26;

// Rotated dimensions (vertical camera)
camera_rotated_width = camera_height;
camera_rotated_height = camera_width;

// Stereo config
lens_to_lens = 65;
lens_offset_in_camera = 18.8;  // Distance from left of camera to lens center
right_cam_x = lens_to_lens - lens_offset_in_camera;  // 59mm

// Generate the base by subtracting both rotated cameras
difference() 
{
    // Outer block: big enough to contain both cameras
    translate([-40, -5, -10])
        cube([right_cam_x + camera_rotated_width - 45, 15, camera_rotated_height + 60]);
 
    {
        /*
        translate([0, 5, 0])
        cube([20, 25, 50]);
        
        translate([0, 5, right_cam_x+15 ])
        cube([20, 25, 50]);*/
        
    // Left camera at origin
    rotate([0, 0, 90])
        camera();

    // Right camera at X = 59mm
    translate([0, 0, right_cam_x+15 ])
    rotate([0, 0, 90])
            camera();
    }
}

// Reusable camera module
module camera() 
{
    difference() 
    {
        roundedCube([camera_width, camera_depth, camera_height], 3);
    }
}

// Rounded cube utility
module roundedCube(size, radius) 
{
    hull() 
    {
        for (x = [0, size[0]])
            for (y = [0, size[1]])
                for (z = [0, size[2]])
                    translate([x, y, z])
                        sphere(r = radius);
    }
}
