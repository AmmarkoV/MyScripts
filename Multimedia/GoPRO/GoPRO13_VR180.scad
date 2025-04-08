// GoPro Hero-style camera dimensions
camera_width = 71.8;
camera_height = 50.8;
camera_depth = 29;        // Approximate body without lens
lens_depth = 4.6;         // Protrusion of lens (total 33.6 - 29)
lens_diameter = 26;       // Approximate lens diameter
lens_offset_x = 53;       // X offset from left
lens_offset_y = 36;       // Y offset from bottom

// Main camera body
difference() 
{
    roundedCube([camera_width, camera_depth, camera_height], 3);
    
    // Optional: add holes or mounts here
}

// Front lens (cylindrical protrusion)
translate([lens_offset_x, camera_depth, lens_offset_y])
    rotate([90, 0, 0])
        cylinder(h = lens_depth, d = lens_diameter, $fn = 100);


// Utility: Rounded cube module
module roundedCube(size, radius) {
    hull() {
        for (x = [0, size[0]])
            for (y = [0, size[1]])
                for (z = [0, size[2]])
                    translate([x, y, z])
                        sphere(r = radius);
    }
}
