# set pixel to 16x16
# set dimension to 512x512 
# set base address to $gp

# Register used: 
# $a0 = X
# $a1 = Y
# $a2 = color
# $gp = base address at (0, 0)
# $s1 = address	of current location
# $s0 = shape representation
# $t2 = form representation
# $t3 = action representation 
# $t0 = i or counter
# $t8 = random int for current shape
# $t9 = random int for next shape

# Each number represent a shape
# lshape1 = 0
# Jshape1 = 1
# Lshape1 = 2
# Oshape  = 3

# Each number represent an action
# draw = 0
# black out = 1
# check = 2

#########################################################################################
# SET CONSTANTS
#******************************************************************#
# set width and height of screen in pixels
# dimension / pixel
.eqv	WIDTH	32	# 512 / 16 = 32
.eqv	HEIGHT	32	# 512 / 16 = 32
# colors
.eqv	RED	0x00FF0000
.eqv	GREEN	0x0000FF00
.eqv	BLUE	0x000000FF
.eqv	YELLOW	0x00FFFF00
.eqv	ORANGE	0x00FF8000
#******************************************************************#
#########################################################################################

#########################################################################################
# MAIN INSTRUCTIONS
#******************************************************************#
.text
main: 
	jal	draw_mainborder		# draw main border
	jal	draw_smallborder	# draw small box that show the next shape
	jal	random		# generate a random int
	li	$t2, 1		# form = 1
	li	$t3, 0		# action = draw
	
	# shape start at (8, 1)
 	# shape inside main border
	li	$a0, 8		# X = 8
	li	$a1, 1		# Y = 1
	jal	shape_option	# draw shape
	move	$t8, $s0	# $t8 = random int for shape in main border
	
	jal	show_next_shape	# display random shape in the small box
	move	$t9, $s0	# $t9 = random int for shape in small box
	
	# give keyboard control to the shape in main border
	li	$a0, 8
	li	$a1, 1
	move	$s0, $t8	# $s0 = shape in main border
	
input_loop: 
	# check for input
	lw	$t1, 0xffff0000	  	# if input is available, $t1 is true
	beq	$t1, $0, input_loop	# branch to input_loop if input is not available
	
	# process inputs
	lw	$s2, 0xffff0004		# $s2 = location of input
	beq	$s2, 9, exit		# branch to exit if input = tab
	beq	$s2, 32, next		# branch to next if input = space
	beq	$s2, 10, clear		# branch to clear if input = ENTER			
	beq	$s2, 119, rotate	# branch to up if input = w
	beq	$s2, 115, down		# branch to down if input = s
	beq	$s2, 97, left		# branch to left if input = a
	beq	$s2, 100, right		# branch to right if input = d
	j 	input_loop		# branch to input_loop if invalid input
	
rotate: # change the form of shape
	# check whether action is allowed (any colored pixel beside the shape?)
	li	$t3, 2		# action = check
	jal	shape_option	
 	jal	rotation	# rotate to next form
	j	input_loop	

down: 	# move shape down
	li	$t3, 2		# action = check
	jal	shape_option
	li	$t3, 1		# action = black out
	jal	shape_option	# black out the shape	
	addi	$a1, $a1, 1	# move one space down
	li	$t3, 0		# action = draw
	jal	shape_option	# draw the shape
	j	input_loop
	
left: 	# move shape left
	li	$t3, 2		# action = check
	jal	shape_option
	li	$t3, 1		# action = black out
	jal	shape_option	# black out the shape
	addi	$a0, $a0, -1	# move one space left
	li	$t3, 0		# action = draw
	jal	shape_option	# draw the shape
	j	input_loop	
	
right: 	# move shape right
	li	$t3, 2		# action = check
	jal	shape_option
	li	$t3, 1		# action = black out
	jal	shape_option	# black out the shape
	addi	$a0, $a0, 1	# move one space right
	li	$t3, 0		# action = draw
	jal	shape_option	# draw the shape
	j	input_loop
		
next: 	# draw and give control to the next shape in the main border
	jal	check_fail	# check if program should continue (any colored pixel at the top row?)
	# set shape location at (8, 1)
	li	$a0, 8		
	li	$a1, 1	
	li	$t2, 1		# form = 1
	li	$t3, 0		# action = draw
	move	$s0, $t9	# $s0 = shape in the small box (next shape)
	jal	shape_option	# draw the shape
	move	$t8, $s0	# $t8 = random int of shape in main border
	jal	black_next_shape	# black out the shape in small box
	jal	show_next_shape	# display next random shape in the small box
	move	$t9, $s0	# $t9 = random int of shape in small box (next shape)
	# give keyboard control to the shape in main border
	# set shape location at (8, 1)
	li	$a0, 8		
	li	$a1, 1
	move	$s0, $t8	# $s0 = shape in main border
	j	input_loop	

clear: 	# clear a row if it is filled
	# check if a row is filled. If it is, clear the row and move all rows above down one space
	jal	check_fill	
	addi	$a1, $a1, 1	# Y + 1 (because all rows were moved down one space)
	addi	$s1, $s1, 128	# move location of current pixel down one space
	j	input_loop	
	
exit:  	# exit the program
	li	$v0, 10
	syscall
#******************************************************************#
#########################################################################################

#########################################################################################
# FUNCTIONS

#******************************************************************#
# function to generate random int with range (0-3)
random: 
	addi	$sp, $sp, -4	
	sw	$a1, ($sp)	# store the value in $a1 on stack
	
	li	$v0, 42
	li	$a1, 4
	syscall
	add	$s0, $a0, $0	# $s0 = random int
	
	lw	$a1, ($sp)	# store value back to $a1
	addi	$sp, $sp, 4
	jr	$ra
#******************************************************************#

#******************************************************************#
# function to display next shape in the small box
show_next_shape: 
	addi	$sp, $sp, -8	
	sw	$ra, 4($sp)
	sw	$s1, ($sp)
	
	li	$t3, 0		# action = draw
	jal	random		# get ranodm int
	# draw shape inside small box
	# shape start at (25, 8)
	li	$a0, 25
	li	$a1, 8
	jal	shape_option	# draw the shape
	
	lw	$s1, ($sp)
	lw	$ra, 4($sp)	
	addi	$sp, $sp, 8
	jr	$ra
#******************************************************************#

#******************************************************************#
# function to black out the shape in the small box
black_next_shape: 
	addi	$sp, $sp, -8	
	sw	$ra, 4($sp)
	sw	$s1, ($sp)
	
	# set shape location at (25, 8)
	li	$a0, 25		
	li	$a1, 8
	li	$t3, 1		# action = black out
	jal	shape_option	# black out the shape
	
	lw	$s1, ($sp)
	lw	$ra, 4($sp)	
	addi	$sp, $sp, 8
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for implementing rotation of shape
rotation: 
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	beq	$s0, 0, two_form	# branch to two_form if it is a l shape
	beq	$s0, 1, four_form	# branch to four_form if it is a J shape
	beq	$s0, 2, four_form	# branch to four_form if it is a L shape
	beq	$s0, 3, exit_rotation	# leave this method if it is a O shape (no rotation)

two_form: # for shapes that have 4 forms 
	li	$t3, 1		# action = black out
	jal	shape_option	# black out the shape according to its current form 
	addi	$t2, $t2, 1	# switch to the next form 
	ble 	$t2, 2, cout1	# branch to cout1 if form <= 2
	li	$t2, 1		# form > 2 so reset form to 1
cout1: 	li	$t3, 0		# action = draw
	jal	shape_option	# draw the shape according to its current form
	j	exit_rotation	# leave this method

four_form: # for shapes that have 2 forms
	li	$t3, 1		# action = black out
	jal	shape_option	# black out the shape according to its current form
	blt	$t2, 4, cout2	# if form < 4, go to cout2
 	li	$t2, 1		# form >= 4, so reset form to 1
 	j	cout3		# branch to cout3
cout2: 	addi	$t2, $t2, 1	# switch to the next form
cout3: 	li	$t3, 0		# action = draw
	jal	shape_option	# draw the shape according its current form

	
exit_rotation:
 	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
#******************************************************************#

#******************************************************************#
# function to check if a row is filled. If it is, clear the row 
check_fill: 
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	la	$s3, 0x10008F48	# base startig address (address at location (19, 31))
	add	$s4, $s3, $0	# current address
	li	$t5, 0		# row count = 0
start: 	li	$t0, 18		# pixel count = 18
loop9: 	lw	$t4, ($s4)	# $t4 = color in the address
	beq	$t5, 29, end_check_fill	# if row count = 29, leave this method
	beq	$t4, 0, next_row1	# if color = black, branch to next1
	beq	$t0, 1, clear_row	# if pixel count = 1, branch to clear_row
	subi	$s4, $s4, 4	# go to the next address
	subi	$t0, $t0, 1	# pixel count--
	j	loop9		# branch to loop9 (continue checking color)

next_row1: 	
	addi	$t5, $t5, 1	# row count++
	mul	$t7, $t5, 32	# row count * 32
	sll	$t7, $t7, 2	# (row count * 32) * 4
	sub	$s4, $s3, $t7	# add to base address (go to the next row)
	j	start		# branch to start to check color for this row

clear_row: 	
loop10: sw	$0, ($s4)	# set color to black at that address
	addi	$s4, $s4, 4	# go to the next address
	addi	$t0, $t0, 1	# pixel count++
	bne	$t0, 19, loop10	# if pixel count != 19, branch to loop10 (continue black out pixel)
	# at this point, all pixels in the row is black out
	jal	move_rows	# move all rows above down
	j	next_row1	# branch to next1 (check next row)

end_check_fill: 
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
#******************************************************************#

#******************************************************************#
# function to move all the rows above the cleared row down
move_rows: 
	addi	$sp, $sp, -8
	sw	$t5, 4($sp)	# store line count on stack
	sw	$s4, ($sp)	# store current address on stack
	
	la	$s7, 0x10008084	# ending address (1, 1)
next_row2:	
	li	$t0, 18		# pixel count = 18
 	addi	$t5, $t5, 1	# row count++
	mul	$t7, $t5, 32	# row count * 32
	sll	$t7, $t7, 2	# (row count * 32) * 4
	sub	$s4, $s3, $t7	# add to base address (go to the next row)
loop11: lw	$t4, ($s4)	# $t4 = color in that pixel
	sw	$0, ($s4)	# set color to black
	addi	$s5, $s4, 128	# move down a row
	sw	$t4, ($s5)	# set color back to its orginal color
	beq	$t0, 1, next_row2	# if pixel count = 1, branch to next2 (go to the next row)
 	subi	$s4, $s4, 4	# go to the next address
	subi	$t0, $t0, 1	# pixel count--
	bne	$s4, $s7, loop11	# if current address != ending address, branch to loop11

exit_move_rows: 
	lw	$s4, ($sp)	# store current address back to $s4
	lw	$t5, 4($sp)	# store line count back to $t5
	addi	$sp, $sp, 8
	jr	$ra
#******************************************************************#

#******************************************************************#
# function to check and implement game failure
check_fail: 
	addi	$sp, $sp, -4		
	sw	$t0, ($sp)
	
	la	$s6, 0x10008084	# $s6 = address of location (1, 1)
	li	$t0, 1		# i = pixel counter = 1
loop12: lw	$t4, ($s6)	# $t4 = color at $s6
	beq	$t0, 19, exit_check_fail	# if i = 19 (end of row), leave this method (program continues)
	bne	$t4, 0, exit	# if color != black (shape reaches the top), exit the program
	addi	$s6, $s6, 4	# go to the next address
	addi	$t0, $t0, 1	# i++
	j	loop12		# branch to loop12
	
exit_check_fail: 
	lw	$t0, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
#******************************************************************#

#******************************************************************#
# function to check color at certain location
check_color: 
	lw	$t4, ($t6)		# $t4 = color at address
	bne	$t4, $0, input_loop	# if color != black, branch to input_loop
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for choosing the right shape to process 
shape_option: 
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
# options for l shape
	# l shape (form 1)
l1: 	bne	$s0, 0, J1	# branch if $s0 != 0
	bne	$t2, 1, l2	# branch if $t2 != 1
	jal	lshape1
	j	exit_shape_option

	# l shape (form 2)
l2: 	bne	$t2, 2, exit_shape_option	# leave this method if $t2 != 2	
	jal	lshape2
	j	exit_shape_option

# options for J shape
	# J shape (form 1)
J1: 	bne	$s0, 1, L1	# branch if $s0 != 1
	bne	$t2, 1, J2	# branch if $t2 != 1
	jal	Jshape1
	j	exit_shape_option
	
	# J shape (form 2)
J2: 	bne	$t2, 2, J3	# branch if $t2 != 2
	jal	Jshape2		
	j	exit_shape_option

	# J shape (form 3)
J3: 	bne	$t2, 3, J4	# branch if $t2 != 3
	jal	Jshape3
	j	exit_shape_option

	# J shape (form 4)
J4: 	bne	$t2, 4, exit_shape_option	# leave this method if $t2 != 4
	jal	Jshape4
	j	exit_shape_option
	
# options for L shape
	# L shape (form 1)
L1: 	bne	$s0, 2, O1	# branch if $s0 != 2
	bne	$t2, 1, L2	# branch if $t2 != 1
	jal	Lshape1
	j	exit_shape_option
	
	# L shape (form 2)
L2: 	bne	$t2, 2, L3	# branch if $t2 != 2
	jal	Lshape2
	j	exit_shape_option

	# L shape (form 3)
L3: 	bne	$t2, 3, L4	# branch if $t2 != 3
	jal	Lshape3
	j	exit_shape_option

	# L shape (form 4)
L4: 	bne	$t2, 4, exit_shape_option	# leave this method if $t2 != 4
	jal	Lshape4
	j	exit_shape_option
	
# option for O shape
	# O shape (form 1)
O1: 	bne	$s0, 3, exit_shape_option	# leave this method if $s0 != 3
	jal	Oshape

exit_shape_option: 
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
#******************************************************************#
#########################################################################################

#########################################################################################
# DRAW PIXEL

#******************************************************************#
# function for drawing a pixel
draw_pixel: 
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	# address = MEM + (4 * (X + (Y * WIDTH)))
	mul	$s1, $a1, WIDTH   # Y * WIDTH
	add	$s1, $s1, $a0	  # add X
	mul	$s1, $s1, 4	  # multiply by 4
	add	$s1, $s1, $gp	  # add to address at (0,0)
	sw	$a2, 0($s1)	  # store color at that location
	
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
#******************************************************************#
#########################################################################################

#########################################################################################
# DRAW BORDERS

#******************************************************************#
# function for drawing game border
draw_mainborder: 
	addi	$sp, $sp, -4
	sw	$ra, ($sp)

	la	$a2, RED	# store color
	jal	draw_pixel	# draw first pixel at (0, 0)
	
	li	$t0, 1		# $t0 = i = 1
loop1: 	# draw the left side of border
	addi	$a1, $a1, 1	# move pixel one space down 
	jal	draw_pixel	
	addi	$t0, $t0, 1	# i++
	blt	$t0, 32, loop1  # exit loop1 if i >= 32

	li	$t0, 1		# reset i = 1
loop2: 	# draw the bottom side of border
	addi	$a0, $a0, 1	# move pixel one space right 
	jal	draw_pixel
	addi	$t0, $t0, 1	# i++
	blt	$t0, 20, loop2  # exit loop2 if i >= 20

	li	$t0, 1		# reset i = 1
loop3: 	# draw the right side of border
	addi	$a1, $a1, -1	# move pixel one space up 
	jal	draw_pixel
	addi	$t0, $t0, 1	# i++
	blt	$t0, 32, loop3  # exit loop3 if i >= 32
	
	li	$t0, 1		# reset i = 1
loop4: 	# draw the top side of border
	addi	$a0, $a0, -1	# move pixel one space left 
	jal	draw_pixel
	addi	$t0, $t0, 1	# i++
	blt	$t0, 20, loop4  # exit loop4 if i >= 20
		
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for drawing border of box showing next available shape
draw_smallborder: 
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	li	$a0, 21
	li	$a1, 5	
	jal	draw_pixel	# draw pixel at (21, 5)
	
	li	$t0, 1		# i = 1
loop5: 	# draw the left side of border
	addi	$a1, $a1, 1	# move pixel one space down 
	jal	draw_pixel	
	addi	$t0, $t0, 1	# i++
	blt	$t0, 9, loop5   # exit loop5 if i >= 9

	li	$t0, 1		# reset i = 1
loop6: 	# draw the bottom side of border
	addi	$a0, $a0, 1	# move pixel one space right 
	jal	draw_pixel
	addi	$t0, $t0, 1	# i++
	blt	$t0, 10, loop6  # exit loop6 if i >= 10

	li	$t0, 1		# reset i = 1
loop7: 	# draw the right side of border
	addi	$a1, $a1, -1	# move pixel one space up 
	jal	draw_pixel
	addi	$t0, $t0, 1	# i++
	blt	$t0, 9, loop7   # exit loop7 if i >= 9
	
	li	$t0, 1		# reset i = 1
loop8: 	# draw the top side of border
	addi	$a0, $a0, -1	# move pixel one space left 
	jal	draw_pixel
	addi	$t0, $t0, 1	# i++
	blt	$t0, 10, loop8  # exit loop8 if i >= 10
	
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
#******************************************************************#
#########################################################################################

#########################################################################################
# DRAW SHAPES 

#******************************************************************#
# function for l-shape (form 1)
lshape1: 
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)	
	sw	$a0, 4($sp)	# store X value on stack
	sw	$a1, ($sp)	# store Y value on stack
	
	beq	$t3, 0, draw_l1		# branch to draw_l1 if action = draw
	beq	$t3, 1, black_l1	# branch to black_l1 if action = black
	beq	$t3, 2, check_l1	# branch to check_l1 if action = check
	
draw_l1: 
	la	$a2, GREEN	# set color to green
	j	action_l1	
black_l1: 
	li	$a2, 0		# set color to black

action_l1: 
	jal	draw_pixel	
	li	$t0, 1		# i = 1
a1: 	addi	$a1, $a1, 1	# move pixel one space down 
	jal	draw_pixel
	addi	$t0, $t0, 1	# i++
	blt	$t0, 4, a1      # branch to a1 if i < 4
	j	exit_lshape1
	
check_l1: 
	add	$s5, $s1, $0	# get current address of pixel
	beq	$s2, 119, check_rotatel1	# branch if input = w
	beq	$s2, 115, check_downl1		# branch if input = s
	beq	$s2, 97, check_leftl1		# branch if input = a
	beq	$s2, 100, check_rightl1		# branch if input = d

check_downl1: 	# check if the shape can move down
	addi	$t6, $s5, 128	# move address down one space
	jal	check_color	
	j	exit_lshape1
	
check_leftl1: 	# check if the shape can move left
	subi	$t6, $s5, 4	# move address left one space
	jal	check_color	
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_lshape1
	
check_rightl1:	# check if the shape can move right
	addi	$t6, $s5, 4	# move address right one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_lshape1
	
check_rotatel1: # check if the shape can rotate to form 2
	subi	$t6, $s5, 384	# move address up three spaces
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color
	
exit_lshape1: 	
	lw	$a1, ($sp)	# store Y value back to $a1
	lw	$a0, 4($sp)	# store X value back to $a0
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for l-shape (form 2)
lshape2: 
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)	
	sw	$a0, 4($sp)
	sw	$a1, ($sp)
	
	beq	$t3, 0, draw_l2		# branch to draw_l2 if action = draw
	beq	$t3, 1, black_l2	# branch to black_l2 if action = black out
	beq	$t3, 2, check_l2	# branch to check_l2 if action = check
	
draw_l2: 
	la	$a2, GREEN	# set color to green
	j	action_l2
black_l2: 
	li	$a2, 0		# set color to black

action_l2: 
	jal	draw_pixel
	li	$t0, 1		# i = 1
a2: 	addi	$a0, $a0, 1	# move pixel one space right 
	jal	draw_pixel
	addi	$t0, $t0, 1	# i++
	blt	$t0, 4, a2     	# branch to a2 if i < 4
	j	exit_lshape2
	
check_l2: 
	add	$s5, $s1, $0	# get current address of pixel
	beq	$s2, 119, check_rotatel2	# branch if input = w
	beq	$s2, 115, check_downl2		# branch if input = s
	beq	$s2, 97, check_leftl2		# branch if input = a
	beq	$s2, 100, check_rightl2		# branch if input = d

check_downl2: 
	addi	$t6, $s5, 128	# move address down one space
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color
	j	exit_lshape2
	
check_leftl2: 
	subi	$t6, $s5, 16	# move address left four spaces
	jal	check_color
	j	exit_lshape2
	
check_rightl2: 
	addi	$t6, $s5, 4	# move address right one space
	jal	check_color
	j	exit_lshape2
	
check_rotatel2: 
	subi	$t6, $s5, 12	# move address left three space
	addi	$t6, $t6, 128	# move address down one space
	jal	check_color
	addi	$t6, $t6, 128	# move address down one space
	jal	check_color
	addi	$t6, $t6, 128	# move address down one space
	jal	check_color

exit_lshape2: 
	lw	$a1, ($sp)
	lw	$a0, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for J-shape (form 1)
Jshape1: 
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)	
	sw	$a0, 4($sp)
	sw	$a1, ($sp)
	
	beq	$t3, 0, draw_J1		# branch if action = draw
	beq	$t3, 1, black_J1	# branch if action = black out
	beq	$t3, 2, check_J1	# branch to check_J1 if action = check
	
draw_J1: 
	la	$a2, BLUE	# set color to blue
	j	action_J1
black_J1: 
	li	$a2, 0		# set color to black

action_J1: 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down 
	jal	draw_pixel
	addi	$a0, $a0, -1	  # move pixel one space left 	
	jal	draw_pixel
	j	exit_Jshape1
	
check_J1: 
	add	$s5, $s1, $0	# get current address of pixel
	beq	$s2, 119, check_rotateJ1	# branch if input = w
	beq	$s2, 115, check_downJ1		# branch if input = s
	beq	$s2, 97, check_leftJ1		# branch if input = a
	beq	$s2, 100, check_rightJ1		# branch if input = d

check_downJ1: 
	addi	$t6, $s5, 128	# move address down one space
	jal	check_color
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color
	j	exit_Jshape1
	
check_leftJ1: 
	subi	$t6, $s5, 4	# move address left one space
	jal	check_color
	subi	$t6, $s5, 128	# move address up one space (from starting address of shape)
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Jshape1
	
check_rightJ1: 
	addi	$t6, $s5, 8	# move address right two space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Jshape1
	
check_rotateJ1: 
	subi	$t6, $s5, 128	# move address up one space
	addi	$t6, $t6, 8	# move address right two space
	jal	check_color
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color

exit_Jshape1: 
	lw	$a1, ($sp)
	lw	$a0, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for J-shape (form 2)
Jshape2: 
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)	
	sw	$a0, 4($sp)
	sw	$a1, ($sp)
	
	beq	$t3, 0, draw_J2		# branch if action = draw
	beq	$t3, 1, black_J2	# branch if action = black out
	beq	$t3, 2, check_J2	# branch to check_J2 if action = check
	
draw_J2: 
	la	$a2, BLUE	# set color to blue
	j	action_J2	
black_J2: 
	li	$a2, 0		# set color to black

action_J2: 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down 
	jal	draw_pixel
	addi	$a0, $a0, 1	  # move pixel one space right 
	jal	draw_pixel
	addi	$a0, $a0, 1	  # move pixel one space right 	
	jal	draw_pixel
	j	exit_Jshape2

check_J2: 
	add	$s5, $s1, $0	# get current address of pixel
	beq	$s2, 119, check_rotateJ2	# branch if input = w
	beq	$s2, 115, check_downJ2 		# branch if input = s
	beq	$s2, 97, check_leftJ2		# branch if input = a
	beq	$s2, 100, check_rightJ2		# branch if input = d

check_downJ2: 
	addi	$t6, $s5, 128	# move address down one space
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color
	j	exit_Jshape2
	
check_leftJ2: 
	subi	$t6, $s5, 12	# move address left three spaces
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Jshape2
	
check_rightJ2: 
	addi	$t6, $s5, 4	# move address right one space
	jal	check_color
	subi	$t6, $s5, 128	# move address up one space (from starting address of shape)
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color
	j	exit_Jshape2
	
check_rotateJ2: 
	subi	$t6, $s5, 12	# move address left three space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	addi	$t6, $t6, 256	# move address down two spaces
	jal	check_color

exit_Jshape2: 
	lw	$a1, ($sp)
	lw	$a0, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for J-shape (form 3)
Jshape3: 
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)	
	sw	$a0, 4($sp)
	sw	$a1, ($sp)
	
	beq	$t3, 0, draw_J3		# branch if action = draw
	beq	$t3, 1, black_J3	# branch if action = black out
	beq	$t3, 2, check_J3	# branch to check_J3 if action = check
	
draw_J3: 
	la	$a2, BLUE	# set color to blue
	j	action_J3
black_J3: 
	li	$a2, 0		# set color to black

action_J3: 
	jal	draw_pixel
	addi	$a0, $a0, -1	  # move pixel one space left 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down 	
	jal	draw_pixel
	j	exit_Jshape3
	
check_J3: 
	add	$s5, $s1, $0	# get current address of pixel
	beq	$s2, 119, check_rotateJ3	# branch if input = w
	beq	$s2, 115, check_downJ3 		# branch if input = s
	beq	$s2, 97, check_leftJ3		# branch if input = a
	beq	$s2, 100, check_rightJ3		# branch if input = d

check_downJ3: 
	addi	$t6, $s5, 128	# move address down one space
	jal	check_color
	addi	$t6, $s5, 4	# move address right one space (from starting address of shape)
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Jshape3
	
check_leftJ3: 
	subi	$t6, $s5, 4	# move address left one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Jshape3
	
check_rightJ3: 
	addi	$t6, $s5, 4	# move address right one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color
	j	exit_Jshape3
	
check_rotateJ3: 
	subi	$t6, $s5, 256	# move address up two spaces
	addi	$t6, $t6, 8	# move address right two spaces
	jal	check_color
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color
	addi	$t6, $t6, 128	# move address down one space
	jal	check_color

exit_Jshape3: 
	lw	$a1, ($sp)
	lw	$a0, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for J-shape (form 4)
Jshape4: 
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)	
	sw	$a0, 4($sp)
	sw	$a1, ($sp)
	
	beq	$t3, 0, draw_J4		# branch if action = draw
	beq	$t3, 1, black_J4	# branch if action = black out
	beq	$t3, 2, check_J4	# branch to check_J4 if action = check
		
draw_J4: 
	la	$a2, BLUE	# set color to blue
	j	action_J4
black_J4: 
	li	$a2, 0		# set color to black 

action_J4: 
	jal	draw_pixel
	addi	$a0, $a0, 1	  # move pixel one space right 
	jal	draw_pixel
	addi	$a0, $a0, 1	  # move pixel one space right 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down 	
	jal	draw_pixel
	j	exit_Jshape4

check_J4: 
	add	$s5, $s1, $0	# get current address of pixel
	beq	$s2, 119, check_rotateJ4	# branch if input = w
	beq	$s2, 115, check_downJ4 		# branch if input = s
	beq	$s2, 97, check_leftJ4		# branch if input = a
	beq	$s2, 100, check_rightJ4		# branch if input = d

check_downJ4: 
	addi	$t6, $s5, 128	# move address down one space
	jal	check_color
	subi	$t6, $s5, 4	# move address left one space (from starting address of shape)
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color
	j	exit_Jshape4
	
check_leftJ4: 
	subi	$t6, $s5, 4	# move address left one space
	jal	check_color
	subi	$t6, $t6, 8	# move address left two spaces
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Jshape4
	
check_rightJ4: 
	addi	$t6, $s5, 4	# move address right one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Jshape4
	
check_rotateJ4: 
	subi	$t6, $s5, 8	# move address left two spaces
	jal	check_color
	addi	$t6, $t6, 128	# move address down one space
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color

exit_Jshape4: 
	lw	$a1, ($sp)
	lw	$a0, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for L-shape (form 1)
Lshape1: 
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)	
	sw	$a0, 4($sp)
	sw	$a1, ($sp)
	
	beq	$t3, 0, draw_L1		# branch if action = draw
	beq	$t3, 1, black_L1	# branch if action = black out
	beq	$t3, 2, check_L1	# branch to check_L1 if action = check
	
draw_L1: 
	la	$a2, ORANGE	# set color to orange
	j	action_L1
black_L1: 
	li	$a2, 0		# set color to black

action_L1: 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down 
	jal	draw_pixel
	addi	$a0, $a0, 1	  # move pixel one space right 	
	jal	draw_pixel
	j	exit_Lshape1

check_L1: 
	add	$s5, $s1, $0	# get current address of pixel
	beq	$s2, 119, check_rotateL1	# branch if input = w
	beq	$s2, 115, check_downL1 		# branch if input = s
	beq	$s2, 97, check_leftL1		# branch if input = a
	beq	$s2, 100, check_rightL1		# branch if input = d

check_downL1: 
	addi	$t6, $s5, 128	# move address down one space
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color
	j	exit_Lshape1
	
check_leftL1: 
	subi	$t6, $s5, 8	# move address left two spaces
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Lshape1
	
check_rightL1: 
	addi	$t6, $s5, 4	# move address right one space
	jal	check_color
	subi	$t6, $s5, 128	# move address up one space (from starting address of shape)
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Lshape1
	
check_rotateL1: 
	subi	$t6, $s5, 256	# move address up two spaces
	jal	check_color
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color

exit_Lshape1: 
	lw	$a1, ($sp)
	lw	$a0, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for L-shape (form 2)
Lshape2: 
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)	
	sw	$a0, 4($sp)
	sw	$a1, ($sp)
	
	beq	$t3, 0, draw_L2		# branch if action = draw
	beq	$t3, 1, black_L2	# branch if action = black out
	beq	$t3, 2, check_L2	# branch to check_L2 if action = check
	
draw_L2: 
	la	$a2, ORANGE	# set color to orange
	j	action_L2	
black_L2: 
	li	$a2, 0		# set color to black

action_L2: 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down
	jal	draw_pixel
	addi	$a1, $a1, -1	  # move pixel one space up
	addi	$a0, $a0, 1	  # move pixel one space right 	
	jal	draw_pixel
	addi	$a0, $a0, 1	  # move pixel one space right 	
	jal	draw_pixel
	j	exit_Lshape2

check_L2: 
	add	$s5, $s1, $0	# get current address of pixel
	beq	$s2, 119, check_rotateL2	# branch if input = w
	beq	$s2, 115, check_downL2		# branch if input = s
	beq	$s2, 97, check_leftL2		# branch if input = a
	beq	$s2, 100, check_rightL2		# branch if input = d

check_downL2: 
	addi	$t6, $s5, 128	# move address down one space
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color	
	subi	$t6, $t6, 4	# move address left one space
	addi	$t6, $t6, 128	# move address down one space
	jal	check_color
	j	exit_Lshape2
	
check_leftL2: 
	subi	$t6, $s5, 12	# move address left three spaces
	jal	check_color
	addi	$t6, $t6, 128	# move address down one space
	jal	check_color
	j	exit_Lshape2
	
check_rightL2: 
	addi	$t6, $s5, 4	# move address right one space
	jal	check_color 
	addi	$t6, $s5, 128	# move address down one space (from starting address of shape)
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color
	j	exit_Lshape2
	
check_rotateL2: 
	subi	$t6, $s5, 4	# move address left one space
	addi	$t6, $t6, 128	# move address down one space
	jal	check_color
	addi	$t6, $t6, 128	# move address down one space
	jal	check_color

exit_Lshape2: 
	lw	$a1, ($sp)
	lw	$a0, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for L-shape (form 3)
Lshape3: 
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)	
	sw	$a0, 4($sp)
	sw	$a1, ($sp)
	
	beq	$t3, 0, draw_L3		# branch if action = draw
	beq	$t3, 1, black_L3	# branch if action = black out
	beq	$t3, 2, check_L3	# branch to check_L3 if action = check
	
draw_L3: 
	la	$a2, ORANGE	# set color to orange
	j	action_L3	
black_L3: 
	li	$a2, 0		# set color to black

action_L3: 
	jal	draw_pixel
	addi	$a0, $a0, 1	  # move pixel one space right 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down 	
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down 	
	jal	draw_pixel
	j	exit_Lshape3

check_L3: 
	add	$s5, $s1, $0	# get current address of pixel
	beq	$s2, 119, check_rotateL3	# branch if input = w
	beq	$s2, 115, check_downL3		# branch if input = s
	beq	$s2, 97, check_leftL3		# branch if input = a
	beq	$s2, 100, check_rightL3		# branch if input = d

check_downL3: 
	addi	$t6, $s5, 128	# move address down one space
	jal	check_color
	subi	$t6, $s5, 4	# move address left one space (from starting address of shape)
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Lshape3
	
check_leftL3: 
	subi	$t6, $s5, 4	# move address left one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color
	j	exit_Lshape3
	
check_rightL3: 
	addi	$t6, $s5, 4	# move address right one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Lshape3
	
check_rotateL3: 
	subi	$t6, $s5, 4	# move address left one space
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color
	subi	$t6, $t6, 4	# move address left one space
	jal	check_color

exit_Lshape3: 
	lw	$a1, ($sp)
	lw	$a0, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for L-shape (form 4)
Lshape4: 
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)	
	sw	$a0, 4($sp)
	sw	$a1, ($sp)
	
	beq	$t3, 0, draw_L4		# branch if action = draw
	beq	$t3, 1, black_L4	# branch if action = black out
	beq	$t3, 2, check_L4	# branch to check_L4 if action = check
		
draw_L4: 
	la	$a2, ORANGE	# set color to orange
	j	action_L4
black_L4: 
	li	$a2, 0		# set color to black

action_L4: 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down	
	jal	draw_pixel
	addi	$a0, $a0, -1	  # move pixel one space left
	jal	draw_pixel
	addi	$a0, $a0, -1	  # move pixel one space left
	jal	draw_pixel
	j	exit_Lshape4
	
check_L4: 
	add	$s5, $s1, $0	# get current address of pixel
	beq	$s2, 119, check_rotateL4	# branch if input = w
	beq	$s2, 115, check_downL4		# branch if input = s
	beq	$s2, 97, check_leftL4		# branch if input = a
	beq	$s2, 100, check_rightL4		# branch if input = d

check_downL4: 
	addi	$t6, $s5, 128	# move address down one space
	jal	check_color
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color
	j	exit_Lshape4
	
check_leftL4: 
	subi	$t6, $s5, 4	# move address left one space
	jal	check_color
	subi	$t6, $s5, 128	# move address up one space (from starting address of shape)
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color
	j	exit_Lshape4
	
check_rightL4: 
	addi	$t6, $s5, 12	# move address right three spaces
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Lshape4
	
check_rotateL4: 
	addi	$t6, $s5, 8	# move address right two spaces
	addi	$t6, $t6, 128	# move address down one space
	jal	check_color
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color
	
exit_Lshape4: 
	lw	$a1, ($sp)
	lw	$a0, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
#******************************************************************#

#******************************************************************#
# function for O-shape 
Oshape: 
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)	
	sw	$a0, 4($sp)
	sw	$a1, ($sp)
	
	beq	$t3, 0, draw_O		# branch if action = draw
	beq	$t3, 1, black_O		# branch if action = black out
	beq	$t3, 2, check_O		# branch to check_O if action = check
	
draw_O: 
	la	$a2, YELLOW	# set color to yellow
	j	action_O	
black_O: 
	li	$a2, 0		# set color to black

action_O: 
	jal	draw_pixel
	addi	$a0, $a0, 1	  # move pixel one space right 
	jal	draw_pixel
	addi	$a1, $a1, 1	  # move pixel one space down 
	jal	draw_pixel
	addi	$a0, $a0, -1	  # move pixel one space left
	jal	draw_pixel
	j	exit_Oshape
	
check_O: 
	add	$s5, $s1, $0	# get current address of pixel
	beq	$s2, 115, check_downO		# branch if input = s
	beq	$s2, 97, check_leftO		# branch if input = a
	beq	$s2, 100, check_rightO		# branch if input = d

check_downO: 
	addi	$t6, $s5, 128	# move address down one space
	jal	check_color
	addi	$t6, $t6, 4	# move address right one space
	jal	check_color
	j	exit_Oshape
	
check_leftO: 
	subi	$t6, $s5, 4	# move address left one space
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color
	j	exit_Oshape
	
check_rightO: 
	addi	$t6, $s5, 8	# move address right two spaces
	jal	check_color
	subi	$t6, $t6, 128	# move address up one space
	jal	check_color	
	
exit_Oshape: 	
	lw	$a1, ($sp)
	lw	$a0, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
#******************************************************************#
#########################################################################################
