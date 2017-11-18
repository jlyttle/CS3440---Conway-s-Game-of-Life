#Jonathan Lyttle
#jbl160530
#MIPS Implementation of Conway's Game of Life with Bitmap Display
#
.data
#golArray:	.space		#Make this a dynamic array later.
gridSize:	.byte	0	#The width or length of the working grid taken from the user in a menu.
sleepTime:	.byte	0	#The amount of time to wait before displaying the next generation (in ms).
patternPrompt:	.asciiz	"Choose a pattern (1 for random, 2 for glider gun)"
errorMessage3:	.asciiz	"Unable to read input, try again."
errorMessage4:	.asciiz	"Enter a correct value for pattern choice."

.text
Main:

PromptForGridSize:
	li	$s0, 128	#Debug
PromptForSleepTime:

InputValidation: #Check if the grid size (64, 128, 512, or 1024) and sleep time (0-) are valid and reprompt if not.

PatternMenu: #Choose either the glider gun pattern or a random pattern.
	li	$v0, 51
	la	$a0, patternPrompt	#Prompt user for pattern choice
	syscall
	
	beq	$a1, -1, Error3		#If input is unreadable, error
	beq	$a1, -2, Exit
	beq	$a1, -3, Error3
	
	blt	$a0, 1, Error4		#If the choice is greater than 3 or less than 1, error
	bgt	$a0, 2, Error4
	
	move	$s2, $a0

InitializeArray:	#Create the array with the specified size and chosen pattern.

DisplayGeneration:	#Display the current generation in the bitmap display.
	mul	$t0, $s0, $s0	#Store the total size of the array in $t0.
	li	$t1, 0		#Initialize variable for current position.
DrawLoop:
	add	$a0, $t1, $zero	#Load current position as an argument for GetDisplayAddress.
	jal	GetDisplayAddress
	move	$a0, $v0
	li	$a1, 0x00ff00	#Debug
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

Error3:
	li	$v0, 55
	li	$a1, 0
	la	$a0, errorMessage3
	syscall
	j	PatternMenu
	
Error4:
	li	$v0, 55
	li	$a1, 0
	la	$a0, errorMessage4
	syscall
	j	PatternMenu

Exit:
	li	$v0, 10
	syscall
