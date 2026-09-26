// Pomodoro desk enclosure for Waveshare ESP32-S3-Touch-LCD-3.5B
// Style: "Ink & Paper" — matte black body, flush front bezel, one tomato-red PWR button.
//
// Parts (all print without supports):
//   body    – tilted wedge housing, print standing on its flat bottom
//   bezel   – thin front plate with screen window, print face-down
//   buttons – PWR (red) and BOOT (black) push caps
//
// !!! Every value marked [MEASURE] is a placeholder until measured on the real board.
// Usage:  openscad -D 'part="body"' -o body.stl pomodoro_enclosure.scad

part = "assembly";            // assembly | body | bezel | buttons | exploded

// ---------------- Board (all [MEASURE]) ----------------
board_w   = 62.0;   // [MEASURE] PCB/LCD outline width, portrait (mm)
board_h   = 94.0;   // [MEASURE] outline height, portrait
board_t   = 12.0;   // [MEASURE] total thickness: glass front -> tallest part on back
win_w     = 49.5;   // [MEASURE] visible screen area width
win_h     = 74.0;   // [MEASURE] visible screen area height
win_dx    = 0.0;    // [MEASURE] screen-area centre offset from board centre (+ = right)
win_dy    = 0.0;    // [MEASURE] (+ = up)

// Openings. side: "left" | "right" | "top" | "bottom" (seen from the front, screen upright)
// pos = centre distance from the board's left edge (top/bottom) or bottom edge (left/right)
// depth = centre distance behind the glass front
usb     = ["bottom", 31.0, 8.0, 10.0, 4.5];  // [MEASURE] side, pos, depth, width, height (USB-C)
tf_slot = ["left",   20.0, 9.0, 13.0, 2.6];  // [MEASURE] microSD slot
btn_pwr = ["right",  70.0, 8.5];             // [MEASURE] side, pos, depth
btn_boot= ["right",  56.0, 8.5];             // [MEASURE]

// ---------------- Battery ----------------
bat = [34, 50, 10];  // [MEASURE] LiPo w x l x t (e.g. 103450 1S 2000 mAh)

// ---------------- Enclosure ----------------
tilt     = 15;    // screen leans back from vertical (deg)
clr      = 0.3;   // board clearance per side
side_m   = 4.5;   // face border left/right/top (outer edge -> board pocket)
chin     = 12.0;  // face border under the screen
bez      = 1.6;   // bezel thickness
rim      = 1.2;   // body lip visible around bezel
skirt_in = 1.8;   // bezel skirt position from outer edge
skirt_t  = 1.0;   // bezel skirt thickness
skirt_d  = 2.5;   // bezel skirt depth
gclr     = 0.15;  // bezel skirt fit clearance
wall     = 2.2;
ledge    = 1.8;   // board rests on this ledge behind its edges
base_d   = 64;    // footprint depth (front -> back)
base_h   = 18;    // battery bay height
floor_t  = 2.0;
edge_r   = 1.2;   // outer edge rounding
$fn = 40;

// ---------------- Derived ----------------
Wf = board_w + 2*clr + 2*side_m;         // face width
Sf = board_h + 2*clr + side_m + chin;    // face length along slope
Pd = bez + board_t + clr;                // pocket depth behind face
Ds = Pd + wall + 4;                      // slab depth (4 mm cable space)
bx0 = side_m + clr;                      // board origin in face frame
bz0 = chin + clr;
H  = Sf * cos(tilt);
echo(str("Face ", Wf, " x ", Sf, " mm; overall ~", Wf, " W x ", base_d, " D x ", round(H*10)/10, " H"));
echo(str("Battery bay height ", base_h - floor_t - wall, " (battery ", bat[2], ")"));

// face frame: x = across, y = into body, z = up the slope
module face() rotate([-tilt, 0, 0]) children();

module rbox(s, r) {  // box with rounded vertical corners (in its own frame)
  hull() for (x = [r, s[0]-r], y = [r, s[1]-r]) translate([x, y, 0]) cylinder(r = r, h = s[2]);
}

// ---------------- Body ----------------
module outer() {
  intersection() {
    minkowski() {
      hull() {
        face() translate([edge_r, edge_r, edge_r]) cube([Wf-2*edge_r, Ds-2*edge_r, Sf-2*edge_r]);
        translate([edge_r, edge_r, edge_r]) cube([Wf-2*edge_r, base_d-2*edge_r, base_h-2*edge_r]);
      }
      sphere(r = edge_r, $fn = 16);
    }
    translate([-50, -50, 0]) cube([Wf+100, base_d+100, H+100]);
  }
}

module cavity() {
  y0 = (Pd + base_h*sin(tilt)) / cos(tilt);    // keep base cavity behind the pocket
  hull() {
    face() translate([bx0+ledge, Pd-0.01, bz0]) cube([board_w-2*ledge, Ds-wall-Pd, board_h-ledge]);
    translate([wall, y0, floor_t]) cube([Wf-2*wall, base_d-wall-y0, base_h-floor_t-wall]);
  }
}

module face_cuts() {
  face() {
    // bezel recess + skirt groove
    translate([rim, -1, rim]) cube([Wf-2*rim, bez+1, Sf-2*rim]);
    difference() {
      translate([skirt_in, -1, skirt_in]) cube([Wf-2*skirt_in, bez+skirt_d+0.4+1, Sf-2*skirt_in]);
      translate([skirt_in+skirt_t+2*gclr, -2, skirt_in+skirt_t+2*gclr])
        cube([Wf-2*(skirt_in+skirt_t+2*gclr), bez+skirt_d+4, Sf-2*(skirt_in+skirt_t+2*gclr)]);
    }
    // board pocket
    translate([side_m, bez-0.01, chin]) cube([board_w+2*clr, board_t+clr+0.02, board_h+2*clr]);
  }
}

// one rectangular opening through the wall on a given side of the board
module side_cut(side, pos, depth, w, h, extra = 0) {
  y = bez + depth;
  face() {
    if (side == "left")   translate([-1,               y-h/2, bz0+pos-w/2]) cube([side_m+2, h, w]);
    if (side == "right")  translate([Wf-side_m-1,      y-h/2, bz0+pos-w/2]) cube([side_m+2, h, w]);
    if (side == "top")    translate([bx0+pos-w/2,      y-h/2, bz0+board_h-1]) cube([w, h, side_m+clr+2]);
    if (side == "bottom") translate([bx0+pos-w/2,      y-h/2, -extra]) cube([w, h, chin+1+extra]);
  }
}

module button_hole(side, pos, depth) {
  y = bez + depth;
  face() {
    xo = side == "left" ? -1 : Wf-side_m-1;
    xc = side == "left" ? side_m-1.0 : Wf-side_m-0.01;   // counterbore on the inside
    translate([xo, y, bz0+pos]) rotate([0, 90, 0]) cylinder(d = 3.6, h = side_m+2);
    translate([side == "left" ? xc : xc-1.0, y, bz0+pos]) rotate([0, 90, 0]) cylinder(d = 6.0, h = 1.01);
  }
}

module body() {
  difference() {
    outer();
    cavity();
    face_cuts();
    // USB-C: side opening, or for a bottom port a channel into the bay + exit in the back wall
    if (usb[0] == "bottom") {
      side_cut("bottom", usb[1], usb[2], usb[3]+4, usb[4]+3, 0);
      translate([Wf/2-6, base_d-wall-1, floor_t+1]) cube([12, wall+2, 7]);   // cable exit (back)
    } else side_cut(usb[0], usb[1], usb[2], usb[3]+1.2, usb[4]+1.2);
    side_cut(tf_slot[0], tf_slot[1], tf_slot[2], tf_slot[3]+1.5, tf_slot[4]+1.2);
    button_hole(btn_pwr[0],  btn_pwr[1],  btn_pwr[2]);
    button_hole(btn_boot[0], btn_boot[1], btn_boot[2]);
    // speaker grille in the floor (sound bounces off the desk)
    for (r = [0:3], a = [0:(r == 0 ? 0 : 360/(6*r)):359.9])
      translate([Wf/2 + 3.2*r*cos(a), base_d-20 + 3.2*r*sin(a), -1]) cylinder(d = 1.8, h = floor_t+2, $fn = 12);
    // rubber-foot recesses
    for (x = [9, Wf-9], y = [9, base_d-9]) translate([x, y, -0.01]) cylinder(d = 10.4, h = 0.8);
  }
}

// ---------------- Bezel (own frame, printed face-down: front at z = 0) ----------------
module bezel() {
  o  = rim + gclr;
  bw = Wf - 2*o; bh = Sf - 2*o;
  wx = bx0 + board_w/2 + win_dx - o;   // window centre in bezel coords
  wy = bz0 + board_h/2 + win_dy - o;
  s0 = skirt_in + gclr - o;            // skirt offset from bezel edge
  difference() {
    union() {
      rbox([bw, bh, bez], 0.6);
      translate([s0, s0, bez-0.01]) difference() {
        cube([bw-2*s0, bh-2*s0, skirt_d]);
        translate([skirt_t, skirt_t, -1]) cube([bw-2*s0-2*skirt_t, bh-2*s0-2*skirt_t, skirt_d+2]);
      }
    }
    // window with a 45° chamfer on the front edge
    hull() {
      translate([wx-win_w/2-0.8, wy-win_h/2-0.8, -0.01]) cube([win_w+1.6, win_h+1.6, 0.01]);
      translate([wx-win_w/2, wy-win_h/2, 0.8]) cube([win_w, win_h, 0.01]);
    }
    translate([wx-win_w/2, wy-win_h/2, 0.5]) cube([win_w, win_h, bez+1]);
  }
}

// ---------------- Button caps ----------------
module button_cap() {
  cylinder(d = 5.6, h = 0.9);                   // flange (inside, stops it falling out)
  cylinder(d = 3.2, h = 0.9 + side_m - 1.0 + 0.8, $fn = 32);  // stem, sticks out 0.8 mm
}
module buttons() { translate([0, 0, 0]) button_cap(); translate([10, 0, 0]) button_cap(); }

// ---------------- Views ----------------
ink = [0.09, 0.09, 0.09]; paper = [0.96, 0.96, 0.95]; tomato = [0.95, 0.33, 0.18];

module board_dummy() {
  face() translate([bx0, bez, bz0]) {
    color([0.12, 0.35, 0.2]) translate([0, 1.6, 0]) cube([board_w, board_t-1.6, board_h]);
    color([0.02, 0.02, 0.03]) translate([board_w/2+win_dx-win_w/2, -0.01, board_h/2+win_dy-win_h/2])
      cube([win_w, 1.7, win_h]);
  }
}
module bezel_placed(dy = 0) {
  o = rim + gclr;
  face() translate([o, bez - dy, o]) rotate([90, 0, 0]) mirror([0, 0, 1]) bezel();
}
module caps_placed(dx = 0) {
  for (b = [btn_pwr, btn_boot]) {
    xs = b[0] == "left" ? side_m - 1.0 - dx : Wf - side_m + 1.0 + dx;
    color(b == btn_pwr ? tomato : ink) face()
      translate([xs, bez + b[2], bz0 + b[1]]) rotate([0, b[0] == "left" ? -90 : 90, 0]) button_cap();
  }
}

if (part == "body")    body();
if (part == "bezel")   bezel();
if (part == "buttons") buttons();
if (part == "assembly") { color(ink) body(); color(ink) bezel_placed(); caps_placed(); board_dummy(); }
if (part == "exploded") { color(ink) body(); color(ink) bezel_placed(30); caps_placed(8); board_dummy(); }
