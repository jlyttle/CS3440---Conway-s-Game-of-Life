#Jonathan Lyttle
#jbl160530
#MIPS Implementation of Conway's Game of Life with Bitmap Display
#
.data
golArray:	.space		#Make this a dynamic array later.
gridSize:	.byte	0	#The width or length of the working grid taken from the user in a menu.
sleepTime:	.byte	0	#The amount of time to wait before displaying the next generation (in ms).

.text
InputValidation: #Check if the grid size () and  
PatternMenu:
	#if the size of the grid is greater than or equal to 36 we can offer    