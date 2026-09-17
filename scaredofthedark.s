.data
gridsize: .byte 8,8
character: .byte 0,0
match: .byte 0,0
unlitCandle: .byte 0,0
litCandle: .byte 26,26
shadowMonster: .byte 0,0
fearFactor: .byte 0
matchesCollected: .byte 0
turnOver: .byte 0
totalFearGauge: .byte 0,0,0,0
parallelFearGauge: .byte 0,0,0,0
parallelTrackPlayer: .byte 0,0,0,0
currentPlayer: .byte 1
numOfPlayers: .byte 0
roundNo: .byte 1

# Snapshot of the round's map
roundcharacter: .byte 0,0
roundmatch: .byte 0,0
roundcandle: .byte 0,0
roundmonster: .byte 0,0


# The representations of the game environment
wallStr: .string "="
characterStr: .string "C"
matchStr: .string "M"
unlitCandleStr: .string "/"
litCandleStr: .string "*"
shadowMonsterStr: .string "S"
emptySpaceStr: .string "."
clearScreen: .string "\033[2J\033[H" # Clears terminal
playermsg: .string "Player "
playermsg_part2: .string "'s Turn"

# Miscellaneous
newLineStr: .string "\n"

# Title screen and prompts
title: .string "~ Scared of the Dark ~"
prompt0: .string "Enter the number of players (1 to 4): "
prompt1: .string "Enter a horizontal grid size (5 to 12): "
prompt2: .string "Enter a vertical grid size (5 to 12): "
invalid_message: .string "Invalid entry!"
round_count_p1: .string "~ Round "
round_count_p2: .string " ~"

# In Game Text
display_fear_factor: .string "Fear Gauge: "
display_matches_collected: .string "Matches Collected: "
display_make_move: .string "wasd To Move, 'r' to Restart, 'q' to Exit"
display_enter_prompt: .string "Enter Input: "
cant_move_message: .string " << You can't make this move!"
dont_know_message: .string " << What does this mean?"
fi_message: .string "Monster got in range >> Fear Gauge +10"
mc_message: .string "You collected a match >> Matches Collected +1"
no_matches_collected: .string "You have 0 matches..."
round_win_message: .string "You lit the candle >> Won This Turn"
round_lost_message: .string "Fear gauge hit 100 >> Lost This Turn"
end_turn_message: .string "VALIDLY MOVE to continue to the next turn."
end_round_message: .string "All turns are over. VALIDLY MOVE to see standings."

# Exit Message
exit_message: .string "You have exited the game."

# Standings
player_txt: .string "Player "
longspace: .string "  "
ranking: .string "Ranking:"
total_fear: .string "Total Fear (Ascending):"
border: .string "- - - - - - - - - - - - - - - - -"
press_anything_msg: .string "'r' to Restart, 'q' to Exit, OTHER for Next Round"

.text
.global _start

_start:
	
	j play_game
	
exit:
	
	li a7, 4
	la a0, clearScreen
	ecall
	
	li a7, 4
	la a0, exit_message
	ecall
	
    li a7, 10
    ecall

restart:
    
	# === Reset variables ===
	
	la t0, fearFactor
	li t1, 0
	sb t1, 0(t0)
	
	la t0, matchesCollected
	li t1, 0
	sb t1, 0(t0)
	
	la t0, turnOver
	li t1, 0
	sb t1, 0(t0)
	
	la t0, currentPlayer
	li t1, 1
	sb t1, 0(t0)
	
	la t0, roundNo
	li t1, 1
	sb t1, 0(t0)
	
	la t0, totalFearGauge
	li t1, 0
	sb t1, 0(t0)
	sb t1, 1(t0)
	sb t1, 2(t0)
	sb t1, 3(t0)
	
	j play_game
    
# --- HELPER FUNCTIONS ---
     
# Arguments: an integer MAX in a0
# Return: A number from 0 (inclusive) to MAX (exclusive)
notrand:
    mv t0, a0
    li a7, 30
    ecall             # time syscall (returns milliseconds)
    remu a0, a0, t0   # modulus on bottom bits 
    li a7, 32
    ecall             # sleeping to try to generate a different number
    jr ra

# Xorshift RNG Function by George Marsaglia from the Florida State University
# Arguments: an integer MAX in a0, and an integer SEED in a1
# Return: A number from 0 (inclusive) to MAX (exclusive) and a new SEED
xorshift:

	mv t0, a1
	
	# Xorshift Algorithm
	slli t1, t0, 5 # Shift the seed (t0) left by 5 and stores in t1
	xor t0, t0, t1 # XOR with a shifted version of itself
	
	srli t1, t0, 13 
	xor t0, t0, t1 
	
	slli t1, t0, 11 
	xor t0, t0, t1 

	mv a1, t0 # Return a new seed 
	
	remu a0, t0, a0 # Return RANDOM mod MAX
	
	jr ra


# Arguments: an integer in a0
# Return: | a0 |
absolute_value:
	mv t0, a0
	
    li t1, 0
	
    blt t0, t1, make_positive # If the argument is less than 0, make positive
	
	jr ra

make_positive:
    
    li t1, -1
    mul t0, t0, t1 # Multiply number by -1

    mv a0, t0
    
    jr ra

# Bubble sorts parallelFearGauge and aligns it with parallelTrackPlayer
bubble_sort_4:
	
	# Saves the return address
	addi sp, sp, -4
	sw ra, 0(sp)
	
	li t0, 0 # Outer loop counter
	li t1, 0 # Inner loop counter
	li t2, 3 # Cieling
	
	j outer_loop
	
	
outer_loop:
	
	jal ra, inner_loop
	
	addi t0, t0, 1
	li t1, 0
	
	blt t0, t2, outer_loop
	
	# Loads back the return address 
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra

inner_loop:
	
	la t3, parallelFearGauge
	add t3, t3, t1
	
	la t6, parallelTrackPlayer
	add t6, t6, t1
	
	lb t4, 0(t3)
	lb t5, 1(t3)
	
	blt t5, t4, swap
	
	addi t1, t1, 1
	
	blt t1, t2, inner_loop
	
	jr ra
	
swap:

	sb t4, 1(t3)
	sb t5, 0(t3)
	
	lb t4, 0(t6)
	lb t5, 1(t6)
	
	sb t4, 1(t6)
	sb t5, 0(t6)
	
	addi t1, t1, 1
	
	blt t1, t2, inner_loop
	
	jr ra

# Loads the round map into the current coordinates
load_round_snapshot:
	
	la t1, character
	la t2, character+1
	lb t3, roundcharacter
	lb t4, roundcharacter+1
	
	sb t3, 0(t1)
	sb t4, 0(t2)
	
	la t1, match
	la t2, match+1
	lb t3, roundmatch
	lb t4, roundmatch+1
	
	sb t3, 0(t1)
	sb t4, 0(t2)
	
	la t1, unlitCandle
	la t2, unlitCandle+1
	lb t3, roundcandle
	lb t4, roundcandle+1
	
	sb t3, 0(t1)
	sb t4, 0(t2)
	
	la t1, shadowMonster
	la t2, shadowMonster+1
	lb t3, roundmonster
	lb t4, roundmonster+1
	
	sb t3, 0(t1)
	sb t4, 0(t2)
	
	jr ra

# Stores coordinates for the round map
store_round_snapshot:

	lb t1, character
	lb t2, character+1
	la t3, roundcharacter
	la t4, roundcharacter+1
	
	sb t1, 0(t3)
	sb t2, 0(t4)
	
	lb t1, match
	lb t2, match+1
	la t3, roundmatch
	la t4, roundmatch+1
	
	sb t1, 0(t3)
	sb t2, 0(t4)
	
	lb t1, unlitCandle
	lb t2, unlitCandle+1
	la t3, roundcandle
	la t4, roundcandle+1
	
	sb t1, 0(t3)
	sb t2, 0(t4)
	
	lb t1, shadowMonster
	lb t2, shadowMonster+1
	la t3, roundmonster
	la t4, roundmonster+1
	
	sb t1, 0(t3)
	sb t2, 0(t4)
	
	jr ra

# ======== Handles ACTUAL GAME =========

play_game:

	jal ra, pregameprompts
	
	j round_loop

round_loop:
	
	# Loads current player and number of players to check if round
	# must end
	
	lb t0, currentPlayer
	lb t1, numOfPlayers
	li t2, 1
	
	blt t1, t0, end_round
	
	beq t0, t2, first_player_case

	jal ra, load_round_snapshot
	
	j turn_loop

first_player_case:
	jal ra, initialRNG
	jal ra, store_round_snapshot
	
	j turn_loop


end_round:
	
	# Adds one to round count
	lb t1, roundNo
	la t2, roundNo
	addi t1, t1, 1
	sb t1, 0(t2)
	
	# Store current player as 1
	la t1, currentPlayer
	li t2, 1
	sb t2, 0(t1)
	
	jal ra, display_standings
	jal ra, end_round_prompt
	
	j round_loop
	
turn_loop:
	
	# === Clears terminal at each display ===
	
	li a7, 4               
	la a0, clearScreen
	ecall
	
	jal ra, game_check
	
	jal ra, display_player_n
	
	jal ra, displayboard
	
	jal ra, handles_move
	
	lb t1, turnOver
	li t2, 1
	
	beq t1, t2, turn_end
	
	j turn_loop

display_player_n:

	lb t0, turnOver
	li t1, 1
	beq t0, t1, turn_over_msg
	
	# === Displays Player N's Turn ===
	li a7, 4
	la a0, playermsg
	ecall
	
	li a7, 1
	lb a0, currentPlayer
	ecall
	
	li a7, 4
	la a0, playermsg_part2
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	jr ra
	
turn_over_msg:

	lb t0, currentPlayer
	lb t1, numOfPlayers
	beq t0, t1, round_over_msg
	
	li a7, 4
	la a0, end_turn_message
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	jr ra

round_over_msg:

	li a7, 4
	la a0, end_round_message
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	jr ra
	
turn_end:
	
	# Load the current player & fear factor
	lb t1, currentPlayer
	lb t2, fearFactor
	la t3, totalFearGauge
	
	# Add one to current player and store in memory
	addi t0, t1, 1
	la t4, currentPlayer
	sb t0, 0(t4)
	
	# Subtract one to find in memory
	addi t0, t1, -1
	add t3, t3, t0 # Add to get address
	
	lb t4, 0(t3) # Now obtain current player's total fear gauge
	
	add t4, t4, t2 # Add current fear gauge into total
	
	sb t4, 0(t3) # Store it back
	
	# Now set fear factor back to 0
	la t0, fearFactor
	li t1, 0
	sb t1, 0(t0)
	
	# Now set turn over back to 0
	la t0, turnOver
	li t1, 0
	sb t1, 0(t0)
	
	j round_loop
	
	

# HANDLES THE MOVEMENT OF THE CHARACTER AND SHADOW MONSTER
handles_move:
	
	# Collects Character
	li a7, 12
	ecall
	mv t0, a0
	
	li t1, 'w'
	beq t0, t1, move_up
	
	li t1, 'a'
	beq t0, t1, move_left
	
	li t1, 's'
	beq t0, t1, move_down
	
	li t1, 'd'
	beq t0, t1, move_right
	
	li t1, 'r'
	beq t0, t1, restart
	
	li t1, 'q'
	beq t0, t1, exit
	
	j cant_do_this_2

move_up:
	lb t0, character+1
	la t1, character+1
	
	li t2, 0
	
	beq t0, t2, cant_do_this
	
	addi t0, t0, -1
	sb t0, 0(t1)
	
	j resulting_monster_move

move_left:
	lb t0, character
	la t1, character
	
	li t2, 0
	beq t0, t2, cant_do_this
	
	addi t0, t0, -1
	sb t0, 0(t1)
	
	j resulting_monster_move

move_down:
	lb t0, character+1
	la t1, character+1
	
	lb t2, gridsize
	addi t2, t2, -1
	beq t0, t2, cant_do_this
	
	addi t0, t0, 1
	sb t0, 0(t1)
	
	j resulting_monster_move

move_right:
	lb t0, character
	la t1, character
	
	lb t2, gridsize
	addi t2, t2, -1
	beq t0, t2, cant_do_this

	
	addi t0, t0, 1
	sb t0, 0(t1)
	
	j resulting_monster_move
	

cant_do_this:
	
	li a7, 4
	la a0, cant_move_message
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	j handles_move
	
cant_do_this_2:
	
	li a7, 4
	la a0, dont_know_message
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	j handles_move
	

# RESULTING SHADOW MONSTER MOVE ALGORITHM
# Precondition: The monster is not in the fear-increasing
# range of the character
resulting_monster_move:
	
	# Saves the return address
	addi sp, sp, -4
	sw ra, 0(sp)
	
	la t4, shadowMonster
	
	# loads coords of character
	lb t0, character
	lb t1, character+1
	
	# loads coords of monster
	lb t2, shadowMonster
	lb t3, shadowMonster+1
	
	sub t5, t2, t0 # Difference in x
	sub t6, t3, t1 # Difference in y
	
	# NOTE THAT IN absolute_value, t0 and t1 are used
	mv a0, t5
	jal ra, absolute_value
	mv t5, a0
	
	mv a0, t6
	jal ra, absolute_value
	mv t6, a0
	
	# reload coords of character
	lb t0, character
	lb t1, character+1
	
	blt t6, t5, rmm_left_or_right # If x-diff > y-diff
	j rmm_up_or_down # If y-diff > x-diff

rmm_up_or_down:
	
	blt t1, t3, rmm_up # note that the more up you go, the lesser the coord
	j rmm_down

rmm_up:
	addi t3, t3, -1
	sb t3, 1(t4)
	j exit_sm_move

rmm_down:
	addi t3, t3, 1
	sb t3, 1(t4)
	j exit_sm_move

rmm_left_or_right:
	
	blt t0, t2, rmm_left
	j rmm_right

rmm_left:
	addi t2, t2, -1
	sb t2, 0(t4)
	j exit_sm_move

rmm_right:
	addi t2, t2, 1
	sb t2, 0(t4)
	j exit_sm_move

exit_sm_move:
	
	# Loads back the return address 
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra

# HANDLES ALL CHECKS
# If monster gets in region, and fear gauge must increase
# If user collects a match
# If user lights up the candle
game_check:

	# Saves the return address
	addi sp, sp, -4
	sw ra, 0(sp)
	
	jal ra, check_monster_in_range
	jal ra, check_match_collected
	jal ra, check_candle_lit
	jal ra, check_turn_lost
	
	# Loads back the return address 
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra

check_turn_lost:
	
	# Checks in case we already won
	lb t0, turnOver
	li t1, 1
	beq t0, t1, already_won
	
	lb t0, fearFactor
	li t1, 100
	beq t0, t1, turn_lost
	
	jr ra

already_won:
	jr ra
	
turn_lost:
	
	li a7, 4
	la a0, round_lost_message
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	lb t0, turnOver
	la t1, turnOver
	addi t0, t0, 1
	sb t0, 0(t1)

	jr ra
	

check_candle_lit:
	lb t0, character
	lb t1, character+1
	lb t2, unlitCandle
	lb t3, unlitCandle+1
	
	beq t0, t2, check_candle_y
	jr ra

check_candle_y:
	beq t1, t3, check_light_candle
	jr ra
	
check_light_candle:
	
	lb t4, matchesCollected
	li t5, 1
	
	bge t4, t5, light_candle
	
	li a7, 4
	la a0, no_matches_collected
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	jr ra

light_candle:
	
	# Removes one match
	addi t4, t4, -1
	la t5, matchesCollected
	sb t4, 0(t5)
	
	li a7, 4
	la a0, round_win_message
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	# Sets to 1 to end the turn
	lb t4, turnOver
	la t5, turnOver
	addi t4, t4, 1
	sb t4, 0(t5)
	
	jr ra

check_match_collected:
	
	lb t0, character
	lb t1, character+1
	lb t2, match
	lb t3, match+1
	
	beq t0, t2, check_match_y
	jr ra

check_match_y:
	beq t1, t3, collect_match
	jr ra

collect_match:

	# Get off the grid
	li t2, 26
	
	la t4, match
	sb t2, 0(t4)
	sb t2, 1(t4)
	
	# Add 1 to matches collected
	lb t4, matchesCollected
	addi t4, t4, 1
	
	# Store back in memory
	la t5, matchesCollected
	sb t4, 0(t5)
	
	# Display message
	li a7, 4
	la a0, mc_message
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	jr ra

check_monster_in_range:

	# Saves the return address
	addi sp, sp, -4
	sw ra, 0(sp)
	
	lb t0, character
	lb t1, character+1
	lb t2, shadowMonster
	lb t3, shadowMonster+1
	
	sub t4, t0, t2
	sub t5, t1, t3
	
	mv a0, t4
	jal ra, absolute_value
	mv t4, a0
	
	mv a0, t5
	jal ra, absolute_value
	mv t5, a0
	
	li t6, 2
	blt t4, t6, monster_in_range_y_check
	
	# Loads back the return address 
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra
	
monster_in_range_y_check:

	blt t5, t6, monster_in_range
	
	# Loads back the return address 
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra

monster_in_range:

	lb t0, fearFactor
	la t1, fearFactor
	addi t0, t0, 10
	sb t0, 0(t1)
	
	li a7, 4
	la a0, fi_message
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	j regenerate_shadow

regenerate_shadow:
	
	lb t0, gridsize # Loads the horizontal grid size
	
	# Sets the MAX and calls the RNG to make a random x-coordinate
	mv a0, t0
	jal ra, xorshift
	
	# Stores this as the x-coordinate for the monster
	la t0, shadowMonster
	sb a0, 0(t0)
	
	lb t0, gridsize+1 # Loads the vertical grid size
	
	# Sets the MAX and calls the RNG to make a random y-coordinate
	mv a0, t0
	jal ra, xorshift
	
	# Stores this as the y-coordinate for the monster
	la t0, shadowMonster
	sb a0, 1(t0)
	
	j valid_regshadow_x # Start the valid-generation process
	
valid_regshadow_x:

	lb t0, character
	lb t1, unlitCandle
	lb t2, match
	lb t3, shadowMonster
	beq t0, t3, valid_regshadow_y
	beq t1, t3, valid_regshadow_y
	beq t2, t3, valid_regshadow_y
	
	j valid_shadow_regen_region
	
valid_regshadow_y:

	lb t0, character
	lb t1, unlitCandle
	lb t2, match
	lb t3, shadowMonster
	beq t0, t3, regenerate_shadow
	beq t1, t3, regenerate_shadow
	beq t2, t3, regenerate_shadow
	
	j valid_shadow_regen_region

# Note that if the shadow monster immediately spots in a region that would cause the fear guauge to increase, it is invalid
valid_shadow_regen_region:

	lb t0, character
	lb t1, character+1
	
	lb t2, shadowMonster
	lb t3, shadowMonster+1
	
	sub t4, t0, t2 # Gets the x-difference in coordinates
	sub t5, t1, t3 # Gets the y-difference in coordinates
	
	# Makes sure everything is positive
    mv a0, t4
	jal ra, absolute_value
	mv t4, a0
	
	mv a0, t5
	jal ra, absolute_value
	mv t5, a0
	
	li t6, 1
	
	bge t6, t4, vsregen_y
	
	# Loads back the return address 
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra

vsregen_y:
	
	bge t6, t5, regenerate_shadow
	
	# Loads back the return address 
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra

# ======= Handles START OF GAME COORDINATE GENERATION ===========
initialRNG:

	# Saves the return address
	addi sp, sp, -4
	sw ra, 0(sp)
	
	# Starts the coordinate generation process
	jal ra, generate_character
	
	# Loads back the return address to _start
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra
	
generate_character:

	# Saves the return address
	addi sp, sp, -4
	sw ra, 0(sp)
	
	lb t0, gridsize # Loads the horizontal grid size
	
	# Sets the MAX and calls the RNG to make a random x-coordinate
	mv a0, t0
	jal ra, xorshift
	
	# Stores this as the x-coordinate for the character
	la t0, character
	sb a0, 0(t0)
	
	lb t0, gridsize+1 # Loads the vertical grid size
	
	# Sets the MAX and calls the RNG to make a random y-coordinate
	mv a0, t0
	jal ra, xorshift
	
	# Stores this as the y-coordinate for the character
	la t0, character
	sb a0, 1(t0)
	
	j generate_shadow_monster

# THIS IS SOLELY FOR INITIAL RNG
generate_shadow_monster:

	lb t0, gridsize # Loads the horizontal grid size
	
	# Sets the MAX and calls the RNG to make a random x-coordinate
	mv a0, t0
	jal ra, xorshift
	
	# Stores this as the x-coordinate for the monster
	la t0, shadowMonster
	sb a0, 0(t0)
	
	lb t0, gridsize+1 # Loads the vertical grid size
	
	# Sets the MAX and calls the RNG to make a random y-coordinate
	mv a0, t0
	jal ra, xorshift
	
	# Stores this as the y-coordinate for the monster
	la t0, shadowMonster
	sb a0, 1(t0)
	
	j valid_shadow_checker_x # Start the valid-generation process

# DETERMINES IF THE SHADOW MONSTER WAS GENERATED IN A VALID COORDINATE
valid_shadow_checker_x:
	
	lb t0, character
	lb t1, shadowMonster
	beq t0, t1, valid_shadow_checker_y
	j valid_shadow_checker_region
	
valid_shadow_checker_y:

	lb t0, character+1
	lb t1, shadowMonster+1
	beq t0, t1, generate_shadow_monster
	j valid_shadow_checker_region

# Note that if the shadow monster immediately spots in a region that would cause the fear guauge to increase, it is invalid
valid_shadow_checker_region:

	lb t0, character
	lb t1, character+1
	
	lb t2, shadowMonster
	lb t3, shadowMonster+1
	
	sub t4, t0, t2 # Gets the x-difference in coordinates
	sub t5, t1, t3 # Gets the y-difference in coordinates
	
	# Makes sure everything is positive
    mv a0, t4
	jal ra, absolute_value
	mv t4, a0
	
	mv a0, t5
	jal ra, absolute_value
	mv t5, a0
	
	li t6, 1
	
	bge t6, t4, vscr_y
	
	j generate_match

vscr_y:
	
	bge t6, t5, generate_shadow_monster
	j generate_match

generate_match:

	lb t0, gridsize # Loads the horizontal grid size
	
	# Sets the MAX and calls the RNG to make a random x-coordinate
	mv a0, t0
	jal ra, xorshift
	
	# Stores this as the x-coordinate for the match
	la t0, match
	sb a0, 0(t0)
	
	lb t0, gridsize+1 # Loads the vertical grid size
	
	# Sets the MAX and calls the RNG to make a random y-coordinate
	mv a0, t0
	jal ra, xorshift
	
	# Stores this as the y-coordinate for the match
	la t0, match
	sb a0, 1(t0)
	
	j valid_match_checker_x
	
valid_match_checker_x:
	
	lb t0, character
	lb t1, shadowMonster
	lb t2, match
	beq t0, t2, valid_match_checker_y
	beq t1, t2, valid_match_checker_y
	
	j generate_unlit

valid_match_checker_y:
	
	lb t0, character+1
	lb t1, shadowMonster+1
	lb t2, match+1
	beq t0, t2, generate_match
	beq t1, t2, generate_match
	
	j generate_unlit
	
generate_unlit:

	lb t0, gridsize # Loads the horizontal grid size
	
	# Sets the MAX and calls the RNG to make a random x-coordinate
	mv a0, t0
	jal ra, xorshift
	
	# Stores this as the x-coordinate for the candle
	la t0, unlitCandle
	sb a0, 0(t0)
	
	lb t0, gridsize+1 # Loads the vertical grid size
	
	# Sets the MAX and calls the RNG to make a random y-coordinate
	mv a0, t0
	jal ra, xorshift
	
	# Stores this as the y-coordinate for the candle
	la t0, unlitCandle
	sb a0, 1(t0)
	
	j valid_unlit_checker_x

valid_unlit_checker_x:
	
	lb t0, character
	lb t1, shadowMonster
	lb t2, match
	lb t3, unlitCandle
	beq t0, t3, valid_unlit_checker_y
	beq t1, t3, valid_unlit_checker_y
	beq t2, t3, valid_unlit_checker_y
	
	j back_to_initialRNG
	
valid_unlit_checker_y:
	
	lb t0, character+1
	lb t1, shadowMonster+1
	lb t2, match+1
	lb t3, unlitCandle+1
	beq t0, t3, generate_unlit
	beq t1, t3, generate_unlit
	beq t2, t3, generate_unlit
	
	j back_to_initialRNG

back_to_initialRNG:
	
	# Loads back the return address in initialRNG
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra

# ======== Handles PRE-GAME ========

pregameprompts:
	
	# Saves the return address to _start
	addi sp, sp, -4
	sw ra, 0(sp)
	
	li a7, 4
	la a0, clearScreen
	ecall
	
	# PRINTS THE TITLE SCREEN
    li a7, 4
    la a0, title
    ecall

    li a7, 4
    la a0, newLineStr
    ecall
	
	li t1, 1 # Minimum player count
	li t2, 5 # Maximum player count + 1
	
	# Prompts for the number of players
	jal ra, player_prompt
	
	li t1, 5 # Minimum Grid Size
	li t2, 13 # One Above Maximum Grid Size
	li a1, 123 # Initial value for seed
	
	# Load the address for the grid size
    la t0, gridsize
	
	# Prompts for the grid size
	jal ra, horizontal_prompt
	jal ra, vertical_prompt
	
	# Loads back the return address to _start
	lw ra, 0(sp)
	addi sp, sp, 4
	
	li a7, 4
    la a0, newLineStr
    ecall
	
	li a7, 4
    la a0, newLineStr
    ecall
	
	# After getting the random seed from the prompts, do some
	# arithmetic with the time to finalize the game seed
	li a7, 30
	ecall
	mul a1, a0, a1
    
    jr ra

player_prompt:
	
	li a7, 4
	la a0, prompt0
	ecall
	
	li a7, 5
	ecall
	
	blt a0, t1, invalid_player
	bge a0, t2, invalid_player
	
	lb t0, numOfPlayers
	la t1, numOfPlayers
	
	addi t0, a0, 0
	
	# Quick math to come up with a RNG seed based on the prompt
	add a1, a1, a0
	slli a1, a1, 4
	
	sb t0, 0(t1)
	
	jr ra

invalid_player:

	li a7, 4
	la a0, invalid_message
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	j player_prompt

# PROMPTS FOR HORIZONTAL GRID SIZE
horizontal_prompt:
    li a7, 4
    la a0, prompt1
    ecall

    li a7, 5
    ecall
	
	blt a0, t1, invalid_horizontal
	bge a0, t2, invalid_horizontal
	
	sb a0, 0(t0)
	
	# Quick math to come up with a RNG seed based on the prompt
	add a1, a1, a0
	slli a1, a1, 4
	
	jr ra

invalid_horizontal:
	
	li a7, 4
	la a0, invalid_message
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	j horizontal_prompt
	
# PROMPTS FOR VERTICAL GRID SIZE
vertical_prompt:

    li a7, 4
    la a0, prompt2
    ecall

    li a7, 5
    ecall
	
	blt a0, t1, invalid_vertical
	bge a0, t2, invalid_vertical
	
	# Quick math to come up with a RNG seed based on the prompt
	add a1, a1, a0
	slli a1, a1, 4
	
	sb a0, 1(t0)
	
	jr ra

invalid_vertical:

	li a7, 4
	la a0, invalid_message
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	j vertical_prompt
	
end_round_prompt:
	# Saves the return address to _start
	addi sp, sp, -4
	sw ra, 0(sp)
	
	li a7, 4
	la a0, clearScreen
	ecall
	
	li a7, 4
	la a0, round_count_p1
	ecall
	
	li a7, 1
	lb a0, roundNo
	ecall
	
	li a7, 4
	la a0, round_count_p2
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	# Load the address for the grid size
    la t0, gridsize
	
	li t1, 6 # Minimum Grid Size
	li t2, 26 # One Above Maximum Grid Size
	
	# Prompts for the grid size
	jal ra, horizontal_prompt
	jal ra, vertical_prompt
	
	# Loads back the return address to _start
	lw ra, 0(sp)
	addi sp, sp, 4
	
	li a7, 4
    la a0, newLineStr
    ecall
	
	li a7, 4
    la a0, newLineStr
    ecall
    
    jr ra

# ======== Handles Displaying the Board ========

# Just used for testing, if I want to display coordinates
coordinate_test:
	li a7, 1
	lb a0, character
	ecall
	
	li a7, 1
	lb a0, character+1
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	li a7, 1
	lb a0, shadowMonster
	ecall
	
	li a7, 1
	lb a0, shadowMonster+1
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	li a7, 1
	lb a0, match
	ecall
	
	li a7, 1
	lb a0, match+1
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	li a7, 1
	lb a0, unlitCandle
	ecall
	
	li a7, 1
	lb a0, unlitCandle+1
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	jr ra

displayboard:

	# t0 -> x Grid Size
	# t4 -> y Grid Size
	# t1 -> x-counter
	# t2 -> y-counter
	# t3 -> coordinate checker
	
	# Saves the return address to _start
	addi sp, sp, -4
	sw ra, 0(sp)
	
	# === Prints board ===
	
	lb t0, gridsize # Storing the horizontal gridsize in register
	lb t4, gridsize+1 # Storing the vertical gridsize in register

    li t1, 0 # X-counter
    li t2, 0 # Y-counter

    addi t0, t0, 2 # To print a nxn grid, you must add two to consider for walls
    jal ra, printboard_ends # Start with the cieling
    addi t0, t0, -2 # Removes 2 for the process of printing middle rows
	
	jal ra, pre_printboard_mid # Gets the inside done
	
    addi t0, t0, 2 # To print a nxn grid, you must add two to consider for walls
	jal ra, printboard_ends # End with the flooring
    addi t0, t0, -2 # Removes 2 to reset
	
	# === Prints text under board === #
	
	# Displays make move
    li a7, 4
    la a0, display_make_move
    ecall
	
    li a7, 4
    la a0, newLineStr
    ecall

    # Displays fear factor
    li a7, 4
    la a0, display_fear_factor
    ecall

    li a7, 1
    lb a0, fearFactor
    ecall
	
	li a7, 4
    la a0, newLineStr
    ecall
	
	# Displays matches collected
	li a7, 4
    la a0, display_matches_collected
    ecall

    li a7, 1
    lb a0, matchesCollected
    ecall

    li a7, 4
    la a0, newLineStr
    ecall
	
	# Retrieves the return address from _start
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra # Gets back to main

printboard_ends:
    # Loops until X-Counter = Grid Size
    beq t1, t0, if_x_done_ends

    # Prints a wall (cieling or floor)
    li a7, 4
    la a0, wallStr
    ecall

    # Adds 1 to the counter
    addi t1, t1, 1

    j printboard_ends

# End function specifically for the ends of the board
if_x_done_ends:
	
	li t1, 0 # Reset x counter
	
    # Prints a newline
    li a7, 4
    la a0, newLineStr
    ecall
	
    jr ra

# This function is to save a return address in displayboard before the loops in printboard_mid
pre_printboard_mid:

	addi sp, sp, -4
	sw ra, 0(sp)
	j printboard_mid
	
printboard_mid:
	
    # Start by printing a wall
    li a7, 4
    la a0, wallStr
    ecall
	
	# Prints the environment of the row
	jal ra, print_environment
	
    # End by printing a wall and new line
    li a7, 4
    la a0, wallStr
    ecall

    li a7, 4
    la a0, newLineStr
	ecall
    
    addi t2, t2, 1
	
    beq t2, t4, done_middle # If we are done all rows, stop

	j printboard_mid # Loops for the next row

# We check the specific coordinate to see what should be placed in it
print_environment:

	# We start with the x-coordinate check for character
	lb t3, character
	beq t3, t1, char_y_check
	j monster_x_check
	
char_y_check:
	lb t3, character+1
	beq t3, t2, print_char
	j monster_x_check

monster_x_check:
    lb t3, shadowMonster
    beq t3, t1, monster_y_check
    j match_x_check

monster_y_check:
    lb t3, shadowMonster+1
    beq t3, t2, print_monster
    j match_x_check
	
match_x_check:
	lb t3, match
	beq t3, t1, match_y_check
    j lit_x_check
	
match_y_check:
	lb t3, match+1
	beq t3, t2, print_match
    j lit_x_check

lit_x_check:
    lb t3, litCandle
    beq t3, t1, lit_y_check
    j unlit_x_check

lit_y_check:
    lb t3, litCandle+1
    beq t3, t2, print_lit
    j unlit_x_check

unlit_x_check:
    lb t3, unlitCandle
    beq t3, t1, unlit_y_check
    j print_empty

unlit_y_check:
    lb t3, unlitCandle+1
    beq t3, t2, print_unlit
    j print_empty

# Whatever is located in this coordinate will now be printed
print_char:
    # Prints the character at the coordinate
    li a7, 4
    la a0, characterStr
    ecall
    j done_coordinate

print_match:
    # Prints the match at the coordinate
    li a7, 4
    la a0, matchStr
    ecall
    j done_coordinate

print_lit:
    # Prints the lit candle at the coordinate
    li a7, 4
    la a0, litCandleStr
    ecall
    j done_coordinate

print_unlit:
    # Prints the unlit candle at the coordinate
    li a7, 4
    la a0, unlitCandleStr
    ecall
    j done_coordinate

print_monster:
    # Prints the monster at the coordinate
    li a7, 4
    la a0, shadowMonsterStr
    ecall
    j done_coordinate

print_empty:
    # Prints empty space at the coordinate
    li a7, 4
    la a0, emptySpaceStr
    ecall
    j done_coordinate

done_coordinate:
    
    addi t1, t1, 1 # Adds one to the x-counter
	
	blt t1, t0, print_environment # If x-counter < grid size, get to the next coordinate
	
	li t1, 0 # We are now done the row, so reset x-counter
	
    jr ra # Jump to printboard_mid

	
done_middle:
	
	# Calls the return address from display board
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra
	
# ================ Displays Standings ===================

display_standings:
	
	addi sp, sp, -4
	sw ra, 0(sp)
	
	li a7, 4
	la a0, clearScreen
	ecall
	
	# Displays the top
	
	li a7, 4
	la a0, ranking
	ecall
	
	li a7, 4
	la a0, longspace
	ecall
	
	li a7, 4
	la a0, total_fear
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	li a7, 4
	la a0, border
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	# ORDERS RANKINGS AND PRINTS THEM
	
	# Gets values
	lb t0, totalFearGauge # Of Player 1
	lb t1, totalFearGauge+1 # Of Player 2
	lb t2, totalFearGauge+2 # Of Player 3
	lb t3, totalFearGauge+3 # Of Player 4
	
	# Puts it in a parallel list to sort
	la t4, parallelFearGauge
	sb t0, 0(t4)
	sb t1, 1(t4)
	sb t2, 2(t4)
	sb t3, 3(t4)
	
	# Sets up track player to adjust in parallel to the sort
	la t4, parallelTrackPlayer
	li t0, 1
	sb t0, 0(t4)
	li t0, 2
	sb t0, 1(t4)
	li t0, 3
	sb t0, 2(t4)
	li t0, 4
	sb t0, 3(t4)
	
	jal ra, bubble_sort_4
	
	lb t4, numOfPlayers
	
	j check_first_place

# These functions check who is in the nth place,
# but also if the player number is higher than the total
# amount of players this game has. If that is true, we skip.
check_first_place:
	lb t2, parallelFearGauge
	lb t3, parallelTrackPlayer
	
	blt t4, t3, check_second_place
	
	li a7, 4
	la a0, playermsg
	ecall
	
	li a7, 1
	mv a0, t3
	ecall
	
	li a7, 4
	la a0, longspace
	ecall
	
	li a7, 1
	mv a0, t2
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	j check_second_place

check_second_place:
	lb t2, parallelFearGauge+1
	lb t3, parallelTrackPlayer+1
	
	blt t4, t3, check_third_place
	
	li a7, 4
	la a0, playermsg
	ecall
	
	li a7, 1
	mv a0, t3
	ecall
	
	li a7, 4
	la a0, longspace
	ecall
	
	li a7, 1
	mv a0, t2
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	j check_third_place

check_third_place:
	lb t2, parallelFearGauge+2
	lb t3, parallelTrackPlayer+2
	
	blt t4, t3, check_fourth_place
	
	li a7, 4
	la a0, playermsg
	ecall
	
	li a7, 1
	mv a0, t3
	ecall
	
	li a7, 4
	la a0, longspace
	ecall
	
	li a7, 1
	mv a0, t2
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	j check_fourth_place

check_fourth_place:
	lb t2, parallelFearGauge+3
	lb t3, parallelTrackPlayer+3
	
	blt t4, t3, end_standings_display
	
	li a7, 4
	la a0, playermsg
	ecall
	
	li a7, 1
	mv a0, t3
	ecall
	
	li a7, 4
	la a0, longspace
	ecall
	
	li a7, 1
	mv a0, t2
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	j end_standings_display
	
end_standings_display:

	li a7, 4
	la a0, border
	ecall
	
	li a7, 4
	la a0, newLineStr
	ecall
	
	li a7, 4
	la a0, press_anything_msg
	ecall
	
	li a7, 12
	ecall
	
	mv t0, a0
	
	li t1, 'r'
	beq t0, t1, restart
	
	li t1, 'q'
	beq t0, t1, exit
	
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra
	
