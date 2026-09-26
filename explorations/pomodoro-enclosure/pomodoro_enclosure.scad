// Pomodoro desk enclosure v2 "Slab" — Waveshare ESP32-S3-Touch-LCD-3.5B
// A thin rounded slab (whole glass visible, corners concentric with the glass R6)
// resting at 15° in a low foot that hides the battery, speaker and cables.
// One colour accent: the tomato-red PWR button.
//
// Board data from Waveshare's drawings: glass 92.44 x 61.00 R6, active 73.44 x 48.96,
// depth 11.50, M2 standoffs 72.00 x 48.50, buttons at 11.00 / 8.50 / 8.50.
// Board is used PORTRAIT, USB-C at the bottom (90° clockwise from Waveshare's front drawing).
//
// Parts (no supports):
//   shell    – slab front + walls, print FACE-DOWN
//   cover    – slab back, screwed to the 4 board standoffs, print flat
//   foot     – stand with battery bay, print UPSIDE-DOWN (top on the bed)
//   plate    – foot bottom plate, print flat
//   buttons  – PWR (red) + BOOT (black) caps
// Export: openscad -D 'part="shell"' -o out/shell.stl pomodoro_enclosure.scad

part = "assembly";   // assembly | exploded | shell | cover | foot | plate | buttons

// ---------------- Board (portrait, front view) ----------------
board_w = 61.00;  board_h = 92.44;  board_t = 11.50;  glass_r = 6.00;
standoff = [[6.25, 10.22], [54.75, 10.22], [6.25, 82.22], [54.75, 82.22]];
usb_x  = 30.35;                   // bottom edge
pwr_z  = 21.22; rst_z = 29.72; boot_z = 38.22; btn_d = 8.7; btn_inset = 3.6;   // right edge
sd_z   = 69.9;  sd_d = 8.4;       // right edge, estimated from photo — check before printing

// ---------------- Slab ----------------
tilt    = 15;
clr     = 0.3;
ws      = 3.2;     // side wall
lip     = 1.2;     // front lip over the glass edge
overlap = 1.0;     // how far the lip covers the glass edge
cover_t = 2.0;
fr      = 1.0;     // front edge fillet
br      = 3.0;     // back edge fillet
SW = board_w + 2*clr + 2*ws;
SH = board_h + 2*clr + 2*ws;
SD = lip + board_t + clr + cover_t;
SR = glass_r + clr + ws;          // outer corner radius, concentric with the glass
gx = ws + clr; gz = ws + clr;     // glass bottom-left corner

// ---------------- Foot ----------------
fm  = 4.0;         // foot extends past the slab on each side
FW  = SW + 2*fm;
FD  = 58;
FH  = 26;
ins = 11;          // how deep the slab sits in the foot (along the slope)
fy0 = 10;          // slab front edge, measured from the foot front
bay = [62, 46, 11];
plate_t = 2.0;
$fn = 56;

echo(str("Slab ", SW, " x ", round(SH*10)/10, " x ", SD, " mm; foot ", FW, " x ", FD, " x ", FH,
         "; overall height ~", round((FH - ins*cos(tilt) + SH*cos(tilt))*10)/10));

// ---------------- helpers ----------------
module rr2(w, h, r) { offset(r) offset(-r) square([w, h]); }
// rounded rectangle in x/z, extruded from y0 to y0+d
module rr_xz(x, z, w, h, r, y0, d) {
  translate([x, y0 + d, z]) rotate([90, 0, 0]) linear_extrude(d) rr2(w, h, r);
}

// slab outer body, grown by g on every side
module slab_outer(g = 0) {
  steps = [0:15:90];
  hull() {
    for (a = steps) {   // front fillet
      i = fr - fr*cos(a); y = fr - fr*sin(a);
      rr_xz(-g+i, -g+i, SW+2*g-2*i, SH+2*g-2*i, max(SR+g-i, 0.5), y-g, 0.01);
    }
    for (a = steps) {   // back fillet
      i = br - br*cos(a); y = SD - br + br*sin(a);
      rr_xz(-g+i, -g+i, SW+2*g-2*i, SH+2*g-2*i, max(SR+g-i, 0.5), y+g-0.01, 0.01);
    }
  }
}

// ---------------- Shell ----------------
module shell() {
  difference() {
    slab_outer();
    // window: glass minus the overlap, with a small chamfer
    hull() {
      rr_xz(gx+overlap-0.5, gz+overlap-0.5, board_w-2*overlap+1, board_h-2*overlap+1, glass_r-overlap+0.5, -0.01, 0.01);
      rr_xz(gx+overlap, gz+overlap, board_w-2*overlap, board_h-2*overlap, glass_r-overlap, 0.5, 0.01);
    }
    rr_xz(gx+overlap, gz+overlap, board_w-2*overlap, board_h-2*overlap, glass_r-overlap, 0, lip+1);
    // board + cover pocket, open at the back
    rr_xz(ws, ws, board_w+2*clr, board_h+2*clr, glass_r+clr, lip, SD);
    // right side: PWR + BOOT caps, RESET pinhole, microSD
    for (zz = [pwr_z, boot_z]) translate([SW-ws-1, lip+btn_d, gz+zz]) rotate([0, 90, 0]) cylinder(d = 3.6, h = ws+2);
    translate([SW-ws-1, lip+btn_d, gz+rst_z]) rotate([0, 90, 0]) cylinder(d = 1.6, h = ws+2, $fn = 16);
    translate([SW-ws-1, lip+sd_d-1.6, gz+sd_z-7.25]) cube([ws+2, 3.2, 14.5]);
  }
}

// ---------------- Cover (own frame: x/y = slab x/z, z = thickness) ----------------
module cover() {
  cw = board_w + 2*clr - 0.2; ch = board_h + 2*clr - 0.2;
  difference() {
    union() {
      linear_extrude(cover_t) rr2(cw, ch, glass_r+clr-0.1);
      for (x = [-0.15, cw-0.5], y = [0.2*ch, 0.7*ch])   // friction ribs, 0.15 mm interference
        translate([x, y, 0.3]) cube([0.65, 0.1*ch, cover_t-0.6]);
    }
    for (s = standoff) translate([s[0]+clr-0.1, s[1]+clr-0.1, -1]) {
      cylinder(d = 2.4, h = cover_t+2);
      translate([0, 0, 1+cover_t-1.3]) cylinder(d1 = 2.4, d2 = 4.4, h = 1.31);   // countersink
    }
    // cable exit for the 90° USB-C plug and the battery lead (sits inside the foot)
    translate([usb_x+clr-0.1-9, -1, -1]) cube([18, 12, cover_t+2]);
    // pry notch
    translate([cw/2-5, ch-1.2, -1]) cube([10, 2, 1.8]);
  }
}

// ---------------- Foot ----------------
module foot_outer() {
  hull() {
    translate([0, 0, 1.5]) linear_extrude(FH-3) rr2(FW, FD, SR+fm);
    translate([1.5, 1.5, 0]) linear_extrude(FH) rr2(FW-3, FD-3, SR+fm-1.5);
  }
}
module slab_placed(g = 0) {   // slab pose in the foot
  translate([fm, fy0, FH - ins*cos(tilt)]) rotate([-tilt, 0, 0]) children();
}
module foot() {
  difference() {
    foot_outer();
    slab_placed() slab_outer(0.2);
    // battery bay, open at the bottom (meets the slot at the back = cable path)
    translate([(FW-bay[0])/2, 6, -0.01]) linear_extrude(bay[2]+plate_t) rr2(bay[0], bay[1], 4);
    // plate recess
    translate([0, 0, -0.01]) linear_extrude(plate_t) offset(-1.6) rr2(FW, FD, SR+fm);
    // screw pilots for the plate
    for (p = plate_screws()) translate([p[0], p[1], -1]) cylinder(d = 1.7, h = plate_t+8, $fn = 16);
    // back: USB-C panel socket (left) + speaker grille (right)
    translate([FW*0.3-6.5, FD-4, plate_t+2.5]) cube([13, 6, 6.5]);
    for (i = [0:5], j = [0:2]) translate([FW*0.62 + i*3.2, FD-4, plate_t+3.5 + j*3.2]) rotate([-90, 0, 0]) cylinder(d = 1.8, h = 6, $fn = 12);
  }
}
function plate_screws() = [[5, FD/2], [FW-5, FD/2], [FW/2, 3.4], [FW/2, FD-3.4]];

module plate() {
  difference() {
    linear_extrude(plate_t) offset(-1.75) rr2(FW, FD, SR+fm);
    for (p = plate_screws()) translate([p[0], p[1], -1]) {
      cylinder(d = 2.3, h = plate_t+2, $fn = 16);
      translate([0, 0, 0.99]) cylinder(d1 = 4.4, d2 = 2.3, h = 1.0, $fn = 16);   // countersink (outside face down)
    }
    for (x = [12, FW-12], y = [12, FD-12]) translate([x, y, -0.01]) cylinder(d = 10.4, h = 0.6);   // feet
  }
}

// ---------------- Buttons ----------------
module button_cap() {
  inside = clr + btn_inset - 0.3;
  cylinder(d = 3.2, h = inside + ws + 0.8, $fn = 32);
  translate([0, 0, inside - 0.9]) cylinder(d = 5.6, h = 0.9);
}
module buttons() { button_cap(); translate([10, 0, 0]) button_cap(); }

// ---------------- Views ----------------
shade      = "black";   // render colour of everything: black | white
slab_shade = shade;     // override per part for two-tone renders
foot_shade = shade;
function c1(sh) = sh == "white" ? [0.93, 0.93, 0.91] : [0.10, 0.10, 0.11];
function c2(sh) = sh == "white" ? [0.86, 0.86, 0.84] : [0.16, 0.16, 0.17];
ink    = c1(slab_shade);
ink2   = c2(slab_shade);
foot_c = c1(foot_shade);
tomato = [0.95, 0.33, 0.18];
module glass() {
  color([0.02, 0.02, 0.025]) rr_xz(gx, gz, board_w, board_h, glass_r, lip-0.02, 1.1);
  color([0.95, 0.95, 0.93]) translate([gx+6.02, lip-0.05, gz+9.5]) cube([48.96, 0.04, 73.44]);   // lit screen
}
module caps() {
  for (zz = [pwr_z, boot_z]) color(zz == pwr_z ? tomato : ink)
    translate([SW+0.8, lip+btn_d, gz+zz]) rotate([0, -90, 0]) button_cap();
}
module slab_assembly(e = 0) {
  color(ink) shell();
  glass();
  caps();
  color(ink2) translate([ws+0.1, SD - cover_t + e, ws+0.1]) rotate([90, 0, 0]) mirror([0, 0, 1]) cover();
}

if (part == "shell")   shell();
if (part == "cover")   cover();
if (part == "foot")    foot();
if (part == "plate")   plate();
if (part == "buttons") buttons();
if (part == "assembly") { color(foot_c) foot(); slab_placed() slab_assembly(); }
if (part == "exploded") {
  color(foot_c) foot(); color(c2(foot_shade)) translate([0, 0, -25]) plate();
  slab_placed() translate([0, -10, 45]) slab_assembly(18);
}
