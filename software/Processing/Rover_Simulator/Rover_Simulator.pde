/*import org.gamecontrolplus.gui.*;
import org.gamecontrolplus.*;
import net.java.games.input.*;

ControlIO control;
Configuration config;
ControlDevice gpad;*/

PFont f;  // Declare a font variable for on-screen text

// Constant declarations
int nMaxSpeed = 255;
float fRadiusFactor = 500;
float fWheelHeight = 40;
float fWheelWidth = 20;

// Whether or not the console is in focus
boolean bConsoleFocus = false;
// String to store the console input
String sInputString = "";

// Stick inputs, all of the range [-1, 1]
float X1Stick, Y1Stick, X2Stick, Y2Stick;
// Global variables for defining the rover's motion
float fRoverRadius = 0, fRoverVelocity, fRoverRotation;
// Drive mode 0 is akin to a car, while 1 is only for rotating in place
boolean bDriveMode = false;
// Mast mode 0 is position control, while 1 is rate control
boolean bMastMode = false;
// Angle of the mast
float fMastPan = 0;
// Toggle for drawing the wheel indicators
RadioButton drawWheelIndicators = new RadioButton(15, 30, 5);
// Toggles for drawing the rover's turn radius and velocity
RadioButton drawRoverRadius = new RadioButton(15, 50, 5);
RadioButton drawRoverVelocity = new RadioButton(15, 70, 5);
RadioButton drawRoverRotation = new RadioButton(15, 50, 5);

// Wheel array
Wheel[] wheels = new Wheel[6];

public void setup() {
	size(1680, 1050);

	// Define the font and use it
	f = createFont("Source Code Pro", 16, true);
	textFont(f, 16);
	textAlign(LEFT, CENTER);

	/*// Initialise the ControlIO
	control = ControlIO.getInstance(this);
	// Find a device that matches the configuration file
	gpad = control.getMatchedDevice("ChillStream");
	if (gpad == null) {
		println("No suitable device configured");
		System.exit(-1); // End the program NOW!
	}

	// Register a listener so that changeDriveMode() is called every time the
	// left stick is pressed.
	gpad.getButton("B1").plug(this, "changeDriveMode", ControlIO.ON_PRESS);

	// Register a listener so that changeMastMode() is called every time the
	// right stick is pressed.
	gpad.getButton("B2").plug(this, "changeMastMode", ControlIO.ON_PRESS);*/

	// Initialize radio buttons
	drawWheelIndicators.set(true);
	drawRoverRadius.set(true);
	drawRoverVelocity.set(true);
	drawRoverRotation.set(true);

	// Wheel declarations
	wheels[0] = new Wheel(STEERABLE, REVERSE, -150, 200);
	wheels[1] = new Wheel(STEERABLE, NORMAL, 150, 200);
	wheels[2] = new Wheel(STATIONARY, REVERSE, -150, 0);
	wheels[3] = new Wheel(STATIONARY, NORMAL, 150, 0);
	wheels[4] = new Wheel(STEERABLE, REVERSE, -150, -200);
	wheels[5] = new Wheel(STEERABLE, NORMAL, 150, -200);
}

public void draw() {
	// Global style
	background(200, 200, 200);
	strokeWeight(2);

	// Get gamepad values for the requisite sliders
	/*X1Stick = gpad.getSlider("X1").getValue();
	Y1Stick = gpad.getSlider("Y1").getValue();
	X2Stick = gpad.getSlider("X2").getValue();
	Y2Stick = gpad.getSlider("Y2").getValue();*/

	// Use mouse position instead of a gamepad
	X1Stick = (float(mouseX) * 2 / width) - 1;
	Y1Stick = 1 - (float(mouseY) * 2 / height);

	// Different rules for each mode
	if (bDriveMode) {
		fRoverRadius = 0;
		fRoverVelocity = 0;
		fRoverRotation = -X1Stick;
	} else {
		// Handle the endpoints of the functions. If the stick is all the way to
		// the left or the right, we have to set the rover radius equal to the
		// minimum positive or minimum negative float value, respectively.
		if (X1Stick == -1) {
			fRoverRadius = Float.MIN_NORMAL;
		} else if (X1Stick == 1) {
			fRoverRadius = -Float.MIN_NORMAL;
		} else {
			fRoverRadius = fRadiusFactor * tan(HALF_PI*(X1Stick + 1));
		}
		fRoverVelocity = nMaxSpeed * Y1Stick * abs(fRoverRadius) / maxRadius(fRoverRadius);
	}

	// Update all wheels
	for (Wheel wheel : wheels) {
		wheel.update();
	}

	// Center the matrix (from now on, the origin is at (640, 360))
	pushMatrix();
	translate(width / 2, height / 2);

	for (Wheel wheel : wheels) {
		if (wheel.bPressed) {
			wheel.drawRadius();
		}
	}

	if (bDriveMode) {
		drawBody();
		drawMast();
		if (drawRoverRotation.pressed()) {
			drawRotation();
		}
	} else {
		if (drawRoverRadius.pressed()) {
			drawRadius();
		}
		drawBody();
		drawMast();
		if (drawRoverVelocity.pressed()) {
			drawVelocity();
		}
	}

	// Draw all wheels
	for (Wheel wheel : wheels) {
		wheel.draw();
	}

	popMatrix();

	// Display important information (HUD)
	fill(48, 48, 48);
	drawWheelIndicators.draw("Wheel Indicators");
	if (bDriveMode) {
		text("Drive Mode: 1", 10, 10);
		drawRoverRotation.draw("Rotation: " + fRoverRotation);
	} else {
		text("Drive Mode: 0", 10, 10);
		drawRoverRadius.draw("Radius: " + fRoverRadius);
		drawRoverVelocity.draw("Velocity: " + fRoverVelocity);
		text("Radius Factor: " + fRadiusFactor, 10, height - 35);
	}

	fill(48, 48, 48);
	strokeWeight(2);
	float fRightTextWidth = textWidth("Mast Pan: -180" + (char)0x00B0) + 10;
	if (bMastMode) {
		text("Mast Mode: 1", width - fRightTextWidth, 10);
	} else {
		text("Mast Mode: 0", width - fRightTextWidth, 10);
	}
	text("Mast Pan: " + String.format("%.0f", degrees(fMastPan)) + (char)0x00B0, width - fRightTextWidth, 30);

	// Draw console
	drawConsole();
}

// Automatically called whenever a mouse button is pressed.
void mousePressed() {
	if (mouseButton == LEFT) {
		// Check if the mouse is inside the console and set the appropriate flag
		if (mouseY > height - 20) {
			bConsoleFocus = true;
		} else {
			bConsoleFocus = false;

			if (drawWheelIndicators.over()) {
				drawWheelIndicators.toggle();
			}

			if (bDriveMode) {
				if (drawRoverRotation.over()) {
					drawRoverRotation.toggle();
				}
			} else {
				//float fRadiusWidth = textWidth("Radius Factor: ") + 10;

				if (drawRoverRadius.over()) {
					drawRoverRadius.toggle();
				} else if (drawRoverVelocity.over()) {
					drawRoverVelocity.toggle();
				} /*else if ((mouseX > fRadiusWidth) && (mouseX < fRadiusWidth + textWidth(Float.toString(fRadiusFactor))) && (mouseY > height - 45)) {
					fill(255, 0, 0);
					text("YAY!", 0, height / 2);
				}*/
			}

			// Check if the mouse is over any of the wheels
			for (Wheel wheel : wheels) {
				if (wheel.over()) {
					wheel.bPressed = !wheel.bPressed;
				}
			}
		}
	}
}

// Automatically called whenever a key is pressed on the keyboard.
void keyPressed() {
	// If there isn't anything in the console yet, bring it into focus
	if (sInputString.length() == 0) {
		bConsoleFocus = true;
	}

	// Only do stuff if the console is in focus
	if (bConsoleFocus) {
		if (key == '\n' ) {
			// TODO: add cases for other operations/commands
			if (sInputString.charAt(0) == 'm') {
				changeDriveMode();
			} else if (sInputString.charAt(0) == 'r'){
				fRadiusFactor = Float.parseFloat(sInputString.substring(1));
			}

			sInputString = "";
		} else if (key == 8) {
			// If the backspace key is pressed, delete the last character in the
			// input string.
			if (sInputString.length() > 0) {
				sInputString = sInputString.substring(0, sInputString.length() - 1);
			}
		} else {
			// Otherwise, concatenate the String. Each character typed by the
			// user is added to the end of the input String.
			sInputString = sInputString + key;
		}
	}
}

// Called whenever the left joystick button on the gamepad transitions from low
// to high. Toggles the control mode each time.
void changeDriveMode() {
	bDriveMode = !bDriveMode;
}

// Called whenever the left joystick button on the gamepad transitions from low
// to high. Toggles the control mode each time.
void changeMastMode() {
	bMastMode = !bMastMode;
}

// Draws the console at the bottom of the screen.
void drawConsole() {
	// Change the cursor on hover
	if (mouseY > height - 20) {
		cursor(TEXT);
	} else {
		cursor(ARROW);
	}

	// Draw console box
	fill(48, 48, 48, 255);
	noStroke();
	rectMode(CORNERS);
	rect(0, height - 20, width, height);

	// Highlight the console text if it's in focus
	if (bConsoleFocus) {
		fill(255, 255, 255);

		if (sInputString.length() == 0) {
			rect(30, height - 18, 40, height - 2);
		}
	} else {
		fill(255, 255, 255, 64);
	}
	// Draw console text
	text(">> " + sInputString, 2, height - 12);
}

// Draws a circle that represents the path that the center of the rover will
// take.
void drawRadius() {
	noFill();
	stroke(0, 0, 0, 200);
	ellipseMode(RADIUS);
	point(0, 0);

	if (X1Stick == 0) {
		// If we're going straight, just draw a line
		line(0, -height / 2, 0, height / 2);
	} else {
		// If not, draw a circle, and a point at the center of that circle
		point(-fRoverRadius, 0);
		ellipse(-fRoverRadius, 0, abs(fRoverRadius), abs(fRoverRadius));
	}
}

// Draws a vector that represents the translational velocity of the center of
// the rover.
void drawVelocity() {
	// Don't draw anything if the rover isn't moving
	if (fRoverVelocity != 0) {
		stroke(0, 0, 0, 255);
		line(0, 0, 0, -fRoverVelocity / 2);
		line(-10, -fRoverVelocity / 2, 10, -fRoverVelocity / 2);
	}
}

// Draws a nice curvy vector-thing that represents the rover's rotation about
// its center.
void drawRotation() {
	noFill();
	stroke(0, 0, 0, 255);
	ellipseMode(RADIUS);

	// Only necessary because Processing does not allow negative angles in arcs
	if (fRoverRotation < 0) {
		arc(0, 0, 50, 50, 0, -fRoverRotation * TWO_PI);
	} else {
		arc(0, 0, 50, 50, TWO_PI - fRoverRotation * TWO_PI, TWO_PI);
	}

	// Only draw the tip of the arrow if the rover is actually turning
	if (fRoverRotation != 0) {
		point(0, 0);
		pushMatrix();
		rotate(-fRoverRotation * TWO_PI);
		line(45, 0, 55, 0);
		popMatrix();
	}
}

// Draws the body of the rover. Just a stationary, semi-translucent rectangle.
void drawBody() {
	fill(255, 255, 255, 127);
	stroke(0, 0, 0, 127);
	rectMode(RADIUS);
	rect(0, 0, 100, 200, 5);
}

// Draws the camera mast on the front of the rover
void drawMast() {
	pushMatrix();
	translate(0, -175);
	if (bMastMode) {
		float fNew = X2Stick * PI / 100;
		if (abs(fMastPan + fNew) <= PI) {
			fMastPan += fNew;
		}
	} else {
		fMastPan = X2Stick * PI;
	}
	rotate(fMastPan);

	fill(48, 48, 48, 255);
	noStroke();
	rectMode(RADIUS);
	rect(0, 0, 50, 15, 10);
	rect(0, 10, 25, 10, 10);

	popMatrix();
}

// Returns the value of the maximum distance of any wheel from its center to the
// center of rotation of the rover.
float maxRadius(float fRadius) {
	float fMaxRadius = 0;
	for (Wheel wheel : wheels) {
		if (wheel.radius(fRadius) > fMaxRadius) {
			fMaxRadius = wheel.radius(fRadius);
		}
	}

	return fMaxRadius;
}
