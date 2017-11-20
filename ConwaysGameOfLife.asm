#Jonathan Lyttle
#jbl160530
#MIPS Implementation of Conway's Game of Life with Bitmap Display
#Works with 8 pixel width and height and 512 display width and height
#Or 16 unit width and height and 1024 display width and height

#GLOBAL VARIABLES:
#$s0 = grid width/length
#$s1 = births and deaths array address
#$s2 = chosen pattern
#$s3 = Black color (blank)
#$s4 = White color (Living)
#$s5 = Total area of the array (64x64)
#$s6 = Dying cell color (white minus grey)
#$t9 = Current generation

.data
birthsAndDeathsArray:	.space	16384		#An array for tracking births and deaths, the same size as the bitmap display (64x64 pixels expressed in words)
gridSize:		.word	64		#The width or length of the working grid.
gridArea:		.word	4096
blankCellColor:		.word	0x000000	#The color chosen for a blank cell
livingCellColor:	.word	0xffffff	#The color chosen for a living cell
deadCellColor:		.word	0xeeeeee	#The starting color for a dead cell
patternPrompt:		.asciiz	"Choose a pattern (1 for random, 2 for glider gun, 3 for 10-line)"
continuePrompt:		.asciiz	"Press space to continue another generation, 1 for a random pattern, 2 for glider gun, 3 for 10-line or p to auto-advance.\n\n"
errorMessage1:		.asciiz	"Unable to read input, try again."
errorMessage2:		.asciiz	"Enter a correct value for pattern choice."

.text
Main:
	lw	$s0, gridSize			#Load the grid size into $s0
	la	$s1, birthsAndDeathsArray	#Load the birth and death tracking array into $s1
	lw	$s3, blankCellColor
	lw	$s4, livingCellColor
	lw	$s5, gridArea
	lw	$s6, deadCellColor

PatternMenu: 					#Choose either the glider gun, 10-line pattern or a random pattern.
	li	$v0, 51
	la	$a0, patternPrompt		#Prompt user for pattern choice
	syscall
	
	beq	$a1, -1, Error1			#If input is unreadable, error
	beq	$a1, -2, Exit
	beq	$a1, -3, Error1
	
	blt	$a0, 1, Error2			#If the choice is greater than 3 or less than 1, error
	bgt	$a0, 3, Error2
	
	move	$s2, $a0			#Store pattern choice in $s2

ArrayInit:	#Initialize all values in the array to 0 and display
	li	$t1, 0				#Current position
	mul	$t3, $s5, 4			#Area size in words to use with the branch in the loop
	li	$t9, 0				#Reinitialize current generation to 0
	InitializeBirthsAndDeathsArray:
	addu	$t2, $s1, $t1					#Get address for current array index into $t2
	sw	$s3, ($t2)					#Store 0 at the array index (for blank)
	addiu	$t1, $t1, 4					#Advance the pointer to the next word
	ble	$t1, $t3, InitializeBirthsAndDeathsArray	#Loop until the array is filled
	jal	DisplayGeneration

	#Create the array with the chosen pattern.
	beq	$s2, 2, Preset1			#Initialize the glider gun pattern
	beq	$s2, 3, Preset2			#Initialize the 10-cell row pattern

	#If the user chose random, we want to intialize the array with a chance of having a living cell. To have more space, we'll choose a third of a chance of spawning.
	li	$t0, 0				#Current position
	Random:	
	li	$v0, 42				#Choose an int between a range.
	li	$a1, 10				#Set 10 as the upper bound (0 is the lower bound).	
	syscall					#Get the random number
	addiu	$t0, $t0, 1			#Increment position
	blt	$a0, 3, LivingCell		#If the random is less than 5, set cell as living
	blt	$t0, $s5, Random		#Else, if we're still less than the grid area, loop back to random
	j	WriteGenToConsole
	LivingCell:
	addu	$a0, $t0, $zero			#Draw the cell to the grid
	jal	DrawForPreset
	blt	$t0, $s5, Random		#Loop while position is less than the grid area
	
	j	WriteGenToConsole		#Write the current generation number to console (gen 0)
	
	Preset1:
	#Glider gun preset
	li	$a0, 452
	jal	DrawForPreset
	li	$a0, 453
	jal	DrawForPreset		#Left square
	li	$a0, 516
	jal	DrawForPreset
	li	$a0, 517
	jal	DrawForPreset
	
	li	$a0, 461
	jal	DrawForPreset
	li	$a0, 462
	jal	DrawForPreset		#Left structure
	li	$a0, 526
	jal	DrawForPreset
	li	$a0, 524
	jal	DrawForPreset
	li	$a0, 588
	jal	DrawForPreset
	li	$a0, 589
	jal	DrawForPreset

	li	$a0, 474
	jal	DrawForPreset		#Right structure	
	li	$a0, 475
	jal	DrawForPreset
	li	$a0, 410
	jal	DrawForPreset
	li	$a0, 347
	jal	DrawForPreset
	li	$a0, 412
	jal	DrawForPreset
	li	$a0, 348
	jal	DrawForPreset
	
	li	$a0, 358
	jal	DrawForPreset
	li	$a0, 422
	jal	DrawForPreset		#Right square
	li	$a0, 423
	jal	DrawForPreset
	li	$a0, 359
	jal	DrawForPreset
	
	li	$a0, 596
	jal	DrawForPreset
	li	$a0, 597
	jal	DrawForPreset
	li	$a0, 660
	jal	DrawForPreset		#Left glider
	li	$a0, 724
	jal	DrawForPreset
	li	$a0, 662
	jal	DrawForPreset
	
	li	$a0, 807
	jal	DrawForPreset
	li	$a0, 808
	jal	DrawForPreset
	li	$a0, 873
	jal	DrawForPreset		#Right glider
	li	$a0, 871
	jal	DrawForPreset
	li	$a0, 935
	jal	DrawForPreset
	
	li	$a0, 1116
	jal	DrawForPreset
	li	$a0, 1180
	jal	DrawForPreset
	li	$a0, 1117
	jal	DrawForPreset		#Middle glider
	li	$a0, 1118
	jal	DrawForPreset
	li	$a0, 1245
	jal	DrawForPreset
	
	j	WriteGenToConsole
	
	Preset2:
	#render a 10-cell row to the grid
	li	$t1, 601
	li	$t2, 610
	jal	PresetLoop1
	
	li	$t1, 1369
	li	$t2, 1378
	jal	PresetLoop1
	
	li	$t1, 2137
	li	$t2, 2146
	jal	PresetLoop1
	
	li	$t1, 2905
	li	$t2, 2914
	jal	PresetLoop1
	
	j	WriteGenToConsole
	
	PresetLoop1:
	#Store return address in the stack
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	addu	$a0, $zero, $t1	#Start at pos 600
	jal	DrawForPreset
	addiu	$t1, $t1, 1
	ble	$t1, $t2, PresetLoop1
	
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra

GameOfLife:
	addiu	$t9, $t9, 1
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
		bne	$t2, $s4, Dead			#If the color we got was not white, the current cell is dead
		Live:					#The current cell is alive if the value is white
			#if $v1 returned less than 2, set this cell as dead
			blt	$v1, 2, SetDead		#Set as dead if there are fewer than 2 neighbors
			bgt	$v1, 3, SetDead		#Set as dead if there are greater than 3 neighbors
			j	SetAlive
			SetDead:
				sw	$s6, ($t4)	#Set as white minus grey, to prepare for transition to dead
				j	CheckLoop
				
		Dead:
			#Set the cell as black if it wasn't already
			sw	$s3, ($t4)
		
			#if $v1 returned 3, set this cell as alive
			beq	$v1, 3, SetAlive
			j	CheckLoop
			SetAlive:
				sw	$s4, ($t4)	#Alive is white
				
		CheckLoop:	#Check if we still need to loop through the rest of the display
		addiu	$t5, $t5, 1			#Advance current position by 1
		beq	$t5, $s5, DisplayAndWrite	#If the current position is greater than the total size, start displaying the births and deaths of this generation
		j	GOLLoop
		DisplayAndWrite:
		jal	DisplayGeneration
		j	WriteGenToConsole

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
		bne	$t2, $s4, CheckTopMiddle	#If the value at $t2 is not white, don't increment
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
		CheckTopMiddle:
		#if we can check top row at all, we can also check top middle
		#if the value at ($t1 - 64) is the color white or green, we have a neighbor and we increment the counter
		subu	$a0, $t1, $s0			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		bne	$t2, $s4, CheckTopRight		#If the value at $t2 is not white, don't increment
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
		bne	$t2, $s4, CheckMiddle		#If the value at $t2 is not white, don't increment
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
		bne	$t2, $s4, CheckMiddleRight	#If the value at $t2 is not white, don't increment
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
		bne	$t2, $s4, CheckBottom		#If the value at $t2 is not white, don't increment
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
		bne	$t2, $s4, CheckBottomMiddle	#If the value at $t2 is not white, don't increment
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
		CheckBottomMiddle:
		#If we can check the bottom at all we must be able to check under the current position
		#if the value at ($t1 + 64) is the color white or green, we have a neighbor and we increment the counter
		addu	$a0, $t1, $s0			#$a0 is the new position to check
		jal	GetDisplayAddress		#Calculate the address of the pixel
		lw	$t2, ($v0)			#Load the value at this location into $t2
		bne	$t2, $s4, CheckBottomRight	#If the value at $t2 is not white, don't increment
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
		bne	$t2, $s4, Return		#If the value at $t2 is not white, don't increment
		addiu	$v1, $v1, 1			#Increment the neighbor counter
	
	Return:
		#v1 returns the number of neighbors
		lw	$ra, ($sp)
		addi	$sp, $sp, 4
		jr	$ra

DisplayGeneration:	#Display the current generation in the bitmap display from the births and deaths array.
	#Store return address in the stack
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
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
		
	#Loop 14 times until all grey pixels are transitioned to black
	li	$t1, 0
	li	$t4, 0
	TransitionToBlack:
		add	$a0, $t1, $zero
		jal	GetDisplayAddress
		move	$a0, $v0
		mul	$t2, $t1, 4
		addu	$t2, $t2, $gp
		lw	$t3, ($t2)
		#if this color is not white and not black, subtract 0x111111 and draw
		beq	$t3, $s3, Increment
		beq	$t3, $s4, Increment
		subu	$t3, $t3, 0x111111
		move	$a1, $t3
		jal	Draw
		Increment:
		addiu	$t1, $t1, 1
		bne	$t1, $s5, TransitionToBlack
		
	addiu	$t4, $t4, 1
	move	$t1, $zero
	bne	$t4, 14, TransitionToBlack
	
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
WriteGenToConsole:
	#Display current generation number in the cli
	li	$v0, 1
	addu	$a0, $t9, $zero
	syscall
	li	$v0, 11
	addiu	$a0, $zero, 10
	syscall
	beq	$t8, 1, GameOfLife	#jump back up if auto advance is on
	li	$v0, 4
	la	$a0, continuePrompt
	syscall
	li	$v0, 12
	syscall
	beq	$v0, 32, GameOfLife		#If the user hits space, loop back to the algorithm
	beq	$v0, 49, SetRandomPattern	#If the user hits 1, change to a different random pattern
	beq	$v0, 50, SetGliderPattern	#If the user hits 2, change to the glider pattern
	beq	$v0, 51, SetTenLinePattern	#If the user hits 3, change to the ten line pattern
	beq	$v0, 112, SetAutoOn		#If the user hits p or P, change to auto advance
	beq	$v0, 80, SetAutoOn
	j	Exit
	
	SetAutoOn:
		li	$t8, 1
		j	GameOfLife
		
	SetRandomPattern:
		li	$s2, 1			#Chosen pattern is random
		j	ArrayInit
	
	SetGliderPattern:
		li	$s2, 2			#Chosen pattern is glider
		j	ArrayInit
		
	SetTenLinePattern:
		li	$s2, 3			#Chosen pattern is 10-line
		j	ArrayInit
	
GetDisplayAddress:	#Gets the address for the bitmap display given a position in $a0.
	mul	$v0, $a0, 4	#Multiply current position by 4 to get word size
	add	$v0, $v0, $gp	#Add the global pointer from the bitmap display
	jr	$ra
	
Draw:	#Draws the pixel to the bitmap display given $a0 (location) and $a1 (color)
	sw	$a1, ($a0)
	jr	$ra

DrawForPreset:	#Draws the pixel to the grid (used in preset)
	#Store return address in the stack
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
		
	jal	GetDisplayAddress
	move	$a0, $v0
	addu	$a1, $s4, 0
	jal	Draw
	
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

Error1:
	li	$v0, 55
	li	$a1, 0
	la	$a0, errorMessage1
	syscall
	j	PatternMenu
	
Error2:
	li	$v0, 55
	li	$a1, 0
	la	$a0, errorMessage2
	syscall
	j	PatternMenu

Exit:
	li	$v0, 10
	syscall
