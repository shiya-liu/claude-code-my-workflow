// Pomodoro desk enclosure — Waveshare ESP32-S3-Touch-LCD-3.5B
// Style "Ink & Paper": matte black body, flush front bezel, one tomato-red PWR button.
//
// Board dimensions from the official Waveshare drawings (glass 92.44 x 61.00, R6,
// active area 73.44 x 48.96 centred, total depth 11.50, M2 standoffs 72.00 x 48.50).
// The board is used in PORTRAIT with the USB-C port at the bottom
// (i.e. rotated 90° clockwise from Waveshare's front drawing) -> set display rotation to match.
//
// Parts (all print without supports):
//   body     – tilted wedge housing, print standing on its flat bottom
//   bezel    – front plate with screen window, print face-down
//   carrier  – plate screwed to the board's 4 M2 standoffs, rests on the pocket ledge
//   buttons  – PWR (red) + BOOT (black) push caps
// Export:  openscad -D 'part="body"' -o body.stl pomodoro_enclosure.scad

part = "assembly";   // assembly | exploded | body | bezel | carrier | buttons

// ---------------- Board, portrait, front view (mm) ----------------
// x from the glass LEFT edge, z from the glass BOTTOM edge, d = depth behind the glass front
board_w  = 61.00;
board_h  = 92.44;
board_t  = 11.50;
glass_r  = 6.00;
win_w    = 48.96;   // active area
win_h    = 73.44;
standoff = [[6.25, 10.22], [54.75, 10.22], [6.25, 82.22], [54.75, 82.22]];  // M2, tips at d = 11.5
usb_x    = 30.35;   // USB-C on the bottom edge
usb_d    = 9.2;
// right edge (tact switches point outward, ~3.6 mm inside the glass edge)
pwr_z    = 21.22;
rst_z    = 29.72;   // RESET -> paper-clip pinhole
boot_z   = 38.22;
btn_d    = 8.7;
btn_inset= 3.6;
sd_z     = 69.9;    // microSD slot, right edge (estimated from photo — check before printing)
sd_d     = 8.4;

// ---------------- Parts & fit ----------------
bat      = [50, 34, 10];  // LiPo footprint used for the bay check (e.g. 103450)
tilt     = 15;
clr      = 0.3;
side_m   = 4.5;    // face border left / right / top
chin     = 16.0;   // face border under the glass
bez      = 1.6;
rim      = 1.2;
skirt_in = 1.8;
skirt_t  = 1.0;
skirt_d  = 2.5;
gclr     = 0.15;
carrier_t= 1.6;
wall     = 2.2;
ledge    = 2.5;
base_d   = 74;
base_h   = 18;
floor_t  = 2.0;
edge_r   = 1.2;
$fn = 48;

// ---------------- Derived ----------------
Wf  = board_w + 2*clr + 2*side_m;
Sf  = board_h + 2*clr + side_m + chin;
Pd  = bez + board_t + carrier_t + clr;   // pocket depth
Ds  = Pd + wall + 4;                     // slab depth
bx0 = side_m + clr;                      // glass bottom-left corner in face frame
bz0 = chin + clr;
H   = Sf * cos(tilt);
by0 = (Pd + base_h*sin(tilt)) / cos(tilt);   // front of the base cavity (world y)
echo(str("Outer ~ ", Wf, " W x ", base_d, " D x ", round(H*10)/10, " H mm"));
echo(str("Battery bay ", Wf-2*wall, " x ", round((base_d-wall-by0)*10)/10, " x ", base_h-floor_t-wall,
         " (battery ", bat[0], " x ", bat[1], " x ", bat[2], ")"));

// face frame: x across, y into the body, z up the slope
module face() rotate([-tilt, 0, 0]) children();

// rounded rectangle in the x/z plane, extruded along +y
module rrect_xz(x, z, w, h, r, y0, d) {
  translate([x, y0 + d, z]) rotate([90, 0, 0])
    linear_extrude(d) offset(r) offset(-r) square([w, h]);
}

// ---------------- Body ----------------
module outer() {
  intersection() {
    minkowski() {
      hull() {
        face() translate([edge_r, edge_r, edge_r]) cube([Wf-2*edge_r, Ds-2*edge_r, Sf-2*edge_r]);
        // base starts behind the tilted face so the face stays one flat plane
        translate([edge_r, base_h*tan(tilt)+edge_r, edge_r]) cube([Wf-2*edge_r, base_d-base_h*tan(tilt)-2*edge_r, base_h-2*edge_r]);
      }
      sphere(r = edge_r, $fn = 16);
    }
    translate([-50, -50, 0]) cube([Wf+100, base_d+100, H+100]);
  }
}

module cavity() {
  hull() {
    face() rrect_xz(bx0+ledge, bz0+ledge, board_w-2*ledge, board_h-2*ledge, glass_r, Pd-0.01, Ds-wall-Pd);
    translate([wall, by0, floor_t]) cube([Wf-2*wall, base_d-wall-by0, base_h-floor_t-wall]);
  }
}

module face_cuts() {
  face() {
    // bezel recess + skirt groove
    translate([rim, -1, rim]) cube([Wf-2*rim, bez+1, Sf-2*rim]);
    difference() {
      translate([skirt_in, -1, skirt_in]) cube([Wf-2*skirt_in, bez+skirt_d+1.4, Sf-2*skirt_in]);
      g = skirt_in + skirt_t + 2*gclr;
      translate([g, -2, g]) cube([Wf-2*g, bez+skirt_d+4, Sf-2*g]);
    }
    // board + carrier pocket (glass outline, R6 corners)
    rrect_xz(side_m, chin, board_w+2*clr, board_h+2*clr, glass_r+clr, bez-0.01, Pd-bez+0.02);
    // USB-C: room for a 90° plug under the board, open to the battery bay
    translate([bx0+usb_x-8, bez+3.5, bz0-6]) cube([16, 20-bez-3.5, 14]);
    // right edge: PWR + BOOT caps, RESET pinhole, microSD slot
    xr = Wf - side_m - 1;
    for (zz = [pwr_z, boot_z]) translate([xr, bez+btn_d, bz0+zz]) rotate([0, 90, 0]) cylinder(d = 3.6, h = side_m+2);
    translate([xr, bez+btn_d, bz0+rst_z]) rotate([0, 90, 0]) cylinder(d = 1.6, h = side_m+2, $fn = 16);
    translate([xr, bez+sd_d-1.6, bz0+sd_z-7.25]) cube([side_m+2, 3.2, 14.5]);
  }
}

module body() {
  difference() {
    outer();
    cavity();
    face_cuts();
    // rear port for a panel-mount USB-C extension (glue in)
    translate([Wf/2-6.5, base_d-wall-1, floor_t+4]) cube([13, wall+2, 6.5]);
    // speaker grille in the floor, behind the battery
    for (r = [0:3], a = [0:(r == 0 ? 360 : 360/(6*r)):359.9])
      translate([Wf/2 + 3.2*r*cos(a), base_d-16 + 3.2*r*sin(a), -1]) cylinder(d = 1.8, h = floor_t+2, $fn = 12);
    // rubber-foot recesses
    for (x = [9, Wf-9], y = [9, base_d-9]) translate([x, y, -0.01]) cylinder(d = 10.4, h = 0.8);
  }
}

// ---------------- Bezel (printed face-down: front at z = 0) ----------------
module bezel() {
  o  = rim + gclr;
  bw = Wf - 2*o; bh = Sf - 2*o;
  wx = bx0 + board_w/2 - o;           // window centre (bezel coords)
  wy = bz0 + board_h/2 - o;
  ww = win_w + 1.0; wh = win_h + 1.0; // 0.5 mm margin so no pixels are hidden
  s0 = skirt_in + gclr - o;
  difference() {
    union() {
      linear_extrude(bez) offset(0.6) offset(-0.6) square([bw, bh]);
      translate([s0, s0, bez-0.01]) difference() {
        cube([bw-2*s0, bh-2*s0, skirt_d]);
        translate([skirt_t, skirt_t, -1]) cube([bw-2*s0-2*skirt_t, bh-2*s0-2*skirt_t, skirt_d+2]);
      }
    }
    hull() {  // window, 45° chamfer on the front edge
      translate([wx-ww/2-0.8, wy-wh/2-0.8, -0.01]) cube([ww+1.6, wh+1.6, 0.01]);
      translate([wx-ww/2, wy-wh/2, 0.8]) cube([ww, wh, 0.01]);
    }
    translate([wx-ww/2, wy-wh/2, 0.5]) cube([ww, wh, bez+1]);
  }
}

// ---------------- Carrier (board-back plate, own frame: x/y = board x/z) ----------------
module carrier() {
  cw = board_w - 0.4; ch = board_h - 0.4;
  translate([0.2, 0.2, 0]) difference() {
    union() {
      difference() {   // outer frame
        linear_extrude(carrier_t) offset(glass_r-0.2) offset(-(glass_r-0.2)) square([cw, ch]);
        translate([4, 4, -1]) cube([cw-8, ch-8, carrier_t+2]);
      }
      for (s = standoff) translate([s[0]-0.2, s[1]-0.2, 0]) {   // pads + ribs to the frame
        cylinder(d = 7, h = carrier_t);
        translate([s[0] < 30 ? -s[0] : 0, -1.5, 0]) cube([s[0] < 30 ? s[0] : cw-s[0]+0.2, 3, carrier_t]);
      }
    }
    for (s = standoff) translate([s[0]-0.2, s[1]-0.2, -1]) cylinder(d = 2.4, h = carrier_t+2);
    translate([usb_x-0.2-8, -1, -1]) cube([16, 5.5, carrier_t+2]);   // notch for the USB plug
  }
}

// ---------------- Button caps ----------------
// stem: 0.8 outside + wall + reaches to ~0.3 mm from the switch; flange stays inside
module button_cap() {
  inside = clr + btn_inset - 0.3;
  cylinder(d = 3.2, h = inside + side_m + 0.8, $fn = 32);
  translate([0, 0, inside - 0.9]) cylinder(d = 5.6, h = 0.9);
}
module buttons() { button_cap(); translate([10, 0, 0]) button_cap(); }

// ---------------- Views ----------------
ink = [0.10, 0.10, 0.10]; tomato = [0.95, 0.33, 0.18];

module board_dummy(dy = 0) {
  face() translate([0, -dy, 0]) {
    color([0.03, 0.03, 0.035]) rrect_xz(bx0, bz0, board_w, board_h, glass_r, bez, 1.1);        // glass
    color([0.18, 0.18, 0.20]) translate([bx0+(board_w-win_w)/2, bez-0.02, bz0+(board_h-win_h)/2])
      cube([win_w, 0.05, win_h]);                                                           // pixels
    color([0.55, 0.56, 0.58]) rrect_xz(bx0+1, bz0+1, board_w-2, board_h-2, 4, bez+1.1, 4.8); // LCD frame
    color([0.15, 0.35, 0.65]) translate([bx0+3.6, bez+5.9, bz0+6.4]) cube([board_w-7.2, 1.6, board_h-12.8]); // PCB
    color([0.8, 0.65, 0.3]) for (s = standoff) translate([bx0+s[0], bez+7.5, bz0+s[1]]) rotate([-90, 0, 0]) cylinder(d = 3.5, h = 4);
  }
}
module bezel_placed(dy = 0) {
  o = rim + gclr;
  face() translate([o, bez - dy, o]) rotate([90, 0, 0]) mirror([0, 0, 1]) bezel();
}
module carrier_placed(dy = 0) {
  face() translate([bx0, bez + board_t + carrier_t + dy, bz0]) rotate([90, 0, 0]) carrier();
}
module caps_placed(dx = 0) {
  xs = Wf + 0.8 + dx;
  for (zz = [pwr_z, boot_z]) color(zz == pwr_z ? tomato : ink) face()
    translate([xs, bez+btn_d, bz0+zz]) rotate([0, -90, 0]) button_cap();
}

if (part == "body")    body();
if (part == "bezel")   bezel();
if (part == "carrier") carrier();
if (part == "buttons") buttons();
if (part == "assembly") { color(ink) body(); color(ink) bezel_placed(); caps_placed(); board_dummy(); }
if (part == "exploded") {
  color(ink) body(); color(ink) bezel_placed(70); caps_placed(12);
  board_dummy(40); color([0.3, 0.3, 0.3]) carrier_placed(-22);
}
