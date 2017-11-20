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
#$s5 = Total area of the array (64x64)

.data
birthsAndDeathsArray:	.space	16384	#An array for tracking births and deaths, the same size as the bitmap display (64x64 pixels expressed in words)
gridSize:		.word	64	#The width or length of the working grid.
gridArea:		.word	4096
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
	lw	$s5, gridArea
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

	Random:	
	#If the user chose random, we want to intialize the array with a chance of having a living cell. To have more space, we'll choose a third of a chance of spawning.
	li	$t0, 3	#Initialize $t0 to 3 (the value we compare with).
	li	$v0, 42	#Choose an int between a range.
	li	$a1, 9	#Set 9 as the upper bound (0 is the lower bound).
	
	Preset1:
	#DEBUG: render a single pixel on the grid
	la	$s1, birthsAndDeathsArray	#Load the birth and death tracking array into $s1
	#srl	$a0, $s5, 1			#Get the total size of the space, SRL, and add 32 to get the middle
	#addiu	$a0, $a0, 32
	li	$a0, 3
	jal	GetDisplayAddress	#Get the address for that space
	move	$a0, $v0
	addu	$a1, $s4, 0
	jal	Draw			#Draw the pixel in that space
	li	$a0, 4
	jal	GetDisplayAddress	#Get the address for that space
	move	$a0, $v0
	addu	$a1, $s4, 0
	jal	Draw			#Draw the pixel in that space
	li	$a0, 5
	jal	GetDisplayAddress	#Get the address for that space
	move	$a0, $v0
	addu	$a1, $s4, 0
	jal	Draw			#Draw the pixel in that space
	
	#render a 10-cell row to the grid
	#li	$t1, 352
	Preset2:
	#addu	$a0, $zero, $t1	#Start at pos 352
	#jal	GetDisplayAddress
	#move	$a0, $v0
	#addu	$a1, $s4, 0
	#jal Draw
	#addiu	$t1, $t1, 1
	#ble	$t1, 362, Preset2
	
	li	$t1, 0	
	mul	$t3, $s5, 4		#Area size in words to use with the branch in the loop
	InitializeBirthsAndDeathsArray:
	addu	$t2, $s1, $t1		#Get address for current array index into $t2
	sw	$s3, ($t2)		#Store 0 at the array index (for blank)
	addiu	$t1, $t1, 4		#Advance the pointer to the next word
	ble	$t1, $t3, InitializeBirthsAndDeathsArray	#Loop until the array is filled

GameOfLife:
	li	$t5, 0			#Set $t5 to the current position
	
	GOLLoop:	
		#For each pixel in the display array, run the algorithm
		addiu	$a0, $t5, 0			#Copy the current position into argument
		jal	GOLAlgorithm			#Run the algorithm given position. # neighbors in $v1
		addiu	$a0, $t5, 0			#Copy current position to argument
		jal	GetDisplayAddress		#Get address of pixel in $v0
		lw	$t2, ($v0)			#$t2 = color at pixel's address
		mul	$t4, $t5, 4			#Convert current position to a word value in $t4
		addu	$t4, $t4, $s1			#Store the base address in the births and deaths array plus the position offset as $t4
		beq	$t2, $s3, Dead			#If the color we got was black, the current cell is dead
		Live:					#The current cell is alive if the value isn't blank
			#if $v1 returned less than 2, set this cell as dead
			blt	$v1, 2, SetDead		#Set as dead if there are fewer than 2 neighbors
			bgt	$v1, 3, SetDead		#Set as dead if there are greater than 3 neighbors
			j	SetAlive
			SetDead:
				sw	$s3, ($t4)
				j	CheckLoop
		Dead:
			#if $v1 returned 3, set this cell as alive
			beq	$v1, 3, SetAlive
			j	CheckLoop
			SetAlive:
				sw	$s4, ($t4)
		
		CheckLoop:	#Check if we still need to loop through the rest of the display
		addiu	$t5, $t5, 1			#Advance current position by 1
		beq	$t5, $s5, DisplayGeneration	#If the current position is greater than the total size, start displaying the births and deaths of this generation
		j	GOLLoop

	GOLAlgorithm:
		#Store return address in the stack
		addi	$sp, $sp, -4
		sw	$ra, ($sp)
	
		#$t1 is the absolute position of the pixel, $s5 is the total size of the grid, $s0 is width of one line, $v1 is the neighbor counter.
		li	$v1, 0		#initialize counter to 0
		move	$t1, $a0	#Move the argument to $t1 to work with
	
		#if ($t1 < 64); we're on the top row so move on to checking the middle row
		blt	$t1, $s0, CheckMiddle
	CheckTop:
		#if (($t1 % 64) == 0); we're on the left border so don't check top left and move on to the middle
		rem	$t2, $t1, $s0	#$t2 = $t1 % 64
		beq	$t2, $zero, CheckTopMiddle

		CheckTopLeft:
		#if the value at ($t1 - 65) is the color white or green, we have a neighbor and we increment the counter
		subu	$a0, $t1, $s0			#$a0 is the new position to check
		subiu	$a0, $a0, 1
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, $s3, CheckTopMiddle	#If the value at $t2 is either black or red, don't increment
		#beq	$t2, 0xff0000, CheckTopMiddle
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
		CheckTopMiddle:
		#if we can check top row at all, we can also check top middle
		#if the value at ($t1 - 64) is the color white or green, we have a neighbor and we increment the counter
		subu	$a0, $t1, $s0			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, $s3, CheckTopRight		#If the value at $t2 is either black or red, don't increment
		#beq	$t2, 0xff0000, CheckTopRight
		addiu	$v1, $v1, 1			#Increment the neighbor counter

		CheckTopRight:	
		#if ((($t1 + 1) % 64) == 0); we're on the right border so don't check the top right and move on to the middle row
		addiu	$t2, $t1, 1	#$t2 = $t1 + 1
		rem	$t2, $t2, $s0	#$t2 = $t2 % 64
		beq	$t2, $zero, CheckMiddle
	
		#if the value at ($t1 - 63) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $s0, -1
		subu	$a0, $t1, $a0			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, $s3, CheckMiddle	#If the value at $t2 is either black or red, don't increment
		#beq	$t2, 0xff0000, CheckTopRight
		addiu	$v1, $v1, 1			#Increment the neighbor counter

	CheckMiddle:
		#if (($t1 % 64) == 0); don't check the middle left and move on to the right
		rem	$t2, $t1, $s0	#$t2 = $t1 % 64
		beq	$t2, $zero, CheckMiddleRight
	
		CheckMiddleLeft:
		#if the value at ($t1 - 1) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $t1, -1			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, $s3, CheckMiddleRight	#If the value at $t2 is either black or red, don't increment
		#beq	$t2, 0xff0000, CheckMiddleRight
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
		CheckMiddleRight:
		#if ((($t1 + 1) % 64) == 0); don't check the middle right and move on to the bottom row
		addi	$t2, $t1, 1	#$t2 = $t1 + 1
		rem	$t2, $t2, $s0	#$t2 = $t2 % 64
		beq	$t2, $zero, CheckBottom
	
		#if the value at ($t1 + 1) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $t1, 1			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, $s3, CheckBottom	#If the value at $t2 is either black or red, don't increment
		#beq	$t2, 0xff0000, CheckBottom
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
	CheckBottom:
		#if (($t1 + 64) > $s5); don't check the entire bottom row and return
		addu	$t2, $t1, $s0	#$t2 = $t1 + 64
		bgt	$t2, $s5, Return

		#If (($t1 % 64) == 0); don't check bottom left and move on to the middle
		rem	$t2, $t1, $s0	#$t2 = $t1 % 64
		beq	$t2, $zero, CheckBottomMiddle
	
		CheckBottomLeft:
		#if the value at ($t1 + 63) is the color white or green, we have a neighbor and we increment the counter
		addi	$a0, $s0, -1
		addu	$a0, $a0, $t1			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, $s3, CheckBottomMiddle	#If the value at $t2 is either black or red, don't increment
		#beq	$t2, 0xff0000, CheckBottomMiddle
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
		CheckBottomMiddle:
		#If we can check the bottom at all we must be able to check under the current position
		#if the value at ($t1 + 64) is the color white or green, we have a neighbor and we increment the counter
		addu	$a0, $t1, $s0			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, $s3, CheckBottomRight	#If the value at $t2 is either black or red, don't increment
		#beq	$t2, 0xff0000, CheckBottomRight
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
		CheckBottomRight:
		#if ((($t1 + 1) % 64) == 0); don't check the bottom right and return
		addiu	$t2, $t1, 1	#$t1 = $a0 + 1
		rem	$t2, $t2, $s0	#t1 = $t1 % 64
		beq	$t2, $zero, Return
		
		#if the value at ($t1 + 65) is the color white or green, we have a neighbor and we increment the counter
		addiu	$a0, $t1, 1			#$a0 is the new position to check
		addu	$a0, $a0, $s0
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		beq	$t2, $s3, Return		#If the value at $t2 is either black or red, don't increment
		#beq	$t2, 0xff0000, Return
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
	Return:
		#v1 returns the number of neighbors
		lw	$ra, ($sp)
		addi	$sp, $sp, 4
		jr	$ra

DisplayGeneration:	#Display the current generation in the bitmap display from the births and deaths array.
	#DEBUG: Is it the display code at fault or the array? Let's add white to the first pixel.
	#sw	$s4, ($s1)	#It's the array... So is it the array or the algorithm (really hope it's not the algorithm)

	#mulu	$t0, $s0, $s0	#Multiply width by height (same value) to get total size.
	li	$t1, 0		#Initialize variable for current position.
	DrawLoop:
		add	$a0, $t1, $zero		#Load current position as an argument for GetDisplayAddress.
		jal	GetDisplayAddress
		move	$a0, $v0		#Move display address to arg 0
		#Decide the color by looking at the births and deaths array at this location
		mul	$t2, $t1, 4		#Get the word value of the position
		addu	$t2, $t2, $s1		#Add word offset to base address of array
		lw	$t3, ($t2)		#Load the color from the array index
		move	$a1, $t3		#Move the color into argument 1
		jal	Draw			#Draw the pixel on screen
		addiu	$t1, $t1, 1		#Increment position
		bne	$t1, $s5, DrawLoop	#Loop until we've filled the whole display
	
		j	Exit #DEBUG
	
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
