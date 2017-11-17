#Jonathan Lyttle
#jbl160530
#MIPS Implementation of Conway's Game of Life with Bitmap Display
#
.data
golArray:	.space		#Make this a dynamic array later.
gridSize:	.byte	0	#The width or length of the working grid taken from the user in a menu.
sleepTime:	.byte	0	#The amount of time to wait before displaying the next generation (in ms).
patternPrompt:	.asciiz	"Choose a pattern (1 for random, 2 for glider gun)"

.text
Main:

InputValidation: #Check if the grid size (64, 128, 512, or 1024) and sleep time (0-) are valid and reprompt if not.

PatternMenu: #Choose either the glider gun pattern or a random pattern.
	li	$v0, 51
	la	$a0, patternPrompt
	syscall
	
	beq	$a1, -1, Error

Error:
	li	$v0, 

Exit:
	li	$v0, 10
	syscall