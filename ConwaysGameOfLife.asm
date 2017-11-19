#Jonathan Lyttle
#jbl160530
#MIPS Implementation of Conway's Game of Life with Bitmap Display
#Works with 8 pixel width and height and 512 display width and height

.data
birthsAndDeathsArray:	.space	4096	#An array for tracking births and deaths, the same size as the bitmap display
gridSize:		.word	64	#The width or length of the working grid.
sleepTime:		.word	0	#The amount of time to wait before displaying the next generation (in ms).
patternPrompt:		.asciiz	"Choose a pattern (1 for random, 2 for glider gun)"
waitTimePrompt:		.asciiz	"Enter the amount of time to wait between displaying generations (in ms)"
errorMessage1:		.asciiz	"Enter a nonnegative value for time between generations."
errorMessage2:		.asciiz	"Unable to read input, try again."
errorMessage3:		.asciiz	"Enter a correct value for pattern choice."

.text
Main:
	lw	$s0, gridSize		#Load the grid size into $s0
	lw	$s3, 0x000000
PromptForSleepTime:
	li	$v0, 51
	la	$a0, waitTimePrompt	#Ask the user how long to wait until displaying the next generation
	syscall
	
	beq	$a1, -1, Error2
	beq	$a1, -2, Exit		#Validate the input, close if cancel is hit
	beq	$a1, -3, Error2
	
	blt	$a0, 0, Error1

PatternMenu: #Choose either the glider gun pattern or a random pattern.
	li	$v0, 51
	la	$a0, patternPrompt	#Prompt user for pattern choice
	syscall
	
	beq	$a1, -1, Error2		#If input is unreadable, error
	beq	$a1, -2, Exit
	beq	$a1, -3, Error2
	
	blt	$a0, 1, Error3		#If the choice is greater than 3 or less than 1, error
	bgt	$a0, 2, Error3
	
	move	$s2, $a0		#Store pattern choice in $s2

InitializeArray:	#Create the array with the chosen pattern.
	beq	$s2, 1, Preset1		#Initialize the glider gun pattern
	
	#If the user chose random, we want to intialize the array with a chance of having a living cell. To have more space, we'll choose a third of a chance of spawning.
	li	$t0, 3	#Initialize $t0 to 3 (the value we compare with).
	li	$v0, 42	#Choose an int between a range.
	li	$a1, 9	#Set 9 as the upper bound (0 is the lower bound).
Preset1:
	#DEBUG: render a single pixel on the grid and kill it
	mulu	$t0, $s0, $s0
	la	$s1, birthsAndDeathsArray	#Load the birth and death tracking array into $s1		
	li	$t1, 0			#Get the total size of the space, SRL, and add 32 to get the middle
	srl	$a0, $t0, 1
	addiu	$a0, $a0, 32
	jal	GetDisplayAddress	#Get the address for that space
	move	$a0, $v0
	li	$a1, 0x00ff00
	jal	Draw			#Draw the pixel in that space
	
	addu	$t2, $s1, 0	
InitializeBirthsAndDeathsArray:
	sw	$s3, ($t2)		#Store 0 at the current address (for blank)
	addu	$t2, ($s1), 4		#Advance the pointer to the next word
	bne	$t1, $t0, InitializeBirthsAndDeathsArray	#Loop until the array is filled

	li	$a0, 0
GOLLoop:	#For each pixel in the array, run this.
	#Set first argument to the current position
	jal	GOLAlogrithm
	addiu	$a0, $a0, 1	#Advance current position by 1
	bgt	$a0, $t0, DisplayGeneration	#If the current position is greater than the total size, start displaying	

#ArrayLoop:
#	syscall
#	bgt	$a0, $t0, ArrayLoop	#If the value we picked was greater than 3, leave the value as 0 and continue.

GOLAlgorithm:
	#First, check if we're on the top row. $a0 is the absolute position of the pixel, $t0 is the total size.
	#if ($a0 < 64); don't check the top and move on to the middle
	blt	$a0, 64, CheckMiddle
CheckTop:
	#TODO

CheckMiddle:
	#if (($a0 % 64) == 0); don't check the middle left and move on to the right
	addi	$t1, $a0, 0	#$t1 = $a0
	rem	$t1, $t1, 64	#$t1 = $t1 % 64
	beq	$t1, $zero, CheckMiddleRight
	
	CheckMiddleLeft:
	#TODO
	
	#if ((($a0 + 1) % 64) == 0); don't check the middle right and move on to the bottom row
	addi	$t1, $a0, 1	#$t1 = $a0 + 1
	rem	$t1, $t1, 64	#t1 = $t1 % 64
	beq	$t1, $zero, CheckBottom
	
	
	CheckMiddleRight:
	#TODO
	
CheckBottom:
	#if (($a0 + 64) > $t0); 

	#If ((($a0 + 64) % 64) == 0); don't check bottom left and move on to the right
	addi	$t1, $a0, 64	#$t1 = $a0 + 64
	rem	$t1, $t1, 64	#$t1 = $t1 % 64
	beq	$t1, $zero, CheckBottomRight
	
	CheckBottomLeft:
	#TODO
	
	

DisplayGeneration:	#Display the current generation in the bitmap display.
	mulu	$t0, $s0, $s0	#Multiply width by height (same value) to get total size.
	li	$t1, 0		#Initialize variable for current position.
DrawLoop:
	add	$a0, $t1, $zero	#Load current position as an argument for GetDisplayAddress.
	jal	GetDisplayAddress
	move	$a0, $v0
	li	$a1, 0x00ff00	#Debug, color green
	jal	Draw
	addiu	$t1, $t1, 1		#Increment position
	bne	$t1, $t0, DrawLoop	#Loop until we've filled the whole display
	
	j	Exit
	
GetDisplayAddress:	#Gets the address for the bitmap display given a position in $a0.
	mul	$v0, $a0, 4	#Multiply current position by 4 to get word size
	add	$v0, $v0, $gp	#Add the global pointer from the bitmap display
	jr	$ra
	
Draw:	#Draws the pixel to the bitmap display given $a0 (location) and $a1 (color)
	sw	$a1, ($a0)
	jr	$ra

Error1:
	li	$v0, 55
	li	$a1, 0
	la	$a0, errorMessage1
	syscall
	j	PromptForSleepTime

Error2:
	li	$v0, 55
	li	$a1, 0
	la	$a0, errorMessage2
	syscall
	j	PatternMenu
	
Error3:
	li	$v0, 55
	li	$a1, 0
	la	$a0, errorMessage3
	syscall
	j	PatternMenu

Exit:
	li	$v0, 10
	syscall
