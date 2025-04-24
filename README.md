# Tetris Game
## Overview 
This program is an alternative version of Tetris game developed using MIPS assembly language (a low-level programming language used to program MIPS processors). The user will use keyboard to control the movement and rotation of the shape within the big rectangular red border. The shape will not fall automatically unless you press the w key. In this game, there are 4 different shapes that you might encountered (l shape, L shape, J shape, and O shape). The shape presented will be random. The small box beside the game border will show the next available shape. The goal is to prevent the shape from touching the top row within the border. If it does, the program will end. The user will position shapes to fill rows. However, a shape can only move or rotate at black spaces inside the border. When a row is filled, it can be cleared by pressing the enter key and all shapes above the row will move down a row. To exit the program, press the tab key.

## Instructions
### Game setup instructions: 
1.	Open MARS IDE (lightweight interactive development environment for programming in MIPS assembly language)
2.	Open Bitmap Display (Tools -> Bitmap Display)
3.	Set both unit width and unit height to 16
4.	Set both display width and display weight to 512
5.	Set base address to $gp
6.	Connect it to MIPS
7.	Open Keyboard Simulator (Tools -> Keyboard and Display MMIO Simulator)
8.	Connect it to MIPS
### Game instructions: 
- Press key ‘w’ to rotate the shape
- Press key ‘a’ to move the shape left one space
- Press key ‘d’ to move the shape right one space
- Press key ‘s’ to move the shape down one space
- Press key ‘space’ to get the next shape on top
- Press key ‘return’ or ‘enter’ to clear a row if any is filled
- Press key ‘tab’ to exit the game
- When a shape reaches the top row within the border, game exits

## Warnings
- Don’t press the space key two or more times continuously. This will cause the program to exit
- Don’t hold the key. Press it one at a time. 
- Sometime the response might delay.

## Flowchart
<img width="469" alt="image" src="https://github.com/user-attachments/assets/abfd1772-3297-45bf-a675-7ea7fbe34d35" />

## Screenshots of sample run
### Start of the game
<img width="177" alt="image" src="https://github.com/user-attachments/assets/ba718e15-6845-4e34-bf59-d9afb640d127" />

### Before clearing a row
<img width="173" alt="image" src="https://github.com/user-attachments/assets/14859b68-db8b-4f59-91d7-c5cb9a94eb47" />

### After clearing a row
<img width="177" alt="image" src="https://github.com/user-attachments/assets/e215022b-abcf-4a4e-95b3-1c33e80a8939" />

### Game failure
<img width="181" alt="image" src="https://github.com/user-attachments/assets/573596c8-a287-4630-9a13-9b9ec55410c3" />

