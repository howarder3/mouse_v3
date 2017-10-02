/**************************************
	Ū����register��Ӫ�G
	ldr r1, =#GPIOA_MODER
	ldr r2, =#LOAD
	ldr r3, =#DATA
	ldr r4, =#CLOCK
	ldr r5, =#GPIO_BSRR_OFFSET //on
	ldr r6, =#GPIO_BRR_OFFSET //off

	�i�Ϋ��O�����Ӫ�G
	str r2, [r1,r5] //DIN 1
	str r2, [r1,r6] //DIN 0
	str r3, [r1,r5] //CS 1
	str r3, [r1,r6] //CS 0
	str r4, [r1,r5] //CLK 1
	str r4, [r1,r6] //CLK 0

	code B decode mode digit��Ӫ�G
	digit 0-9	 0x0-0x9	//0000-1001
	digit - 	 0x10 		//1010
	digit blank	 0x15 		//1111

**************************************/
.data

.text
	.global max7219_init
	.global max7219_send
	.global Delay_1ms
	.global Delay_1s

//-------------GPIO�]�w-------------//
.equ RCC_AHB2ENR, 0x4002104C
//portA
.equ GPIOA_MODER, 0x48000000
.equ GPIOA_IDR, 0x48000010 //IDR(iuput) offset 0x10
.equ GPIOA_ODR, 0x48000014 //ODR(output) offset 0x14

//portB
.equ GPIOB_MODER, 0x48000400
.equ GPIOB_IDR, 0x48000410 //IDR(iuput) offset 0x10
.equ GPIOB_ODR, 0x48000414 //ODR(output) offset 0x14

//portC
.equ GPIOC_MODER, 0x48000800
.equ GPIOC_IDR, 0x48000810 //IDR(iuput) offset 0x10
.equ GPIOC_ODR, 0x48000814 //ODR(output) offset 0x14
.equ GPIO_BSRR_OFFSET, 0x18 //on
.equ GPIO_BRR_OFFSET, 0x28 //off

//-------------�o��Ѧ�table2-------------//
.equ DECODE_MODE, 0x09 //1001
.equ INTENSITY, 0x0A //1010
.equ SCAN_LIMIT, 0x0B //1011
.equ SHUTDOWN, 0x0C //1100
.equ DISPLAY_TEST, 0x0F //1111

//-------------pin offset �]�w-------------//
.equ LOAD, 0x1 //PC0
.equ DATA, 0x2 //PC1
.equ CLOCK, 0x4 //PC2

//-------------delay loop �ѼƳ]�w-------------//
.equ delay_loop_num, 800 //1 msec
.equ delay_loop_num_1s, 8000 //1 sec

//-------------Delay register�ϥ�-------------//
//r6 delay cycle�˼�
Delay_1ms:
	push {r6,lr}
	ldr r6, =#delay_loop_num
	delay_loop: // 5 clocks(per loop)
		SUB r6, #1     //1 cplock
		CMP r6, #0     //1 clock
		BNE delay_loop  //3 clock
	pop {r6,pc}
	BX LR

//-------------Delay register�ϥ�-------------//
//r6 delay cycle�˼�
Delay_1s:
	push {r6,lr}
	ldr r6, =#delay_loop_num_1s
	delay_loop_1s: // 5 clocks(per loop)
		SUB r6, #1     //1 cplock
		CMP r6, #0     //1 clock
		BNE delay_loop_1s  //3 clock
	pop {r6,pc}
	BX LR

//-------------max7219_send register�ϥ�-------------//
//r0 is D11-D8
//r1 is D7-D0
//r2 �p�⻲�U��
//r7 �p��{�bŪ��ĴX��bit �ϥΪ�i��
max7219_send:
push {r4,r5,r6,r7}
	lsl r0, #8 // R0�ȥ���8�� �Y�]�wD11-D8
	add r0, r0, r1 // R1�N���OD7-D0����,��̬ۥ[���r0,�Y�n�s�J15bit����
	mov r7, #16 //r7 = i
read_loop:
	cmp r7,#0 //i=0  ���Ū��16��
	beq CS
	mov r2,#1 //r2 = 1
	lsl r2,r2,r7  //1 * 2^i
	lsr r2,#1  // r2/2 r2 = 1000 0000 0000 0000 when i = 16

	mov r1,r2 //r2 copy�� r1
	and r2,r2,r0 //r2&&r0 �Ӧ�1 = 1 �Ӧ�0 = 0

	cmp r2,r1 // ���and�᪺r2 �P �����r2(r1)
	beq DIN1 //�ۦP��1 DIN1
	bne DIN0 //���P��0 DIN0
end_one_cycle:
	sub r7,#1 //i--
	B read_loop

//-------------DIN1,DIN0,CS register�ϥ�-------------//
//	ldr r1, =#GPIOA_MODER
//	ldr r2, =#LOAD
//	ldr r3, =#DATA
//	ldr r4, =#CLOCK
//	ldr r5, =#GPIO_BSRR_OFFSET //on
//	ldr r6, =#GPIO_BRR_OFFSET //off
DIN1:
	ldr r1, =#GPIOC_MODER
	ldr r2, =#LOAD
	ldr r3, =#DATA
	ldr r4, =#CLOCK
	ldr r5, =#GPIO_BSRR_OFFSET //on
	ldr r6, =#GPIO_BRR_OFFSET //off
	str r2, [r1,r5] //DIN 1
	str r3, [r1,r6] //CS 0
	str r4, [r1,r5] //CLK 1
	str r4, [r1,r6] //CLK 0
	B end_one_cycle

DIN0:
	ldr r1, =#GPIOC_MODER
	ldr r2, =#LOAD
	ldr r3, =#DATA
	ldr r4, =#CLOCK
	ldr r5, =#GPIO_BSRR_OFFSET //on
	ldr r6, =#GPIO_BRR_OFFSET //off
	str r2, [r1,r6] //DIN 0
	str r3, [r1,r6] //CS 0
	str r4, [r1,r5] //CLK 1
	str r4, [r1,r6] //CLK 0
	B end_one_cycle

CS:
	ldr r1, =#GPIOC_MODER
	ldr r2, =#LOAD
	ldr r3, =#DATA
	ldr r4, =#CLOCK
	ldr r5, =#GPIO_BSRR_OFFSET //on
	ldr r6, =#GPIO_BRR_OFFSET //off
	//CS on
	str r2, [r1,r6] //DIN 0
	str r3, [r1,r5] //CS 1
	str r4, [r1,r5] //CLK 1
	str r4, [r1,r6] //CLK 0
	//CS off
	str r2, [r1,r6] //DIN 0
	str r3, [r1,r6] //CS 0
	str r4, [r1,r5] //CLK 1
	str r4, [r1,r6] //CLK 0
	pop {r4,r5,r6,r7}
	BX LR

//-------------max7219_init register�ϥ�-------------//
//r0 is D11-D8
//r1 is D7-D0
max7219_init:
	push {r0, r1, r2, lr}
	//decode mode: Code B decode mode for digits 7-0
	ldr r0, =#DECODE_MODE
	ldr r1, =#0xFF
	BL max7219_send
	//display test : off
	ldr r0, =#DISPLAY_TEST
	ldr r1, =#0x0
	BL max7219_send
	//scan limit: 7 digits display
	ldr r0, =#SCAN_LIMIT
	ldr r1, =#0x7
	BL max7219_send
	//intensity : 0xA�G
	ldr r0, =#INTENSITY
	ldr r1, =#0xA
	BL max7219_send
	//shut down : normal operation
	ldr r0, =#SHUTDOWN
	ldr r1, =#0x1
	BL max7219_send
	pop {r0, r1, r2, pc}
	BX LR

//-------------main-------------//
main:
main_end_loop:
	B main_end_loop
