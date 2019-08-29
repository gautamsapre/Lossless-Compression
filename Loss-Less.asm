# CS 3340
# Gautam Sapre


		.data
Count: 		.word 0
Word: 		.word 0
Length:		.word 0
CompressedLength: .word 0

buffer1: 	.space 1024
buffer2: 	.space 1024
buffer3: 	.space 1024
bufferEmpty: 	.space 1024

newLine: 	.asciiz "\n"
InpName: 	.asciiz ""
Enter: 		.asciiz "Please enter the filename to compress of <enter> to exit: "
Enter2: 	.asciiz "Please enter the filename to compress of <enter> to exit: "
Error: 		.asciiz "Error opening file. Project terminating. "
compressedData: .asciiz "Compressed data:\n"
originalData: 	.asciiz "Original data:\n"
uncompressedData: .asciiz "Uncompressed data:\n"
CompSize: 	.asciiz "Compressed file size: "
OrigSize:	.asciiz "Original file size: "


		.text
#Macros
	.macro InputFileName
	la $a0, InpName 
	.end_macro
	
	.macro OpenFile	
	 li $v0, 13      
    	 li $a1, 0       
    	 li $a2, 0       
    	 syscall
    	 .end_macro
    	 
	.macro PrintStr(%str) 	# Macro to Print
	li $v0, 4      		# code 4 == print string
	la $a0, %str  		# $a0 == address of the string
	syscall    
	.end_macro
	
	.macro PrintNum(%x)
	lw $a0, %x
	li $v0, 1
	syscall
	.end_macro
	
	.macro LoadBuffer (%x,%str)
	la %x, %str 
	.end_macro
	
	.macro StoreChars
	li $t7, 0
	StoreCharacters:
		sb $t1, ($a1) # store the byte
		addi $t7, $t7, 1 # Increment 
		addi $a1, $a1, 1 # Increment byte in buffer3
		addi $t0, $t0, 1 # Increment the size
		bne $t7, $t3, StoreCharacters
	.end_macro
	.macro checkFor2Digit
	beq $t2, $t3, Loop2 		#if the character is the same as the next character branch
	sb $t2, ($a1)			#store the character into buffer2
	addi $a1, $a1, 1
	li $t6, 0 # let iterator to 0
	bgt $t1, 9, DigitConversion
	.end_macro
	
	.macro btm
	jr $ra
	.end_macro
	
main:	
	PrintStr(Enter2) 
	 
	InputFileName		# Call input for File
	li $v0, 8
	li $a1, 21
	syscall
	
	InputFileName
	lb $t1, ($a0)
	beq $t1, 10, End 
	
	li $t0, 0       	#loop counter
    	li $t1, 21      	
	jal clean 		#Clean FIle
	
	InputFileName		# Open the file
	la $a1, buffer1
	jal fileReadFunction 
	
	LoadBuffer($a0,buffer1) 
	li $t0, 0
	li $t2, 0	
	jal getFileLength		# Get the size in the buffer
	
	PrintStr (originalData)
	PrintStr (buffer1) 
	PrintStr (newLine) 
	PrintStr (compressedData)	

	LoadBuffer($a0,buffer1) 	#Load Buffers
	LoadBuffer($a1,buffer2)	
	 
	lw $a2, Length 			# Load the size of buffer1
	li $t0, 0 			# iteration
	li $t5, 0 			# Compressed File 
	jal Loop1 		
	sw $v0, CompressedLength 	# Compress Size is saved
	
	PrintStr (buffer2) 
	PrintStr (newLine) 
	PrintStr (uncompressedData) 
	LoadBuffer($a0,buffer2) 	# Load buffer2
	LoadBuffer($a1,buffer3)		# Load buffer3
	lw $a2, Length 			# Load the size of buffer1
	li $t0, 0
	jal uncompress 			# Jump to the Uncompression function
	
	#Print Everything
	PrintStr (buffer3) 
	PrintStr (newLine) 
	PrintStr (OrigSize) 
	PrintNum (Length)
	PrintStr (newLine) 
	PrintStr (CompSize)
	PrintNum (CompressedLength)
	PrintStr (newLine) 
	PrintStr (newLine) 
	
	j main
	
#Reading the File
fileReadFunction: # Open file 

    	 OpenFile
    	 move $s0, $v0      
    	 bltz $v0, printError  #If the file doesnt open return an error
    	 
   	 li $v0, 14      
   	 move $a0, $s0       
   	 la $a1, buffer1     
   	 li $a2, 1024       
   	 syscall
   	 
   	 add $a1, $a1, $v0 #Stores a null pointer
   	 sb $0, ($a1) 	
   	 li $v0, 16     
	 move $a0, $s0     
	 syscall       
	 
	 btm

getFileLength:
	lb $t1, ($a0)
	addi $t0, $t0, 1 	#increase size iteration
	addi $a0, $a0, 1 	#increment the buffer
	beq  $t1, 13, remLines 	#if the byte is a newline
	bne $t1, $zero, getFileLength
remLines:
	addi $t2, $t2, 1	#iterate the number of newLines
	bne $t1, $zero, getFileLength
	sub $t0, $t0, $t2 	#subtract the number of newlines from the buffer size
	sw $t0, Length
	btm
	
#Clean the Input Name
clean:
    	 beq $t0, $t1, BacktoMain
    	 lb $t3, InpName($t0) 		#load byte from filename
    	 bne $t3, 0x0a, Increment 	#increment the byte in filename
   	 sb $zero, InpName($t0) 
Increment:
   	 addi $t0, $t0, 1 		#Add on to the iterator
         j clean
BacktoMain:
	 btm

#Compress
Loop1:
	beq $t0, $a2, ExitLoop 		#Loop Checker
	li $t1, 0 			
Loop2:
	lb $t2, ($a0)			
	beq $t2, 13, SkipNewLine 	
	addi $t4, $a0, 1
	lb $t3, ($t4) 			#load the next byte from buffer1
	addi $t1, $t1, 1
	addi $a0, $a0, 1
	addi $t0, $t0, 1
 	checkFor2Digit			# check if the number is 2 digit
	addi $t1, $t1, 48
	sb $t1, ($a1) 			# store the one digit number
	addi $a1, $a1, 1 
	addi $t5, $t5, 2 		# increment buffer size by 2
	
	j Loop1 			
		
DigitConversion:
	subi $t1, $t1, 10		
	addi $t6, $t6, 1 		
	bgt $t1, 10, DigitConversion
	addi $t6, $t6, 48 		# add to get the ascii value
	sb $t6, ($a1) 			# store the byte in buffer2
	addi $a1, $a1, 1
	addi $t1, $t1, 48 		
	sb $t1, ($a1)			
	addi $a1, $a1, 1
	addi $t5, $t5, 2 		# Increment size by 2
	j Loop1

SkipNewLine:
	addi $a0, $a0, 1 		# we arent counting the newlines
	j Loop1
ExitLoop:
	sb $0, ($a1) 			#stores new line at end of the buffer2
	move $v0, $t5 			#move t5, to v0
	btm

#Uncompress
uncompress:
	beq $t0, $a2, Exit 	# if the iterator reaches the size
	
	lb $t1, ($a0) 		# load byte from buffer2
	addi $t2, $a0, 1 	# get the next byte
	
	lb $t3, ($t2)
	subi $t3, $t3, 48
	
	addi $t4, $a0, 2 	
	lb $t5, ($t4) 		
	subi $t5, $t5, 48 	# get decimal value
	li $t6, 0
	
CheckIfDec:
	beq $t6, $t5, TwoDecimal# Calls twoDecimal if the byte is deciaml
	addi $t6, $t6, 1 	
	ble  $t6, 9, CheckIfDec # Check if the byte is a deciaml
	StoreChars
	addi $a0, $a0, 2 	# move through the buffer2 by 2
	j uncompress
	
TwoDecimal:
	mul $t3, $t3, 10
	add $t3, $t3, $t5 	# get real number of iterations
	StoreChars
	addi $a0, $a0, 3 	
	j uncompress
Exit:
	sb $0, ($a1) 	# stores new line at end of the buffer3
	btm
	 
#End
printError:
	PrintStr (Error)  
End:
	li $v0, 10
	syscall
