#Jonathan Lyttle
#jbl160530
#MIPS Implementation of Conway's Game of Life with Bitmap Display
#Works with 8 pixel width and height and 512 display width and height

#GLOBAL VARIABLES:
#$s0 = grid width/length
#$s1 = births and deaths array address
#$s2 = chosen pattern
#$s3 = Black color (blank / dead)
#$s4 = White color (Living)


.data
birthsAndDeathsArray:	.space	4096	#An array for tracking births and deaths, the same size as the bitmap display
gridSize:		.word	64	#The width or length of the working grid.
deadCellColor:		.word	0x000000	#The color chosen for a dead cell
livingCellColor:	.word	0xffffff	#The color chosen for a living cell
sleepTime:		.word	0	#The amount of time to wait before displaying the next generation (in ms).
patternPrompt:		.asciiz	"Choose a pattern (1 for random, 2 for glider gun)"
waitTimePrompt:		.asciiz	"Enter the amount of time to wait between displaying generations (in ms)"
errorMessage1:		.asciiz	"Enter a nonnegative value for time between generations."
errorMessage2:		.asciiz	"Unable to read input, try again."
errorMessage3:		.asciiz	"Enter a correct value for pattern choice."

.text
Main:
	lw	$s0, gridSize		#Load the grid size into $s0
	lw	$s3, deadCellColor
	lw	$s4, livingCellColor
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
	#DEBUG: render a single pixel on the grid
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
	addu	$t2, $s1, 4		#Advance the pointer to the next word
	bne	$t1, $t0, InitializeBirthsAndDeathsArray	#Loop until the array is filled

GameOfLife:
	li	$t5, 0			#Set $t5 to the current position
	
	GOLLoop:	
		#For each pixel in the display array, run the algorithm
		addiu	$a0, $t5, 0			#Copy the current position into argument
		jal	GOLAlgorithm
		addiu	$a0, $t5, 0
		jal	GetDisplayAddress
		lw	$t2, ($v0)			#$t2 = value at current address
		mul	$t4, $t5, 4			#Convert current position to a word value in $t4
		addu	$t4, $t4, $s1			#Store the current address in the births and deaths array as $t4
		beq	$t2, $s3, Dead
		Live:					#The current cell is alive if the value isn't blank
			#if $v1 returned less than 2, set this cell as dead
			blt	$v1, 2, SetDead
			bgt	$v1, 3, SetDead
			b	CheckLoop
			SetDead:
				sw	$s3, ($t4)
		Dead:
		
		CheckLoop:
		addiu	$t5, $t5, 1			#Advance current position by 1
		bgt	$t5, $t0, DisplayGeneration	#If the current position is greater than the total size, start displaying the births and deaths of this generation

	GOLAlgorithm:
		#$t1 is the absolute position of the pixel, $t0 is the total size of the grid, $v1 is the neighbor counter.
		li	$v1, 0		#initialize counter to 0
		move	$t1, $a0	#Move the argument to $t1 to work with
	
		#if ($t1 < 64); we're on the top row so move on to checking the middle row
		blt	$t1, 64, CheckMiddle
	CheckTop:
		#if (($t1 % 64) == 0); we're on the left border so don't check top left and move on to the right
		rem	$t2, $t1, 64	#$t2 = $t1 % 64
		beq	$t2, $zero, CheckTopRight

		CheckTopLeft:
		#if the value at ($t1 - 65) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $t1, -65			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, 0x000000, CheckTopMiddle	#If the value at $t2 is either black or red, don't increment
		beq	$t2, 0xff0000, CheckTopMiddle
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
		CheckTopMiddle:
		#if we can check top left, we can also check top middle so we fall through
		#if the value at ($t1 - 64) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $t1, -64			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, 0x000000, CheckTopRight	#If the value at $t2 is either black or red, don't increment
		beq	$t2, 0xff0000, CheckTopRight
		addiu	$v1, $v1, 1			#Increment the neighbor counter

		CheckTopRight:	
		#if ((($t1 + 1) % 64) == 0); we're on the right border so don't check the top right and move on to the middle row
		addi	$t2, $t1, 1	#$t2 = $t1 + 1
		rem	$t2, $t2, 64	#$t2 = $t2 % 64
		beq	$t2, $zero, CheckMiddle
	
		#if the value at ($t1 - 63) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $t1, -63			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, 0x000000, CheckTopRight	#If the value at $t2 is either black or red, don't increment
		beq	$t2, 0xff0000, CheckTopRight
		addiu	$v1, $v1, 1			#Increment the neighbor counter

	CheckMiddle:
		#if (($t1 % 64) == 0); don't check the middle left and move on to the right
		addi	$t2, $t1, 0	#$t2 = $t1
		rem	$t2, $t2, 64	#$t2 = $t2 % 64
		beq	$t2, $zero, CheckMiddleRight
	
		CheckMiddleLeft:
		#if the value at ($t1 - 1) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $t1, -1			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, 0x000000, CheckMiddleRight	#If the value at $t2 is either black or red, don't increment
		beq	$t2, 0xff0000, CheckMiddleRight
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
		CheckMiddleRight:
		#if ((($t1 + 1) % 64) == 0); don't check the middle right and move on to the bottom row
		addi	$t2, $t1, 1	#$t2 = $t1 + 1
		rem	$t2, $t2, 64	#$t2 = $t2 % 64
		beq	$t2, $zero, CheckBottom
	
		#if the value at ($t1 + 1) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $t1, 1			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, 0x000000, CheckBottom	#If the value at $t2 is either black or red, don't increment
		beq	$t2, 0xff0000, CheckBottom
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
	CheckBottom:
		#if (($t1 + 64) > $t0); don't check the entire bottom row and return
		addi	$t2, $t1, 64	#$t2 = $t1 + 64
		bgt	$t2, $t0, Return

		#If (($t1 % 64) == 0); don't check bottom left and move on to the middle
		addi	$t2, $t1, 0	#$t2 = $t1 + 64
		rem	$t2, $t2, 64	#$t2 = $t2 % 64
		beq	$t2, $zero, CheckBottomMiddle
	
		CheckBottomLeft:
		#if the value at ($t1 + 63) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $t1, 63			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, 0x000000, CheckBottomMiddle	#If the value at $t2 is either black or red, don't increment
		beq	$t2, 0xff0000, CheckBottomMiddle
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
		CheckBottomMiddle:
		#If we can check the bottom at all we must be able to check under the current position
		#if the value at ($t1 + 64) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $t1, 64			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, 0x000000, CheckBottomRight	#If the value at $t2 is either black or red, don't increment
		beq	$t2, 0xff0000, CheckBottomRight
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
		#if ((($t1 + 1) % 64) == 0); don't check the bottom right and return
		addi	$t2, $t1, 1	#$t1 = $a0 + 1
		rem	$t2, $t2, 64	#t1 = $t1 % 64
		beq	$t2, $zero, Return
	
		CheckBottomRight:
		#if the value at ($t1 + 65) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $t1, 65			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, 0x000000, CheckBottom	#If the value at $t2 is either black or red, don't increment
		beq	$t2, 0xff0000, CheckBottom
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
	Return:
		#v1 returns the number of neighbors
		jr	$ra

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
