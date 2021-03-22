
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	a8c78793          	addi	a5,a5,-1396 # 80005af0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	31a080e7          	jalr	794(ra) # 80002438 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	7cc080e7          	jalr	1996(ra) # 8000197e <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	e7c080e7          	jalr	-388(ra) # 8000203e <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	1e4080e7          	jalr	484(ra) # 800023e2 <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	1b0080e7          	jalr	432(ra) # 8000248e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	d98080e7          	jalr	-616(ra) # 800021ca <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	eb478793          	addi	a5,a5,-332 # 80021318 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	94c080e7          	jalr	-1716(ra) # 800021ca <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	734080e7          	jalr	1844(ra) # 8000203e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	00025797          	auipc	a5,0x25
    800009ee:	61678793          	addi	a5,a5,1558 # 80026000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	e06080e7          	jalr	-506(ra) # 80001962 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	dd4080e7          	jalr	-556(ra) # 80001962 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	dc8080e7          	jalr	-568(ra) # 80001962 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	db0080e7          	jalr	-592(ra) # 80001962 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	d70080e7          	jalr	-656(ra) # 80001962 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	d44080e7          	jalr	-700(ra) # 80001962 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	ade080e7          	jalr	-1314(ra) # 80001952 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
  if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	ac2080e7          	jalr	-1342(ra) # 80001952 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	71c080e7          	jalr	1820(ra) # 800025ce <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	c76080e7          	jalr	-906(ra) # 80005b30 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	fca080e7          	jalr	-54(ra) # 80001e8c <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	310080e7          	jalr	784(ra) # 80001222 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	980080e7          	jalr	-1664(ra) # 800018a2 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	67c080e7          	jalr	1660(ra) # 800025a6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	69c080e7          	jalr	1692(ra) # 800025ce <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	be0080e7          	jalr	-1056(ra) # 80005b1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	bee080e7          	jalr	-1042(ra) # 80005b30 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	dc4080e7          	jalr	-572(ra) # 80002d0e <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	454080e7          	jalr	1108(ra) # 800033a6 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	3fe080e7          	jalr	1022(ra) # 80004358 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	cf0080e7          	jalr	-784(ra) # 80005c52 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	cec080e7          	jalr	-788(ra) # 80001c56 <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00008717          	auipc	a4,0x8
    80000f7c:	0af72023          	sw	a5,160(a4) # 80009018 <started>
    80000f80:	b789                	j	80000ec2 <main+0x56>

0000000080000f82 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0987b783          	ld	a5,152(a5) # 80009020 <kernel_pagetable>
    80000f90:	83b1                	srli	a5,a5,0xc
    80000f92:	577d                	li	a4,-1
    80000f94:	177e                	slli	a4,a4,0x3f
    80000f96:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f98:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa6:	7139                	addi	sp,sp,-64
    80000fa8:	fc06                	sd	ra,56(sp)
    80000faa:	f822                	sd	s0,48(sp)
    80000fac:	f426                	sd	s1,40(sp)
    80000fae:	f04a                	sd	s2,32(sp)
    80000fb0:	ec4e                	sd	s3,24(sp)
    80000fb2:	e852                	sd	s4,16(sp)
    80000fb4:	e456                	sd	s5,8(sp)
    80000fb6:	e05a                	sd	s6,0(sp)
    80000fb8:	0080                	addi	s0,sp,64
    80000fba:	84aa                	mv	s1,a0
    80000fbc:	89ae                	mv	s3,a1
    80000fbe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc0:	57fd                	li	a5,-1
    80000fc2:	83e9                	srli	a5,a5,0x1a
    80000fc4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc8:	04b7f263          	bgeu	a5,a1,8000100c <walk+0x66>
    panic("walk");
    80000fcc:	00007517          	auipc	a0,0x7
    80000fd0:	10450513          	addi	a0,a0,260 # 800080d0 <digits+0x90>
    80000fd4:	fffff097          	auipc	ra,0xfffff
    80000fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fdc:	060a8663          	beqz	s5,80001048 <walk+0xa2>
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	af2080e7          	jalr	-1294(ra) # 80000ad2 <kalloc>
    80000fe8:	84aa                	mv	s1,a0
    80000fea:	c529                	beqz	a0,80001034 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fec:	6605                	lui	a2,0x1
    80000fee:	4581                	li	a1,0
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	cce080e7          	jalr	-818(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff8:	00c4d793          	srli	a5,s1,0xc
    80000ffc:	07aa                	slli	a5,a5,0xa
    80000ffe:	0017e793          	ori	a5,a5,1
    80001002:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001006:	3a5d                	addiw	s4,s4,-9
    80001008:	036a0063          	beq	s4,s6,80001028 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000100c:	0149d933          	srl	s2,s3,s4
    80001010:	1ff97913          	andi	s2,s2,511
    80001014:	090e                	slli	s2,s2,0x3
    80001016:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001018:	00093483          	ld	s1,0(s2)
    8000101c:	0014f793          	andi	a5,s1,1
    80001020:	dfd5                	beqz	a5,80000fdc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001022:	80a9                	srli	s1,s1,0xa
    80001024:	04b2                	slli	s1,s1,0xc
    80001026:	b7c5                	j	80001006 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001028:	00c9d513          	srli	a0,s3,0xc
    8000102c:	1ff57513          	andi	a0,a0,511
    80001030:	050e                	slli	a0,a0,0x3
    80001032:	9526                	add	a0,a0,s1
}
    80001034:	70e2                	ld	ra,56(sp)
    80001036:	7442                	ld	s0,48(sp)
    80001038:	74a2                	ld	s1,40(sp)
    8000103a:	7902                	ld	s2,32(sp)
    8000103c:	69e2                	ld	s3,24(sp)
    8000103e:	6a42                	ld	s4,16(sp)
    80001040:	6aa2                	ld	s5,8(sp)
    80001042:	6b02                	ld	s6,0(sp)
    80001044:	6121                	addi	sp,sp,64
    80001046:	8082                	ret
        return 0;
    80001048:	4501                	li	a0,0
    8000104a:	b7ed                	j	80001034 <walk+0x8e>

000000008000104c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000104c:	57fd                	li	a5,-1
    8000104e:	83e9                	srli	a5,a5,0x1a
    80001050:	00b7f463          	bgeu	a5,a1,80001058 <walkaddr+0xc>
    return 0;
    80001054:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001056:	8082                	ret
{
    80001058:	1141                	addi	sp,sp,-16
    8000105a:	e406                	sd	ra,8(sp)
    8000105c:	e022                	sd	s0,0(sp)
    8000105e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001060:	4601                	li	a2,0
    80001062:	00000097          	auipc	ra,0x0
    80001066:	f44080e7          	jalr	-188(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000106a:	c105                	beqz	a0,8000108a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000106c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000106e:	0117f693          	andi	a3,a5,17
    80001072:	4745                	li	a4,17
    return 0;
    80001074:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001076:	00e68663          	beq	a3,a4,80001082 <walkaddr+0x36>
}
    8000107a:	60a2                	ld	ra,8(sp)
    8000107c:	6402                	ld	s0,0(sp)
    8000107e:	0141                	addi	sp,sp,16
    80001080:	8082                	ret
  pa = PTE2PA(*pte);
    80001082:	00a7d513          	srli	a0,a5,0xa
    80001086:	0532                	slli	a0,a0,0xc
  return pa;
    80001088:	bfcd                	j	8000107a <walkaddr+0x2e>
    return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7fd                	j	8000107a <walkaddr+0x2e>

000000008000108e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000108e:	715d                	addi	sp,sp,-80
    80001090:	e486                	sd	ra,72(sp)
    80001092:	e0a2                	sd	s0,64(sp)
    80001094:	fc26                	sd	s1,56(sp)
    80001096:	f84a                	sd	s2,48(sp)
    80001098:	f44e                	sd	s3,40(sp)
    8000109a:	f052                	sd	s4,32(sp)
    8000109c:	ec56                	sd	s5,24(sp)
    8000109e:	e85a                	sd	s6,16(sp)
    800010a0:	e45e                	sd	s7,8(sp)
    800010a2:	0880                	addi	s0,sp,80
    800010a4:	8aaa                	mv	s5,a0
    800010a6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010a8:	777d                	lui	a4,0xfffff
    800010aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ae:	167d                	addi	a2,a2,-1
    800010b0:	00b609b3          	add	s3,a2,a1
    800010b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b8:	893e                	mv	s2,a5
    800010ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010be:	6b85                	lui	s7,0x1
    800010c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c4:	4605                	li	a2,1
    800010c6:	85ca                	mv	a1,s2
    800010c8:	8556                	mv	a0,s5
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	edc080e7          	jalr	-292(ra) # 80000fa6 <walk>
    800010d2:	c51d                	beqz	a0,80001100 <mappages+0x72>
    if(*pte & PTE_V)
    800010d4:	611c                	ld	a5,0(a0)
    800010d6:	8b85                	andi	a5,a5,1
    800010d8:	ef81                	bnez	a5,800010f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010da:	80b1                	srli	s1,s1,0xc
    800010dc:	04aa                	slli	s1,s1,0xa
    800010de:	0164e4b3          	or	s1,s1,s6
    800010e2:	0014e493          	ori	s1,s1,1
    800010e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e8:	03390863          	beq	s2,s3,80001118 <mappages+0x8a>
    a += PGSIZE;
    800010ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ee:	bfc9                	j	800010c0 <mappages+0x32>
      panic("remap");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	432080e7          	jalr	1074(ra) # 8000052a <panic>
      return -1;
    80001100:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001102:	60a6                	ld	ra,72(sp)
    80001104:	6406                	ld	s0,64(sp)
    80001106:	74e2                	ld	s1,56(sp)
    80001108:	7942                	ld	s2,48(sp)
    8000110a:	79a2                	ld	s3,40(sp)
    8000110c:	7a02                	ld	s4,32(sp)
    8000110e:	6ae2                	ld	s5,24(sp)
    80001110:	6b42                	ld	s6,16(sp)
    80001112:	6ba2                	ld	s7,8(sp)
    80001114:	6161                	addi	sp,sp,80
    80001116:	8082                	ret
  return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7e5                	j	80001102 <mappages+0x74>

000000008000111c <kvmmap>:
{
    8000111c:	1141                	addi	sp,sp,-16
    8000111e:	e406                	sd	ra,8(sp)
    80001120:	e022                	sd	s0,0(sp)
    80001122:	0800                	addi	s0,sp,16
    80001124:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001126:	86b2                	mv	a3,a2
    80001128:	863e                	mv	a2,a5
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	f64080e7          	jalr	-156(ra) # 8000108e <mappages>
    80001132:	e509                	bnez	a0,8000113c <kvmmap+0x20>
}
    80001134:	60a2                	ld	ra,8(sp)
    80001136:	6402                	ld	s0,0(sp)
    80001138:	0141                	addi	sp,sp,16
    8000113a:	8082                	ret
    panic("kvmmap");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	fa450513          	addi	a0,a0,-92 # 800080e0 <digits+0xa0>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>

000000008000114c <kvmmake>:
{
    8000114c:	1101                	addi	sp,sp,-32
    8000114e:	ec06                	sd	ra,24(sp)
    80001150:	e822                	sd	s0,16(sp)
    80001152:	e426                	sd	s1,8(sp)
    80001154:	e04a                	sd	s2,0(sp)
    80001156:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	97a080e7          	jalr	-1670(ra) # 80000ad2 <kalloc>
    80001160:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001162:	6605                	lui	a2,0x1
    80001164:	4581                	li	a1,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	b58080e7          	jalr	-1192(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000116e:	4719                	li	a4,6
    80001170:	6685                	lui	a3,0x1
    80001172:	10000637          	lui	a2,0x10000
    80001176:	100005b7          	lui	a1,0x10000
    8000117a:	8526                	mv	a0,s1
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	fa0080e7          	jalr	-96(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001184:	4719                	li	a4,6
    80001186:	6685                	lui	a3,0x1
    80001188:	10001637          	lui	a2,0x10001
    8000118c:	100015b7          	lui	a1,0x10001
    80001190:	8526                	mv	a0,s1
    80001192:	00000097          	auipc	ra,0x0
    80001196:	f8a080e7          	jalr	-118(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000119a:	4719                	li	a4,6
    8000119c:	004006b7          	lui	a3,0x400
    800011a0:	0c000637          	lui	a2,0xc000
    800011a4:	0c0005b7          	lui	a1,0xc000
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f72080e7          	jalr	-142(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011b2:	00007917          	auipc	s2,0x7
    800011b6:	e4e90913          	addi	s2,s2,-434 # 80008000 <etext>
    800011ba:	4729                	li	a4,10
    800011bc:	80007697          	auipc	a3,0x80007
    800011c0:	e4468693          	addi	a3,a3,-444 # 8000 <_entry-0x7fff8000>
    800011c4:	4605                	li	a2,1
    800011c6:	067e                	slli	a2,a2,0x1f
    800011c8:	85b2                	mv	a1,a2
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f50080e7          	jalr	-176(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011d4:	4719                	li	a4,6
    800011d6:	46c5                	li	a3,17
    800011d8:	06ee                	slli	a3,a3,0x1b
    800011da:	412686b3          	sub	a3,a3,s2
    800011de:	864a                	mv	a2,s2
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f38080e7          	jalr	-200(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011ec:	4729                	li	a4,10
    800011ee:	6685                	lui	a3,0x1
    800011f0:	00006617          	auipc	a2,0x6
    800011f4:	e1060613          	addi	a2,a2,-496 # 80007000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f1a080e7          	jalr	-230(ra) # 8000111c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000120a:	8526                	mv	a0,s1
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	600080e7          	jalr	1536(ra) # 8000180c <proc_mapstacks>
}
    80001214:	8526                	mv	a0,s1
    80001216:	60e2                	ld	ra,24(sp)
    80001218:	6442                	ld	s0,16(sp)
    8000121a:	64a2                	ld	s1,8(sp)
    8000121c:	6902                	ld	s2,0(sp)
    8000121e:	6105                	addi	sp,sp,32
    80001220:	8082                	ret

0000000080001222 <kvminit>:
{
    80001222:	1141                	addi	sp,sp,-16
    80001224:	e406                	sd	ra,8(sp)
    80001226:	e022                	sd	s0,0(sp)
    80001228:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f22080e7          	jalr	-222(ra) # 8000114c <kvmmake>
    80001232:	00008797          	auipc	a5,0x8
    80001236:	dea7b723          	sd	a0,-530(a5) # 80009020 <kernel_pagetable>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret

0000000080001242 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001242:	715d                	addi	sp,sp,-80
    80001244:	e486                	sd	ra,72(sp)
    80001246:	e0a2                	sd	s0,64(sp)
    80001248:	fc26                	sd	s1,56(sp)
    8000124a:	f84a                	sd	s2,48(sp)
    8000124c:	f44e                	sd	s3,40(sp)
    8000124e:	f052                	sd	s4,32(sp)
    80001250:	ec56                	sd	s5,24(sp)
    80001252:	e85a                	sd	s6,16(sp)
    80001254:	e45e                	sd	s7,8(sp)
    80001256:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001258:	03459793          	slli	a5,a1,0x34
    8000125c:	e795                	bnez	a5,80001288 <uvmunmap+0x46>
    8000125e:	8a2a                	mv	s4,a0
    80001260:	892e                	mv	s2,a1
    80001262:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001264:	0632                	slli	a2,a2,0xc
    80001266:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000126a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126c:	6b05                	lui	s6,0x1
    8000126e:	0735e263          	bltu	a1,s3,800012d2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001272:	60a6                	ld	ra,72(sp)
    80001274:	6406                	ld	s0,64(sp)
    80001276:	74e2                	ld	s1,56(sp)
    80001278:	7942                	ld	s2,48(sp)
    8000127a:	79a2                	ld	s3,40(sp)
    8000127c:	7a02                	ld	s4,32(sp)
    8000127e:	6ae2                	ld	s5,24(sp)
    80001280:	6b42                	ld	s6,16(sp)
    80001282:	6ba2                	ld	s7,8(sp)
    80001284:	6161                	addi	sp,sp,80
    80001286:	8082                	ret
    panic("uvmunmap: not aligned");
    80001288:	00007517          	auipc	a0,0x7
    8000128c:	e6050513          	addi	a0,a0,-416 # 800080e8 <digits+0xa8>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	29a080e7          	jalr	666(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e6850513          	addi	a0,a0,-408 # 80008100 <digits+0xc0>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e6850513          	addi	a0,a0,-408 # 80008110 <digits+0xd0>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e7050513          	addi	a0,a0,-400 # 80008128 <digits+0xe8>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
    *pte = 0;
    800012c8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012cc:	995a                	add	s2,s2,s6
    800012ce:	fb3972e3          	bgeu	s2,s3,80001272 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012d2:	4601                	li	a2,0
    800012d4:	85ca                	mv	a1,s2
    800012d6:	8552                	mv	a0,s4
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	cce080e7          	jalr	-818(ra) # 80000fa6 <walk>
    800012e0:	84aa                	mv	s1,a0
    800012e2:	d95d                	beqz	a0,80001298 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012e4:	6108                	ld	a0,0(a0)
    800012e6:	00157793          	andi	a5,a0,1
    800012ea:	dfdd                	beqz	a5,800012a8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ec:	3ff57793          	andi	a5,a0,1023
    800012f0:	fd7784e3          	beq	a5,s7,800012b8 <uvmunmap+0x76>
    if(do_free){
    800012f4:	fc0a8ae3          	beqz	s5,800012c8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800012f8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fa:	0532                	slli	a0,a0,0xc
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	6da080e7          	jalr	1754(ra) # 800009d6 <kfree>
    80001304:	b7d1                	j	800012c8 <uvmunmap+0x86>

0000000080001306 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001306:	1101                	addi	sp,sp,-32
    80001308:	ec06                	sd	ra,24(sp)
    8000130a:	e822                	sd	s0,16(sp)
    8000130c:	e426                	sd	s1,8(sp)
    8000130e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001310:	fffff097          	auipc	ra,0xfffff
    80001314:	7c2080e7          	jalr	1986(ra) # 80000ad2 <kalloc>
    80001318:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000131a:	c519                	beqz	a0,80001328 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000131c:	6605                	lui	a2,0x1
    8000131e:	4581                	li	a1,0
    80001320:	00000097          	auipc	ra,0x0
    80001324:	99e080e7          	jalr	-1634(ra) # 80000cbe <memset>
  return pagetable;
}
    80001328:	8526                	mv	a0,s1
    8000132a:	60e2                	ld	ra,24(sp)
    8000132c:	6442                	ld	s0,16(sp)
    8000132e:	64a2                	ld	s1,8(sp)
    80001330:	6105                	addi	sp,sp,32
    80001332:	8082                	ret

0000000080001334 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001334:	7179                	addi	sp,sp,-48
    80001336:	f406                	sd	ra,40(sp)
    80001338:	f022                	sd	s0,32(sp)
    8000133a:	ec26                	sd	s1,24(sp)
    8000133c:	e84a                	sd	s2,16(sp)
    8000133e:	e44e                	sd	s3,8(sp)
    80001340:	e052                	sd	s4,0(sp)
    80001342:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001344:	6785                	lui	a5,0x1
    80001346:	04f67863          	bgeu	a2,a5,80001396 <uvminit+0x62>
    8000134a:	8a2a                	mv	s4,a0
    8000134c:	89ae                	mv	s3,a1
    8000134e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	782080e7          	jalr	1922(ra) # 80000ad2 <kalloc>
    80001358:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	960080e7          	jalr	-1696(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001366:	4779                	li	a4,30
    80001368:	86ca                	mv	a3,s2
    8000136a:	6605                	lui	a2,0x1
    8000136c:	4581                	li	a1,0
    8000136e:	8552                	mv	a0,s4
    80001370:	00000097          	auipc	ra,0x0
    80001374:	d1e080e7          	jalr	-738(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    80001378:	8626                	mv	a2,s1
    8000137a:	85ce                	mv	a1,s3
    8000137c:	854a                	mv	a0,s2
    8000137e:	00000097          	auipc	ra,0x0
    80001382:	99c080e7          	jalr	-1636(ra) # 80000d1a <memmove>
}
    80001386:	70a2                	ld	ra,40(sp)
    80001388:	7402                	ld	s0,32(sp)
    8000138a:	64e2                	ld	s1,24(sp)
    8000138c:	6942                	ld	s2,16(sp)
    8000138e:	69a2                	ld	s3,8(sp)
    80001390:	6a02                	ld	s4,0(sp)
    80001392:	6145                	addi	sp,sp,48
    80001394:	8082                	ret
    panic("inituvm: more than a page");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	daa50513          	addi	a0,a0,-598 # 80008140 <digits+0x100>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>

00000000800013a6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013a6:	1101                	addi	sp,sp,-32
    800013a8:	ec06                	sd	ra,24(sp)
    800013aa:	e822                	sd	s0,16(sp)
    800013ac:	e426                	sd	s1,8(sp)
    800013ae:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013b0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013b2:	00b67d63          	bgeu	a2,a1,800013cc <uvmdealloc+0x26>
    800013b6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013b8:	6785                	lui	a5,0x1
    800013ba:	17fd                	addi	a5,a5,-1
    800013bc:	00f60733          	add	a4,a2,a5
    800013c0:	767d                	lui	a2,0xfffff
    800013c2:	8f71                	and	a4,a4,a2
    800013c4:	97ae                	add	a5,a5,a1
    800013c6:	8ff1                	and	a5,a5,a2
    800013c8:	00f76863          	bltu	a4,a5,800013d8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013cc:	8526                	mv	a0,s1
    800013ce:	60e2                	ld	ra,24(sp)
    800013d0:	6442                	ld	s0,16(sp)
    800013d2:	64a2                	ld	s1,8(sp)
    800013d4:	6105                	addi	sp,sp,32
    800013d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013d8:	8f99                	sub	a5,a5,a4
    800013da:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013dc:	4685                	li	a3,1
    800013de:	0007861b          	sext.w	a2,a5
    800013e2:	85ba                	mv	a1,a4
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	e5e080e7          	jalr	-418(ra) # 80001242 <uvmunmap>
    800013ec:	b7c5                	j	800013cc <uvmdealloc+0x26>

00000000800013ee <uvmalloc>:
  if(newsz < oldsz)
    800013ee:	0ab66163          	bltu	a2,a1,80001490 <uvmalloc+0xa2>
{
    800013f2:	7139                	addi	sp,sp,-64
    800013f4:	fc06                	sd	ra,56(sp)
    800013f6:	f822                	sd	s0,48(sp)
    800013f8:	f426                	sd	s1,40(sp)
    800013fa:	f04a                	sd	s2,32(sp)
    800013fc:	ec4e                	sd	s3,24(sp)
    800013fe:	e852                	sd	s4,16(sp)
    80001400:	e456                	sd	s5,8(sp)
    80001402:	0080                	addi	s0,sp,64
    80001404:	8aaa                	mv	s5,a0
    80001406:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001408:	6985                	lui	s3,0x1
    8000140a:	19fd                	addi	s3,s3,-1
    8000140c:	95ce                	add	a1,a1,s3
    8000140e:	79fd                	lui	s3,0xfffff
    80001410:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001414:	08c9f063          	bgeu	s3,a2,80001494 <uvmalloc+0xa6>
    80001418:	894e                	mv	s2,s3
    mem = kalloc();
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	6b8080e7          	jalr	1720(ra) # 80000ad2 <kalloc>
    80001422:	84aa                	mv	s1,a0
    if(mem == 0){
    80001424:	c51d                	beqz	a0,80001452 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001426:	6605                	lui	a2,0x1
    80001428:	4581                	li	a1,0
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	894080e7          	jalr	-1900(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001432:	4779                	li	a4,30
    80001434:	86a6                	mv	a3,s1
    80001436:	6605                	lui	a2,0x1
    80001438:	85ca                	mv	a1,s2
    8000143a:	8556                	mv	a0,s5
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	c52080e7          	jalr	-942(ra) # 8000108e <mappages>
    80001444:	e905                	bnez	a0,80001474 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001446:	6785                	lui	a5,0x1
    80001448:	993e                	add	s2,s2,a5
    8000144a:	fd4968e3          	bltu	s2,s4,8000141a <uvmalloc+0x2c>
  return newsz;
    8000144e:	8552                	mv	a0,s4
    80001450:	a809                	j	80001462 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001452:	864e                	mv	a2,s3
    80001454:	85ca                	mv	a1,s2
    80001456:	8556                	mv	a0,s5
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	f4e080e7          	jalr	-178(ra) # 800013a6 <uvmdealloc>
      return 0;
    80001460:	4501                	li	a0,0
}
    80001462:	70e2                	ld	ra,56(sp)
    80001464:	7442                	ld	s0,48(sp)
    80001466:	74a2                	ld	s1,40(sp)
    80001468:	7902                	ld	s2,32(sp)
    8000146a:	69e2                	ld	s3,24(sp)
    8000146c:	6a42                	ld	s4,16(sp)
    8000146e:	6aa2                	ld	s5,8(sp)
    80001470:	6121                	addi	sp,sp,64
    80001472:	8082                	ret
      kfree(mem);
    80001474:	8526                	mv	a0,s1
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	560080e7          	jalr	1376(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000147e:	864e                	mv	a2,s3
    80001480:	85ca                	mv	a1,s2
    80001482:	8556                	mv	a0,s5
    80001484:	00000097          	auipc	ra,0x0
    80001488:	f22080e7          	jalr	-222(ra) # 800013a6 <uvmdealloc>
      return 0;
    8000148c:	4501                	li	a0,0
    8000148e:	bfd1                	j	80001462 <uvmalloc+0x74>
    return oldsz;
    80001490:	852e                	mv	a0,a1
}
    80001492:	8082                	ret
  return newsz;
    80001494:	8532                	mv	a0,a2
    80001496:	b7f1                	j	80001462 <uvmalloc+0x74>

0000000080001498 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001498:	7179                	addi	sp,sp,-48
    8000149a:	f406                	sd	ra,40(sp)
    8000149c:	f022                	sd	s0,32(sp)
    8000149e:	ec26                	sd	s1,24(sp)
    800014a0:	e84a                	sd	s2,16(sp)
    800014a2:	e44e                	sd	s3,8(sp)
    800014a4:	e052                	sd	s4,0(sp)
    800014a6:	1800                	addi	s0,sp,48
    800014a8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014aa:	84aa                	mv	s1,a0
    800014ac:	6905                	lui	s2,0x1
    800014ae:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014b0:	4985                	li	s3,1
    800014b2:	a821                	j	800014ca <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014b4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014b6:	0532                	slli	a0,a0,0xc
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	fe0080e7          	jalr	-32(ra) # 80001498 <freewalk>
      pagetable[i] = 0;
    800014c0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014c4:	04a1                	addi	s1,s1,8
    800014c6:	03248163          	beq	s1,s2,800014e8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014ca:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014cc:	00f57793          	andi	a5,a0,15
    800014d0:	ff3782e3          	beq	a5,s3,800014b4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014d4:	8905                	andi	a0,a0,1
    800014d6:	d57d                	beqz	a0,800014c4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800014d8:	00007517          	auipc	a0,0x7
    800014dc:	c8850513          	addi	a0,a0,-888 # 80008160 <digits+0x120>
    800014e0:	fffff097          	auipc	ra,0xfffff
    800014e4:	04a080e7          	jalr	74(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014e8:	8552                	mv	a0,s4
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	4ec080e7          	jalr	1260(ra) # 800009d6 <kfree>
}
    800014f2:	70a2                	ld	ra,40(sp)
    800014f4:	7402                	ld	s0,32(sp)
    800014f6:	64e2                	ld	s1,24(sp)
    800014f8:	6942                	ld	s2,16(sp)
    800014fa:	69a2                	ld	s3,8(sp)
    800014fc:	6a02                	ld	s4,0(sp)
    800014fe:	6145                	addi	sp,sp,48
    80001500:	8082                	ret

0000000080001502 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001502:	1101                	addi	sp,sp,-32
    80001504:	ec06                	sd	ra,24(sp)
    80001506:	e822                	sd	s0,16(sp)
    80001508:	e426                	sd	s1,8(sp)
    8000150a:	1000                	addi	s0,sp,32
    8000150c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000150e:	e999                	bnez	a1,80001524 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001510:	8526                	mv	a0,s1
    80001512:	00000097          	auipc	ra,0x0
    80001516:	f86080e7          	jalr	-122(ra) # 80001498 <freewalk>
}
    8000151a:	60e2                	ld	ra,24(sp)
    8000151c:	6442                	ld	s0,16(sp)
    8000151e:	64a2                	ld	s1,8(sp)
    80001520:	6105                	addi	sp,sp,32
    80001522:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001524:	6605                	lui	a2,0x1
    80001526:	167d                	addi	a2,a2,-1
    80001528:	962e                	add	a2,a2,a1
    8000152a:	4685                	li	a3,1
    8000152c:	8231                	srli	a2,a2,0xc
    8000152e:	4581                	li	a1,0
    80001530:	00000097          	auipc	ra,0x0
    80001534:	d12080e7          	jalr	-750(ra) # 80001242 <uvmunmap>
    80001538:	bfe1                	j	80001510 <uvmfree+0xe>

000000008000153a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000153a:	c679                	beqz	a2,80001608 <uvmcopy+0xce>
{
    8000153c:	715d                	addi	sp,sp,-80
    8000153e:	e486                	sd	ra,72(sp)
    80001540:	e0a2                	sd	s0,64(sp)
    80001542:	fc26                	sd	s1,56(sp)
    80001544:	f84a                	sd	s2,48(sp)
    80001546:	f44e                	sd	s3,40(sp)
    80001548:	f052                	sd	s4,32(sp)
    8000154a:	ec56                	sd	s5,24(sp)
    8000154c:	e85a                	sd	s6,16(sp)
    8000154e:	e45e                	sd	s7,8(sp)
    80001550:	0880                	addi	s0,sp,80
    80001552:	8b2a                	mv	s6,a0
    80001554:	8aae                	mv	s5,a1
    80001556:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001558:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000155a:	4601                	li	a2,0
    8000155c:	85ce                	mv	a1,s3
    8000155e:	855a                	mv	a0,s6
    80001560:	00000097          	auipc	ra,0x0
    80001564:	a46080e7          	jalr	-1466(ra) # 80000fa6 <walk>
    80001568:	c531                	beqz	a0,800015b4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000156a:	6118                	ld	a4,0(a0)
    8000156c:	00177793          	andi	a5,a4,1
    80001570:	cbb1                	beqz	a5,800015c4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001572:	00a75593          	srli	a1,a4,0xa
    80001576:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000157a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	554080e7          	jalr	1364(ra) # 80000ad2 <kalloc>
    80001586:	892a                	mv	s2,a0
    80001588:	c939                	beqz	a0,800015de <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000158a:	6605                	lui	a2,0x1
    8000158c:	85de                	mv	a1,s7
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	78c080e7          	jalr	1932(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001596:	8726                	mv	a4,s1
    80001598:	86ca                	mv	a3,s2
    8000159a:	6605                	lui	a2,0x1
    8000159c:	85ce                	mv	a1,s3
    8000159e:	8556                	mv	a0,s5
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	aee080e7          	jalr	-1298(ra) # 8000108e <mappages>
    800015a8:	e515                	bnez	a0,800015d4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015aa:	6785                	lui	a5,0x1
    800015ac:	99be                	add	s3,s3,a5
    800015ae:	fb49e6e3          	bltu	s3,s4,8000155a <uvmcopy+0x20>
    800015b2:	a081                	j	800015f2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015b4:	00007517          	auipc	a0,0x7
    800015b8:	bbc50513          	addi	a0,a0,-1092 # 80008170 <digits+0x130>
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	f6e080e7          	jalr	-146(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015c4:	00007517          	auipc	a0,0x7
    800015c8:	bcc50513          	addi	a0,a0,-1076 # 80008190 <digits+0x150>
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	f5e080e7          	jalr	-162(ra) # 8000052a <panic>
      kfree(mem);
    800015d4:	854a                	mv	a0,s2
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	400080e7          	jalr	1024(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015de:	4685                	li	a3,1
    800015e0:	00c9d613          	srli	a2,s3,0xc
    800015e4:	4581                	li	a1,0
    800015e6:	8556                	mv	a0,s5
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	c5a080e7          	jalr	-934(ra) # 80001242 <uvmunmap>
  return -1;
    800015f0:	557d                	li	a0,-1
}
    800015f2:	60a6                	ld	ra,72(sp)
    800015f4:	6406                	ld	s0,64(sp)
    800015f6:	74e2                	ld	s1,56(sp)
    800015f8:	7942                	ld	s2,48(sp)
    800015fa:	79a2                	ld	s3,40(sp)
    800015fc:	7a02                	ld	s4,32(sp)
    800015fe:	6ae2                	ld	s5,24(sp)
    80001600:	6b42                	ld	s6,16(sp)
    80001602:	6ba2                	ld	s7,8(sp)
    80001604:	6161                	addi	sp,sp,80
    80001606:	8082                	ret
  return 0;
    80001608:	4501                	li	a0,0
}
    8000160a:	8082                	ret

000000008000160c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000160c:	1141                	addi	sp,sp,-16
    8000160e:	e406                	sd	ra,8(sp)
    80001610:	e022                	sd	s0,0(sp)
    80001612:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001614:	4601                	li	a2,0
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	990080e7          	jalr	-1648(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000161e:	c901                	beqz	a0,8000162e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001620:	611c                	ld	a5,0(a0)
    80001622:	9bbd                	andi	a5,a5,-17
    80001624:	e11c                	sd	a5,0(a0)
}
    80001626:	60a2                	ld	ra,8(sp)
    80001628:	6402                	ld	s0,0(sp)
    8000162a:	0141                	addi	sp,sp,16
    8000162c:	8082                	ret
    panic("uvmclear");
    8000162e:	00007517          	auipc	a0,0x7
    80001632:	b8250513          	addi	a0,a0,-1150 # 800081b0 <digits+0x170>
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	ef4080e7          	jalr	-268(ra) # 8000052a <panic>

000000008000163e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000163e:	c6bd                	beqz	a3,800016ac <copyout+0x6e>
{
    80001640:	715d                	addi	sp,sp,-80
    80001642:	e486                	sd	ra,72(sp)
    80001644:	e0a2                	sd	s0,64(sp)
    80001646:	fc26                	sd	s1,56(sp)
    80001648:	f84a                	sd	s2,48(sp)
    8000164a:	f44e                	sd	s3,40(sp)
    8000164c:	f052                	sd	s4,32(sp)
    8000164e:	ec56                	sd	s5,24(sp)
    80001650:	e85a                	sd	s6,16(sp)
    80001652:	e45e                	sd	s7,8(sp)
    80001654:	e062                	sd	s8,0(sp)
    80001656:	0880                	addi	s0,sp,80
    80001658:	8b2a                	mv	s6,a0
    8000165a:	8c2e                	mv	s8,a1
    8000165c:	8a32                	mv	s4,a2
    8000165e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001660:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001662:	6a85                	lui	s5,0x1
    80001664:	a015                	j	80001688 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001666:	9562                	add	a0,a0,s8
    80001668:	0004861b          	sext.w	a2,s1
    8000166c:	85d2                	mv	a1,s4
    8000166e:	41250533          	sub	a0,a0,s2
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	6a8080e7          	jalr	1704(ra) # 80000d1a <memmove>

    len -= n;
    8000167a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000167e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001680:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001684:	02098263          	beqz	s3,800016a8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001688:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000168c:	85ca                	mv	a1,s2
    8000168e:	855a                	mv	a0,s6
    80001690:	00000097          	auipc	ra,0x0
    80001694:	9bc080e7          	jalr	-1604(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001698:	cd01                	beqz	a0,800016b0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000169a:	418904b3          	sub	s1,s2,s8
    8000169e:	94d6                	add	s1,s1,s5
    if(n > len)
    800016a0:	fc99f3e3          	bgeu	s3,s1,80001666 <copyout+0x28>
    800016a4:	84ce                	mv	s1,s3
    800016a6:	b7c1                	j	80001666 <copyout+0x28>
  }
  return 0;
    800016a8:	4501                	li	a0,0
    800016aa:	a021                	j	800016b2 <copyout+0x74>
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret
      return -1;
    800016b0:	557d                	li	a0,-1
}
    800016b2:	60a6                	ld	ra,72(sp)
    800016b4:	6406                	ld	s0,64(sp)
    800016b6:	74e2                	ld	s1,56(sp)
    800016b8:	7942                	ld	s2,48(sp)
    800016ba:	79a2                	ld	s3,40(sp)
    800016bc:	7a02                	ld	s4,32(sp)
    800016be:	6ae2                	ld	s5,24(sp)
    800016c0:	6b42                	ld	s6,16(sp)
    800016c2:	6ba2                	ld	s7,8(sp)
    800016c4:	6c02                	ld	s8,0(sp)
    800016c6:	6161                	addi	sp,sp,80
    800016c8:	8082                	ret

00000000800016ca <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ca:	caa5                	beqz	a3,8000173a <copyin+0x70>
{
    800016cc:	715d                	addi	sp,sp,-80
    800016ce:	e486                	sd	ra,72(sp)
    800016d0:	e0a2                	sd	s0,64(sp)
    800016d2:	fc26                	sd	s1,56(sp)
    800016d4:	f84a                	sd	s2,48(sp)
    800016d6:	f44e                	sd	s3,40(sp)
    800016d8:	f052                	sd	s4,32(sp)
    800016da:	ec56                	sd	s5,24(sp)
    800016dc:	e85a                	sd	s6,16(sp)
    800016de:	e45e                	sd	s7,8(sp)
    800016e0:	e062                	sd	s8,0(sp)
    800016e2:	0880                	addi	s0,sp,80
    800016e4:	8b2a                	mv	s6,a0
    800016e6:	8a2e                	mv	s4,a1
    800016e8:	8c32                	mv	s8,a2
    800016ea:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ec:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ee:	6a85                	lui	s5,0x1
    800016f0:	a01d                	j	80001716 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016f2:	018505b3          	add	a1,a0,s8
    800016f6:	0004861b          	sext.w	a2,s1
    800016fa:	412585b3          	sub	a1,a1,s2
    800016fe:	8552                	mv	a0,s4
    80001700:	fffff097          	auipc	ra,0xfffff
    80001704:	61a080e7          	jalr	1562(ra) # 80000d1a <memmove>

    len -= n;
    80001708:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000170c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000170e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001712:	02098263          	beqz	s3,80001736 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001716:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000171a:	85ca                	mv	a1,s2
    8000171c:	855a                	mv	a0,s6
    8000171e:	00000097          	auipc	ra,0x0
    80001722:	92e080e7          	jalr	-1746(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001726:	cd01                	beqz	a0,8000173e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001728:	418904b3          	sub	s1,s2,s8
    8000172c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172e:	fc99f2e3          	bgeu	s3,s1,800016f2 <copyin+0x28>
    80001732:	84ce                	mv	s1,s3
    80001734:	bf7d                	j	800016f2 <copyin+0x28>
  }
  return 0;
    80001736:	4501                	li	a0,0
    80001738:	a021                	j	80001740 <copyin+0x76>
    8000173a:	4501                	li	a0,0
}
    8000173c:	8082                	ret
      return -1;
    8000173e:	557d                	li	a0,-1
}
    80001740:	60a6                	ld	ra,72(sp)
    80001742:	6406                	ld	s0,64(sp)
    80001744:	74e2                	ld	s1,56(sp)
    80001746:	7942                	ld	s2,48(sp)
    80001748:	79a2                	ld	s3,40(sp)
    8000174a:	7a02                	ld	s4,32(sp)
    8000174c:	6ae2                	ld	s5,24(sp)
    8000174e:	6b42                	ld	s6,16(sp)
    80001750:	6ba2                	ld	s7,8(sp)
    80001752:	6c02                	ld	s8,0(sp)
    80001754:	6161                	addi	sp,sp,80
    80001756:	8082                	ret

0000000080001758 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001758:	c6c5                	beqz	a3,80001800 <copyinstr+0xa8>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	0880                	addi	s0,sp,80
    80001770:	8a2a                	mv	s4,a0
    80001772:	8b2e                	mv	s6,a1
    80001774:	8bb2                	mv	s7,a2
    80001776:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001778:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000177a:	6985                	lui	s3,0x1
    8000177c:	a035                	j	800017a8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000177e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001782:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001784:	0017b793          	seqz	a5,a5
    80001788:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000178c:	60a6                	ld	ra,72(sp)
    8000178e:	6406                	ld	s0,64(sp)
    80001790:	74e2                	ld	s1,56(sp)
    80001792:	7942                	ld	s2,48(sp)
    80001794:	79a2                	ld	s3,40(sp)
    80001796:	7a02                	ld	s4,32(sp)
    80001798:	6ae2                	ld	s5,24(sp)
    8000179a:	6b42                	ld	s6,16(sp)
    8000179c:	6ba2                	ld	s7,8(sp)
    8000179e:	6161                	addi	sp,sp,80
    800017a0:	8082                	ret
    srcva = va0 + PGSIZE;
    800017a2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017a6:	c8a9                	beqz	s1,800017f8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ac:	85ca                	mv	a1,s2
    800017ae:	8552                	mv	a0,s4
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	89c080e7          	jalr	-1892(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800017b8:	c131                	beqz	a0,800017fc <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ba:	41790833          	sub	a6,s2,s7
    800017be:	984e                	add	a6,a6,s3
    if(n > max)
    800017c0:	0104f363          	bgeu	s1,a6,800017c6 <copyinstr+0x6e>
    800017c4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017c6:	955e                	add	a0,a0,s7
    800017c8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017cc:	fc080be3          	beqz	a6,800017a2 <copyinstr+0x4a>
    800017d0:	985a                	add	a6,a6,s6
    800017d2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017d4:	41650633          	sub	a2,a0,s6
    800017d8:	14fd                	addi	s1,s1,-1
    800017da:	9b26                	add	s6,s6,s1
    800017dc:	00f60733          	add	a4,a2,a5
    800017e0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017e4:	df49                	beqz	a4,8000177e <copyinstr+0x26>
        *dst = *p;
    800017e6:	00e78023          	sb	a4,0(a5)
      --max;
    800017ea:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ee:	0785                	addi	a5,a5,1
    while(n > 0){
    800017f0:	ff0796e3          	bne	a5,a6,800017dc <copyinstr+0x84>
      dst++;
    800017f4:	8b42                	mv	s6,a6
    800017f6:	b775                	j	800017a2 <copyinstr+0x4a>
    800017f8:	4781                	li	a5,0
    800017fa:	b769                	j	80001784 <copyinstr+0x2c>
      return -1;
    800017fc:	557d                	li	a0,-1
    800017fe:	b779                	j	8000178c <copyinstr+0x34>
  int got_null = 0;
    80001800:	4781                	li	a5,0
  if(got_null){
    80001802:	0017b793          	seqz	a5,a5
    80001806:	40f00533          	neg	a0,a5
}
    8000180a:	8082                	ret

000000008000180c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000180c:	7139                	addi	sp,sp,-64
    8000180e:	fc06                	sd	ra,56(sp)
    80001810:	f822                	sd	s0,48(sp)
    80001812:	f426                	sd	s1,40(sp)
    80001814:	f04a                	sd	s2,32(sp)
    80001816:	ec4e                	sd	s3,24(sp)
    80001818:	e852                	sd	s4,16(sp)
    8000181a:	e456                	sd	s5,8(sp)
    8000181c:	e05a                	sd	s6,0(sp)
    8000181e:	0080                	addi	s0,sp,64
    80001820:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001822:	00010497          	auipc	s1,0x10
    80001826:	eae48493          	addi	s1,s1,-338 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000182a:	8b26                	mv	s6,s1
    8000182c:	00006a97          	auipc	s5,0x6
    80001830:	7d4a8a93          	addi	s5,s5,2004 # 80008000 <etext>
    80001834:	04000937          	lui	s2,0x4000
    80001838:	197d                	addi	s2,s2,-1
    8000183a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183c:	00016a17          	auipc	s4,0x16
    80001840:	894a0a13          	addi	s4,s4,-1900 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001844:	fffff097          	auipc	ra,0xfffff
    80001848:	28e080e7          	jalr	654(ra) # 80000ad2 <kalloc>
    8000184c:	862a                	mv	a2,a0
    if(pa == 0)
    8000184e:	c131                	beqz	a0,80001892 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001850:	416485b3          	sub	a1,s1,s6
    80001854:	858d                	srai	a1,a1,0x3
    80001856:	000ab783          	ld	a5,0(s5)
    8000185a:	02f585b3          	mul	a1,a1,a5
    8000185e:	2585                	addiw	a1,a1,1
    80001860:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001864:	4719                	li	a4,6
    80001866:	6685                	lui	a3,0x1
    80001868:	40b905b3          	sub	a1,s2,a1
    8000186c:	854e                	mv	a0,s3
    8000186e:	00000097          	auipc	ra,0x0
    80001872:	8ae080e7          	jalr	-1874(ra) # 8000111c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001876:	16848493          	addi	s1,s1,360
    8000187a:	fd4495e3          	bne	s1,s4,80001844 <proc_mapstacks+0x38>
  }
}
    8000187e:	70e2                	ld	ra,56(sp)
    80001880:	7442                	ld	s0,48(sp)
    80001882:	74a2                	ld	s1,40(sp)
    80001884:	7902                	ld	s2,32(sp)
    80001886:	69e2                	ld	s3,24(sp)
    80001888:	6a42                	ld	s4,16(sp)
    8000188a:	6aa2                	ld	s5,8(sp)
    8000188c:	6b02                	ld	s6,0(sp)
    8000188e:	6121                	addi	sp,sp,64
    80001890:	8082                	ret
      panic("kalloc");
    80001892:	00007517          	auipc	a0,0x7
    80001896:	92e50513          	addi	a0,a0,-1746 # 800081c0 <digits+0x180>
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	c90080e7          	jalr	-880(ra) # 8000052a <panic>

00000000800018a2 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018a2:	7139                	addi	sp,sp,-64
    800018a4:	fc06                	sd	ra,56(sp)
    800018a6:	f822                	sd	s0,48(sp)
    800018a8:	f426                	sd	s1,40(sp)
    800018aa:	f04a                	sd	s2,32(sp)
    800018ac:	ec4e                	sd	s3,24(sp)
    800018ae:	e852                	sd	s4,16(sp)
    800018b0:	e456                	sd	s5,8(sp)
    800018b2:	e05a                	sd	s6,0(sp)
    800018b4:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018b6:	00007597          	auipc	a1,0x7
    800018ba:	91258593          	addi	a1,a1,-1774 # 800081c8 <digits+0x188>
    800018be:	00010517          	auipc	a0,0x10
    800018c2:	9e250513          	addi	a0,a0,-1566 # 800112a0 <pid_lock>
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	26c080e7          	jalr	620(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	90258593          	addi	a1,a1,-1790 # 800081d0 <digits+0x190>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9e250513          	addi	a0,a0,-1566 # 800112b8 <wait_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	254080e7          	jalr	596(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018e6:	00010497          	auipc	s1,0x10
    800018ea:	dea48493          	addi	s1,s1,-534 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    800018ee:	00007b17          	auipc	s6,0x7
    800018f2:	8f2b0b13          	addi	s6,s6,-1806 # 800081e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    800018f6:	8aa6                	mv	s5,s1
    800018f8:	00006a17          	auipc	s4,0x6
    800018fc:	708a0a13          	addi	s4,s4,1800 # 80008000 <etext>
    80001900:	04000937          	lui	s2,0x4000
    80001904:	197d                	addi	s2,s2,-1
    80001906:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001908:	00015997          	auipc	s3,0x15
    8000190c:	7c898993          	addi	s3,s3,1992 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001910:	85da                	mv	a1,s6
    80001912:	8526                	mv	a0,s1
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	21e080e7          	jalr	542(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000191c:	415487b3          	sub	a5,s1,s5
    80001920:	878d                	srai	a5,a5,0x3
    80001922:	000a3703          	ld	a4,0(s4)
    80001926:	02e787b3          	mul	a5,a5,a4
    8000192a:	2785                	addiw	a5,a5,1
    8000192c:	00d7979b          	slliw	a5,a5,0xd
    80001930:	40f907b3          	sub	a5,s2,a5
    80001934:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001936:	16848493          	addi	s1,s1,360
    8000193a:	fd349be3          	bne	s1,s3,80001910 <procinit+0x6e>
  }
}
    8000193e:	70e2                	ld	ra,56(sp)
    80001940:	7442                	ld	s0,48(sp)
    80001942:	74a2                	ld	s1,40(sp)
    80001944:	7902                	ld	s2,32(sp)
    80001946:	69e2                	ld	s3,24(sp)
    80001948:	6a42                	ld	s4,16(sp)
    8000194a:	6aa2                	ld	s5,8(sp)
    8000194c:	6b02                	ld	s6,0(sp)
    8000194e:	6121                	addi	sp,sp,64
    80001950:	8082                	ret

0000000080001952 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001952:	1141                	addi	sp,sp,-16
    80001954:	e422                	sd	s0,8(sp)
    80001956:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001958:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000195a:	2501                	sext.w	a0,a0
    8000195c:	6422                	ld	s0,8(sp)
    8000195e:	0141                	addi	sp,sp,16
    80001960:	8082                	ret

0000000080001962 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001962:	1141                	addi	sp,sp,-16
    80001964:	e422                	sd	s0,8(sp)
    80001966:	0800                	addi	s0,sp,16
    80001968:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000196a:	2781                	sext.w	a5,a5
    8000196c:	079e                	slli	a5,a5,0x7
  return c;
}
    8000196e:	00010517          	auipc	a0,0x10
    80001972:	96250513          	addi	a0,a0,-1694 # 800112d0 <cpus>
    80001976:	953e                	add	a0,a0,a5
    80001978:	6422                	ld	s0,8(sp)
    8000197a:	0141                	addi	sp,sp,16
    8000197c:	8082                	ret

000000008000197e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    8000197e:	1101                	addi	sp,sp,-32
    80001980:	ec06                	sd	ra,24(sp)
    80001982:	e822                	sd	s0,16(sp)
    80001984:	e426                	sd	s1,8(sp)
    80001986:	1000                	addi	s0,sp,32
  push_off();
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	1ee080e7          	jalr	494(ra) # 80000b76 <push_off>
    80001990:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	slli	a5,a5,0x7
    80001996:	00010717          	auipc	a4,0x10
    8000199a:	90a70713          	addi	a4,a4,-1782 # 800112a0 <pid_lock>
    8000199e:	97ba                	add	a5,a5,a4
    800019a0:	7b84                	ld	s1,48(a5)
  pop_off();
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	274080e7          	jalr	628(ra) # 80000c16 <pop_off>
  return p;
}
    800019aa:	8526                	mv	a0,s1
    800019ac:	60e2                	ld	ra,24(sp)
    800019ae:	6442                	ld	s0,16(sp)
    800019b0:	64a2                	ld	s1,8(sp)
    800019b2:	6105                	addi	sp,sp,32
    800019b4:	8082                	ret

00000000800019b6 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019b6:	1141                	addi	sp,sp,-16
    800019b8:	e406                	sd	ra,8(sp)
    800019ba:	e022                	sd	s0,0(sp)
    800019bc:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019be:	00000097          	auipc	ra,0x0
    800019c2:	fc0080e7          	jalr	-64(ra) # 8000197e <myproc>
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	2b0080e7          	jalr	688(ra) # 80000c76 <release>

  if (first) {
    800019ce:	00007797          	auipc	a5,0x7
    800019d2:	e327a783          	lw	a5,-462(a5) # 80008800 <first.1>
    800019d6:	eb89                	bnez	a5,800019e8 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019d8:	00001097          	auipc	ra,0x1
    800019dc:	c0e080e7          	jalr	-1010(ra) # 800025e6 <usertrapret>
}
    800019e0:	60a2                	ld	ra,8(sp)
    800019e2:	6402                	ld	s0,0(sp)
    800019e4:	0141                	addi	sp,sp,16
    800019e6:	8082                	ret
    first = 0;
    800019e8:	00007797          	auipc	a5,0x7
    800019ec:	e007ac23          	sw	zero,-488(a5) # 80008800 <first.1>
    fsinit(ROOTDEV);
    800019f0:	4505                	li	a0,1
    800019f2:	00002097          	auipc	ra,0x2
    800019f6:	934080e7          	jalr	-1740(ra) # 80003326 <fsinit>
    800019fa:	bff9                	j	800019d8 <forkret+0x22>

00000000800019fc <allocpid>:
allocpid() {
    800019fc:	1101                	addi	sp,sp,-32
    800019fe:	ec06                	sd	ra,24(sp)
    80001a00:	e822                	sd	s0,16(sp)
    80001a02:	e426                	sd	s1,8(sp)
    80001a04:	e04a                	sd	s2,0(sp)
    80001a06:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a08:	00010917          	auipc	s2,0x10
    80001a0c:	89890913          	addi	s2,s2,-1896 # 800112a0 <pid_lock>
    80001a10:	854a                	mv	a0,s2
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	1b0080e7          	jalr	432(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	dea78793          	addi	a5,a5,-534 # 80008804 <nextpid>
    80001a22:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a24:	0014871b          	addiw	a4,s1,1
    80001a28:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a2a:	854a                	mv	a0,s2
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	24a080e7          	jalr	586(ra) # 80000c76 <release>
}
    80001a34:	8526                	mv	a0,s1
    80001a36:	60e2                	ld	ra,24(sp)
    80001a38:	6442                	ld	s0,16(sp)
    80001a3a:	64a2                	ld	s1,8(sp)
    80001a3c:	6902                	ld	s2,0(sp)
    80001a3e:	6105                	addi	sp,sp,32
    80001a40:	8082                	ret

0000000080001a42 <proc_pagetable>:
{
    80001a42:	1101                	addi	sp,sp,-32
    80001a44:	ec06                	sd	ra,24(sp)
    80001a46:	e822                	sd	s0,16(sp)
    80001a48:	e426                	sd	s1,8(sp)
    80001a4a:	e04a                	sd	s2,0(sp)
    80001a4c:	1000                	addi	s0,sp,32
    80001a4e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a50:	00000097          	auipc	ra,0x0
    80001a54:	8b6080e7          	jalr	-1866(ra) # 80001306 <uvmcreate>
    80001a58:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a5a:	c121                	beqz	a0,80001a9a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a5c:	4729                	li	a4,10
    80001a5e:	00005697          	auipc	a3,0x5
    80001a62:	5a268693          	addi	a3,a3,1442 # 80007000 <_trampoline>
    80001a66:	6605                	lui	a2,0x1
    80001a68:	040005b7          	lui	a1,0x4000
    80001a6c:	15fd                	addi	a1,a1,-1
    80001a6e:	05b2                	slli	a1,a1,0xc
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	61e080e7          	jalr	1566(ra) # 8000108e <mappages>
    80001a78:	02054863          	bltz	a0,80001aa8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a7c:	4719                	li	a4,6
    80001a7e:	05893683          	ld	a3,88(s2)
    80001a82:	6605                	lui	a2,0x1
    80001a84:	020005b7          	lui	a1,0x2000
    80001a88:	15fd                	addi	a1,a1,-1
    80001a8a:	05b6                	slli	a1,a1,0xd
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	600080e7          	jalr	1536(ra) # 8000108e <mappages>
    80001a96:	02054163          	bltz	a0,80001ab8 <proc_pagetable+0x76>
}
    80001a9a:	8526                	mv	a0,s1
    80001a9c:	60e2                	ld	ra,24(sp)
    80001a9e:	6442                	ld	s0,16(sp)
    80001aa0:	64a2                	ld	s1,8(sp)
    80001aa2:	6902                	ld	s2,0(sp)
    80001aa4:	6105                	addi	sp,sp,32
    80001aa6:	8082                	ret
    uvmfree(pagetable, 0);
    80001aa8:	4581                	li	a1,0
    80001aaa:	8526                	mv	a0,s1
    80001aac:	00000097          	auipc	ra,0x0
    80001ab0:	a56080e7          	jalr	-1450(ra) # 80001502 <uvmfree>
    return 0;
    80001ab4:	4481                	li	s1,0
    80001ab6:	b7d5                	j	80001a9a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ab8:	4681                	li	a3,0
    80001aba:	4605                	li	a2,1
    80001abc:	040005b7          	lui	a1,0x4000
    80001ac0:	15fd                	addi	a1,a1,-1
    80001ac2:	05b2                	slli	a1,a1,0xc
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	77c080e7          	jalr	1916(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ace:	4581                	li	a1,0
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	00000097          	auipc	ra,0x0
    80001ad6:	a30080e7          	jalr	-1488(ra) # 80001502 <uvmfree>
    return 0;
    80001ada:	4481                	li	s1,0
    80001adc:	bf7d                	j	80001a9a <proc_pagetable+0x58>

0000000080001ade <proc_freepagetable>:
{
    80001ade:	1101                	addi	sp,sp,-32
    80001ae0:	ec06                	sd	ra,24(sp)
    80001ae2:	e822                	sd	s0,16(sp)
    80001ae4:	e426                	sd	s1,8(sp)
    80001ae6:	e04a                	sd	s2,0(sp)
    80001ae8:	1000                	addi	s0,sp,32
    80001aea:	84aa                	mv	s1,a0
    80001aec:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aee:	4681                	li	a3,0
    80001af0:	4605                	li	a2,1
    80001af2:	040005b7          	lui	a1,0x4000
    80001af6:	15fd                	addi	a1,a1,-1
    80001af8:	05b2                	slli	a1,a1,0xc
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	748080e7          	jalr	1864(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b02:	4681                	li	a3,0
    80001b04:	4605                	li	a2,1
    80001b06:	020005b7          	lui	a1,0x2000
    80001b0a:	15fd                	addi	a1,a1,-1
    80001b0c:	05b6                	slli	a1,a1,0xd
    80001b0e:	8526                	mv	a0,s1
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	732080e7          	jalr	1842(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b18:	85ca                	mv	a1,s2
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	9e6080e7          	jalr	-1562(ra) # 80001502 <uvmfree>
}
    80001b24:	60e2                	ld	ra,24(sp)
    80001b26:	6442                	ld	s0,16(sp)
    80001b28:	64a2                	ld	s1,8(sp)
    80001b2a:	6902                	ld	s2,0(sp)
    80001b2c:	6105                	addi	sp,sp,32
    80001b2e:	8082                	ret

0000000080001b30 <freeproc>:
{
    80001b30:	1101                	addi	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	1000                	addi	s0,sp,32
    80001b3a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b3c:	6d28                	ld	a0,88(a0)
    80001b3e:	c509                	beqz	a0,80001b48 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	e96080e7          	jalr	-362(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b48:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b4c:	68a8                	ld	a0,80(s1)
    80001b4e:	c511                	beqz	a0,80001b5a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b50:	64ac                	ld	a1,72(s1)
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	f8c080e7          	jalr	-116(ra) # 80001ade <proc_freepagetable>
  p->pagetable = 0;
    80001b5a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b5e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b62:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b66:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b6a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b6e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b72:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b76:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b7a:	0004ac23          	sw	zero,24(s1)
}
    80001b7e:	60e2                	ld	ra,24(sp)
    80001b80:	6442                	ld	s0,16(sp)
    80001b82:	64a2                	ld	s1,8(sp)
    80001b84:	6105                	addi	sp,sp,32
    80001b86:	8082                	ret

0000000080001b88 <allocproc>:
{
    80001b88:	1101                	addi	sp,sp,-32
    80001b8a:	ec06                	sd	ra,24(sp)
    80001b8c:	e822                	sd	s0,16(sp)
    80001b8e:	e426                	sd	s1,8(sp)
    80001b90:	e04a                	sd	s2,0(sp)
    80001b92:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b94:	00010497          	auipc	s1,0x10
    80001b98:	b3c48493          	addi	s1,s1,-1220 # 800116d0 <proc>
    80001b9c:	00015917          	auipc	s2,0x15
    80001ba0:	53490913          	addi	s2,s2,1332 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	01c080e7          	jalr	28(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bae:	4c9c                	lw	a5,24(s1)
    80001bb0:	cf81                	beqz	a5,80001bc8 <allocproc+0x40>
      release(&p->lock);
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	0c2080e7          	jalr	194(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bbc:	16848493          	addi	s1,s1,360
    80001bc0:	ff2492e3          	bne	s1,s2,80001ba4 <allocproc+0x1c>
  return 0;
    80001bc4:	4481                	li	s1,0
    80001bc6:	a889                	j	80001c18 <allocproc+0x90>
  p->pid = allocpid();
    80001bc8:	00000097          	auipc	ra,0x0
    80001bcc:	e34080e7          	jalr	-460(ra) # 800019fc <allocpid>
    80001bd0:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bd2:	4785                	li	a5,1
    80001bd4:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	efc080e7          	jalr	-260(ra) # 80000ad2 <kalloc>
    80001bde:	892a                	mv	s2,a0
    80001be0:	eca8                	sd	a0,88(s1)
    80001be2:	c131                	beqz	a0,80001c26 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001be4:	8526                	mv	a0,s1
    80001be6:	00000097          	auipc	ra,0x0
    80001bea:	e5c080e7          	jalr	-420(ra) # 80001a42 <proc_pagetable>
    80001bee:	892a                	mv	s2,a0
    80001bf0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001bf2:	c531                	beqz	a0,80001c3e <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001bf4:	07000613          	li	a2,112
    80001bf8:	4581                	li	a1,0
    80001bfa:	06048513          	addi	a0,s1,96
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	0c0080e7          	jalr	192(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c06:	00000797          	auipc	a5,0x0
    80001c0a:	db078793          	addi	a5,a5,-592 # 800019b6 <forkret>
    80001c0e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c10:	60bc                	ld	a5,64(s1)
    80001c12:	6705                	lui	a4,0x1
    80001c14:	97ba                	add	a5,a5,a4
    80001c16:	f4bc                	sd	a5,104(s1)
}
    80001c18:	8526                	mv	a0,s1
    80001c1a:	60e2                	ld	ra,24(sp)
    80001c1c:	6442                	ld	s0,16(sp)
    80001c1e:	64a2                	ld	s1,8(sp)
    80001c20:	6902                	ld	s2,0(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret
    freeproc(p);
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	f08080e7          	jalr	-248(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c30:	8526                	mv	a0,s1
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	044080e7          	jalr	68(ra) # 80000c76 <release>
    return 0;
    80001c3a:	84ca                	mv	s1,s2
    80001c3c:	bff1                	j	80001c18 <allocproc+0x90>
    freeproc(p);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	ef0080e7          	jalr	-272(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	02c080e7          	jalr	44(ra) # 80000c76 <release>
    return 0;
    80001c52:	84ca                	mv	s1,s2
    80001c54:	b7d1                	j	80001c18 <allocproc+0x90>

0000000080001c56 <userinit>:
{
    80001c56:	1101                	addi	sp,sp,-32
    80001c58:	ec06                	sd	ra,24(sp)
    80001c5a:	e822                	sd	s0,16(sp)
    80001c5c:	e426                	sd	s1,8(sp)
    80001c5e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	f28080e7          	jalr	-216(ra) # 80001b88 <allocproc>
    80001c68:	84aa                	mv	s1,a0
  initproc = p;
    80001c6a:	00007797          	auipc	a5,0x7
    80001c6e:	3aa7bf23          	sd	a0,958(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c72:	03400613          	li	a2,52
    80001c76:	00007597          	auipc	a1,0x7
    80001c7a:	b9a58593          	addi	a1,a1,-1126 # 80008810 <initcode>
    80001c7e:	6928                	ld	a0,80(a0)
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	6b4080e7          	jalr	1716(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001c88:	6785                	lui	a5,0x1
    80001c8a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001c8c:	6cb8                	ld	a4,88(s1)
    80001c8e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001c92:	6cb8                	ld	a4,88(s1)
    80001c94:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001c96:	4641                	li	a2,16
    80001c98:	00006597          	auipc	a1,0x6
    80001c9c:	55058593          	addi	a1,a1,1360 # 800081e8 <digits+0x1a8>
    80001ca0:	15848513          	addi	a0,s1,344
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	16c080e7          	jalr	364(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cac:	00006517          	auipc	a0,0x6
    80001cb0:	54c50513          	addi	a0,a0,1356 # 800081f8 <digits+0x1b8>
    80001cb4:	00002097          	auipc	ra,0x2
    80001cb8:	0a0080e7          	jalr	160(ra) # 80003d54 <namei>
    80001cbc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cc0:	478d                	li	a5,3
    80001cc2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	fb0080e7          	jalr	-80(ra) # 80000c76 <release>
}
    80001cce:	60e2                	ld	ra,24(sp)
    80001cd0:	6442                	ld	s0,16(sp)
    80001cd2:	64a2                	ld	s1,8(sp)
    80001cd4:	6105                	addi	sp,sp,32
    80001cd6:	8082                	ret

0000000080001cd8 <growproc>:
{
    80001cd8:	1101                	addi	sp,sp,-32
    80001cda:	ec06                	sd	ra,24(sp)
    80001cdc:	e822                	sd	s0,16(sp)
    80001cde:	e426                	sd	s1,8(sp)
    80001ce0:	e04a                	sd	s2,0(sp)
    80001ce2:	1000                	addi	s0,sp,32
    80001ce4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	c98080e7          	jalr	-872(ra) # 8000197e <myproc>
    80001cee:	892a                	mv	s2,a0
  sz = p->sz;
    80001cf0:	652c                	ld	a1,72(a0)
    80001cf2:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001cf6:	00904f63          	bgtz	s1,80001d14 <growproc+0x3c>
  } else if(n < 0){
    80001cfa:	0204cc63          	bltz	s1,80001d32 <growproc+0x5a>
  p->sz = sz;
    80001cfe:	1602                	slli	a2,a2,0x20
    80001d00:	9201                	srli	a2,a2,0x20
    80001d02:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d06:	4501                	li	a0,0
}
    80001d08:	60e2                	ld	ra,24(sp)
    80001d0a:	6442                	ld	s0,16(sp)
    80001d0c:	64a2                	ld	s1,8(sp)
    80001d0e:	6902                	ld	s2,0(sp)
    80001d10:	6105                	addi	sp,sp,32
    80001d12:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d14:	9e25                	addw	a2,a2,s1
    80001d16:	1602                	slli	a2,a2,0x20
    80001d18:	9201                	srli	a2,a2,0x20
    80001d1a:	1582                	slli	a1,a1,0x20
    80001d1c:	9181                	srli	a1,a1,0x20
    80001d1e:	6928                	ld	a0,80(a0)
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	6ce080e7          	jalr	1742(ra) # 800013ee <uvmalloc>
    80001d28:	0005061b          	sext.w	a2,a0
    80001d2c:	fa69                	bnez	a2,80001cfe <growproc+0x26>
      return -1;
    80001d2e:	557d                	li	a0,-1
    80001d30:	bfe1                	j	80001d08 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d32:	9e25                	addw	a2,a2,s1
    80001d34:	1602                	slli	a2,a2,0x20
    80001d36:	9201                	srli	a2,a2,0x20
    80001d38:	1582                	slli	a1,a1,0x20
    80001d3a:	9181                	srli	a1,a1,0x20
    80001d3c:	6928                	ld	a0,80(a0)
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	668080e7          	jalr	1640(ra) # 800013a6 <uvmdealloc>
    80001d46:	0005061b          	sext.w	a2,a0
    80001d4a:	bf55                	j	80001cfe <growproc+0x26>

0000000080001d4c <fork>:
{
    80001d4c:	7139                	addi	sp,sp,-64
    80001d4e:	fc06                	sd	ra,56(sp)
    80001d50:	f822                	sd	s0,48(sp)
    80001d52:	f426                	sd	s1,40(sp)
    80001d54:	f04a                	sd	s2,32(sp)
    80001d56:	ec4e                	sd	s3,24(sp)
    80001d58:	e852                	sd	s4,16(sp)
    80001d5a:	e456                	sd	s5,8(sp)
    80001d5c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d5e:	00000097          	auipc	ra,0x0
    80001d62:	c20080e7          	jalr	-992(ra) # 8000197e <myproc>
    80001d66:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	e20080e7          	jalr	-480(ra) # 80001b88 <allocproc>
    80001d70:	10050c63          	beqz	a0,80001e88 <fork+0x13c>
    80001d74:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d76:	048ab603          	ld	a2,72(s5)
    80001d7a:	692c                	ld	a1,80(a0)
    80001d7c:	050ab503          	ld	a0,80(s5)
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	7ba080e7          	jalr	1978(ra) # 8000153a <uvmcopy>
    80001d88:	04054863          	bltz	a0,80001dd8 <fork+0x8c>
  np->sz = p->sz;
    80001d8c:	048ab783          	ld	a5,72(s5)
    80001d90:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001d94:	058ab683          	ld	a3,88(s5)
    80001d98:	87b6                	mv	a5,a3
    80001d9a:	058a3703          	ld	a4,88(s4)
    80001d9e:	12068693          	addi	a3,a3,288
    80001da2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001da6:	6788                	ld	a0,8(a5)
    80001da8:	6b8c                	ld	a1,16(a5)
    80001daa:	6f90                	ld	a2,24(a5)
    80001dac:	01073023          	sd	a6,0(a4)
    80001db0:	e708                	sd	a0,8(a4)
    80001db2:	eb0c                	sd	a1,16(a4)
    80001db4:	ef10                	sd	a2,24(a4)
    80001db6:	02078793          	addi	a5,a5,32
    80001dba:	02070713          	addi	a4,a4,32
    80001dbe:	fed792e3          	bne	a5,a3,80001da2 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dc2:	058a3783          	ld	a5,88(s4)
    80001dc6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dca:	0d0a8493          	addi	s1,s5,208
    80001dce:	0d0a0913          	addi	s2,s4,208
    80001dd2:	150a8993          	addi	s3,s5,336
    80001dd6:	a00d                	j	80001df8 <fork+0xac>
    freeproc(np);
    80001dd8:	8552                	mv	a0,s4
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	d56080e7          	jalr	-682(ra) # 80001b30 <freeproc>
    release(&np->lock);
    80001de2:	8552                	mv	a0,s4
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	e92080e7          	jalr	-366(ra) # 80000c76 <release>
    return -1;
    80001dec:	597d                	li	s2,-1
    80001dee:	a059                	j	80001e74 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001df0:	04a1                	addi	s1,s1,8
    80001df2:	0921                	addi	s2,s2,8
    80001df4:	01348b63          	beq	s1,s3,80001e0a <fork+0xbe>
    if(p->ofile[i])
    80001df8:	6088                	ld	a0,0(s1)
    80001dfa:	d97d                	beqz	a0,80001df0 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001dfc:	00002097          	auipc	ra,0x2
    80001e00:	5ee080e7          	jalr	1518(ra) # 800043ea <filedup>
    80001e04:	00a93023          	sd	a0,0(s2)
    80001e08:	b7e5                	j	80001df0 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e0a:	150ab503          	ld	a0,336(s5)
    80001e0e:	00001097          	auipc	ra,0x1
    80001e12:	752080e7          	jalr	1874(ra) # 80003560 <idup>
    80001e16:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e1a:	4641                	li	a2,16
    80001e1c:	158a8593          	addi	a1,s5,344
    80001e20:	158a0513          	addi	a0,s4,344
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	fec080e7          	jalr	-20(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e2c:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e30:	8552                	mv	a0,s4
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e44080e7          	jalr	-444(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e3a:	0000f497          	auipc	s1,0xf
    80001e3e:	47e48493          	addi	s1,s1,1150 # 800112b8 <wait_lock>
    80001e42:	8526                	mv	a0,s1
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	d7e080e7          	jalr	-642(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e4c:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e50:	8526                	mv	a0,s1
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	e24080e7          	jalr	-476(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001e5a:	8552                	mv	a0,s4
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	d66080e7          	jalr	-666(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001e64:	478d                	li	a5,3
    80001e66:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e6a:	8552                	mv	a0,s4
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e0a080e7          	jalr	-502(ra) # 80000c76 <release>
}
    80001e74:	854a                	mv	a0,s2
    80001e76:	70e2                	ld	ra,56(sp)
    80001e78:	7442                	ld	s0,48(sp)
    80001e7a:	74a2                	ld	s1,40(sp)
    80001e7c:	7902                	ld	s2,32(sp)
    80001e7e:	69e2                	ld	s3,24(sp)
    80001e80:	6a42                	ld	s4,16(sp)
    80001e82:	6aa2                	ld	s5,8(sp)
    80001e84:	6121                	addi	sp,sp,64
    80001e86:	8082                	ret
    return -1;
    80001e88:	597d                	li	s2,-1
    80001e8a:	b7ed                	j	80001e74 <fork+0x128>

0000000080001e8c <scheduler>:
{
    80001e8c:	7139                	addi	sp,sp,-64
    80001e8e:	fc06                	sd	ra,56(sp)
    80001e90:	f822                	sd	s0,48(sp)
    80001e92:	f426                	sd	s1,40(sp)
    80001e94:	f04a                	sd	s2,32(sp)
    80001e96:	ec4e                	sd	s3,24(sp)
    80001e98:	e852                	sd	s4,16(sp)
    80001e9a:	e456                	sd	s5,8(sp)
    80001e9c:	e05a                	sd	s6,0(sp)
    80001e9e:	0080                	addi	s0,sp,64
    80001ea0:	8792                	mv	a5,tp
  int id = r_tp();
    80001ea2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ea4:	00779a93          	slli	s5,a5,0x7
    80001ea8:	0000f717          	auipc	a4,0xf
    80001eac:	3f870713          	addi	a4,a4,1016 # 800112a0 <pid_lock>
    80001eb0:	9756                	add	a4,a4,s5
    80001eb2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eb6:	0000f717          	auipc	a4,0xf
    80001eba:	42270713          	addi	a4,a4,1058 # 800112d8 <cpus+0x8>
    80001ebe:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ec0:	498d                	li	s3,3
        p->state = RUNNING;
    80001ec2:	4b11                	li	s6,4
        c->proc = p;
    80001ec4:	079e                	slli	a5,a5,0x7
    80001ec6:	0000fa17          	auipc	s4,0xf
    80001eca:	3daa0a13          	addi	s4,s4,986 # 800112a0 <pid_lock>
    80001ece:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ed0:	00015917          	auipc	s2,0x15
    80001ed4:	20090913          	addi	s2,s2,512 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ed8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001edc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ee0:	10079073          	csrw	sstatus,a5
    80001ee4:	0000f497          	auipc	s1,0xf
    80001ee8:	7ec48493          	addi	s1,s1,2028 # 800116d0 <proc>
    80001eec:	a811                	j	80001f00 <scheduler+0x74>
      release(&p->lock);
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	d86080e7          	jalr	-634(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ef8:	16848493          	addi	s1,s1,360
    80001efc:	fd248ee3          	beq	s1,s2,80001ed8 <scheduler+0x4c>
      acquire(&p->lock);
    80001f00:	8526                	mv	a0,s1
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	cc0080e7          	jalr	-832(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f0a:	4c9c                	lw	a5,24(s1)
    80001f0c:	ff3791e3          	bne	a5,s3,80001eee <scheduler+0x62>
        p->state = RUNNING;
    80001f10:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f14:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f18:	06048593          	addi	a1,s1,96
    80001f1c:	8556                	mv	a0,s5
    80001f1e:	00000097          	auipc	ra,0x0
    80001f22:	61e080e7          	jalr	1566(ra) # 8000253c <swtch>
        c->proc = 0;
    80001f26:	020a3823          	sd	zero,48(s4)
    80001f2a:	b7d1                	j	80001eee <scheduler+0x62>

0000000080001f2c <sched>:
{
    80001f2c:	7179                	addi	sp,sp,-48
    80001f2e:	f406                	sd	ra,40(sp)
    80001f30:	f022                	sd	s0,32(sp)
    80001f32:	ec26                	sd	s1,24(sp)
    80001f34:	e84a                	sd	s2,16(sp)
    80001f36:	e44e                	sd	s3,8(sp)
    80001f38:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f3a:	00000097          	auipc	ra,0x0
    80001f3e:	a44080e7          	jalr	-1468(ra) # 8000197e <myproc>
    80001f42:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	c04080e7          	jalr	-1020(ra) # 80000b48 <holding>
    80001f4c:	c93d                	beqz	a0,80001fc2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f4e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f50:	2781                	sext.w	a5,a5
    80001f52:	079e                	slli	a5,a5,0x7
    80001f54:	0000f717          	auipc	a4,0xf
    80001f58:	34c70713          	addi	a4,a4,844 # 800112a0 <pid_lock>
    80001f5c:	97ba                	add	a5,a5,a4
    80001f5e:	0a87a703          	lw	a4,168(a5)
    80001f62:	4785                	li	a5,1
    80001f64:	06f71763          	bne	a4,a5,80001fd2 <sched+0xa6>
  if(p->state == RUNNING)
    80001f68:	4c98                	lw	a4,24(s1)
    80001f6a:	4791                	li	a5,4
    80001f6c:	06f70b63          	beq	a4,a5,80001fe2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f70:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f74:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f76:	efb5                	bnez	a5,80001ff2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f78:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f7a:	0000f917          	auipc	s2,0xf
    80001f7e:	32690913          	addi	s2,s2,806 # 800112a0 <pid_lock>
    80001f82:	2781                	sext.w	a5,a5
    80001f84:	079e                	slli	a5,a5,0x7
    80001f86:	97ca                	add	a5,a5,s2
    80001f88:	0ac7a983          	lw	s3,172(a5)
    80001f8c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f8e:	2781                	sext.w	a5,a5
    80001f90:	079e                	slli	a5,a5,0x7
    80001f92:	0000f597          	auipc	a1,0xf
    80001f96:	34658593          	addi	a1,a1,838 # 800112d8 <cpus+0x8>
    80001f9a:	95be                	add	a1,a1,a5
    80001f9c:	06048513          	addi	a0,s1,96
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	59c080e7          	jalr	1436(ra) # 8000253c <swtch>
    80001fa8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001faa:	2781                	sext.w	a5,a5
    80001fac:	079e                	slli	a5,a5,0x7
    80001fae:	97ca                	add	a5,a5,s2
    80001fb0:	0b37a623          	sw	s3,172(a5)
}
    80001fb4:	70a2                	ld	ra,40(sp)
    80001fb6:	7402                	ld	s0,32(sp)
    80001fb8:	64e2                	ld	s1,24(sp)
    80001fba:	6942                	ld	s2,16(sp)
    80001fbc:	69a2                	ld	s3,8(sp)
    80001fbe:	6145                	addi	sp,sp,48
    80001fc0:	8082                	ret
    panic("sched p->lock");
    80001fc2:	00006517          	auipc	a0,0x6
    80001fc6:	23e50513          	addi	a0,a0,574 # 80008200 <digits+0x1c0>
    80001fca:	ffffe097          	auipc	ra,0xffffe
    80001fce:	560080e7          	jalr	1376(ra) # 8000052a <panic>
    panic("sched locks");
    80001fd2:	00006517          	auipc	a0,0x6
    80001fd6:	23e50513          	addi	a0,a0,574 # 80008210 <digits+0x1d0>
    80001fda:	ffffe097          	auipc	ra,0xffffe
    80001fde:	550080e7          	jalr	1360(ra) # 8000052a <panic>
    panic("sched running");
    80001fe2:	00006517          	auipc	a0,0x6
    80001fe6:	23e50513          	addi	a0,a0,574 # 80008220 <digits+0x1e0>
    80001fea:	ffffe097          	auipc	ra,0xffffe
    80001fee:	540080e7          	jalr	1344(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001ff2:	00006517          	auipc	a0,0x6
    80001ff6:	23e50513          	addi	a0,a0,574 # 80008230 <digits+0x1f0>
    80001ffa:	ffffe097          	auipc	ra,0xffffe
    80001ffe:	530080e7          	jalr	1328(ra) # 8000052a <panic>

0000000080002002 <yield>:
{
    80002002:	1101                	addi	sp,sp,-32
    80002004:	ec06                	sd	ra,24(sp)
    80002006:	e822                	sd	s0,16(sp)
    80002008:	e426                	sd	s1,8(sp)
    8000200a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	972080e7          	jalr	-1678(ra) # 8000197e <myproc>
    80002014:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	bac080e7          	jalr	-1108(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    8000201e:	478d                	li	a5,3
    80002020:	cc9c                	sw	a5,24(s1)
  sched();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	f0a080e7          	jalr	-246(ra) # 80001f2c <sched>
  release(&p->lock);
    8000202a:	8526                	mv	a0,s1
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	c4a080e7          	jalr	-950(ra) # 80000c76 <release>
}
    80002034:	60e2                	ld	ra,24(sp)
    80002036:	6442                	ld	s0,16(sp)
    80002038:	64a2                	ld	s1,8(sp)
    8000203a:	6105                	addi	sp,sp,32
    8000203c:	8082                	ret

000000008000203e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000203e:	7179                	addi	sp,sp,-48
    80002040:	f406                	sd	ra,40(sp)
    80002042:	f022                	sd	s0,32(sp)
    80002044:	ec26                	sd	s1,24(sp)
    80002046:	e84a                	sd	s2,16(sp)
    80002048:	e44e                	sd	s3,8(sp)
    8000204a:	1800                	addi	s0,sp,48
    8000204c:	89aa                	mv	s3,a0
    8000204e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002050:	00000097          	auipc	ra,0x0
    80002054:	92e080e7          	jalr	-1746(ra) # 8000197e <myproc>
    80002058:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	b68080e7          	jalr	-1176(ra) # 80000bc2 <acquire>
  release(lk);
    80002062:	854a                	mv	a0,s2
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	c12080e7          	jalr	-1006(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    8000206c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002070:	4789                	li	a5,2
    80002072:	cc9c                	sw	a5,24(s1)

  sched();
    80002074:	00000097          	auipc	ra,0x0
    80002078:	eb8080e7          	jalr	-328(ra) # 80001f2c <sched>

  // Tidy up.
  p->chan = 0;
    8000207c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002080:	8526                	mv	a0,s1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	bf4080e7          	jalr	-1036(ra) # 80000c76 <release>
  acquire(lk);
    8000208a:	854a                	mv	a0,s2
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	b36080e7          	jalr	-1226(ra) # 80000bc2 <acquire>
}
    80002094:	70a2                	ld	ra,40(sp)
    80002096:	7402                	ld	s0,32(sp)
    80002098:	64e2                	ld	s1,24(sp)
    8000209a:	6942                	ld	s2,16(sp)
    8000209c:	69a2                	ld	s3,8(sp)
    8000209e:	6145                	addi	sp,sp,48
    800020a0:	8082                	ret

00000000800020a2 <wait>:
{
    800020a2:	715d                	addi	sp,sp,-80
    800020a4:	e486                	sd	ra,72(sp)
    800020a6:	e0a2                	sd	s0,64(sp)
    800020a8:	fc26                	sd	s1,56(sp)
    800020aa:	f84a                	sd	s2,48(sp)
    800020ac:	f44e                	sd	s3,40(sp)
    800020ae:	f052                	sd	s4,32(sp)
    800020b0:	ec56                	sd	s5,24(sp)
    800020b2:	e85a                	sd	s6,16(sp)
    800020b4:	e45e                	sd	s7,8(sp)
    800020b6:	e062                	sd	s8,0(sp)
    800020b8:	0880                	addi	s0,sp,80
    800020ba:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020bc:	00000097          	auipc	ra,0x0
    800020c0:	8c2080e7          	jalr	-1854(ra) # 8000197e <myproc>
    800020c4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020c6:	0000f517          	auipc	a0,0xf
    800020ca:	1f250513          	addi	a0,a0,498 # 800112b8 <wait_lock>
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	af4080e7          	jalr	-1292(ra) # 80000bc2 <acquire>
    havekids = 0;
    800020d6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020d8:	4a15                	li	s4,5
        havekids = 1;
    800020da:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020dc:	00015997          	auipc	s3,0x15
    800020e0:	ff498993          	addi	s3,s3,-12 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020e4:	0000fc17          	auipc	s8,0xf
    800020e8:	1d4c0c13          	addi	s8,s8,468 # 800112b8 <wait_lock>
    havekids = 0;
    800020ec:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800020ee:	0000f497          	auipc	s1,0xf
    800020f2:	5e248493          	addi	s1,s1,1506 # 800116d0 <proc>
    800020f6:	a0bd                	j	80002164 <wait+0xc2>
          pid = np->pid;
    800020f8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800020fc:	000b0e63          	beqz	s6,80002118 <wait+0x76>
    80002100:	4691                	li	a3,4
    80002102:	02c48613          	addi	a2,s1,44
    80002106:	85da                	mv	a1,s6
    80002108:	05093503          	ld	a0,80(s2)
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	532080e7          	jalr	1330(ra) # 8000163e <copyout>
    80002114:	02054563          	bltz	a0,8000213e <wait+0x9c>
          freeproc(np);
    80002118:	8526                	mv	a0,s1
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	a16080e7          	jalr	-1514(ra) # 80001b30 <freeproc>
          release(&np->lock);
    80002122:	8526                	mv	a0,s1
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	b52080e7          	jalr	-1198(ra) # 80000c76 <release>
          release(&wait_lock);
    8000212c:	0000f517          	auipc	a0,0xf
    80002130:	18c50513          	addi	a0,a0,396 # 800112b8 <wait_lock>
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	b42080e7          	jalr	-1214(ra) # 80000c76 <release>
          return pid;
    8000213c:	a09d                	j	800021a2 <wait+0x100>
            release(&np->lock);
    8000213e:	8526                	mv	a0,s1
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b36080e7          	jalr	-1226(ra) # 80000c76 <release>
            release(&wait_lock);
    80002148:	0000f517          	auipc	a0,0xf
    8000214c:	17050513          	addi	a0,a0,368 # 800112b8 <wait_lock>
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	b26080e7          	jalr	-1242(ra) # 80000c76 <release>
            return -1;
    80002158:	59fd                	li	s3,-1
    8000215a:	a0a1                	j	800021a2 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000215c:	16848493          	addi	s1,s1,360
    80002160:	03348463          	beq	s1,s3,80002188 <wait+0xe6>
      if(np->parent == p){
    80002164:	7c9c                	ld	a5,56(s1)
    80002166:	ff279be3          	bne	a5,s2,8000215c <wait+0xba>
        acquire(&np->lock);
    8000216a:	8526                	mv	a0,s1
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	a56080e7          	jalr	-1450(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002174:	4c9c                	lw	a5,24(s1)
    80002176:	f94781e3          	beq	a5,s4,800020f8 <wait+0x56>
        release(&np->lock);
    8000217a:	8526                	mv	a0,s1
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	afa080e7          	jalr	-1286(ra) # 80000c76 <release>
        havekids = 1;
    80002184:	8756                	mv	a4,s5
    80002186:	bfd9                	j	8000215c <wait+0xba>
    if(!havekids || p->killed){
    80002188:	c701                	beqz	a4,80002190 <wait+0xee>
    8000218a:	02892783          	lw	a5,40(s2)
    8000218e:	c79d                	beqz	a5,800021bc <wait+0x11a>
      release(&wait_lock);
    80002190:	0000f517          	auipc	a0,0xf
    80002194:	12850513          	addi	a0,a0,296 # 800112b8 <wait_lock>
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	ade080e7          	jalr	-1314(ra) # 80000c76 <release>
      return -1;
    800021a0:	59fd                	li	s3,-1
}
    800021a2:	854e                	mv	a0,s3
    800021a4:	60a6                	ld	ra,72(sp)
    800021a6:	6406                	ld	s0,64(sp)
    800021a8:	74e2                	ld	s1,56(sp)
    800021aa:	7942                	ld	s2,48(sp)
    800021ac:	79a2                	ld	s3,40(sp)
    800021ae:	7a02                	ld	s4,32(sp)
    800021b0:	6ae2                	ld	s5,24(sp)
    800021b2:	6b42                	ld	s6,16(sp)
    800021b4:	6ba2                	ld	s7,8(sp)
    800021b6:	6c02                	ld	s8,0(sp)
    800021b8:	6161                	addi	sp,sp,80
    800021ba:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021bc:	85e2                	mv	a1,s8
    800021be:	854a                	mv	a0,s2
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	e7e080e7          	jalr	-386(ra) # 8000203e <sleep>
    havekids = 0;
    800021c8:	b715                	j	800020ec <wait+0x4a>

00000000800021ca <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021ca:	7139                	addi	sp,sp,-64
    800021cc:	fc06                	sd	ra,56(sp)
    800021ce:	f822                	sd	s0,48(sp)
    800021d0:	f426                	sd	s1,40(sp)
    800021d2:	f04a                	sd	s2,32(sp)
    800021d4:	ec4e                	sd	s3,24(sp)
    800021d6:	e852                	sd	s4,16(sp)
    800021d8:	e456                	sd	s5,8(sp)
    800021da:	0080                	addi	s0,sp,64
    800021dc:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021de:	0000f497          	auipc	s1,0xf
    800021e2:	4f248493          	addi	s1,s1,1266 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021e6:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021e8:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021ea:	00015917          	auipc	s2,0x15
    800021ee:	ee690913          	addi	s2,s2,-282 # 800170d0 <tickslock>
    800021f2:	a811                	j	80002206 <wakeup+0x3c>
      }
      release(&p->lock);
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	a80080e7          	jalr	-1408(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021fe:	16848493          	addi	s1,s1,360
    80002202:	03248663          	beq	s1,s2,8000222e <wakeup+0x64>
    if(p != myproc()){
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	778080e7          	jalr	1912(ra) # 8000197e <myproc>
    8000220e:	fea488e3          	beq	s1,a0,800021fe <wakeup+0x34>
      acquire(&p->lock);
    80002212:	8526                	mv	a0,s1
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	9ae080e7          	jalr	-1618(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000221c:	4c9c                	lw	a5,24(s1)
    8000221e:	fd379be3          	bne	a5,s3,800021f4 <wakeup+0x2a>
    80002222:	709c                	ld	a5,32(s1)
    80002224:	fd4798e3          	bne	a5,s4,800021f4 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002228:	0154ac23          	sw	s5,24(s1)
    8000222c:	b7e1                	j	800021f4 <wakeup+0x2a>
    }
  }
}
    8000222e:	70e2                	ld	ra,56(sp)
    80002230:	7442                	ld	s0,48(sp)
    80002232:	74a2                	ld	s1,40(sp)
    80002234:	7902                	ld	s2,32(sp)
    80002236:	69e2                	ld	s3,24(sp)
    80002238:	6a42                	ld	s4,16(sp)
    8000223a:	6aa2                	ld	s5,8(sp)
    8000223c:	6121                	addi	sp,sp,64
    8000223e:	8082                	ret

0000000080002240 <reparent>:
{
    80002240:	7179                	addi	sp,sp,-48
    80002242:	f406                	sd	ra,40(sp)
    80002244:	f022                	sd	s0,32(sp)
    80002246:	ec26                	sd	s1,24(sp)
    80002248:	e84a                	sd	s2,16(sp)
    8000224a:	e44e                	sd	s3,8(sp)
    8000224c:	e052                	sd	s4,0(sp)
    8000224e:	1800                	addi	s0,sp,48
    80002250:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002252:	0000f497          	auipc	s1,0xf
    80002256:	47e48493          	addi	s1,s1,1150 # 800116d0 <proc>
      pp->parent = initproc;
    8000225a:	00007a17          	auipc	s4,0x7
    8000225e:	dcea0a13          	addi	s4,s4,-562 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002262:	00015997          	auipc	s3,0x15
    80002266:	e6e98993          	addi	s3,s3,-402 # 800170d0 <tickslock>
    8000226a:	a029                	j	80002274 <reparent+0x34>
    8000226c:	16848493          	addi	s1,s1,360
    80002270:	01348d63          	beq	s1,s3,8000228a <reparent+0x4a>
    if(pp->parent == p){
    80002274:	7c9c                	ld	a5,56(s1)
    80002276:	ff279be3          	bne	a5,s2,8000226c <reparent+0x2c>
      pp->parent = initproc;
    8000227a:	000a3503          	ld	a0,0(s4)
    8000227e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002280:	00000097          	auipc	ra,0x0
    80002284:	f4a080e7          	jalr	-182(ra) # 800021ca <wakeup>
    80002288:	b7d5                	j	8000226c <reparent+0x2c>
}
    8000228a:	70a2                	ld	ra,40(sp)
    8000228c:	7402                	ld	s0,32(sp)
    8000228e:	64e2                	ld	s1,24(sp)
    80002290:	6942                	ld	s2,16(sp)
    80002292:	69a2                	ld	s3,8(sp)
    80002294:	6a02                	ld	s4,0(sp)
    80002296:	6145                	addi	sp,sp,48
    80002298:	8082                	ret

000000008000229a <exit>:
{
    8000229a:	7179                	addi	sp,sp,-48
    8000229c:	f406                	sd	ra,40(sp)
    8000229e:	f022                	sd	s0,32(sp)
    800022a0:	ec26                	sd	s1,24(sp)
    800022a2:	e84a                	sd	s2,16(sp)
    800022a4:	e44e                	sd	s3,8(sp)
    800022a6:	e052                	sd	s4,0(sp)
    800022a8:	1800                	addi	s0,sp,48
    800022aa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	6d2080e7          	jalr	1746(ra) # 8000197e <myproc>
    800022b4:	89aa                	mv	s3,a0
  if(p == initproc)
    800022b6:	00007797          	auipc	a5,0x7
    800022ba:	d727b783          	ld	a5,-654(a5) # 80009028 <initproc>
    800022be:	0d050493          	addi	s1,a0,208
    800022c2:	15050913          	addi	s2,a0,336
    800022c6:	02a79363          	bne	a5,a0,800022ec <exit+0x52>
    panic("init exiting");
    800022ca:	00006517          	auipc	a0,0x6
    800022ce:	f7e50513          	addi	a0,a0,-130 # 80008248 <digits+0x208>
    800022d2:	ffffe097          	auipc	ra,0xffffe
    800022d6:	258080e7          	jalr	600(ra) # 8000052a <panic>
      fileclose(f);
    800022da:	00002097          	auipc	ra,0x2
    800022de:	162080e7          	jalr	354(ra) # 8000443c <fileclose>
      p->ofile[fd] = 0;
    800022e2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022e6:	04a1                	addi	s1,s1,8
    800022e8:	01248563          	beq	s1,s2,800022f2 <exit+0x58>
    if(p->ofile[fd]){
    800022ec:	6088                	ld	a0,0(s1)
    800022ee:	f575                	bnez	a0,800022da <exit+0x40>
    800022f0:	bfdd                	j	800022e6 <exit+0x4c>
  begin_op();
    800022f2:	00002097          	auipc	ra,0x2
    800022f6:	c7e080e7          	jalr	-898(ra) # 80003f70 <begin_op>
  iput(p->cwd);
    800022fa:	1509b503          	ld	a0,336(s3)
    800022fe:	00001097          	auipc	ra,0x1
    80002302:	45a080e7          	jalr	1114(ra) # 80003758 <iput>
  end_op();
    80002306:	00002097          	auipc	ra,0x2
    8000230a:	cea080e7          	jalr	-790(ra) # 80003ff0 <end_op>
  p->cwd = 0;
    8000230e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002312:	0000f497          	auipc	s1,0xf
    80002316:	fa648493          	addi	s1,s1,-90 # 800112b8 <wait_lock>
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	8a6080e7          	jalr	-1882(ra) # 80000bc2 <acquire>
  reparent(p);
    80002324:	854e                	mv	a0,s3
    80002326:	00000097          	auipc	ra,0x0
    8000232a:	f1a080e7          	jalr	-230(ra) # 80002240 <reparent>
  wakeup(p->parent);
    8000232e:	0389b503          	ld	a0,56(s3)
    80002332:	00000097          	auipc	ra,0x0
    80002336:	e98080e7          	jalr	-360(ra) # 800021ca <wakeup>
  acquire(&p->lock);
    8000233a:	854e                	mv	a0,s3
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	886080e7          	jalr	-1914(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002344:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002348:	4795                	li	a5,5
    8000234a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000234e:	8526                	mv	a0,s1
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	926080e7          	jalr	-1754(ra) # 80000c76 <release>
  sched();
    80002358:	00000097          	auipc	ra,0x0
    8000235c:	bd4080e7          	jalr	-1068(ra) # 80001f2c <sched>
  panic("zombie exit");
    80002360:	00006517          	auipc	a0,0x6
    80002364:	ef850513          	addi	a0,a0,-264 # 80008258 <digits+0x218>
    80002368:	ffffe097          	auipc	ra,0xffffe
    8000236c:	1c2080e7          	jalr	450(ra) # 8000052a <panic>

0000000080002370 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002370:	7179                	addi	sp,sp,-48
    80002372:	f406                	sd	ra,40(sp)
    80002374:	f022                	sd	s0,32(sp)
    80002376:	ec26                	sd	s1,24(sp)
    80002378:	e84a                	sd	s2,16(sp)
    8000237a:	e44e                	sd	s3,8(sp)
    8000237c:	1800                	addi	s0,sp,48
    8000237e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002380:	0000f497          	auipc	s1,0xf
    80002384:	35048493          	addi	s1,s1,848 # 800116d0 <proc>
    80002388:	00015997          	auipc	s3,0x15
    8000238c:	d4898993          	addi	s3,s3,-696 # 800170d0 <tickslock>
    acquire(&p->lock);
    80002390:	8526                	mv	a0,s1
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	830080e7          	jalr	-2000(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    8000239a:	589c                	lw	a5,48(s1)
    8000239c:	01278d63          	beq	a5,s2,800023b6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023a0:	8526                	mv	a0,s1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	8d4080e7          	jalr	-1836(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023aa:	16848493          	addi	s1,s1,360
    800023ae:	ff3491e3          	bne	s1,s3,80002390 <kill+0x20>
  }
  return -1;
    800023b2:	557d                	li	a0,-1
    800023b4:	a829                	j	800023ce <kill+0x5e>
      p->killed = 1;
    800023b6:	4785                	li	a5,1
    800023b8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023ba:	4c98                	lw	a4,24(s1)
    800023bc:	4789                	li	a5,2
    800023be:	00f70f63          	beq	a4,a5,800023dc <kill+0x6c>
      release(&p->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8b2080e7          	jalr	-1870(ra) # 80000c76 <release>
      return 0;
    800023cc:	4501                	li	a0,0
}
    800023ce:	70a2                	ld	ra,40(sp)
    800023d0:	7402                	ld	s0,32(sp)
    800023d2:	64e2                	ld	s1,24(sp)
    800023d4:	6942                	ld	s2,16(sp)
    800023d6:	69a2                	ld	s3,8(sp)
    800023d8:	6145                	addi	sp,sp,48
    800023da:	8082                	ret
        p->state = RUNNABLE;
    800023dc:	478d                	li	a5,3
    800023de:	cc9c                	sw	a5,24(s1)
    800023e0:	b7cd                	j	800023c2 <kill+0x52>

00000000800023e2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023e2:	7179                	addi	sp,sp,-48
    800023e4:	f406                	sd	ra,40(sp)
    800023e6:	f022                	sd	s0,32(sp)
    800023e8:	ec26                	sd	s1,24(sp)
    800023ea:	e84a                	sd	s2,16(sp)
    800023ec:	e44e                	sd	s3,8(sp)
    800023ee:	e052                	sd	s4,0(sp)
    800023f0:	1800                	addi	s0,sp,48
    800023f2:	84aa                	mv	s1,a0
    800023f4:	892e                	mv	s2,a1
    800023f6:	89b2                	mv	s3,a2
    800023f8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	584080e7          	jalr	1412(ra) # 8000197e <myproc>
  if(user_dst){
    80002402:	c08d                	beqz	s1,80002424 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002404:	86d2                	mv	a3,s4
    80002406:	864e                	mv	a2,s3
    80002408:	85ca                	mv	a1,s2
    8000240a:	6928                	ld	a0,80(a0)
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	232080e7          	jalr	562(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002414:	70a2                	ld	ra,40(sp)
    80002416:	7402                	ld	s0,32(sp)
    80002418:	64e2                	ld	s1,24(sp)
    8000241a:	6942                	ld	s2,16(sp)
    8000241c:	69a2                	ld	s3,8(sp)
    8000241e:	6a02                	ld	s4,0(sp)
    80002420:	6145                	addi	sp,sp,48
    80002422:	8082                	ret
    memmove((char *)dst, src, len);
    80002424:	000a061b          	sext.w	a2,s4
    80002428:	85ce                	mv	a1,s3
    8000242a:	854a                	mv	a0,s2
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	8ee080e7          	jalr	-1810(ra) # 80000d1a <memmove>
    return 0;
    80002434:	8526                	mv	a0,s1
    80002436:	bff9                	j	80002414 <either_copyout+0x32>

0000000080002438 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002438:	7179                	addi	sp,sp,-48
    8000243a:	f406                	sd	ra,40(sp)
    8000243c:	f022                	sd	s0,32(sp)
    8000243e:	ec26                	sd	s1,24(sp)
    80002440:	e84a                	sd	s2,16(sp)
    80002442:	e44e                	sd	s3,8(sp)
    80002444:	e052                	sd	s4,0(sp)
    80002446:	1800                	addi	s0,sp,48
    80002448:	892a                	mv	s2,a0
    8000244a:	84ae                	mv	s1,a1
    8000244c:	89b2                	mv	s3,a2
    8000244e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	52e080e7          	jalr	1326(ra) # 8000197e <myproc>
  if(user_src){
    80002458:	c08d                	beqz	s1,8000247a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000245a:	86d2                	mv	a3,s4
    8000245c:	864e                	mv	a2,s3
    8000245e:	85ca                	mv	a1,s2
    80002460:	6928                	ld	a0,80(a0)
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	268080e7          	jalr	616(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000246a:	70a2                	ld	ra,40(sp)
    8000246c:	7402                	ld	s0,32(sp)
    8000246e:	64e2                	ld	s1,24(sp)
    80002470:	6942                	ld	s2,16(sp)
    80002472:	69a2                	ld	s3,8(sp)
    80002474:	6a02                	ld	s4,0(sp)
    80002476:	6145                	addi	sp,sp,48
    80002478:	8082                	ret
    memmove(dst, (char*)src, len);
    8000247a:	000a061b          	sext.w	a2,s4
    8000247e:	85ce                	mv	a1,s3
    80002480:	854a                	mv	a0,s2
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	898080e7          	jalr	-1896(ra) # 80000d1a <memmove>
    return 0;
    8000248a:	8526                	mv	a0,s1
    8000248c:	bff9                	j	8000246a <either_copyin+0x32>

000000008000248e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000248e:	715d                	addi	sp,sp,-80
    80002490:	e486                	sd	ra,72(sp)
    80002492:	e0a2                	sd	s0,64(sp)
    80002494:	fc26                	sd	s1,56(sp)
    80002496:	f84a                	sd	s2,48(sp)
    80002498:	f44e                	sd	s3,40(sp)
    8000249a:	f052                	sd	s4,32(sp)
    8000249c:	ec56                	sd	s5,24(sp)
    8000249e:	e85a                	sd	s6,16(sp)
    800024a0:	e45e                	sd	s7,8(sp)
    800024a2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024a4:	00006517          	auipc	a0,0x6
    800024a8:	c2450513          	addi	a0,a0,-988 # 800080c8 <digits+0x88>
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	0c8080e7          	jalr	200(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024b4:	0000f497          	auipc	s1,0xf
    800024b8:	37448493          	addi	s1,s1,884 # 80011828 <proc+0x158>
    800024bc:	00015917          	auipc	s2,0x15
    800024c0:	d6c90913          	addi	s2,s2,-660 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024c4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024c6:	00006997          	auipc	s3,0x6
    800024ca:	da298993          	addi	s3,s3,-606 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800024ce:	00006a97          	auipc	s5,0x6
    800024d2:	da2a8a93          	addi	s5,s5,-606 # 80008270 <digits+0x230>
    printf("\n");
    800024d6:	00006a17          	auipc	s4,0x6
    800024da:	bf2a0a13          	addi	s4,s4,-1038 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024de:	00006b97          	auipc	s7,0x6
    800024e2:	dcab8b93          	addi	s7,s7,-566 # 800082a8 <states.0>
    800024e6:	a00d                	j	80002508 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800024e8:	ed86a583          	lw	a1,-296(a3)
    800024ec:	8556                	mv	a0,s5
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	086080e7          	jalr	134(ra) # 80000574 <printf>
    printf("\n");
    800024f6:	8552                	mv	a0,s4
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	07c080e7          	jalr	124(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002500:	16848493          	addi	s1,s1,360
    80002504:	03248163          	beq	s1,s2,80002526 <procdump+0x98>
    if(p->state == UNUSED)
    80002508:	86a6                	mv	a3,s1
    8000250a:	ec04a783          	lw	a5,-320(s1)
    8000250e:	dbed                	beqz	a5,80002500 <procdump+0x72>
      state = "???";
    80002510:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002512:	fcfb6be3          	bltu	s6,a5,800024e8 <procdump+0x5a>
    80002516:	1782                	slli	a5,a5,0x20
    80002518:	9381                	srli	a5,a5,0x20
    8000251a:	078e                	slli	a5,a5,0x3
    8000251c:	97de                	add	a5,a5,s7
    8000251e:	6390                	ld	a2,0(a5)
    80002520:	f661                	bnez	a2,800024e8 <procdump+0x5a>
      state = "???";
    80002522:	864e                	mv	a2,s3
    80002524:	b7d1                	j	800024e8 <procdump+0x5a>
  }
}
    80002526:	60a6                	ld	ra,72(sp)
    80002528:	6406                	ld	s0,64(sp)
    8000252a:	74e2                	ld	s1,56(sp)
    8000252c:	7942                	ld	s2,48(sp)
    8000252e:	79a2                	ld	s3,40(sp)
    80002530:	7a02                	ld	s4,32(sp)
    80002532:	6ae2                	ld	s5,24(sp)
    80002534:	6b42                	ld	s6,16(sp)
    80002536:	6ba2                	ld	s7,8(sp)
    80002538:	6161                	addi	sp,sp,80
    8000253a:	8082                	ret

000000008000253c <swtch>:
    8000253c:	00153023          	sd	ra,0(a0)
    80002540:	00253423          	sd	sp,8(a0)
    80002544:	e900                	sd	s0,16(a0)
    80002546:	ed04                	sd	s1,24(a0)
    80002548:	03253023          	sd	s2,32(a0)
    8000254c:	03353423          	sd	s3,40(a0)
    80002550:	03453823          	sd	s4,48(a0)
    80002554:	03553c23          	sd	s5,56(a0)
    80002558:	05653023          	sd	s6,64(a0)
    8000255c:	05753423          	sd	s7,72(a0)
    80002560:	05853823          	sd	s8,80(a0)
    80002564:	05953c23          	sd	s9,88(a0)
    80002568:	07a53023          	sd	s10,96(a0)
    8000256c:	07b53423          	sd	s11,104(a0)
    80002570:	0005b083          	ld	ra,0(a1)
    80002574:	0085b103          	ld	sp,8(a1)
    80002578:	6980                	ld	s0,16(a1)
    8000257a:	6d84                	ld	s1,24(a1)
    8000257c:	0205b903          	ld	s2,32(a1)
    80002580:	0285b983          	ld	s3,40(a1)
    80002584:	0305ba03          	ld	s4,48(a1)
    80002588:	0385ba83          	ld	s5,56(a1)
    8000258c:	0405bb03          	ld	s6,64(a1)
    80002590:	0485bb83          	ld	s7,72(a1)
    80002594:	0505bc03          	ld	s8,80(a1)
    80002598:	0585bc83          	ld	s9,88(a1)
    8000259c:	0605bd03          	ld	s10,96(a1)
    800025a0:	0685bd83          	ld	s11,104(a1)
    800025a4:	8082                	ret

00000000800025a6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025a6:	1141                	addi	sp,sp,-16
    800025a8:	e406                	sd	ra,8(sp)
    800025aa:	e022                	sd	s0,0(sp)
    800025ac:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025ae:	00006597          	auipc	a1,0x6
    800025b2:	d2a58593          	addi	a1,a1,-726 # 800082d8 <states.0+0x30>
    800025b6:	00015517          	auipc	a0,0x15
    800025ba:	b1a50513          	addi	a0,a0,-1254 # 800170d0 <tickslock>
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	574080e7          	jalr	1396(ra) # 80000b32 <initlock>
}
    800025c6:	60a2                	ld	ra,8(sp)
    800025c8:	6402                	ld	s0,0(sp)
    800025ca:	0141                	addi	sp,sp,16
    800025cc:	8082                	ret

00000000800025ce <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025ce:	1141                	addi	sp,sp,-16
    800025d0:	e422                	sd	s0,8(sp)
    800025d2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025d4:	00003797          	auipc	a5,0x3
    800025d8:	48c78793          	addi	a5,a5,1164 # 80005a60 <kernelvec>
    800025dc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800025e0:	6422                	ld	s0,8(sp)
    800025e2:	0141                	addi	sp,sp,16
    800025e4:	8082                	ret

00000000800025e6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800025e6:	1141                	addi	sp,sp,-16
    800025e8:	e406                	sd	ra,8(sp)
    800025ea:	e022                	sd	s0,0(sp)
    800025ec:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	390080e7          	jalr	912(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025f6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800025fa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025fc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002600:	00005617          	auipc	a2,0x5
    80002604:	a0060613          	addi	a2,a2,-1536 # 80007000 <_trampoline>
    80002608:	00005697          	auipc	a3,0x5
    8000260c:	9f868693          	addi	a3,a3,-1544 # 80007000 <_trampoline>
    80002610:	8e91                	sub	a3,a3,a2
    80002612:	040007b7          	lui	a5,0x4000
    80002616:	17fd                	addi	a5,a5,-1
    80002618:	07b2                	slli	a5,a5,0xc
    8000261a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000261c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002620:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002622:	180026f3          	csrr	a3,satp
    80002626:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002628:	6d38                	ld	a4,88(a0)
    8000262a:	6134                	ld	a3,64(a0)
    8000262c:	6585                	lui	a1,0x1
    8000262e:	96ae                	add	a3,a3,a1
    80002630:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002632:	6d38                	ld	a4,88(a0)
    80002634:	00000697          	auipc	a3,0x0
    80002638:	13868693          	addi	a3,a3,312 # 8000276c <usertrap>
    8000263c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000263e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002640:	8692                	mv	a3,tp
    80002642:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002644:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002648:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000264c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002650:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002654:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002656:	6f18                	ld	a4,24(a4)
    80002658:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000265c:	692c                	ld	a1,80(a0)
    8000265e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002660:	00005717          	auipc	a4,0x5
    80002664:	a3070713          	addi	a4,a4,-1488 # 80007090 <userret>
    80002668:	8f11                	sub	a4,a4,a2
    8000266a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000266c:	577d                	li	a4,-1
    8000266e:	177e                	slli	a4,a4,0x3f
    80002670:	8dd9                	or	a1,a1,a4
    80002672:	02000537          	lui	a0,0x2000
    80002676:	157d                	addi	a0,a0,-1
    80002678:	0536                	slli	a0,a0,0xd
    8000267a:	9782                	jalr	a5
}
    8000267c:	60a2                	ld	ra,8(sp)
    8000267e:	6402                	ld	s0,0(sp)
    80002680:	0141                	addi	sp,sp,16
    80002682:	8082                	ret

0000000080002684 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002684:	1101                	addi	sp,sp,-32
    80002686:	ec06                	sd	ra,24(sp)
    80002688:	e822                	sd	s0,16(sp)
    8000268a:	e426                	sd	s1,8(sp)
    8000268c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000268e:	00015497          	auipc	s1,0x15
    80002692:	a4248493          	addi	s1,s1,-1470 # 800170d0 <tickslock>
    80002696:	8526                	mv	a0,s1
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	52a080e7          	jalr	1322(ra) # 80000bc2 <acquire>
  ticks++;
    800026a0:	00007517          	auipc	a0,0x7
    800026a4:	99050513          	addi	a0,a0,-1648 # 80009030 <ticks>
    800026a8:	411c                	lw	a5,0(a0)
    800026aa:	2785                	addiw	a5,a5,1
    800026ac:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026ae:	00000097          	auipc	ra,0x0
    800026b2:	b1c080e7          	jalr	-1252(ra) # 800021ca <wakeup>
  release(&tickslock);
    800026b6:	8526                	mv	a0,s1
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	5be080e7          	jalr	1470(ra) # 80000c76 <release>
}
    800026c0:	60e2                	ld	ra,24(sp)
    800026c2:	6442                	ld	s0,16(sp)
    800026c4:	64a2                	ld	s1,8(sp)
    800026c6:	6105                	addi	sp,sp,32
    800026c8:	8082                	ret

00000000800026ca <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026ca:	1101                	addi	sp,sp,-32
    800026cc:	ec06                	sd	ra,24(sp)
    800026ce:	e822                	sd	s0,16(sp)
    800026d0:	e426                	sd	s1,8(sp)
    800026d2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026d4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800026d8:	00074d63          	bltz	a4,800026f2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800026dc:	57fd                	li	a5,-1
    800026de:	17fe                	slli	a5,a5,0x3f
    800026e0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800026e2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800026e4:	06f70363          	beq	a4,a5,8000274a <devintr+0x80>
  }
}
    800026e8:	60e2                	ld	ra,24(sp)
    800026ea:	6442                	ld	s0,16(sp)
    800026ec:	64a2                	ld	s1,8(sp)
    800026ee:	6105                	addi	sp,sp,32
    800026f0:	8082                	ret
     (scause & 0xff) == 9){
    800026f2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800026f6:	46a5                	li	a3,9
    800026f8:	fed792e3          	bne	a5,a3,800026dc <devintr+0x12>
    int irq = plic_claim();
    800026fc:	00003097          	auipc	ra,0x3
    80002700:	46c080e7          	jalr	1132(ra) # 80005b68 <plic_claim>
    80002704:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002706:	47a9                	li	a5,10
    80002708:	02f50763          	beq	a0,a5,80002736 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000270c:	4785                	li	a5,1
    8000270e:	02f50963          	beq	a0,a5,80002740 <devintr+0x76>
    return 1;
    80002712:	4505                	li	a0,1
    } else if(irq){
    80002714:	d8f1                	beqz	s1,800026e8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002716:	85a6                	mv	a1,s1
    80002718:	00006517          	auipc	a0,0x6
    8000271c:	bc850513          	addi	a0,a0,-1080 # 800082e0 <states.0+0x38>
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	e54080e7          	jalr	-428(ra) # 80000574 <printf>
      plic_complete(irq);
    80002728:	8526                	mv	a0,s1
    8000272a:	00003097          	auipc	ra,0x3
    8000272e:	462080e7          	jalr	1122(ra) # 80005b8c <plic_complete>
    return 1;
    80002732:	4505                	li	a0,1
    80002734:	bf55                	j	800026e8 <devintr+0x1e>
      uartintr();
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	250080e7          	jalr	592(ra) # 80000986 <uartintr>
    8000273e:	b7ed                	j	80002728 <devintr+0x5e>
      virtio_disk_intr();
    80002740:	00004097          	auipc	ra,0x4
    80002744:	8de080e7          	jalr	-1826(ra) # 8000601e <virtio_disk_intr>
    80002748:	b7c5                	j	80002728 <devintr+0x5e>
    if(cpuid() == 0){
    8000274a:	fffff097          	auipc	ra,0xfffff
    8000274e:	208080e7          	jalr	520(ra) # 80001952 <cpuid>
    80002752:	c901                	beqz	a0,80002762 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002754:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002758:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000275a:	14479073          	csrw	sip,a5
    return 2;
    8000275e:	4509                	li	a0,2
    80002760:	b761                	j	800026e8 <devintr+0x1e>
      clockintr();
    80002762:	00000097          	auipc	ra,0x0
    80002766:	f22080e7          	jalr	-222(ra) # 80002684 <clockintr>
    8000276a:	b7ed                	j	80002754 <devintr+0x8a>

000000008000276c <usertrap>:
{
    8000276c:	1101                	addi	sp,sp,-32
    8000276e:	ec06                	sd	ra,24(sp)
    80002770:	e822                	sd	s0,16(sp)
    80002772:	e426                	sd	s1,8(sp)
    80002774:	e04a                	sd	s2,0(sp)
    80002776:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002778:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000277c:	1007f793          	andi	a5,a5,256
    80002780:	e3ad                	bnez	a5,800027e2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002782:	00003797          	auipc	a5,0x3
    80002786:	2de78793          	addi	a5,a5,734 # 80005a60 <kernelvec>
    8000278a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000278e:	fffff097          	auipc	ra,0xfffff
    80002792:	1f0080e7          	jalr	496(ra) # 8000197e <myproc>
    80002796:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002798:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000279a:	14102773          	csrr	a4,sepc
    8000279e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027a0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027a4:	47a1                	li	a5,8
    800027a6:	04f71c63          	bne	a4,a5,800027fe <usertrap+0x92>
    if(p->killed)
    800027aa:	551c                	lw	a5,40(a0)
    800027ac:	e3b9                	bnez	a5,800027f2 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027ae:	6cb8                	ld	a4,88(s1)
    800027b0:	6f1c                	ld	a5,24(a4)
    800027b2:	0791                	addi	a5,a5,4
    800027b4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027b6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027ba:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027be:	10079073          	csrw	sstatus,a5
    syscall();
    800027c2:	00000097          	auipc	ra,0x0
    800027c6:	2e0080e7          	jalr	736(ra) # 80002aa2 <syscall>
  if(p->killed)
    800027ca:	549c                	lw	a5,40(s1)
    800027cc:	ebc1                	bnez	a5,8000285c <usertrap+0xf0>
  usertrapret();
    800027ce:	00000097          	auipc	ra,0x0
    800027d2:	e18080e7          	jalr	-488(ra) # 800025e6 <usertrapret>
}
    800027d6:	60e2                	ld	ra,24(sp)
    800027d8:	6442                	ld	s0,16(sp)
    800027da:	64a2                	ld	s1,8(sp)
    800027dc:	6902                	ld	s2,0(sp)
    800027de:	6105                	addi	sp,sp,32
    800027e0:	8082                	ret
    panic("usertrap: not from user mode");
    800027e2:	00006517          	auipc	a0,0x6
    800027e6:	b1e50513          	addi	a0,a0,-1250 # 80008300 <states.0+0x58>
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	d40080e7          	jalr	-704(ra) # 8000052a <panic>
      exit(-1);
    800027f2:	557d                	li	a0,-1
    800027f4:	00000097          	auipc	ra,0x0
    800027f8:	aa6080e7          	jalr	-1370(ra) # 8000229a <exit>
    800027fc:	bf4d                	j	800027ae <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	ecc080e7          	jalr	-308(ra) # 800026ca <devintr>
    80002806:	892a                	mv	s2,a0
    80002808:	c501                	beqz	a0,80002810 <usertrap+0xa4>
  if(p->killed)
    8000280a:	549c                	lw	a5,40(s1)
    8000280c:	c3a1                	beqz	a5,8000284c <usertrap+0xe0>
    8000280e:	a815                	j	80002842 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002810:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002814:	5890                	lw	a2,48(s1)
    80002816:	00006517          	auipc	a0,0x6
    8000281a:	b0a50513          	addi	a0,a0,-1270 # 80008320 <states.0+0x78>
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	d56080e7          	jalr	-682(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002826:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000282a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000282e:	00006517          	auipc	a0,0x6
    80002832:	b2250513          	addi	a0,a0,-1246 # 80008350 <states.0+0xa8>
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	d3e080e7          	jalr	-706(ra) # 80000574 <printf>
    p->killed = 1;
    8000283e:	4785                	li	a5,1
    80002840:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002842:	557d                	li	a0,-1
    80002844:	00000097          	auipc	ra,0x0
    80002848:	a56080e7          	jalr	-1450(ra) # 8000229a <exit>
  if(which_dev == 2)
    8000284c:	4789                	li	a5,2
    8000284e:	f8f910e3          	bne	s2,a5,800027ce <usertrap+0x62>
    yield();
    80002852:	fffff097          	auipc	ra,0xfffff
    80002856:	7b0080e7          	jalr	1968(ra) # 80002002 <yield>
    8000285a:	bf95                	j	800027ce <usertrap+0x62>
  int which_dev = 0;
    8000285c:	4901                	li	s2,0
    8000285e:	b7d5                	j	80002842 <usertrap+0xd6>

0000000080002860 <kerneltrap>:
{
    80002860:	7179                	addi	sp,sp,-48
    80002862:	f406                	sd	ra,40(sp)
    80002864:	f022                	sd	s0,32(sp)
    80002866:	ec26                	sd	s1,24(sp)
    80002868:	e84a                	sd	s2,16(sp)
    8000286a:	e44e                	sd	s3,8(sp)
    8000286c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000286e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002872:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002876:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000287a:	1004f793          	andi	a5,s1,256
    8000287e:	cb85                	beqz	a5,800028ae <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002880:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002884:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002886:	ef85                	bnez	a5,800028be <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	e42080e7          	jalr	-446(ra) # 800026ca <devintr>
    80002890:	cd1d                	beqz	a0,800028ce <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002892:	4789                	li	a5,2
    80002894:	06f50a63          	beq	a0,a5,80002908 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002898:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000289c:	10049073          	csrw	sstatus,s1
}
    800028a0:	70a2                	ld	ra,40(sp)
    800028a2:	7402                	ld	s0,32(sp)
    800028a4:	64e2                	ld	s1,24(sp)
    800028a6:	6942                	ld	s2,16(sp)
    800028a8:	69a2                	ld	s3,8(sp)
    800028aa:	6145                	addi	sp,sp,48
    800028ac:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028ae:	00006517          	auipc	a0,0x6
    800028b2:	ac250513          	addi	a0,a0,-1342 # 80008370 <states.0+0xc8>
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	c74080e7          	jalr	-908(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800028be:	00006517          	auipc	a0,0x6
    800028c2:	ada50513          	addi	a0,a0,-1318 # 80008398 <states.0+0xf0>
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	c64080e7          	jalr	-924(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    800028ce:	85ce                	mv	a1,s3
    800028d0:	00006517          	auipc	a0,0x6
    800028d4:	ae850513          	addi	a0,a0,-1304 # 800083b8 <states.0+0x110>
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	c9c080e7          	jalr	-868(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028e4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028e8:	00006517          	auipc	a0,0x6
    800028ec:	ae050513          	addi	a0,a0,-1312 # 800083c8 <states.0+0x120>
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	c84080e7          	jalr	-892(ra) # 80000574 <printf>
    panic("kerneltrap");
    800028f8:	00006517          	auipc	a0,0x6
    800028fc:	ae850513          	addi	a0,a0,-1304 # 800083e0 <states.0+0x138>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c2a080e7          	jalr	-982(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002908:	fffff097          	auipc	ra,0xfffff
    8000290c:	076080e7          	jalr	118(ra) # 8000197e <myproc>
    80002910:	d541                	beqz	a0,80002898 <kerneltrap+0x38>
    80002912:	fffff097          	auipc	ra,0xfffff
    80002916:	06c080e7          	jalr	108(ra) # 8000197e <myproc>
    8000291a:	4d18                	lw	a4,24(a0)
    8000291c:	4791                	li	a5,4
    8000291e:	f6f71de3          	bne	a4,a5,80002898 <kerneltrap+0x38>
    yield();
    80002922:	fffff097          	auipc	ra,0xfffff
    80002926:	6e0080e7          	jalr	1760(ra) # 80002002 <yield>
    8000292a:	b7bd                	j	80002898 <kerneltrap+0x38>

000000008000292c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000292c:	1101                	addi	sp,sp,-32
    8000292e:	ec06                	sd	ra,24(sp)
    80002930:	e822                	sd	s0,16(sp)
    80002932:	e426                	sd	s1,8(sp)
    80002934:	1000                	addi	s0,sp,32
    80002936:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002938:	fffff097          	auipc	ra,0xfffff
    8000293c:	046080e7          	jalr	70(ra) # 8000197e <myproc>
  switch (n) {
    80002940:	4795                	li	a5,5
    80002942:	0497e163          	bltu	a5,s1,80002984 <argraw+0x58>
    80002946:	048a                	slli	s1,s1,0x2
    80002948:	00006717          	auipc	a4,0x6
    8000294c:	ad070713          	addi	a4,a4,-1328 # 80008418 <states.0+0x170>
    80002950:	94ba                	add	s1,s1,a4
    80002952:	409c                	lw	a5,0(s1)
    80002954:	97ba                	add	a5,a5,a4
    80002956:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002958:	6d3c                	ld	a5,88(a0)
    8000295a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000295c:	60e2                	ld	ra,24(sp)
    8000295e:	6442                	ld	s0,16(sp)
    80002960:	64a2                	ld	s1,8(sp)
    80002962:	6105                	addi	sp,sp,32
    80002964:	8082                	ret
    return p->trapframe->a1;
    80002966:	6d3c                	ld	a5,88(a0)
    80002968:	7fa8                	ld	a0,120(a5)
    8000296a:	bfcd                	j	8000295c <argraw+0x30>
    return p->trapframe->a2;
    8000296c:	6d3c                	ld	a5,88(a0)
    8000296e:	63c8                	ld	a0,128(a5)
    80002970:	b7f5                	j	8000295c <argraw+0x30>
    return p->trapframe->a3;
    80002972:	6d3c                	ld	a5,88(a0)
    80002974:	67c8                	ld	a0,136(a5)
    80002976:	b7dd                	j	8000295c <argraw+0x30>
    return p->trapframe->a4;
    80002978:	6d3c                	ld	a5,88(a0)
    8000297a:	6bc8                	ld	a0,144(a5)
    8000297c:	b7c5                	j	8000295c <argraw+0x30>
    return p->trapframe->a5;
    8000297e:	6d3c                	ld	a5,88(a0)
    80002980:	6fc8                	ld	a0,152(a5)
    80002982:	bfe9                	j	8000295c <argraw+0x30>
  panic("argraw");
    80002984:	00006517          	auipc	a0,0x6
    80002988:	a6c50513          	addi	a0,a0,-1428 # 800083f0 <states.0+0x148>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	b9e080e7          	jalr	-1122(ra) # 8000052a <panic>

0000000080002994 <fetchaddr>:
{
    80002994:	1101                	addi	sp,sp,-32
    80002996:	ec06                	sd	ra,24(sp)
    80002998:	e822                	sd	s0,16(sp)
    8000299a:	e426                	sd	s1,8(sp)
    8000299c:	e04a                	sd	s2,0(sp)
    8000299e:	1000                	addi	s0,sp,32
    800029a0:	84aa                	mv	s1,a0
    800029a2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029a4:	fffff097          	auipc	ra,0xfffff
    800029a8:	fda080e7          	jalr	-38(ra) # 8000197e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029ac:	653c                	ld	a5,72(a0)
    800029ae:	02f4f863          	bgeu	s1,a5,800029de <fetchaddr+0x4a>
    800029b2:	00848713          	addi	a4,s1,8
    800029b6:	02e7e663          	bltu	a5,a4,800029e2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029ba:	46a1                	li	a3,8
    800029bc:	8626                	mv	a2,s1
    800029be:	85ca                	mv	a1,s2
    800029c0:	6928                	ld	a0,80(a0)
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	d08080e7          	jalr	-760(ra) # 800016ca <copyin>
    800029ca:	00a03533          	snez	a0,a0
    800029ce:	40a00533          	neg	a0,a0
}
    800029d2:	60e2                	ld	ra,24(sp)
    800029d4:	6442                	ld	s0,16(sp)
    800029d6:	64a2                	ld	s1,8(sp)
    800029d8:	6902                	ld	s2,0(sp)
    800029da:	6105                	addi	sp,sp,32
    800029dc:	8082                	ret
    return -1;
    800029de:	557d                	li	a0,-1
    800029e0:	bfcd                	j	800029d2 <fetchaddr+0x3e>
    800029e2:	557d                	li	a0,-1
    800029e4:	b7fd                	j	800029d2 <fetchaddr+0x3e>

00000000800029e6 <fetchstr>:
{
    800029e6:	7179                	addi	sp,sp,-48
    800029e8:	f406                	sd	ra,40(sp)
    800029ea:	f022                	sd	s0,32(sp)
    800029ec:	ec26                	sd	s1,24(sp)
    800029ee:	e84a                	sd	s2,16(sp)
    800029f0:	e44e                	sd	s3,8(sp)
    800029f2:	1800                	addi	s0,sp,48
    800029f4:	892a                	mv	s2,a0
    800029f6:	84ae                	mv	s1,a1
    800029f8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800029fa:	fffff097          	auipc	ra,0xfffff
    800029fe:	f84080e7          	jalr	-124(ra) # 8000197e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a02:	86ce                	mv	a3,s3
    80002a04:	864a                	mv	a2,s2
    80002a06:	85a6                	mv	a1,s1
    80002a08:	6928                	ld	a0,80(a0)
    80002a0a:	fffff097          	auipc	ra,0xfffff
    80002a0e:	d4e080e7          	jalr	-690(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002a12:	00054763          	bltz	a0,80002a20 <fetchstr+0x3a>
  return strlen(buf);
    80002a16:	8526                	mv	a0,s1
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	42a080e7          	jalr	1066(ra) # 80000e42 <strlen>
}
    80002a20:	70a2                	ld	ra,40(sp)
    80002a22:	7402                	ld	s0,32(sp)
    80002a24:	64e2                	ld	s1,24(sp)
    80002a26:	6942                	ld	s2,16(sp)
    80002a28:	69a2                	ld	s3,8(sp)
    80002a2a:	6145                	addi	sp,sp,48
    80002a2c:	8082                	ret

0000000080002a2e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a2e:	1101                	addi	sp,sp,-32
    80002a30:	ec06                	sd	ra,24(sp)
    80002a32:	e822                	sd	s0,16(sp)
    80002a34:	e426                	sd	s1,8(sp)
    80002a36:	1000                	addi	s0,sp,32
    80002a38:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	ef2080e7          	jalr	-270(ra) # 8000292c <argraw>
    80002a42:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a44:	4501                	li	a0,0
    80002a46:	60e2                	ld	ra,24(sp)
    80002a48:	6442                	ld	s0,16(sp)
    80002a4a:	64a2                	ld	s1,8(sp)
    80002a4c:	6105                	addi	sp,sp,32
    80002a4e:	8082                	ret

0000000080002a50 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a50:	1101                	addi	sp,sp,-32
    80002a52:	ec06                	sd	ra,24(sp)
    80002a54:	e822                	sd	s0,16(sp)
    80002a56:	e426                	sd	s1,8(sp)
    80002a58:	1000                	addi	s0,sp,32
    80002a5a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a5c:	00000097          	auipc	ra,0x0
    80002a60:	ed0080e7          	jalr	-304(ra) # 8000292c <argraw>
    80002a64:	e088                	sd	a0,0(s1)
  return 0;
}
    80002a66:	4501                	li	a0,0
    80002a68:	60e2                	ld	ra,24(sp)
    80002a6a:	6442                	ld	s0,16(sp)
    80002a6c:	64a2                	ld	s1,8(sp)
    80002a6e:	6105                	addi	sp,sp,32
    80002a70:	8082                	ret

0000000080002a72 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002a72:	1101                	addi	sp,sp,-32
    80002a74:	ec06                	sd	ra,24(sp)
    80002a76:	e822                	sd	s0,16(sp)
    80002a78:	e426                	sd	s1,8(sp)
    80002a7a:	e04a                	sd	s2,0(sp)
    80002a7c:	1000                	addi	s0,sp,32
    80002a7e:	84ae                	mv	s1,a1
    80002a80:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	eaa080e7          	jalr	-342(ra) # 8000292c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002a8a:	864a                	mv	a2,s2
    80002a8c:	85a6                	mv	a1,s1
    80002a8e:	00000097          	auipc	ra,0x0
    80002a92:	f58080e7          	jalr	-168(ra) # 800029e6 <fetchstr>
}
    80002a96:	60e2                	ld	ra,24(sp)
    80002a98:	6442                	ld	s0,16(sp)
    80002a9a:	64a2                	ld	s1,8(sp)
    80002a9c:	6902                	ld	s2,0(sp)
    80002a9e:	6105                	addi	sp,sp,32
    80002aa0:	8082                	ret

0000000080002aa2 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002aa2:	1101                	addi	sp,sp,-32
    80002aa4:	ec06                	sd	ra,24(sp)
    80002aa6:	e822                	sd	s0,16(sp)
    80002aa8:	e426                	sd	s1,8(sp)
    80002aaa:	e04a                	sd	s2,0(sp)
    80002aac:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	ed0080e7          	jalr	-304(ra) # 8000197e <myproc>
    80002ab6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ab8:	05853903          	ld	s2,88(a0)
    80002abc:	0a893783          	ld	a5,168(s2)
    80002ac0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ac4:	37fd                	addiw	a5,a5,-1
    80002ac6:	4751                	li	a4,20
    80002ac8:	00f76f63          	bltu	a4,a5,80002ae6 <syscall+0x44>
    80002acc:	00369713          	slli	a4,a3,0x3
    80002ad0:	00006797          	auipc	a5,0x6
    80002ad4:	96078793          	addi	a5,a5,-1696 # 80008430 <syscalls>
    80002ad8:	97ba                	add	a5,a5,a4
    80002ada:	639c                	ld	a5,0(a5)
    80002adc:	c789                	beqz	a5,80002ae6 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ade:	9782                	jalr	a5
    80002ae0:	06a93823          	sd	a0,112(s2)
    80002ae4:	a839                	j	80002b02 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ae6:	15848613          	addi	a2,s1,344
    80002aea:	588c                	lw	a1,48(s1)
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	90c50513          	addi	a0,a0,-1780 # 800083f8 <states.0+0x150>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a80080e7          	jalr	-1408(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002afc:	6cbc                	ld	a5,88(s1)
    80002afe:	577d                	li	a4,-1
    80002b00:	fbb8                	sd	a4,112(a5)
  }
}
    80002b02:	60e2                	ld	ra,24(sp)
    80002b04:	6442                	ld	s0,16(sp)
    80002b06:	64a2                	ld	s1,8(sp)
    80002b08:	6902                	ld	s2,0(sp)
    80002b0a:	6105                	addi	sp,sp,32
    80002b0c:	8082                	ret

0000000080002b0e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b0e:	1101                	addi	sp,sp,-32
    80002b10:	ec06                	sd	ra,24(sp)
    80002b12:	e822                	sd	s0,16(sp)
    80002b14:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b16:	fec40593          	addi	a1,s0,-20
    80002b1a:	4501                	li	a0,0
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	f12080e7          	jalr	-238(ra) # 80002a2e <argint>
    return -1;
    80002b24:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b26:	00054963          	bltz	a0,80002b38 <sys_exit+0x2a>
  exit(n);
    80002b2a:	fec42503          	lw	a0,-20(s0)
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	76c080e7          	jalr	1900(ra) # 8000229a <exit>
  return 0;  // not reached
    80002b36:	4781                	li	a5,0
}
    80002b38:	853e                	mv	a0,a5
    80002b3a:	60e2                	ld	ra,24(sp)
    80002b3c:	6442                	ld	s0,16(sp)
    80002b3e:	6105                	addi	sp,sp,32
    80002b40:	8082                	ret

0000000080002b42 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b42:	1141                	addi	sp,sp,-16
    80002b44:	e406                	sd	ra,8(sp)
    80002b46:	e022                	sd	s0,0(sp)
    80002b48:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	e34080e7          	jalr	-460(ra) # 8000197e <myproc>
}
    80002b52:	5908                	lw	a0,48(a0)
    80002b54:	60a2                	ld	ra,8(sp)
    80002b56:	6402                	ld	s0,0(sp)
    80002b58:	0141                	addi	sp,sp,16
    80002b5a:	8082                	ret

0000000080002b5c <sys_fork>:

uint64
sys_fork(void)
{
    80002b5c:	1141                	addi	sp,sp,-16
    80002b5e:	e406                	sd	ra,8(sp)
    80002b60:	e022                	sd	s0,0(sp)
    80002b62:	0800                	addi	s0,sp,16
  return fork();
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	1e8080e7          	jalr	488(ra) # 80001d4c <fork>
}
    80002b6c:	60a2                	ld	ra,8(sp)
    80002b6e:	6402                	ld	s0,0(sp)
    80002b70:	0141                	addi	sp,sp,16
    80002b72:	8082                	ret

0000000080002b74 <sys_wait>:

uint64
sys_wait(void)
{
    80002b74:	1101                	addi	sp,sp,-32
    80002b76:	ec06                	sd	ra,24(sp)
    80002b78:	e822                	sd	s0,16(sp)
    80002b7a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002b7c:	fe840593          	addi	a1,s0,-24
    80002b80:	4501                	li	a0,0
    80002b82:	00000097          	auipc	ra,0x0
    80002b86:	ece080e7          	jalr	-306(ra) # 80002a50 <argaddr>
    80002b8a:	87aa                	mv	a5,a0
    return -1;
    80002b8c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002b8e:	0007c863          	bltz	a5,80002b9e <sys_wait+0x2a>
  return wait(p);
    80002b92:	fe843503          	ld	a0,-24(s0)
    80002b96:	fffff097          	auipc	ra,0xfffff
    80002b9a:	50c080e7          	jalr	1292(ra) # 800020a2 <wait>
}
    80002b9e:	60e2                	ld	ra,24(sp)
    80002ba0:	6442                	ld	s0,16(sp)
    80002ba2:	6105                	addi	sp,sp,32
    80002ba4:	8082                	ret

0000000080002ba6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ba6:	7179                	addi	sp,sp,-48
    80002ba8:	f406                	sd	ra,40(sp)
    80002baa:	f022                	sd	s0,32(sp)
    80002bac:	ec26                	sd	s1,24(sp)
    80002bae:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bb0:	fdc40593          	addi	a1,s0,-36
    80002bb4:	4501                	li	a0,0
    80002bb6:	00000097          	auipc	ra,0x0
    80002bba:	e78080e7          	jalr	-392(ra) # 80002a2e <argint>
    return -1;
    80002bbe:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002bc0:	00054f63          	bltz	a0,80002bde <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002bc4:	fffff097          	auipc	ra,0xfffff
    80002bc8:	dba080e7          	jalr	-582(ra) # 8000197e <myproc>
    80002bcc:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002bce:	fdc42503          	lw	a0,-36(s0)
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	106080e7          	jalr	262(ra) # 80001cd8 <growproc>
    80002bda:	00054863          	bltz	a0,80002bea <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002bde:	8526                	mv	a0,s1
    80002be0:	70a2                	ld	ra,40(sp)
    80002be2:	7402                	ld	s0,32(sp)
    80002be4:	64e2                	ld	s1,24(sp)
    80002be6:	6145                	addi	sp,sp,48
    80002be8:	8082                	ret
    return -1;
    80002bea:	54fd                	li	s1,-1
    80002bec:	bfcd                	j	80002bde <sys_sbrk+0x38>

0000000080002bee <sys_sleep>:

uint64
sys_sleep(void)
{
    80002bee:	7139                	addi	sp,sp,-64
    80002bf0:	fc06                	sd	ra,56(sp)
    80002bf2:	f822                	sd	s0,48(sp)
    80002bf4:	f426                	sd	s1,40(sp)
    80002bf6:	f04a                	sd	s2,32(sp)
    80002bf8:	ec4e                	sd	s3,24(sp)
    80002bfa:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002bfc:	fcc40593          	addi	a1,s0,-52
    80002c00:	4501                	li	a0,0
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	e2c080e7          	jalr	-468(ra) # 80002a2e <argint>
    return -1;
    80002c0a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c0c:	06054563          	bltz	a0,80002c76 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c10:	00014517          	auipc	a0,0x14
    80002c14:	4c050513          	addi	a0,a0,1216 # 800170d0 <tickslock>
    80002c18:	ffffe097          	auipc	ra,0xffffe
    80002c1c:	faa080e7          	jalr	-86(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002c20:	00006917          	auipc	s2,0x6
    80002c24:	41092903          	lw	s2,1040(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c28:	fcc42783          	lw	a5,-52(s0)
    80002c2c:	cf85                	beqz	a5,80002c64 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c2e:	00014997          	auipc	s3,0x14
    80002c32:	4a298993          	addi	s3,s3,1186 # 800170d0 <tickslock>
    80002c36:	00006497          	auipc	s1,0x6
    80002c3a:	3fa48493          	addi	s1,s1,1018 # 80009030 <ticks>
    if(myproc()->killed){
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	d40080e7          	jalr	-704(ra) # 8000197e <myproc>
    80002c46:	551c                	lw	a5,40(a0)
    80002c48:	ef9d                	bnez	a5,80002c86 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c4a:	85ce                	mv	a1,s3
    80002c4c:	8526                	mv	a0,s1
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	3f0080e7          	jalr	1008(ra) # 8000203e <sleep>
  while(ticks - ticks0 < n){
    80002c56:	409c                	lw	a5,0(s1)
    80002c58:	412787bb          	subw	a5,a5,s2
    80002c5c:	fcc42703          	lw	a4,-52(s0)
    80002c60:	fce7efe3          	bltu	a5,a4,80002c3e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002c64:	00014517          	auipc	a0,0x14
    80002c68:	46c50513          	addi	a0,a0,1132 # 800170d0 <tickslock>
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	00a080e7          	jalr	10(ra) # 80000c76 <release>
  return 0;
    80002c74:	4781                	li	a5,0
}
    80002c76:	853e                	mv	a0,a5
    80002c78:	70e2                	ld	ra,56(sp)
    80002c7a:	7442                	ld	s0,48(sp)
    80002c7c:	74a2                	ld	s1,40(sp)
    80002c7e:	7902                	ld	s2,32(sp)
    80002c80:	69e2                	ld	s3,24(sp)
    80002c82:	6121                	addi	sp,sp,64
    80002c84:	8082                	ret
      release(&tickslock);
    80002c86:	00014517          	auipc	a0,0x14
    80002c8a:	44a50513          	addi	a0,a0,1098 # 800170d0 <tickslock>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	fe8080e7          	jalr	-24(ra) # 80000c76 <release>
      return -1;
    80002c96:	57fd                	li	a5,-1
    80002c98:	bff9                	j	80002c76 <sys_sleep+0x88>

0000000080002c9a <sys_kill>:

uint64
sys_kill(void)
{
    80002c9a:	1101                	addi	sp,sp,-32
    80002c9c:	ec06                	sd	ra,24(sp)
    80002c9e:	e822                	sd	s0,16(sp)
    80002ca0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ca2:	fec40593          	addi	a1,s0,-20
    80002ca6:	4501                	li	a0,0
    80002ca8:	00000097          	auipc	ra,0x0
    80002cac:	d86080e7          	jalr	-634(ra) # 80002a2e <argint>
    80002cb0:	87aa                	mv	a5,a0
    return -1;
    80002cb2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002cb4:	0007c863          	bltz	a5,80002cc4 <sys_kill+0x2a>
  return kill(pid);
    80002cb8:	fec42503          	lw	a0,-20(s0)
    80002cbc:	fffff097          	auipc	ra,0xfffff
    80002cc0:	6b4080e7          	jalr	1716(ra) # 80002370 <kill>
}
    80002cc4:	60e2                	ld	ra,24(sp)
    80002cc6:	6442                	ld	s0,16(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret

0000000080002ccc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ccc:	1101                	addi	sp,sp,-32
    80002cce:	ec06                	sd	ra,24(sp)
    80002cd0:	e822                	sd	s0,16(sp)
    80002cd2:	e426                	sd	s1,8(sp)
    80002cd4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002cd6:	00014517          	auipc	a0,0x14
    80002cda:	3fa50513          	addi	a0,a0,1018 # 800170d0 <tickslock>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	ee4080e7          	jalr	-284(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002ce6:	00006497          	auipc	s1,0x6
    80002cea:	34a4a483          	lw	s1,842(s1) # 80009030 <ticks>
  release(&tickslock);
    80002cee:	00014517          	auipc	a0,0x14
    80002cf2:	3e250513          	addi	a0,a0,994 # 800170d0 <tickslock>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	f80080e7          	jalr	-128(ra) # 80000c76 <release>
  return xticks;
}
    80002cfe:	02049513          	slli	a0,s1,0x20
    80002d02:	9101                	srli	a0,a0,0x20
    80002d04:	60e2                	ld	ra,24(sp)
    80002d06:	6442                	ld	s0,16(sp)
    80002d08:	64a2                	ld	s1,8(sp)
    80002d0a:	6105                	addi	sp,sp,32
    80002d0c:	8082                	ret

0000000080002d0e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d0e:	7179                	addi	sp,sp,-48
    80002d10:	f406                	sd	ra,40(sp)
    80002d12:	f022                	sd	s0,32(sp)
    80002d14:	ec26                	sd	s1,24(sp)
    80002d16:	e84a                	sd	s2,16(sp)
    80002d18:	e44e                	sd	s3,8(sp)
    80002d1a:	e052                	sd	s4,0(sp)
    80002d1c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d1e:	00005597          	auipc	a1,0x5
    80002d22:	7c258593          	addi	a1,a1,1986 # 800084e0 <syscalls+0xb0>
    80002d26:	00014517          	auipc	a0,0x14
    80002d2a:	3c250513          	addi	a0,a0,962 # 800170e8 <bcache>
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	e04080e7          	jalr	-508(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d36:	0001c797          	auipc	a5,0x1c
    80002d3a:	3b278793          	addi	a5,a5,946 # 8001f0e8 <bcache+0x8000>
    80002d3e:	0001c717          	auipc	a4,0x1c
    80002d42:	61270713          	addi	a4,a4,1554 # 8001f350 <bcache+0x8268>
    80002d46:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d4a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d4e:	00014497          	auipc	s1,0x14
    80002d52:	3b248493          	addi	s1,s1,946 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002d56:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002d58:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002d5a:	00005a17          	auipc	s4,0x5
    80002d5e:	78ea0a13          	addi	s4,s4,1934 # 800084e8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002d62:	2b893783          	ld	a5,696(s2)
    80002d66:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002d68:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002d6c:	85d2                	mv	a1,s4
    80002d6e:	01048513          	addi	a0,s1,16
    80002d72:	00001097          	auipc	ra,0x1
    80002d76:	4bc080e7          	jalr	1212(ra) # 8000422e <initsleeplock>
    bcache.head.next->prev = b;
    80002d7a:	2b893783          	ld	a5,696(s2)
    80002d7e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002d80:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d84:	45848493          	addi	s1,s1,1112
    80002d88:	fd349de3          	bne	s1,s3,80002d62 <binit+0x54>
  }
}
    80002d8c:	70a2                	ld	ra,40(sp)
    80002d8e:	7402                	ld	s0,32(sp)
    80002d90:	64e2                	ld	s1,24(sp)
    80002d92:	6942                	ld	s2,16(sp)
    80002d94:	69a2                	ld	s3,8(sp)
    80002d96:	6a02                	ld	s4,0(sp)
    80002d98:	6145                	addi	sp,sp,48
    80002d9a:	8082                	ret

0000000080002d9c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002d9c:	7179                	addi	sp,sp,-48
    80002d9e:	f406                	sd	ra,40(sp)
    80002da0:	f022                	sd	s0,32(sp)
    80002da2:	ec26                	sd	s1,24(sp)
    80002da4:	e84a                	sd	s2,16(sp)
    80002da6:	e44e                	sd	s3,8(sp)
    80002da8:	1800                	addi	s0,sp,48
    80002daa:	892a                	mv	s2,a0
    80002dac:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002dae:	00014517          	auipc	a0,0x14
    80002db2:	33a50513          	addi	a0,a0,826 # 800170e8 <bcache>
    80002db6:	ffffe097          	auipc	ra,0xffffe
    80002dba:	e0c080e7          	jalr	-500(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002dbe:	0001c497          	auipc	s1,0x1c
    80002dc2:	5e24b483          	ld	s1,1506(s1) # 8001f3a0 <bcache+0x82b8>
    80002dc6:	0001c797          	auipc	a5,0x1c
    80002dca:	58a78793          	addi	a5,a5,1418 # 8001f350 <bcache+0x8268>
    80002dce:	02f48f63          	beq	s1,a5,80002e0c <bread+0x70>
    80002dd2:	873e                	mv	a4,a5
    80002dd4:	a021                	j	80002ddc <bread+0x40>
    80002dd6:	68a4                	ld	s1,80(s1)
    80002dd8:	02e48a63          	beq	s1,a4,80002e0c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ddc:	449c                	lw	a5,8(s1)
    80002dde:	ff279ce3          	bne	a5,s2,80002dd6 <bread+0x3a>
    80002de2:	44dc                	lw	a5,12(s1)
    80002de4:	ff3799e3          	bne	a5,s3,80002dd6 <bread+0x3a>
      b->refcnt++;
    80002de8:	40bc                	lw	a5,64(s1)
    80002dea:	2785                	addiw	a5,a5,1
    80002dec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002dee:	00014517          	auipc	a0,0x14
    80002df2:	2fa50513          	addi	a0,a0,762 # 800170e8 <bcache>
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	e80080e7          	jalr	-384(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002dfe:	01048513          	addi	a0,s1,16
    80002e02:	00001097          	auipc	ra,0x1
    80002e06:	466080e7          	jalr	1126(ra) # 80004268 <acquiresleep>
      return b;
    80002e0a:	a8b9                	j	80002e68 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e0c:	0001c497          	auipc	s1,0x1c
    80002e10:	58c4b483          	ld	s1,1420(s1) # 8001f398 <bcache+0x82b0>
    80002e14:	0001c797          	auipc	a5,0x1c
    80002e18:	53c78793          	addi	a5,a5,1340 # 8001f350 <bcache+0x8268>
    80002e1c:	00f48863          	beq	s1,a5,80002e2c <bread+0x90>
    80002e20:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e22:	40bc                	lw	a5,64(s1)
    80002e24:	cf81                	beqz	a5,80002e3c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e26:	64a4                	ld	s1,72(s1)
    80002e28:	fee49de3          	bne	s1,a4,80002e22 <bread+0x86>
  panic("bget: no buffers");
    80002e2c:	00005517          	auipc	a0,0x5
    80002e30:	6c450513          	addi	a0,a0,1732 # 800084f0 <syscalls+0xc0>
    80002e34:	ffffd097          	auipc	ra,0xffffd
    80002e38:	6f6080e7          	jalr	1782(ra) # 8000052a <panic>
      b->dev = dev;
    80002e3c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002e40:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002e44:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e48:	4785                	li	a5,1
    80002e4a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e4c:	00014517          	auipc	a0,0x14
    80002e50:	29c50513          	addi	a0,a0,668 # 800170e8 <bcache>
    80002e54:	ffffe097          	auipc	ra,0xffffe
    80002e58:	e22080e7          	jalr	-478(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002e5c:	01048513          	addi	a0,s1,16
    80002e60:	00001097          	auipc	ra,0x1
    80002e64:	408080e7          	jalr	1032(ra) # 80004268 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002e68:	409c                	lw	a5,0(s1)
    80002e6a:	cb89                	beqz	a5,80002e7c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002e6c:	8526                	mv	a0,s1
    80002e6e:	70a2                	ld	ra,40(sp)
    80002e70:	7402                	ld	s0,32(sp)
    80002e72:	64e2                	ld	s1,24(sp)
    80002e74:	6942                	ld	s2,16(sp)
    80002e76:	69a2                	ld	s3,8(sp)
    80002e78:	6145                	addi	sp,sp,48
    80002e7a:	8082                	ret
    virtio_disk_rw(b, 0);
    80002e7c:	4581                	li	a1,0
    80002e7e:	8526                	mv	a0,s1
    80002e80:	00003097          	auipc	ra,0x3
    80002e84:	f16080e7          	jalr	-234(ra) # 80005d96 <virtio_disk_rw>
    b->valid = 1;
    80002e88:	4785                	li	a5,1
    80002e8a:	c09c                	sw	a5,0(s1)
  return b;
    80002e8c:	b7c5                	j	80002e6c <bread+0xd0>

0000000080002e8e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002e8e:	1101                	addi	sp,sp,-32
    80002e90:	ec06                	sd	ra,24(sp)
    80002e92:	e822                	sd	s0,16(sp)
    80002e94:	e426                	sd	s1,8(sp)
    80002e96:	1000                	addi	s0,sp,32
    80002e98:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002e9a:	0541                	addi	a0,a0,16
    80002e9c:	00001097          	auipc	ra,0x1
    80002ea0:	466080e7          	jalr	1126(ra) # 80004302 <holdingsleep>
    80002ea4:	cd01                	beqz	a0,80002ebc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ea6:	4585                	li	a1,1
    80002ea8:	8526                	mv	a0,s1
    80002eaa:	00003097          	auipc	ra,0x3
    80002eae:	eec080e7          	jalr	-276(ra) # 80005d96 <virtio_disk_rw>
}
    80002eb2:	60e2                	ld	ra,24(sp)
    80002eb4:	6442                	ld	s0,16(sp)
    80002eb6:	64a2                	ld	s1,8(sp)
    80002eb8:	6105                	addi	sp,sp,32
    80002eba:	8082                	ret
    panic("bwrite");
    80002ebc:	00005517          	auipc	a0,0x5
    80002ec0:	64c50513          	addi	a0,a0,1612 # 80008508 <syscalls+0xd8>
    80002ec4:	ffffd097          	auipc	ra,0xffffd
    80002ec8:	666080e7          	jalr	1638(ra) # 8000052a <panic>

0000000080002ecc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002ecc:	1101                	addi	sp,sp,-32
    80002ece:	ec06                	sd	ra,24(sp)
    80002ed0:	e822                	sd	s0,16(sp)
    80002ed2:	e426                	sd	s1,8(sp)
    80002ed4:	e04a                	sd	s2,0(sp)
    80002ed6:	1000                	addi	s0,sp,32
    80002ed8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002eda:	01050913          	addi	s2,a0,16
    80002ede:	854a                	mv	a0,s2
    80002ee0:	00001097          	auipc	ra,0x1
    80002ee4:	422080e7          	jalr	1058(ra) # 80004302 <holdingsleep>
    80002ee8:	c92d                	beqz	a0,80002f5a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002eea:	854a                	mv	a0,s2
    80002eec:	00001097          	auipc	ra,0x1
    80002ef0:	3d2080e7          	jalr	978(ra) # 800042be <releasesleep>

  acquire(&bcache.lock);
    80002ef4:	00014517          	auipc	a0,0x14
    80002ef8:	1f450513          	addi	a0,a0,500 # 800170e8 <bcache>
    80002efc:	ffffe097          	auipc	ra,0xffffe
    80002f00:	cc6080e7          	jalr	-826(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80002f04:	40bc                	lw	a5,64(s1)
    80002f06:	37fd                	addiw	a5,a5,-1
    80002f08:	0007871b          	sext.w	a4,a5
    80002f0c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f0e:	eb05                	bnez	a4,80002f3e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f10:	68bc                	ld	a5,80(s1)
    80002f12:	64b8                	ld	a4,72(s1)
    80002f14:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f16:	64bc                	ld	a5,72(s1)
    80002f18:	68b8                	ld	a4,80(s1)
    80002f1a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f1c:	0001c797          	auipc	a5,0x1c
    80002f20:	1cc78793          	addi	a5,a5,460 # 8001f0e8 <bcache+0x8000>
    80002f24:	2b87b703          	ld	a4,696(a5)
    80002f28:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f2a:	0001c717          	auipc	a4,0x1c
    80002f2e:	42670713          	addi	a4,a4,1062 # 8001f350 <bcache+0x8268>
    80002f32:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f34:	2b87b703          	ld	a4,696(a5)
    80002f38:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f3a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f3e:	00014517          	auipc	a0,0x14
    80002f42:	1aa50513          	addi	a0,a0,426 # 800170e8 <bcache>
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	d30080e7          	jalr	-720(ra) # 80000c76 <release>
}
    80002f4e:	60e2                	ld	ra,24(sp)
    80002f50:	6442                	ld	s0,16(sp)
    80002f52:	64a2                	ld	s1,8(sp)
    80002f54:	6902                	ld	s2,0(sp)
    80002f56:	6105                	addi	sp,sp,32
    80002f58:	8082                	ret
    panic("brelse");
    80002f5a:	00005517          	auipc	a0,0x5
    80002f5e:	5b650513          	addi	a0,a0,1462 # 80008510 <syscalls+0xe0>
    80002f62:	ffffd097          	auipc	ra,0xffffd
    80002f66:	5c8080e7          	jalr	1480(ra) # 8000052a <panic>

0000000080002f6a <bpin>:

void
bpin(struct buf *b) {
    80002f6a:	1101                	addi	sp,sp,-32
    80002f6c:	ec06                	sd	ra,24(sp)
    80002f6e:	e822                	sd	s0,16(sp)
    80002f70:	e426                	sd	s1,8(sp)
    80002f72:	1000                	addi	s0,sp,32
    80002f74:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002f76:	00014517          	auipc	a0,0x14
    80002f7a:	17250513          	addi	a0,a0,370 # 800170e8 <bcache>
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	c44080e7          	jalr	-956(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80002f86:	40bc                	lw	a5,64(s1)
    80002f88:	2785                	addiw	a5,a5,1
    80002f8a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002f8c:	00014517          	auipc	a0,0x14
    80002f90:	15c50513          	addi	a0,a0,348 # 800170e8 <bcache>
    80002f94:	ffffe097          	auipc	ra,0xffffe
    80002f98:	ce2080e7          	jalr	-798(ra) # 80000c76 <release>
}
    80002f9c:	60e2                	ld	ra,24(sp)
    80002f9e:	6442                	ld	s0,16(sp)
    80002fa0:	64a2                	ld	s1,8(sp)
    80002fa2:	6105                	addi	sp,sp,32
    80002fa4:	8082                	ret

0000000080002fa6 <bunpin>:

void
bunpin(struct buf *b) {
    80002fa6:	1101                	addi	sp,sp,-32
    80002fa8:	ec06                	sd	ra,24(sp)
    80002faa:	e822                	sd	s0,16(sp)
    80002fac:	e426                	sd	s1,8(sp)
    80002fae:	1000                	addi	s0,sp,32
    80002fb0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fb2:	00014517          	auipc	a0,0x14
    80002fb6:	13650513          	addi	a0,a0,310 # 800170e8 <bcache>
    80002fba:	ffffe097          	auipc	ra,0xffffe
    80002fbe:	c08080e7          	jalr	-1016(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80002fc2:	40bc                	lw	a5,64(s1)
    80002fc4:	37fd                	addiw	a5,a5,-1
    80002fc6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fc8:	00014517          	auipc	a0,0x14
    80002fcc:	12050513          	addi	a0,a0,288 # 800170e8 <bcache>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	ca6080e7          	jalr	-858(ra) # 80000c76 <release>
}
    80002fd8:	60e2                	ld	ra,24(sp)
    80002fda:	6442                	ld	s0,16(sp)
    80002fdc:	64a2                	ld	s1,8(sp)
    80002fde:	6105                	addi	sp,sp,32
    80002fe0:	8082                	ret

0000000080002fe2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002fe2:	1101                	addi	sp,sp,-32
    80002fe4:	ec06                	sd	ra,24(sp)
    80002fe6:	e822                	sd	s0,16(sp)
    80002fe8:	e426                	sd	s1,8(sp)
    80002fea:	e04a                	sd	s2,0(sp)
    80002fec:	1000                	addi	s0,sp,32
    80002fee:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002ff0:	00d5d59b          	srliw	a1,a1,0xd
    80002ff4:	0001c797          	auipc	a5,0x1c
    80002ff8:	7d07a783          	lw	a5,2000(a5) # 8001f7c4 <sb+0x1c>
    80002ffc:	9dbd                	addw	a1,a1,a5
    80002ffe:	00000097          	auipc	ra,0x0
    80003002:	d9e080e7          	jalr	-610(ra) # 80002d9c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003006:	0074f713          	andi	a4,s1,7
    8000300a:	4785                	li	a5,1
    8000300c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003010:	14ce                	slli	s1,s1,0x33
    80003012:	90d9                	srli	s1,s1,0x36
    80003014:	00950733          	add	a4,a0,s1
    80003018:	05874703          	lbu	a4,88(a4)
    8000301c:	00e7f6b3          	and	a3,a5,a4
    80003020:	c69d                	beqz	a3,8000304e <bfree+0x6c>
    80003022:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003024:	94aa                	add	s1,s1,a0
    80003026:	fff7c793          	not	a5,a5
    8000302a:	8ff9                	and	a5,a5,a4
    8000302c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003030:	00001097          	auipc	ra,0x1
    80003034:	118080e7          	jalr	280(ra) # 80004148 <log_write>
  brelse(bp);
    80003038:	854a                	mv	a0,s2
    8000303a:	00000097          	auipc	ra,0x0
    8000303e:	e92080e7          	jalr	-366(ra) # 80002ecc <brelse>
}
    80003042:	60e2                	ld	ra,24(sp)
    80003044:	6442                	ld	s0,16(sp)
    80003046:	64a2                	ld	s1,8(sp)
    80003048:	6902                	ld	s2,0(sp)
    8000304a:	6105                	addi	sp,sp,32
    8000304c:	8082                	ret
    panic("freeing free block");
    8000304e:	00005517          	auipc	a0,0x5
    80003052:	4ca50513          	addi	a0,a0,1226 # 80008518 <syscalls+0xe8>
    80003056:	ffffd097          	auipc	ra,0xffffd
    8000305a:	4d4080e7          	jalr	1236(ra) # 8000052a <panic>

000000008000305e <balloc>:
{
    8000305e:	711d                	addi	sp,sp,-96
    80003060:	ec86                	sd	ra,88(sp)
    80003062:	e8a2                	sd	s0,80(sp)
    80003064:	e4a6                	sd	s1,72(sp)
    80003066:	e0ca                	sd	s2,64(sp)
    80003068:	fc4e                	sd	s3,56(sp)
    8000306a:	f852                	sd	s4,48(sp)
    8000306c:	f456                	sd	s5,40(sp)
    8000306e:	f05a                	sd	s6,32(sp)
    80003070:	ec5e                	sd	s7,24(sp)
    80003072:	e862                	sd	s8,16(sp)
    80003074:	e466                	sd	s9,8(sp)
    80003076:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003078:	0001c797          	auipc	a5,0x1c
    8000307c:	7347a783          	lw	a5,1844(a5) # 8001f7ac <sb+0x4>
    80003080:	cbd1                	beqz	a5,80003114 <balloc+0xb6>
    80003082:	8baa                	mv	s7,a0
    80003084:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003086:	0001cb17          	auipc	s6,0x1c
    8000308a:	722b0b13          	addi	s6,s6,1826 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000308e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003090:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003092:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003094:	6c89                	lui	s9,0x2
    80003096:	a831                	j	800030b2 <balloc+0x54>
    brelse(bp);
    80003098:	854a                	mv	a0,s2
    8000309a:	00000097          	auipc	ra,0x0
    8000309e:	e32080e7          	jalr	-462(ra) # 80002ecc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030a2:	015c87bb          	addw	a5,s9,s5
    800030a6:	00078a9b          	sext.w	s5,a5
    800030aa:	004b2703          	lw	a4,4(s6)
    800030ae:	06eaf363          	bgeu	s5,a4,80003114 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800030b2:	41fad79b          	sraiw	a5,s5,0x1f
    800030b6:	0137d79b          	srliw	a5,a5,0x13
    800030ba:	015787bb          	addw	a5,a5,s5
    800030be:	40d7d79b          	sraiw	a5,a5,0xd
    800030c2:	01cb2583          	lw	a1,28(s6)
    800030c6:	9dbd                	addw	a1,a1,a5
    800030c8:	855e                	mv	a0,s7
    800030ca:	00000097          	auipc	ra,0x0
    800030ce:	cd2080e7          	jalr	-814(ra) # 80002d9c <bread>
    800030d2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030d4:	004b2503          	lw	a0,4(s6)
    800030d8:	000a849b          	sext.w	s1,s5
    800030dc:	8662                	mv	a2,s8
    800030de:	faa4fde3          	bgeu	s1,a0,80003098 <balloc+0x3a>
      m = 1 << (bi % 8);
    800030e2:	41f6579b          	sraiw	a5,a2,0x1f
    800030e6:	01d7d69b          	srliw	a3,a5,0x1d
    800030ea:	00c6873b          	addw	a4,a3,a2
    800030ee:	00777793          	andi	a5,a4,7
    800030f2:	9f95                	subw	a5,a5,a3
    800030f4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800030f8:	4037571b          	sraiw	a4,a4,0x3
    800030fc:	00e906b3          	add	a3,s2,a4
    80003100:	0586c683          	lbu	a3,88(a3)
    80003104:	00d7f5b3          	and	a1,a5,a3
    80003108:	cd91                	beqz	a1,80003124 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000310a:	2605                	addiw	a2,a2,1
    8000310c:	2485                	addiw	s1,s1,1
    8000310e:	fd4618e3          	bne	a2,s4,800030de <balloc+0x80>
    80003112:	b759                	j	80003098 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003114:	00005517          	auipc	a0,0x5
    80003118:	41c50513          	addi	a0,a0,1052 # 80008530 <syscalls+0x100>
    8000311c:	ffffd097          	auipc	ra,0xffffd
    80003120:	40e080e7          	jalr	1038(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003124:	974a                	add	a4,a4,s2
    80003126:	8fd5                	or	a5,a5,a3
    80003128:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000312c:	854a                	mv	a0,s2
    8000312e:	00001097          	auipc	ra,0x1
    80003132:	01a080e7          	jalr	26(ra) # 80004148 <log_write>
        brelse(bp);
    80003136:	854a                	mv	a0,s2
    80003138:	00000097          	auipc	ra,0x0
    8000313c:	d94080e7          	jalr	-620(ra) # 80002ecc <brelse>
  bp = bread(dev, bno);
    80003140:	85a6                	mv	a1,s1
    80003142:	855e                	mv	a0,s7
    80003144:	00000097          	auipc	ra,0x0
    80003148:	c58080e7          	jalr	-936(ra) # 80002d9c <bread>
    8000314c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000314e:	40000613          	li	a2,1024
    80003152:	4581                	li	a1,0
    80003154:	05850513          	addi	a0,a0,88
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	b66080e7          	jalr	-1178(ra) # 80000cbe <memset>
  log_write(bp);
    80003160:	854a                	mv	a0,s2
    80003162:	00001097          	auipc	ra,0x1
    80003166:	fe6080e7          	jalr	-26(ra) # 80004148 <log_write>
  brelse(bp);
    8000316a:	854a                	mv	a0,s2
    8000316c:	00000097          	auipc	ra,0x0
    80003170:	d60080e7          	jalr	-672(ra) # 80002ecc <brelse>
}
    80003174:	8526                	mv	a0,s1
    80003176:	60e6                	ld	ra,88(sp)
    80003178:	6446                	ld	s0,80(sp)
    8000317a:	64a6                	ld	s1,72(sp)
    8000317c:	6906                	ld	s2,64(sp)
    8000317e:	79e2                	ld	s3,56(sp)
    80003180:	7a42                	ld	s4,48(sp)
    80003182:	7aa2                	ld	s5,40(sp)
    80003184:	7b02                	ld	s6,32(sp)
    80003186:	6be2                	ld	s7,24(sp)
    80003188:	6c42                	ld	s8,16(sp)
    8000318a:	6ca2                	ld	s9,8(sp)
    8000318c:	6125                	addi	sp,sp,96
    8000318e:	8082                	ret

0000000080003190 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003190:	7179                	addi	sp,sp,-48
    80003192:	f406                	sd	ra,40(sp)
    80003194:	f022                	sd	s0,32(sp)
    80003196:	ec26                	sd	s1,24(sp)
    80003198:	e84a                	sd	s2,16(sp)
    8000319a:	e44e                	sd	s3,8(sp)
    8000319c:	e052                	sd	s4,0(sp)
    8000319e:	1800                	addi	s0,sp,48
    800031a0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031a2:	47ad                	li	a5,11
    800031a4:	04b7fe63          	bgeu	a5,a1,80003200 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031a8:	ff45849b          	addiw	s1,a1,-12
    800031ac:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800031b0:	0ff00793          	li	a5,255
    800031b4:	0ae7e363          	bltu	a5,a4,8000325a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800031b8:	08052583          	lw	a1,128(a0)
    800031bc:	c5ad                	beqz	a1,80003226 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800031be:	00092503          	lw	a0,0(s2)
    800031c2:	00000097          	auipc	ra,0x0
    800031c6:	bda080e7          	jalr	-1062(ra) # 80002d9c <bread>
    800031ca:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800031cc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800031d0:	02049593          	slli	a1,s1,0x20
    800031d4:	9181                	srli	a1,a1,0x20
    800031d6:	058a                	slli	a1,a1,0x2
    800031d8:	00b784b3          	add	s1,a5,a1
    800031dc:	0004a983          	lw	s3,0(s1)
    800031e0:	04098d63          	beqz	s3,8000323a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800031e4:	8552                	mv	a0,s4
    800031e6:	00000097          	auipc	ra,0x0
    800031ea:	ce6080e7          	jalr	-794(ra) # 80002ecc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800031ee:	854e                	mv	a0,s3
    800031f0:	70a2                	ld	ra,40(sp)
    800031f2:	7402                	ld	s0,32(sp)
    800031f4:	64e2                	ld	s1,24(sp)
    800031f6:	6942                	ld	s2,16(sp)
    800031f8:	69a2                	ld	s3,8(sp)
    800031fa:	6a02                	ld	s4,0(sp)
    800031fc:	6145                	addi	sp,sp,48
    800031fe:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003200:	02059493          	slli	s1,a1,0x20
    80003204:	9081                	srli	s1,s1,0x20
    80003206:	048a                	slli	s1,s1,0x2
    80003208:	94aa                	add	s1,s1,a0
    8000320a:	0504a983          	lw	s3,80(s1)
    8000320e:	fe0990e3          	bnez	s3,800031ee <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003212:	4108                	lw	a0,0(a0)
    80003214:	00000097          	auipc	ra,0x0
    80003218:	e4a080e7          	jalr	-438(ra) # 8000305e <balloc>
    8000321c:	0005099b          	sext.w	s3,a0
    80003220:	0534a823          	sw	s3,80(s1)
    80003224:	b7e9                	j	800031ee <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003226:	4108                	lw	a0,0(a0)
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	e36080e7          	jalr	-458(ra) # 8000305e <balloc>
    80003230:	0005059b          	sext.w	a1,a0
    80003234:	08b92023          	sw	a1,128(s2)
    80003238:	b759                	j	800031be <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000323a:	00092503          	lw	a0,0(s2)
    8000323e:	00000097          	auipc	ra,0x0
    80003242:	e20080e7          	jalr	-480(ra) # 8000305e <balloc>
    80003246:	0005099b          	sext.w	s3,a0
    8000324a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000324e:	8552                	mv	a0,s4
    80003250:	00001097          	auipc	ra,0x1
    80003254:	ef8080e7          	jalr	-264(ra) # 80004148 <log_write>
    80003258:	b771                	j	800031e4 <bmap+0x54>
  panic("bmap: out of range");
    8000325a:	00005517          	auipc	a0,0x5
    8000325e:	2ee50513          	addi	a0,a0,750 # 80008548 <syscalls+0x118>
    80003262:	ffffd097          	auipc	ra,0xffffd
    80003266:	2c8080e7          	jalr	712(ra) # 8000052a <panic>

000000008000326a <iget>:
{
    8000326a:	7179                	addi	sp,sp,-48
    8000326c:	f406                	sd	ra,40(sp)
    8000326e:	f022                	sd	s0,32(sp)
    80003270:	ec26                	sd	s1,24(sp)
    80003272:	e84a                	sd	s2,16(sp)
    80003274:	e44e                	sd	s3,8(sp)
    80003276:	e052                	sd	s4,0(sp)
    80003278:	1800                	addi	s0,sp,48
    8000327a:	89aa                	mv	s3,a0
    8000327c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000327e:	0001c517          	auipc	a0,0x1c
    80003282:	54a50513          	addi	a0,a0,1354 # 8001f7c8 <itable>
    80003286:	ffffe097          	auipc	ra,0xffffe
    8000328a:	93c080e7          	jalr	-1732(ra) # 80000bc2 <acquire>
  empty = 0;
    8000328e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003290:	0001c497          	auipc	s1,0x1c
    80003294:	55048493          	addi	s1,s1,1360 # 8001f7e0 <itable+0x18>
    80003298:	0001e697          	auipc	a3,0x1e
    8000329c:	fd868693          	addi	a3,a3,-40 # 80021270 <log>
    800032a0:	a039                	j	800032ae <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032a2:	02090b63          	beqz	s2,800032d8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032a6:	08848493          	addi	s1,s1,136
    800032aa:	02d48a63          	beq	s1,a3,800032de <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800032ae:	449c                	lw	a5,8(s1)
    800032b0:	fef059e3          	blez	a5,800032a2 <iget+0x38>
    800032b4:	4098                	lw	a4,0(s1)
    800032b6:	ff3716e3          	bne	a4,s3,800032a2 <iget+0x38>
    800032ba:	40d8                	lw	a4,4(s1)
    800032bc:	ff4713e3          	bne	a4,s4,800032a2 <iget+0x38>
      ip->ref++;
    800032c0:	2785                	addiw	a5,a5,1
    800032c2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800032c4:	0001c517          	auipc	a0,0x1c
    800032c8:	50450513          	addi	a0,a0,1284 # 8001f7c8 <itable>
    800032cc:	ffffe097          	auipc	ra,0xffffe
    800032d0:	9aa080e7          	jalr	-1622(ra) # 80000c76 <release>
      return ip;
    800032d4:	8926                	mv	s2,s1
    800032d6:	a03d                	j	80003304 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032d8:	f7f9                	bnez	a5,800032a6 <iget+0x3c>
    800032da:	8926                	mv	s2,s1
    800032dc:	b7e9                	j	800032a6 <iget+0x3c>
  if(empty == 0)
    800032de:	02090c63          	beqz	s2,80003316 <iget+0xac>
  ip->dev = dev;
    800032e2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800032e6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800032ea:	4785                	li	a5,1
    800032ec:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800032f0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800032f4:	0001c517          	auipc	a0,0x1c
    800032f8:	4d450513          	addi	a0,a0,1236 # 8001f7c8 <itable>
    800032fc:	ffffe097          	auipc	ra,0xffffe
    80003300:	97a080e7          	jalr	-1670(ra) # 80000c76 <release>
}
    80003304:	854a                	mv	a0,s2
    80003306:	70a2                	ld	ra,40(sp)
    80003308:	7402                	ld	s0,32(sp)
    8000330a:	64e2                	ld	s1,24(sp)
    8000330c:	6942                	ld	s2,16(sp)
    8000330e:	69a2                	ld	s3,8(sp)
    80003310:	6a02                	ld	s4,0(sp)
    80003312:	6145                	addi	sp,sp,48
    80003314:	8082                	ret
    panic("iget: no inodes");
    80003316:	00005517          	auipc	a0,0x5
    8000331a:	24a50513          	addi	a0,a0,586 # 80008560 <syscalls+0x130>
    8000331e:	ffffd097          	auipc	ra,0xffffd
    80003322:	20c080e7          	jalr	524(ra) # 8000052a <panic>

0000000080003326 <fsinit>:
fsinit(int dev) {
    80003326:	7179                	addi	sp,sp,-48
    80003328:	f406                	sd	ra,40(sp)
    8000332a:	f022                	sd	s0,32(sp)
    8000332c:	ec26                	sd	s1,24(sp)
    8000332e:	e84a                	sd	s2,16(sp)
    80003330:	e44e                	sd	s3,8(sp)
    80003332:	1800                	addi	s0,sp,48
    80003334:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003336:	4585                	li	a1,1
    80003338:	00000097          	auipc	ra,0x0
    8000333c:	a64080e7          	jalr	-1436(ra) # 80002d9c <bread>
    80003340:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003342:	0001c997          	auipc	s3,0x1c
    80003346:	46698993          	addi	s3,s3,1126 # 8001f7a8 <sb>
    8000334a:	02000613          	li	a2,32
    8000334e:	05850593          	addi	a1,a0,88
    80003352:	854e                	mv	a0,s3
    80003354:	ffffe097          	auipc	ra,0xffffe
    80003358:	9c6080e7          	jalr	-1594(ra) # 80000d1a <memmove>
  brelse(bp);
    8000335c:	8526                	mv	a0,s1
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	b6e080e7          	jalr	-1170(ra) # 80002ecc <brelse>
  if(sb.magic != FSMAGIC)
    80003366:	0009a703          	lw	a4,0(s3)
    8000336a:	102037b7          	lui	a5,0x10203
    8000336e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003372:	02f71263          	bne	a4,a5,80003396 <fsinit+0x70>
  initlog(dev, &sb);
    80003376:	0001c597          	auipc	a1,0x1c
    8000337a:	43258593          	addi	a1,a1,1074 # 8001f7a8 <sb>
    8000337e:	854a                	mv	a0,s2
    80003380:	00001097          	auipc	ra,0x1
    80003384:	b4c080e7          	jalr	-1204(ra) # 80003ecc <initlog>
}
    80003388:	70a2                	ld	ra,40(sp)
    8000338a:	7402                	ld	s0,32(sp)
    8000338c:	64e2                	ld	s1,24(sp)
    8000338e:	6942                	ld	s2,16(sp)
    80003390:	69a2                	ld	s3,8(sp)
    80003392:	6145                	addi	sp,sp,48
    80003394:	8082                	ret
    panic("invalid file system");
    80003396:	00005517          	auipc	a0,0x5
    8000339a:	1da50513          	addi	a0,a0,474 # 80008570 <syscalls+0x140>
    8000339e:	ffffd097          	auipc	ra,0xffffd
    800033a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>

00000000800033a6 <iinit>:
{
    800033a6:	7179                	addi	sp,sp,-48
    800033a8:	f406                	sd	ra,40(sp)
    800033aa:	f022                	sd	s0,32(sp)
    800033ac:	ec26                	sd	s1,24(sp)
    800033ae:	e84a                	sd	s2,16(sp)
    800033b0:	e44e                	sd	s3,8(sp)
    800033b2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800033b4:	00005597          	auipc	a1,0x5
    800033b8:	1d458593          	addi	a1,a1,468 # 80008588 <syscalls+0x158>
    800033bc:	0001c517          	auipc	a0,0x1c
    800033c0:	40c50513          	addi	a0,a0,1036 # 8001f7c8 <itable>
    800033c4:	ffffd097          	auipc	ra,0xffffd
    800033c8:	76e080e7          	jalr	1902(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800033cc:	0001c497          	auipc	s1,0x1c
    800033d0:	42448493          	addi	s1,s1,1060 # 8001f7f0 <itable+0x28>
    800033d4:	0001e997          	auipc	s3,0x1e
    800033d8:	eac98993          	addi	s3,s3,-340 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800033dc:	00005917          	auipc	s2,0x5
    800033e0:	1b490913          	addi	s2,s2,436 # 80008590 <syscalls+0x160>
    800033e4:	85ca                	mv	a1,s2
    800033e6:	8526                	mv	a0,s1
    800033e8:	00001097          	auipc	ra,0x1
    800033ec:	e46080e7          	jalr	-442(ra) # 8000422e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800033f0:	08848493          	addi	s1,s1,136
    800033f4:	ff3498e3          	bne	s1,s3,800033e4 <iinit+0x3e>
}
    800033f8:	70a2                	ld	ra,40(sp)
    800033fa:	7402                	ld	s0,32(sp)
    800033fc:	64e2                	ld	s1,24(sp)
    800033fe:	6942                	ld	s2,16(sp)
    80003400:	69a2                	ld	s3,8(sp)
    80003402:	6145                	addi	sp,sp,48
    80003404:	8082                	ret

0000000080003406 <ialloc>:
{
    80003406:	715d                	addi	sp,sp,-80
    80003408:	e486                	sd	ra,72(sp)
    8000340a:	e0a2                	sd	s0,64(sp)
    8000340c:	fc26                	sd	s1,56(sp)
    8000340e:	f84a                	sd	s2,48(sp)
    80003410:	f44e                	sd	s3,40(sp)
    80003412:	f052                	sd	s4,32(sp)
    80003414:	ec56                	sd	s5,24(sp)
    80003416:	e85a                	sd	s6,16(sp)
    80003418:	e45e                	sd	s7,8(sp)
    8000341a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000341c:	0001c717          	auipc	a4,0x1c
    80003420:	39872703          	lw	a4,920(a4) # 8001f7b4 <sb+0xc>
    80003424:	4785                	li	a5,1
    80003426:	04e7fa63          	bgeu	a5,a4,8000347a <ialloc+0x74>
    8000342a:	8aaa                	mv	s5,a0
    8000342c:	8bae                	mv	s7,a1
    8000342e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003430:	0001ca17          	auipc	s4,0x1c
    80003434:	378a0a13          	addi	s4,s4,888 # 8001f7a8 <sb>
    80003438:	00048b1b          	sext.w	s6,s1
    8000343c:	0044d793          	srli	a5,s1,0x4
    80003440:	018a2583          	lw	a1,24(s4)
    80003444:	9dbd                	addw	a1,a1,a5
    80003446:	8556                	mv	a0,s5
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	954080e7          	jalr	-1708(ra) # 80002d9c <bread>
    80003450:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003452:	05850993          	addi	s3,a0,88
    80003456:	00f4f793          	andi	a5,s1,15
    8000345a:	079a                	slli	a5,a5,0x6
    8000345c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000345e:	00099783          	lh	a5,0(s3)
    80003462:	c785                	beqz	a5,8000348a <ialloc+0x84>
    brelse(bp);
    80003464:	00000097          	auipc	ra,0x0
    80003468:	a68080e7          	jalr	-1432(ra) # 80002ecc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000346c:	0485                	addi	s1,s1,1
    8000346e:	00ca2703          	lw	a4,12(s4)
    80003472:	0004879b          	sext.w	a5,s1
    80003476:	fce7e1e3          	bltu	a5,a4,80003438 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000347a:	00005517          	auipc	a0,0x5
    8000347e:	11e50513          	addi	a0,a0,286 # 80008598 <syscalls+0x168>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	0a8080e7          	jalr	168(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    8000348a:	04000613          	li	a2,64
    8000348e:	4581                	li	a1,0
    80003490:	854e                	mv	a0,s3
    80003492:	ffffe097          	auipc	ra,0xffffe
    80003496:	82c080e7          	jalr	-2004(ra) # 80000cbe <memset>
      dip->type = type;
    8000349a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000349e:	854a                	mv	a0,s2
    800034a0:	00001097          	auipc	ra,0x1
    800034a4:	ca8080e7          	jalr	-856(ra) # 80004148 <log_write>
      brelse(bp);
    800034a8:	854a                	mv	a0,s2
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	a22080e7          	jalr	-1502(ra) # 80002ecc <brelse>
      return iget(dev, inum);
    800034b2:	85da                	mv	a1,s6
    800034b4:	8556                	mv	a0,s5
    800034b6:	00000097          	auipc	ra,0x0
    800034ba:	db4080e7          	jalr	-588(ra) # 8000326a <iget>
}
    800034be:	60a6                	ld	ra,72(sp)
    800034c0:	6406                	ld	s0,64(sp)
    800034c2:	74e2                	ld	s1,56(sp)
    800034c4:	7942                	ld	s2,48(sp)
    800034c6:	79a2                	ld	s3,40(sp)
    800034c8:	7a02                	ld	s4,32(sp)
    800034ca:	6ae2                	ld	s5,24(sp)
    800034cc:	6b42                	ld	s6,16(sp)
    800034ce:	6ba2                	ld	s7,8(sp)
    800034d0:	6161                	addi	sp,sp,80
    800034d2:	8082                	ret

00000000800034d4 <iupdate>:
{
    800034d4:	1101                	addi	sp,sp,-32
    800034d6:	ec06                	sd	ra,24(sp)
    800034d8:	e822                	sd	s0,16(sp)
    800034da:	e426                	sd	s1,8(sp)
    800034dc:	e04a                	sd	s2,0(sp)
    800034de:	1000                	addi	s0,sp,32
    800034e0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800034e2:	415c                	lw	a5,4(a0)
    800034e4:	0047d79b          	srliw	a5,a5,0x4
    800034e8:	0001c597          	auipc	a1,0x1c
    800034ec:	2d85a583          	lw	a1,728(a1) # 8001f7c0 <sb+0x18>
    800034f0:	9dbd                	addw	a1,a1,a5
    800034f2:	4108                	lw	a0,0(a0)
    800034f4:	00000097          	auipc	ra,0x0
    800034f8:	8a8080e7          	jalr	-1880(ra) # 80002d9c <bread>
    800034fc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800034fe:	05850793          	addi	a5,a0,88
    80003502:	40c8                	lw	a0,4(s1)
    80003504:	893d                	andi	a0,a0,15
    80003506:	051a                	slli	a0,a0,0x6
    80003508:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000350a:	04449703          	lh	a4,68(s1)
    8000350e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003512:	04649703          	lh	a4,70(s1)
    80003516:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000351a:	04849703          	lh	a4,72(s1)
    8000351e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003522:	04a49703          	lh	a4,74(s1)
    80003526:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000352a:	44f8                	lw	a4,76(s1)
    8000352c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000352e:	03400613          	li	a2,52
    80003532:	05048593          	addi	a1,s1,80
    80003536:	0531                	addi	a0,a0,12
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	7e2080e7          	jalr	2018(ra) # 80000d1a <memmove>
  log_write(bp);
    80003540:	854a                	mv	a0,s2
    80003542:	00001097          	auipc	ra,0x1
    80003546:	c06080e7          	jalr	-1018(ra) # 80004148 <log_write>
  brelse(bp);
    8000354a:	854a                	mv	a0,s2
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	980080e7          	jalr	-1664(ra) # 80002ecc <brelse>
}
    80003554:	60e2                	ld	ra,24(sp)
    80003556:	6442                	ld	s0,16(sp)
    80003558:	64a2                	ld	s1,8(sp)
    8000355a:	6902                	ld	s2,0(sp)
    8000355c:	6105                	addi	sp,sp,32
    8000355e:	8082                	ret

0000000080003560 <idup>:
{
    80003560:	1101                	addi	sp,sp,-32
    80003562:	ec06                	sd	ra,24(sp)
    80003564:	e822                	sd	s0,16(sp)
    80003566:	e426                	sd	s1,8(sp)
    80003568:	1000                	addi	s0,sp,32
    8000356a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000356c:	0001c517          	auipc	a0,0x1c
    80003570:	25c50513          	addi	a0,a0,604 # 8001f7c8 <itable>
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	64e080e7          	jalr	1614(ra) # 80000bc2 <acquire>
  ip->ref++;
    8000357c:	449c                	lw	a5,8(s1)
    8000357e:	2785                	addiw	a5,a5,1
    80003580:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003582:	0001c517          	auipc	a0,0x1c
    80003586:	24650513          	addi	a0,a0,582 # 8001f7c8 <itable>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	6ec080e7          	jalr	1772(ra) # 80000c76 <release>
}
    80003592:	8526                	mv	a0,s1
    80003594:	60e2                	ld	ra,24(sp)
    80003596:	6442                	ld	s0,16(sp)
    80003598:	64a2                	ld	s1,8(sp)
    8000359a:	6105                	addi	sp,sp,32
    8000359c:	8082                	ret

000000008000359e <ilock>:
{
    8000359e:	1101                	addi	sp,sp,-32
    800035a0:	ec06                	sd	ra,24(sp)
    800035a2:	e822                	sd	s0,16(sp)
    800035a4:	e426                	sd	s1,8(sp)
    800035a6:	e04a                	sd	s2,0(sp)
    800035a8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800035aa:	c115                	beqz	a0,800035ce <ilock+0x30>
    800035ac:	84aa                	mv	s1,a0
    800035ae:	451c                	lw	a5,8(a0)
    800035b0:	00f05f63          	blez	a5,800035ce <ilock+0x30>
  acquiresleep(&ip->lock);
    800035b4:	0541                	addi	a0,a0,16
    800035b6:	00001097          	auipc	ra,0x1
    800035ba:	cb2080e7          	jalr	-846(ra) # 80004268 <acquiresleep>
  if(ip->valid == 0){
    800035be:	40bc                	lw	a5,64(s1)
    800035c0:	cf99                	beqz	a5,800035de <ilock+0x40>
}
    800035c2:	60e2                	ld	ra,24(sp)
    800035c4:	6442                	ld	s0,16(sp)
    800035c6:	64a2                	ld	s1,8(sp)
    800035c8:	6902                	ld	s2,0(sp)
    800035ca:	6105                	addi	sp,sp,32
    800035cc:	8082                	ret
    panic("ilock");
    800035ce:	00005517          	auipc	a0,0x5
    800035d2:	fe250513          	addi	a0,a0,-30 # 800085b0 <syscalls+0x180>
    800035d6:	ffffd097          	auipc	ra,0xffffd
    800035da:	f54080e7          	jalr	-172(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035de:	40dc                	lw	a5,4(s1)
    800035e0:	0047d79b          	srliw	a5,a5,0x4
    800035e4:	0001c597          	auipc	a1,0x1c
    800035e8:	1dc5a583          	lw	a1,476(a1) # 8001f7c0 <sb+0x18>
    800035ec:	9dbd                	addw	a1,a1,a5
    800035ee:	4088                	lw	a0,0(s1)
    800035f0:	fffff097          	auipc	ra,0xfffff
    800035f4:	7ac080e7          	jalr	1964(ra) # 80002d9c <bread>
    800035f8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035fa:	05850593          	addi	a1,a0,88
    800035fe:	40dc                	lw	a5,4(s1)
    80003600:	8bbd                	andi	a5,a5,15
    80003602:	079a                	slli	a5,a5,0x6
    80003604:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003606:	00059783          	lh	a5,0(a1)
    8000360a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000360e:	00259783          	lh	a5,2(a1)
    80003612:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003616:	00459783          	lh	a5,4(a1)
    8000361a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000361e:	00659783          	lh	a5,6(a1)
    80003622:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003626:	459c                	lw	a5,8(a1)
    80003628:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000362a:	03400613          	li	a2,52
    8000362e:	05b1                	addi	a1,a1,12
    80003630:	05048513          	addi	a0,s1,80
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	6e6080e7          	jalr	1766(ra) # 80000d1a <memmove>
    brelse(bp);
    8000363c:	854a                	mv	a0,s2
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	88e080e7          	jalr	-1906(ra) # 80002ecc <brelse>
    ip->valid = 1;
    80003646:	4785                	li	a5,1
    80003648:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000364a:	04449783          	lh	a5,68(s1)
    8000364e:	fbb5                	bnez	a5,800035c2 <ilock+0x24>
      panic("ilock: no type");
    80003650:	00005517          	auipc	a0,0x5
    80003654:	f6850513          	addi	a0,a0,-152 # 800085b8 <syscalls+0x188>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	ed2080e7          	jalr	-302(ra) # 8000052a <panic>

0000000080003660 <iunlock>:
{
    80003660:	1101                	addi	sp,sp,-32
    80003662:	ec06                	sd	ra,24(sp)
    80003664:	e822                	sd	s0,16(sp)
    80003666:	e426                	sd	s1,8(sp)
    80003668:	e04a                	sd	s2,0(sp)
    8000366a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000366c:	c905                	beqz	a0,8000369c <iunlock+0x3c>
    8000366e:	84aa                	mv	s1,a0
    80003670:	01050913          	addi	s2,a0,16
    80003674:	854a                	mv	a0,s2
    80003676:	00001097          	auipc	ra,0x1
    8000367a:	c8c080e7          	jalr	-884(ra) # 80004302 <holdingsleep>
    8000367e:	cd19                	beqz	a0,8000369c <iunlock+0x3c>
    80003680:	449c                	lw	a5,8(s1)
    80003682:	00f05d63          	blez	a5,8000369c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003686:	854a                	mv	a0,s2
    80003688:	00001097          	auipc	ra,0x1
    8000368c:	c36080e7          	jalr	-970(ra) # 800042be <releasesleep>
}
    80003690:	60e2                	ld	ra,24(sp)
    80003692:	6442                	ld	s0,16(sp)
    80003694:	64a2                	ld	s1,8(sp)
    80003696:	6902                	ld	s2,0(sp)
    80003698:	6105                	addi	sp,sp,32
    8000369a:	8082                	ret
    panic("iunlock");
    8000369c:	00005517          	auipc	a0,0x5
    800036a0:	f2c50513          	addi	a0,a0,-212 # 800085c8 <syscalls+0x198>
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	e86080e7          	jalr	-378(ra) # 8000052a <panic>

00000000800036ac <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800036ac:	7179                	addi	sp,sp,-48
    800036ae:	f406                	sd	ra,40(sp)
    800036b0:	f022                	sd	s0,32(sp)
    800036b2:	ec26                	sd	s1,24(sp)
    800036b4:	e84a                	sd	s2,16(sp)
    800036b6:	e44e                	sd	s3,8(sp)
    800036b8:	e052                	sd	s4,0(sp)
    800036ba:	1800                	addi	s0,sp,48
    800036bc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800036be:	05050493          	addi	s1,a0,80
    800036c2:	08050913          	addi	s2,a0,128
    800036c6:	a021                	j	800036ce <itrunc+0x22>
    800036c8:	0491                	addi	s1,s1,4
    800036ca:	01248d63          	beq	s1,s2,800036e4 <itrunc+0x38>
    if(ip->addrs[i]){
    800036ce:	408c                	lw	a1,0(s1)
    800036d0:	dde5                	beqz	a1,800036c8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800036d2:	0009a503          	lw	a0,0(s3)
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	90c080e7          	jalr	-1780(ra) # 80002fe2 <bfree>
      ip->addrs[i] = 0;
    800036de:	0004a023          	sw	zero,0(s1)
    800036e2:	b7dd                	j	800036c8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800036e4:	0809a583          	lw	a1,128(s3)
    800036e8:	e185                	bnez	a1,80003708 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800036ea:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800036ee:	854e                	mv	a0,s3
    800036f0:	00000097          	auipc	ra,0x0
    800036f4:	de4080e7          	jalr	-540(ra) # 800034d4 <iupdate>
}
    800036f8:	70a2                	ld	ra,40(sp)
    800036fa:	7402                	ld	s0,32(sp)
    800036fc:	64e2                	ld	s1,24(sp)
    800036fe:	6942                	ld	s2,16(sp)
    80003700:	69a2                	ld	s3,8(sp)
    80003702:	6a02                	ld	s4,0(sp)
    80003704:	6145                	addi	sp,sp,48
    80003706:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003708:	0009a503          	lw	a0,0(s3)
    8000370c:	fffff097          	auipc	ra,0xfffff
    80003710:	690080e7          	jalr	1680(ra) # 80002d9c <bread>
    80003714:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003716:	05850493          	addi	s1,a0,88
    8000371a:	45850913          	addi	s2,a0,1112
    8000371e:	a021                	j	80003726 <itrunc+0x7a>
    80003720:	0491                	addi	s1,s1,4
    80003722:	01248b63          	beq	s1,s2,80003738 <itrunc+0x8c>
      if(a[j])
    80003726:	408c                	lw	a1,0(s1)
    80003728:	dde5                	beqz	a1,80003720 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000372a:	0009a503          	lw	a0,0(s3)
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	8b4080e7          	jalr	-1868(ra) # 80002fe2 <bfree>
    80003736:	b7ed                	j	80003720 <itrunc+0x74>
    brelse(bp);
    80003738:	8552                	mv	a0,s4
    8000373a:	fffff097          	auipc	ra,0xfffff
    8000373e:	792080e7          	jalr	1938(ra) # 80002ecc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003742:	0809a583          	lw	a1,128(s3)
    80003746:	0009a503          	lw	a0,0(s3)
    8000374a:	00000097          	auipc	ra,0x0
    8000374e:	898080e7          	jalr	-1896(ra) # 80002fe2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003752:	0809a023          	sw	zero,128(s3)
    80003756:	bf51                	j	800036ea <itrunc+0x3e>

0000000080003758 <iput>:
{
    80003758:	1101                	addi	sp,sp,-32
    8000375a:	ec06                	sd	ra,24(sp)
    8000375c:	e822                	sd	s0,16(sp)
    8000375e:	e426                	sd	s1,8(sp)
    80003760:	e04a                	sd	s2,0(sp)
    80003762:	1000                	addi	s0,sp,32
    80003764:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003766:	0001c517          	auipc	a0,0x1c
    8000376a:	06250513          	addi	a0,a0,98 # 8001f7c8 <itable>
    8000376e:	ffffd097          	auipc	ra,0xffffd
    80003772:	454080e7          	jalr	1108(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003776:	4498                	lw	a4,8(s1)
    80003778:	4785                	li	a5,1
    8000377a:	02f70363          	beq	a4,a5,800037a0 <iput+0x48>
  ip->ref--;
    8000377e:	449c                	lw	a5,8(s1)
    80003780:	37fd                	addiw	a5,a5,-1
    80003782:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003784:	0001c517          	auipc	a0,0x1c
    80003788:	04450513          	addi	a0,a0,68 # 8001f7c8 <itable>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	4ea080e7          	jalr	1258(ra) # 80000c76 <release>
}
    80003794:	60e2                	ld	ra,24(sp)
    80003796:	6442                	ld	s0,16(sp)
    80003798:	64a2                	ld	s1,8(sp)
    8000379a:	6902                	ld	s2,0(sp)
    8000379c:	6105                	addi	sp,sp,32
    8000379e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037a0:	40bc                	lw	a5,64(s1)
    800037a2:	dff1                	beqz	a5,8000377e <iput+0x26>
    800037a4:	04a49783          	lh	a5,74(s1)
    800037a8:	fbf9                	bnez	a5,8000377e <iput+0x26>
    acquiresleep(&ip->lock);
    800037aa:	01048913          	addi	s2,s1,16
    800037ae:	854a                	mv	a0,s2
    800037b0:	00001097          	auipc	ra,0x1
    800037b4:	ab8080e7          	jalr	-1352(ra) # 80004268 <acquiresleep>
    release(&itable.lock);
    800037b8:	0001c517          	auipc	a0,0x1c
    800037bc:	01050513          	addi	a0,a0,16 # 8001f7c8 <itable>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	4b6080e7          	jalr	1206(ra) # 80000c76 <release>
    itrunc(ip);
    800037c8:	8526                	mv	a0,s1
    800037ca:	00000097          	auipc	ra,0x0
    800037ce:	ee2080e7          	jalr	-286(ra) # 800036ac <itrunc>
    ip->type = 0;
    800037d2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800037d6:	8526                	mv	a0,s1
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	cfc080e7          	jalr	-772(ra) # 800034d4 <iupdate>
    ip->valid = 0;
    800037e0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800037e4:	854a                	mv	a0,s2
    800037e6:	00001097          	auipc	ra,0x1
    800037ea:	ad8080e7          	jalr	-1320(ra) # 800042be <releasesleep>
    acquire(&itable.lock);
    800037ee:	0001c517          	auipc	a0,0x1c
    800037f2:	fda50513          	addi	a0,a0,-38 # 8001f7c8 <itable>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	3cc080e7          	jalr	972(ra) # 80000bc2 <acquire>
    800037fe:	b741                	j	8000377e <iput+0x26>

0000000080003800 <iunlockput>:
{
    80003800:	1101                	addi	sp,sp,-32
    80003802:	ec06                	sd	ra,24(sp)
    80003804:	e822                	sd	s0,16(sp)
    80003806:	e426                	sd	s1,8(sp)
    80003808:	1000                	addi	s0,sp,32
    8000380a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	e54080e7          	jalr	-428(ra) # 80003660 <iunlock>
  iput(ip);
    80003814:	8526                	mv	a0,s1
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	f42080e7          	jalr	-190(ra) # 80003758 <iput>
}
    8000381e:	60e2                	ld	ra,24(sp)
    80003820:	6442                	ld	s0,16(sp)
    80003822:	64a2                	ld	s1,8(sp)
    80003824:	6105                	addi	sp,sp,32
    80003826:	8082                	ret

0000000080003828 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003828:	1141                	addi	sp,sp,-16
    8000382a:	e422                	sd	s0,8(sp)
    8000382c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000382e:	411c                	lw	a5,0(a0)
    80003830:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003832:	415c                	lw	a5,4(a0)
    80003834:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003836:	04451783          	lh	a5,68(a0)
    8000383a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000383e:	04a51783          	lh	a5,74(a0)
    80003842:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003846:	04c56783          	lwu	a5,76(a0)
    8000384a:	e99c                	sd	a5,16(a1)
}
    8000384c:	6422                	ld	s0,8(sp)
    8000384e:	0141                	addi	sp,sp,16
    80003850:	8082                	ret

0000000080003852 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003852:	457c                	lw	a5,76(a0)
    80003854:	0ed7e963          	bltu	a5,a3,80003946 <readi+0xf4>
{
    80003858:	7159                	addi	sp,sp,-112
    8000385a:	f486                	sd	ra,104(sp)
    8000385c:	f0a2                	sd	s0,96(sp)
    8000385e:	eca6                	sd	s1,88(sp)
    80003860:	e8ca                	sd	s2,80(sp)
    80003862:	e4ce                	sd	s3,72(sp)
    80003864:	e0d2                	sd	s4,64(sp)
    80003866:	fc56                	sd	s5,56(sp)
    80003868:	f85a                	sd	s6,48(sp)
    8000386a:	f45e                	sd	s7,40(sp)
    8000386c:	f062                	sd	s8,32(sp)
    8000386e:	ec66                	sd	s9,24(sp)
    80003870:	e86a                	sd	s10,16(sp)
    80003872:	e46e                	sd	s11,8(sp)
    80003874:	1880                	addi	s0,sp,112
    80003876:	8baa                	mv	s7,a0
    80003878:	8c2e                	mv	s8,a1
    8000387a:	8ab2                	mv	s5,a2
    8000387c:	84b6                	mv	s1,a3
    8000387e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003880:	9f35                	addw	a4,a4,a3
    return 0;
    80003882:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003884:	0ad76063          	bltu	a4,a3,80003924 <readi+0xd2>
  if(off + n > ip->size)
    80003888:	00e7f463          	bgeu	a5,a4,80003890 <readi+0x3e>
    n = ip->size - off;
    8000388c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003890:	0a0b0963          	beqz	s6,80003942 <readi+0xf0>
    80003894:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003896:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000389a:	5cfd                	li	s9,-1
    8000389c:	a82d                	j	800038d6 <readi+0x84>
    8000389e:	020a1d93          	slli	s11,s4,0x20
    800038a2:	020ddd93          	srli	s11,s11,0x20
    800038a6:	05890793          	addi	a5,s2,88
    800038aa:	86ee                	mv	a3,s11
    800038ac:	963e                	add	a2,a2,a5
    800038ae:	85d6                	mv	a1,s5
    800038b0:	8562                	mv	a0,s8
    800038b2:	fffff097          	auipc	ra,0xfffff
    800038b6:	b30080e7          	jalr	-1232(ra) # 800023e2 <either_copyout>
    800038ba:	05950d63          	beq	a0,s9,80003914 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800038be:	854a                	mv	a0,s2
    800038c0:	fffff097          	auipc	ra,0xfffff
    800038c4:	60c080e7          	jalr	1548(ra) # 80002ecc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038c8:	013a09bb          	addw	s3,s4,s3
    800038cc:	009a04bb          	addw	s1,s4,s1
    800038d0:	9aee                	add	s5,s5,s11
    800038d2:	0569f763          	bgeu	s3,s6,80003920 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800038d6:	000ba903          	lw	s2,0(s7)
    800038da:	00a4d59b          	srliw	a1,s1,0xa
    800038de:	855e                	mv	a0,s7
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	8b0080e7          	jalr	-1872(ra) # 80003190 <bmap>
    800038e8:	0005059b          	sext.w	a1,a0
    800038ec:	854a                	mv	a0,s2
    800038ee:	fffff097          	auipc	ra,0xfffff
    800038f2:	4ae080e7          	jalr	1198(ra) # 80002d9c <bread>
    800038f6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800038f8:	3ff4f613          	andi	a2,s1,1023
    800038fc:	40cd07bb          	subw	a5,s10,a2
    80003900:	413b073b          	subw	a4,s6,s3
    80003904:	8a3e                	mv	s4,a5
    80003906:	2781                	sext.w	a5,a5
    80003908:	0007069b          	sext.w	a3,a4
    8000390c:	f8f6f9e3          	bgeu	a3,a5,8000389e <readi+0x4c>
    80003910:	8a3a                	mv	s4,a4
    80003912:	b771                	j	8000389e <readi+0x4c>
      brelse(bp);
    80003914:	854a                	mv	a0,s2
    80003916:	fffff097          	auipc	ra,0xfffff
    8000391a:	5b6080e7          	jalr	1462(ra) # 80002ecc <brelse>
      tot = -1;
    8000391e:	59fd                	li	s3,-1
  }
  return tot;
    80003920:	0009851b          	sext.w	a0,s3
}
    80003924:	70a6                	ld	ra,104(sp)
    80003926:	7406                	ld	s0,96(sp)
    80003928:	64e6                	ld	s1,88(sp)
    8000392a:	6946                	ld	s2,80(sp)
    8000392c:	69a6                	ld	s3,72(sp)
    8000392e:	6a06                	ld	s4,64(sp)
    80003930:	7ae2                	ld	s5,56(sp)
    80003932:	7b42                	ld	s6,48(sp)
    80003934:	7ba2                	ld	s7,40(sp)
    80003936:	7c02                	ld	s8,32(sp)
    80003938:	6ce2                	ld	s9,24(sp)
    8000393a:	6d42                	ld	s10,16(sp)
    8000393c:	6da2                	ld	s11,8(sp)
    8000393e:	6165                	addi	sp,sp,112
    80003940:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003942:	89da                	mv	s3,s6
    80003944:	bff1                	j	80003920 <readi+0xce>
    return 0;
    80003946:	4501                	li	a0,0
}
    80003948:	8082                	ret

000000008000394a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000394a:	457c                	lw	a5,76(a0)
    8000394c:	10d7e863          	bltu	a5,a3,80003a5c <writei+0x112>
{
    80003950:	7159                	addi	sp,sp,-112
    80003952:	f486                	sd	ra,104(sp)
    80003954:	f0a2                	sd	s0,96(sp)
    80003956:	eca6                	sd	s1,88(sp)
    80003958:	e8ca                	sd	s2,80(sp)
    8000395a:	e4ce                	sd	s3,72(sp)
    8000395c:	e0d2                	sd	s4,64(sp)
    8000395e:	fc56                	sd	s5,56(sp)
    80003960:	f85a                	sd	s6,48(sp)
    80003962:	f45e                	sd	s7,40(sp)
    80003964:	f062                	sd	s8,32(sp)
    80003966:	ec66                	sd	s9,24(sp)
    80003968:	e86a                	sd	s10,16(sp)
    8000396a:	e46e                	sd	s11,8(sp)
    8000396c:	1880                	addi	s0,sp,112
    8000396e:	8b2a                	mv	s6,a0
    80003970:	8c2e                	mv	s8,a1
    80003972:	8ab2                	mv	s5,a2
    80003974:	8936                	mv	s2,a3
    80003976:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003978:	00e687bb          	addw	a5,a3,a4
    8000397c:	0ed7e263          	bltu	a5,a3,80003a60 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003980:	00043737          	lui	a4,0x43
    80003984:	0ef76063          	bltu	a4,a5,80003a64 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003988:	0c0b8863          	beqz	s7,80003a58 <writei+0x10e>
    8000398c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000398e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003992:	5cfd                	li	s9,-1
    80003994:	a091                	j	800039d8 <writei+0x8e>
    80003996:	02099d93          	slli	s11,s3,0x20
    8000399a:	020ddd93          	srli	s11,s11,0x20
    8000399e:	05848793          	addi	a5,s1,88
    800039a2:	86ee                	mv	a3,s11
    800039a4:	8656                	mv	a2,s5
    800039a6:	85e2                	mv	a1,s8
    800039a8:	953e                	add	a0,a0,a5
    800039aa:	fffff097          	auipc	ra,0xfffff
    800039ae:	a8e080e7          	jalr	-1394(ra) # 80002438 <either_copyin>
    800039b2:	07950263          	beq	a0,s9,80003a16 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800039b6:	8526                	mv	a0,s1
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	790080e7          	jalr	1936(ra) # 80004148 <log_write>
    brelse(bp);
    800039c0:	8526                	mv	a0,s1
    800039c2:	fffff097          	auipc	ra,0xfffff
    800039c6:	50a080e7          	jalr	1290(ra) # 80002ecc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039ca:	01498a3b          	addw	s4,s3,s4
    800039ce:	0129893b          	addw	s2,s3,s2
    800039d2:	9aee                	add	s5,s5,s11
    800039d4:	057a7663          	bgeu	s4,s7,80003a20 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039d8:	000b2483          	lw	s1,0(s6)
    800039dc:	00a9559b          	srliw	a1,s2,0xa
    800039e0:	855a                	mv	a0,s6
    800039e2:	fffff097          	auipc	ra,0xfffff
    800039e6:	7ae080e7          	jalr	1966(ra) # 80003190 <bmap>
    800039ea:	0005059b          	sext.w	a1,a0
    800039ee:	8526                	mv	a0,s1
    800039f0:	fffff097          	auipc	ra,0xfffff
    800039f4:	3ac080e7          	jalr	940(ra) # 80002d9c <bread>
    800039f8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039fa:	3ff97513          	andi	a0,s2,1023
    800039fe:	40ad07bb          	subw	a5,s10,a0
    80003a02:	414b873b          	subw	a4,s7,s4
    80003a06:	89be                	mv	s3,a5
    80003a08:	2781                	sext.w	a5,a5
    80003a0a:	0007069b          	sext.w	a3,a4
    80003a0e:	f8f6f4e3          	bgeu	a3,a5,80003996 <writei+0x4c>
    80003a12:	89ba                	mv	s3,a4
    80003a14:	b749                	j	80003996 <writei+0x4c>
      brelse(bp);
    80003a16:	8526                	mv	a0,s1
    80003a18:	fffff097          	auipc	ra,0xfffff
    80003a1c:	4b4080e7          	jalr	1204(ra) # 80002ecc <brelse>
  }

  if(off > ip->size)
    80003a20:	04cb2783          	lw	a5,76(s6)
    80003a24:	0127f463          	bgeu	a5,s2,80003a2c <writei+0xe2>
    ip->size = off;
    80003a28:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a2c:	855a                	mv	a0,s6
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	aa6080e7          	jalr	-1370(ra) # 800034d4 <iupdate>

  return tot;
    80003a36:	000a051b          	sext.w	a0,s4
}
    80003a3a:	70a6                	ld	ra,104(sp)
    80003a3c:	7406                	ld	s0,96(sp)
    80003a3e:	64e6                	ld	s1,88(sp)
    80003a40:	6946                	ld	s2,80(sp)
    80003a42:	69a6                	ld	s3,72(sp)
    80003a44:	6a06                	ld	s4,64(sp)
    80003a46:	7ae2                	ld	s5,56(sp)
    80003a48:	7b42                	ld	s6,48(sp)
    80003a4a:	7ba2                	ld	s7,40(sp)
    80003a4c:	7c02                	ld	s8,32(sp)
    80003a4e:	6ce2                	ld	s9,24(sp)
    80003a50:	6d42                	ld	s10,16(sp)
    80003a52:	6da2                	ld	s11,8(sp)
    80003a54:	6165                	addi	sp,sp,112
    80003a56:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a58:	8a5e                	mv	s4,s7
    80003a5a:	bfc9                	j	80003a2c <writei+0xe2>
    return -1;
    80003a5c:	557d                	li	a0,-1
}
    80003a5e:	8082                	ret
    return -1;
    80003a60:	557d                	li	a0,-1
    80003a62:	bfe1                	j	80003a3a <writei+0xf0>
    return -1;
    80003a64:	557d                	li	a0,-1
    80003a66:	bfd1                	j	80003a3a <writei+0xf0>

0000000080003a68 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003a68:	1141                	addi	sp,sp,-16
    80003a6a:	e406                	sd	ra,8(sp)
    80003a6c:	e022                	sd	s0,0(sp)
    80003a6e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003a70:	4639                	li	a2,14
    80003a72:	ffffd097          	auipc	ra,0xffffd
    80003a76:	324080e7          	jalr	804(ra) # 80000d96 <strncmp>
}
    80003a7a:	60a2                	ld	ra,8(sp)
    80003a7c:	6402                	ld	s0,0(sp)
    80003a7e:	0141                	addi	sp,sp,16
    80003a80:	8082                	ret

0000000080003a82 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003a82:	7139                	addi	sp,sp,-64
    80003a84:	fc06                	sd	ra,56(sp)
    80003a86:	f822                	sd	s0,48(sp)
    80003a88:	f426                	sd	s1,40(sp)
    80003a8a:	f04a                	sd	s2,32(sp)
    80003a8c:	ec4e                	sd	s3,24(sp)
    80003a8e:	e852                	sd	s4,16(sp)
    80003a90:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003a92:	04451703          	lh	a4,68(a0)
    80003a96:	4785                	li	a5,1
    80003a98:	00f71a63          	bne	a4,a5,80003aac <dirlookup+0x2a>
    80003a9c:	892a                	mv	s2,a0
    80003a9e:	89ae                	mv	s3,a1
    80003aa0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003aa2:	457c                	lw	a5,76(a0)
    80003aa4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003aa6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003aa8:	e79d                	bnez	a5,80003ad6 <dirlookup+0x54>
    80003aaa:	a8a5                	j	80003b22 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003aac:	00005517          	auipc	a0,0x5
    80003ab0:	b2450513          	addi	a0,a0,-1244 # 800085d0 <syscalls+0x1a0>
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	a76080e7          	jalr	-1418(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003abc:	00005517          	auipc	a0,0x5
    80003ac0:	b2c50513          	addi	a0,a0,-1236 # 800085e8 <syscalls+0x1b8>
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	a66080e7          	jalr	-1434(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003acc:	24c1                	addiw	s1,s1,16
    80003ace:	04c92783          	lw	a5,76(s2)
    80003ad2:	04f4f763          	bgeu	s1,a5,80003b20 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ad6:	4741                	li	a4,16
    80003ad8:	86a6                	mv	a3,s1
    80003ada:	fc040613          	addi	a2,s0,-64
    80003ade:	4581                	li	a1,0
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	d70080e7          	jalr	-656(ra) # 80003852 <readi>
    80003aea:	47c1                	li	a5,16
    80003aec:	fcf518e3          	bne	a0,a5,80003abc <dirlookup+0x3a>
    if(de.inum == 0)
    80003af0:	fc045783          	lhu	a5,-64(s0)
    80003af4:	dfe1                	beqz	a5,80003acc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003af6:	fc240593          	addi	a1,s0,-62
    80003afa:	854e                	mv	a0,s3
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	f6c080e7          	jalr	-148(ra) # 80003a68 <namecmp>
    80003b04:	f561                	bnez	a0,80003acc <dirlookup+0x4a>
      if(poff)
    80003b06:	000a0463          	beqz	s4,80003b0e <dirlookup+0x8c>
        *poff = off;
    80003b0a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b0e:	fc045583          	lhu	a1,-64(s0)
    80003b12:	00092503          	lw	a0,0(s2)
    80003b16:	fffff097          	auipc	ra,0xfffff
    80003b1a:	754080e7          	jalr	1876(ra) # 8000326a <iget>
    80003b1e:	a011                	j	80003b22 <dirlookup+0xa0>
  return 0;
    80003b20:	4501                	li	a0,0
}
    80003b22:	70e2                	ld	ra,56(sp)
    80003b24:	7442                	ld	s0,48(sp)
    80003b26:	74a2                	ld	s1,40(sp)
    80003b28:	7902                	ld	s2,32(sp)
    80003b2a:	69e2                	ld	s3,24(sp)
    80003b2c:	6a42                	ld	s4,16(sp)
    80003b2e:	6121                	addi	sp,sp,64
    80003b30:	8082                	ret

0000000080003b32 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b32:	711d                	addi	sp,sp,-96
    80003b34:	ec86                	sd	ra,88(sp)
    80003b36:	e8a2                	sd	s0,80(sp)
    80003b38:	e4a6                	sd	s1,72(sp)
    80003b3a:	e0ca                	sd	s2,64(sp)
    80003b3c:	fc4e                	sd	s3,56(sp)
    80003b3e:	f852                	sd	s4,48(sp)
    80003b40:	f456                	sd	s5,40(sp)
    80003b42:	f05a                	sd	s6,32(sp)
    80003b44:	ec5e                	sd	s7,24(sp)
    80003b46:	e862                	sd	s8,16(sp)
    80003b48:	e466                	sd	s9,8(sp)
    80003b4a:	1080                	addi	s0,sp,96
    80003b4c:	84aa                	mv	s1,a0
    80003b4e:	8aae                	mv	s5,a1
    80003b50:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003b52:	00054703          	lbu	a4,0(a0)
    80003b56:	02f00793          	li	a5,47
    80003b5a:	02f70363          	beq	a4,a5,80003b80 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003b5e:	ffffe097          	auipc	ra,0xffffe
    80003b62:	e20080e7          	jalr	-480(ra) # 8000197e <myproc>
    80003b66:	15053503          	ld	a0,336(a0)
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	9f6080e7          	jalr	-1546(ra) # 80003560 <idup>
    80003b72:	89aa                	mv	s3,a0
  while(*path == '/')
    80003b74:	02f00913          	li	s2,47
  len = path - s;
    80003b78:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003b7a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003b7c:	4b85                	li	s7,1
    80003b7e:	a865                	j	80003c36 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003b80:	4585                	li	a1,1
    80003b82:	4505                	li	a0,1
    80003b84:	fffff097          	auipc	ra,0xfffff
    80003b88:	6e6080e7          	jalr	1766(ra) # 8000326a <iget>
    80003b8c:	89aa                	mv	s3,a0
    80003b8e:	b7dd                	j	80003b74 <namex+0x42>
      iunlockput(ip);
    80003b90:	854e                	mv	a0,s3
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	c6e080e7          	jalr	-914(ra) # 80003800 <iunlockput>
      return 0;
    80003b9a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003b9c:	854e                	mv	a0,s3
    80003b9e:	60e6                	ld	ra,88(sp)
    80003ba0:	6446                	ld	s0,80(sp)
    80003ba2:	64a6                	ld	s1,72(sp)
    80003ba4:	6906                	ld	s2,64(sp)
    80003ba6:	79e2                	ld	s3,56(sp)
    80003ba8:	7a42                	ld	s4,48(sp)
    80003baa:	7aa2                	ld	s5,40(sp)
    80003bac:	7b02                	ld	s6,32(sp)
    80003bae:	6be2                	ld	s7,24(sp)
    80003bb0:	6c42                	ld	s8,16(sp)
    80003bb2:	6ca2                	ld	s9,8(sp)
    80003bb4:	6125                	addi	sp,sp,96
    80003bb6:	8082                	ret
      iunlock(ip);
    80003bb8:	854e                	mv	a0,s3
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	aa6080e7          	jalr	-1370(ra) # 80003660 <iunlock>
      return ip;
    80003bc2:	bfe9                	j	80003b9c <namex+0x6a>
      iunlockput(ip);
    80003bc4:	854e                	mv	a0,s3
    80003bc6:	00000097          	auipc	ra,0x0
    80003bca:	c3a080e7          	jalr	-966(ra) # 80003800 <iunlockput>
      return 0;
    80003bce:	89e6                	mv	s3,s9
    80003bd0:	b7f1                	j	80003b9c <namex+0x6a>
  len = path - s;
    80003bd2:	40b48633          	sub	a2,s1,a1
    80003bd6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003bda:	099c5463          	bge	s8,s9,80003c62 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003bde:	4639                	li	a2,14
    80003be0:	8552                	mv	a0,s4
    80003be2:	ffffd097          	auipc	ra,0xffffd
    80003be6:	138080e7          	jalr	312(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003bea:	0004c783          	lbu	a5,0(s1)
    80003bee:	01279763          	bne	a5,s2,80003bfc <namex+0xca>
    path++;
    80003bf2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003bf4:	0004c783          	lbu	a5,0(s1)
    80003bf8:	ff278de3          	beq	a5,s2,80003bf2 <namex+0xc0>
    ilock(ip);
    80003bfc:	854e                	mv	a0,s3
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	9a0080e7          	jalr	-1632(ra) # 8000359e <ilock>
    if(ip->type != T_DIR){
    80003c06:	04499783          	lh	a5,68(s3)
    80003c0a:	f97793e3          	bne	a5,s7,80003b90 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c0e:	000a8563          	beqz	s5,80003c18 <namex+0xe6>
    80003c12:	0004c783          	lbu	a5,0(s1)
    80003c16:	d3cd                	beqz	a5,80003bb8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c18:	865a                	mv	a2,s6
    80003c1a:	85d2                	mv	a1,s4
    80003c1c:	854e                	mv	a0,s3
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	e64080e7          	jalr	-412(ra) # 80003a82 <dirlookup>
    80003c26:	8caa                	mv	s9,a0
    80003c28:	dd51                	beqz	a0,80003bc4 <namex+0x92>
    iunlockput(ip);
    80003c2a:	854e                	mv	a0,s3
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	bd4080e7          	jalr	-1068(ra) # 80003800 <iunlockput>
    ip = next;
    80003c34:	89e6                	mv	s3,s9
  while(*path == '/')
    80003c36:	0004c783          	lbu	a5,0(s1)
    80003c3a:	05279763          	bne	a5,s2,80003c88 <namex+0x156>
    path++;
    80003c3e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c40:	0004c783          	lbu	a5,0(s1)
    80003c44:	ff278de3          	beq	a5,s2,80003c3e <namex+0x10c>
  if(*path == 0)
    80003c48:	c79d                	beqz	a5,80003c76 <namex+0x144>
    path++;
    80003c4a:	85a6                	mv	a1,s1
  len = path - s;
    80003c4c:	8cda                	mv	s9,s6
    80003c4e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003c50:	01278963          	beq	a5,s2,80003c62 <namex+0x130>
    80003c54:	dfbd                	beqz	a5,80003bd2 <namex+0xa0>
    path++;
    80003c56:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003c58:	0004c783          	lbu	a5,0(s1)
    80003c5c:	ff279ce3          	bne	a5,s2,80003c54 <namex+0x122>
    80003c60:	bf8d                	j	80003bd2 <namex+0xa0>
    memmove(name, s, len);
    80003c62:	2601                	sext.w	a2,a2
    80003c64:	8552                	mv	a0,s4
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	0b4080e7          	jalr	180(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003c6e:	9cd2                	add	s9,s9,s4
    80003c70:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003c74:	bf9d                	j	80003bea <namex+0xb8>
  if(nameiparent){
    80003c76:	f20a83e3          	beqz	s5,80003b9c <namex+0x6a>
    iput(ip);
    80003c7a:	854e                	mv	a0,s3
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	adc080e7          	jalr	-1316(ra) # 80003758 <iput>
    return 0;
    80003c84:	4981                	li	s3,0
    80003c86:	bf19                	j	80003b9c <namex+0x6a>
  if(*path == 0)
    80003c88:	d7fd                	beqz	a5,80003c76 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003c8a:	0004c783          	lbu	a5,0(s1)
    80003c8e:	85a6                	mv	a1,s1
    80003c90:	b7d1                	j	80003c54 <namex+0x122>

0000000080003c92 <dirlink>:
{
    80003c92:	7139                	addi	sp,sp,-64
    80003c94:	fc06                	sd	ra,56(sp)
    80003c96:	f822                	sd	s0,48(sp)
    80003c98:	f426                	sd	s1,40(sp)
    80003c9a:	f04a                	sd	s2,32(sp)
    80003c9c:	ec4e                	sd	s3,24(sp)
    80003c9e:	e852                	sd	s4,16(sp)
    80003ca0:	0080                	addi	s0,sp,64
    80003ca2:	892a                	mv	s2,a0
    80003ca4:	8a2e                	mv	s4,a1
    80003ca6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ca8:	4601                	li	a2,0
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	dd8080e7          	jalr	-552(ra) # 80003a82 <dirlookup>
    80003cb2:	e93d                	bnez	a0,80003d28 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb4:	04c92483          	lw	s1,76(s2)
    80003cb8:	c49d                	beqz	s1,80003ce6 <dirlink+0x54>
    80003cba:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cbc:	4741                	li	a4,16
    80003cbe:	86a6                	mv	a3,s1
    80003cc0:	fc040613          	addi	a2,s0,-64
    80003cc4:	4581                	li	a1,0
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	b8a080e7          	jalr	-1142(ra) # 80003852 <readi>
    80003cd0:	47c1                	li	a5,16
    80003cd2:	06f51163          	bne	a0,a5,80003d34 <dirlink+0xa2>
    if(de.inum == 0)
    80003cd6:	fc045783          	lhu	a5,-64(s0)
    80003cda:	c791                	beqz	a5,80003ce6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cdc:	24c1                	addiw	s1,s1,16
    80003cde:	04c92783          	lw	a5,76(s2)
    80003ce2:	fcf4ede3          	bltu	s1,a5,80003cbc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ce6:	4639                	li	a2,14
    80003ce8:	85d2                	mv	a1,s4
    80003cea:	fc240513          	addi	a0,s0,-62
    80003cee:	ffffd097          	auipc	ra,0xffffd
    80003cf2:	0e4080e7          	jalr	228(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003cf6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cfa:	4741                	li	a4,16
    80003cfc:	86a6                	mv	a3,s1
    80003cfe:	fc040613          	addi	a2,s0,-64
    80003d02:	4581                	li	a1,0
    80003d04:	854a                	mv	a0,s2
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	c44080e7          	jalr	-956(ra) # 8000394a <writei>
    80003d0e:	872a                	mv	a4,a0
    80003d10:	47c1                	li	a5,16
  return 0;
    80003d12:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d14:	02f71863          	bne	a4,a5,80003d44 <dirlink+0xb2>
}
    80003d18:	70e2                	ld	ra,56(sp)
    80003d1a:	7442                	ld	s0,48(sp)
    80003d1c:	74a2                	ld	s1,40(sp)
    80003d1e:	7902                	ld	s2,32(sp)
    80003d20:	69e2                	ld	s3,24(sp)
    80003d22:	6a42                	ld	s4,16(sp)
    80003d24:	6121                	addi	sp,sp,64
    80003d26:	8082                	ret
    iput(ip);
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	a30080e7          	jalr	-1488(ra) # 80003758 <iput>
    return -1;
    80003d30:	557d                	li	a0,-1
    80003d32:	b7dd                	j	80003d18 <dirlink+0x86>
      panic("dirlink read");
    80003d34:	00005517          	auipc	a0,0x5
    80003d38:	8c450513          	addi	a0,a0,-1852 # 800085f8 <syscalls+0x1c8>
    80003d3c:	ffffc097          	auipc	ra,0xffffc
    80003d40:	7ee080e7          	jalr	2030(ra) # 8000052a <panic>
    panic("dirlink");
    80003d44:	00005517          	auipc	a0,0x5
    80003d48:	9c450513          	addi	a0,a0,-1596 # 80008708 <syscalls+0x2d8>
    80003d4c:	ffffc097          	auipc	ra,0xffffc
    80003d50:	7de080e7          	jalr	2014(ra) # 8000052a <panic>

0000000080003d54 <namei>:

struct inode*
namei(char *path)
{
    80003d54:	1101                	addi	sp,sp,-32
    80003d56:	ec06                	sd	ra,24(sp)
    80003d58:	e822                	sd	s0,16(sp)
    80003d5a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003d5c:	fe040613          	addi	a2,s0,-32
    80003d60:	4581                	li	a1,0
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	dd0080e7          	jalr	-560(ra) # 80003b32 <namex>
}
    80003d6a:	60e2                	ld	ra,24(sp)
    80003d6c:	6442                	ld	s0,16(sp)
    80003d6e:	6105                	addi	sp,sp,32
    80003d70:	8082                	ret

0000000080003d72 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003d72:	1141                	addi	sp,sp,-16
    80003d74:	e406                	sd	ra,8(sp)
    80003d76:	e022                	sd	s0,0(sp)
    80003d78:	0800                	addi	s0,sp,16
    80003d7a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003d7c:	4585                	li	a1,1
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	db4080e7          	jalr	-588(ra) # 80003b32 <namex>
}
    80003d86:	60a2                	ld	ra,8(sp)
    80003d88:	6402                	ld	s0,0(sp)
    80003d8a:	0141                	addi	sp,sp,16
    80003d8c:	8082                	ret

0000000080003d8e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003d8e:	1101                	addi	sp,sp,-32
    80003d90:	ec06                	sd	ra,24(sp)
    80003d92:	e822                	sd	s0,16(sp)
    80003d94:	e426                	sd	s1,8(sp)
    80003d96:	e04a                	sd	s2,0(sp)
    80003d98:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003d9a:	0001d917          	auipc	s2,0x1d
    80003d9e:	4d690913          	addi	s2,s2,1238 # 80021270 <log>
    80003da2:	01892583          	lw	a1,24(s2)
    80003da6:	02892503          	lw	a0,40(s2)
    80003daa:	fffff097          	auipc	ra,0xfffff
    80003dae:	ff2080e7          	jalr	-14(ra) # 80002d9c <bread>
    80003db2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003db4:	02c92683          	lw	a3,44(s2)
    80003db8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003dba:	02d05763          	blez	a3,80003de8 <write_head+0x5a>
    80003dbe:	0001d797          	auipc	a5,0x1d
    80003dc2:	4e278793          	addi	a5,a5,1250 # 800212a0 <log+0x30>
    80003dc6:	05c50713          	addi	a4,a0,92
    80003dca:	36fd                	addiw	a3,a3,-1
    80003dcc:	1682                	slli	a3,a3,0x20
    80003dce:	9281                	srli	a3,a3,0x20
    80003dd0:	068a                	slli	a3,a3,0x2
    80003dd2:	0001d617          	auipc	a2,0x1d
    80003dd6:	4d260613          	addi	a2,a2,1234 # 800212a4 <log+0x34>
    80003dda:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ddc:	4390                	lw	a2,0(a5)
    80003dde:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003de0:	0791                	addi	a5,a5,4
    80003de2:	0711                	addi	a4,a4,4
    80003de4:	fed79ce3          	bne	a5,a3,80003ddc <write_head+0x4e>
  }
  bwrite(buf);
    80003de8:	8526                	mv	a0,s1
    80003dea:	fffff097          	auipc	ra,0xfffff
    80003dee:	0a4080e7          	jalr	164(ra) # 80002e8e <bwrite>
  brelse(buf);
    80003df2:	8526                	mv	a0,s1
    80003df4:	fffff097          	auipc	ra,0xfffff
    80003df8:	0d8080e7          	jalr	216(ra) # 80002ecc <brelse>
}
    80003dfc:	60e2                	ld	ra,24(sp)
    80003dfe:	6442                	ld	s0,16(sp)
    80003e00:	64a2                	ld	s1,8(sp)
    80003e02:	6902                	ld	s2,0(sp)
    80003e04:	6105                	addi	sp,sp,32
    80003e06:	8082                	ret

0000000080003e08 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e08:	0001d797          	auipc	a5,0x1d
    80003e0c:	4947a783          	lw	a5,1172(a5) # 8002129c <log+0x2c>
    80003e10:	0af05d63          	blez	a5,80003eca <install_trans+0xc2>
{
    80003e14:	7139                	addi	sp,sp,-64
    80003e16:	fc06                	sd	ra,56(sp)
    80003e18:	f822                	sd	s0,48(sp)
    80003e1a:	f426                	sd	s1,40(sp)
    80003e1c:	f04a                	sd	s2,32(sp)
    80003e1e:	ec4e                	sd	s3,24(sp)
    80003e20:	e852                	sd	s4,16(sp)
    80003e22:	e456                	sd	s5,8(sp)
    80003e24:	e05a                	sd	s6,0(sp)
    80003e26:	0080                	addi	s0,sp,64
    80003e28:	8b2a                	mv	s6,a0
    80003e2a:	0001da97          	auipc	s5,0x1d
    80003e2e:	476a8a93          	addi	s5,s5,1142 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e32:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e34:	0001d997          	auipc	s3,0x1d
    80003e38:	43c98993          	addi	s3,s3,1084 # 80021270 <log>
    80003e3c:	a00d                	j	80003e5e <install_trans+0x56>
    brelse(lbuf);
    80003e3e:	854a                	mv	a0,s2
    80003e40:	fffff097          	auipc	ra,0xfffff
    80003e44:	08c080e7          	jalr	140(ra) # 80002ecc <brelse>
    brelse(dbuf);
    80003e48:	8526                	mv	a0,s1
    80003e4a:	fffff097          	auipc	ra,0xfffff
    80003e4e:	082080e7          	jalr	130(ra) # 80002ecc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e52:	2a05                	addiw	s4,s4,1
    80003e54:	0a91                	addi	s5,s5,4
    80003e56:	02c9a783          	lw	a5,44(s3)
    80003e5a:	04fa5e63          	bge	s4,a5,80003eb6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e5e:	0189a583          	lw	a1,24(s3)
    80003e62:	014585bb          	addw	a1,a1,s4
    80003e66:	2585                	addiw	a1,a1,1
    80003e68:	0289a503          	lw	a0,40(s3)
    80003e6c:	fffff097          	auipc	ra,0xfffff
    80003e70:	f30080e7          	jalr	-208(ra) # 80002d9c <bread>
    80003e74:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003e76:	000aa583          	lw	a1,0(s5)
    80003e7a:	0289a503          	lw	a0,40(s3)
    80003e7e:	fffff097          	auipc	ra,0xfffff
    80003e82:	f1e080e7          	jalr	-226(ra) # 80002d9c <bread>
    80003e86:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003e88:	40000613          	li	a2,1024
    80003e8c:	05890593          	addi	a1,s2,88
    80003e90:	05850513          	addi	a0,a0,88
    80003e94:	ffffd097          	auipc	ra,0xffffd
    80003e98:	e86080e7          	jalr	-378(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80003e9c:	8526                	mv	a0,s1
    80003e9e:	fffff097          	auipc	ra,0xfffff
    80003ea2:	ff0080e7          	jalr	-16(ra) # 80002e8e <bwrite>
    if(recovering == 0)
    80003ea6:	f80b1ce3          	bnez	s6,80003e3e <install_trans+0x36>
      bunpin(dbuf);
    80003eaa:	8526                	mv	a0,s1
    80003eac:	fffff097          	auipc	ra,0xfffff
    80003eb0:	0fa080e7          	jalr	250(ra) # 80002fa6 <bunpin>
    80003eb4:	b769                	j	80003e3e <install_trans+0x36>
}
    80003eb6:	70e2                	ld	ra,56(sp)
    80003eb8:	7442                	ld	s0,48(sp)
    80003eba:	74a2                	ld	s1,40(sp)
    80003ebc:	7902                	ld	s2,32(sp)
    80003ebe:	69e2                	ld	s3,24(sp)
    80003ec0:	6a42                	ld	s4,16(sp)
    80003ec2:	6aa2                	ld	s5,8(sp)
    80003ec4:	6b02                	ld	s6,0(sp)
    80003ec6:	6121                	addi	sp,sp,64
    80003ec8:	8082                	ret
    80003eca:	8082                	ret

0000000080003ecc <initlog>:
{
    80003ecc:	7179                	addi	sp,sp,-48
    80003ece:	f406                	sd	ra,40(sp)
    80003ed0:	f022                	sd	s0,32(sp)
    80003ed2:	ec26                	sd	s1,24(sp)
    80003ed4:	e84a                	sd	s2,16(sp)
    80003ed6:	e44e                	sd	s3,8(sp)
    80003ed8:	1800                	addi	s0,sp,48
    80003eda:	892a                	mv	s2,a0
    80003edc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003ede:	0001d497          	auipc	s1,0x1d
    80003ee2:	39248493          	addi	s1,s1,914 # 80021270 <log>
    80003ee6:	00004597          	auipc	a1,0x4
    80003eea:	72258593          	addi	a1,a1,1826 # 80008608 <syscalls+0x1d8>
    80003eee:	8526                	mv	a0,s1
    80003ef0:	ffffd097          	auipc	ra,0xffffd
    80003ef4:	c42080e7          	jalr	-958(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80003ef8:	0149a583          	lw	a1,20(s3)
    80003efc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003efe:	0109a783          	lw	a5,16(s3)
    80003f02:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f04:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f08:	854a                	mv	a0,s2
    80003f0a:	fffff097          	auipc	ra,0xfffff
    80003f0e:	e92080e7          	jalr	-366(ra) # 80002d9c <bread>
  log.lh.n = lh->n;
    80003f12:	4d34                	lw	a3,88(a0)
    80003f14:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f16:	02d05563          	blez	a3,80003f40 <initlog+0x74>
    80003f1a:	05c50793          	addi	a5,a0,92
    80003f1e:	0001d717          	auipc	a4,0x1d
    80003f22:	38270713          	addi	a4,a4,898 # 800212a0 <log+0x30>
    80003f26:	36fd                	addiw	a3,a3,-1
    80003f28:	1682                	slli	a3,a3,0x20
    80003f2a:	9281                	srli	a3,a3,0x20
    80003f2c:	068a                	slli	a3,a3,0x2
    80003f2e:	06050613          	addi	a2,a0,96
    80003f32:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003f34:	4390                	lw	a2,0(a5)
    80003f36:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f38:	0791                	addi	a5,a5,4
    80003f3a:	0711                	addi	a4,a4,4
    80003f3c:	fed79ce3          	bne	a5,a3,80003f34 <initlog+0x68>
  brelse(buf);
    80003f40:	fffff097          	auipc	ra,0xfffff
    80003f44:	f8c080e7          	jalr	-116(ra) # 80002ecc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f48:	4505                	li	a0,1
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	ebe080e7          	jalr	-322(ra) # 80003e08 <install_trans>
  log.lh.n = 0;
    80003f52:	0001d797          	auipc	a5,0x1d
    80003f56:	3407a523          	sw	zero,842(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	e34080e7          	jalr	-460(ra) # 80003d8e <write_head>
}
    80003f62:	70a2                	ld	ra,40(sp)
    80003f64:	7402                	ld	s0,32(sp)
    80003f66:	64e2                	ld	s1,24(sp)
    80003f68:	6942                	ld	s2,16(sp)
    80003f6a:	69a2                	ld	s3,8(sp)
    80003f6c:	6145                	addi	sp,sp,48
    80003f6e:	8082                	ret

0000000080003f70 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003f70:	1101                	addi	sp,sp,-32
    80003f72:	ec06                	sd	ra,24(sp)
    80003f74:	e822                	sd	s0,16(sp)
    80003f76:	e426                	sd	s1,8(sp)
    80003f78:	e04a                	sd	s2,0(sp)
    80003f7a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003f7c:	0001d517          	auipc	a0,0x1d
    80003f80:	2f450513          	addi	a0,a0,756 # 80021270 <log>
    80003f84:	ffffd097          	auipc	ra,0xffffd
    80003f88:	c3e080e7          	jalr	-962(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80003f8c:	0001d497          	auipc	s1,0x1d
    80003f90:	2e448493          	addi	s1,s1,740 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003f94:	4979                	li	s2,30
    80003f96:	a039                	j	80003fa4 <begin_op+0x34>
      sleep(&log, &log.lock);
    80003f98:	85a6                	mv	a1,s1
    80003f9a:	8526                	mv	a0,s1
    80003f9c:	ffffe097          	auipc	ra,0xffffe
    80003fa0:	0a2080e7          	jalr	162(ra) # 8000203e <sleep>
    if(log.committing){
    80003fa4:	50dc                	lw	a5,36(s1)
    80003fa6:	fbed                	bnez	a5,80003f98 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fa8:	509c                	lw	a5,32(s1)
    80003faa:	0017871b          	addiw	a4,a5,1
    80003fae:	0007069b          	sext.w	a3,a4
    80003fb2:	0027179b          	slliw	a5,a4,0x2
    80003fb6:	9fb9                	addw	a5,a5,a4
    80003fb8:	0017979b          	slliw	a5,a5,0x1
    80003fbc:	54d8                	lw	a4,44(s1)
    80003fbe:	9fb9                	addw	a5,a5,a4
    80003fc0:	00f95963          	bge	s2,a5,80003fd2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003fc4:	85a6                	mv	a1,s1
    80003fc6:	8526                	mv	a0,s1
    80003fc8:	ffffe097          	auipc	ra,0xffffe
    80003fcc:	076080e7          	jalr	118(ra) # 8000203e <sleep>
    80003fd0:	bfd1                	j	80003fa4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80003fd2:	0001d517          	auipc	a0,0x1d
    80003fd6:	29e50513          	addi	a0,a0,670 # 80021270 <log>
    80003fda:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80003fdc:	ffffd097          	auipc	ra,0xffffd
    80003fe0:	c9a080e7          	jalr	-870(ra) # 80000c76 <release>
      break;
    }
  }
}
    80003fe4:	60e2                	ld	ra,24(sp)
    80003fe6:	6442                	ld	s0,16(sp)
    80003fe8:	64a2                	ld	s1,8(sp)
    80003fea:	6902                	ld	s2,0(sp)
    80003fec:	6105                	addi	sp,sp,32
    80003fee:	8082                	ret

0000000080003ff0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003ff0:	7139                	addi	sp,sp,-64
    80003ff2:	fc06                	sd	ra,56(sp)
    80003ff4:	f822                	sd	s0,48(sp)
    80003ff6:	f426                	sd	s1,40(sp)
    80003ff8:	f04a                	sd	s2,32(sp)
    80003ffa:	ec4e                	sd	s3,24(sp)
    80003ffc:	e852                	sd	s4,16(sp)
    80003ffe:	e456                	sd	s5,8(sp)
    80004000:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004002:	0001d497          	auipc	s1,0x1d
    80004006:	26e48493          	addi	s1,s1,622 # 80021270 <log>
    8000400a:	8526                	mv	a0,s1
    8000400c:	ffffd097          	auipc	ra,0xffffd
    80004010:	bb6080e7          	jalr	-1098(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004014:	509c                	lw	a5,32(s1)
    80004016:	37fd                	addiw	a5,a5,-1
    80004018:	0007891b          	sext.w	s2,a5
    8000401c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000401e:	50dc                	lw	a5,36(s1)
    80004020:	e7b9                	bnez	a5,8000406e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004022:	04091e63          	bnez	s2,8000407e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004026:	0001d497          	auipc	s1,0x1d
    8000402a:	24a48493          	addi	s1,s1,586 # 80021270 <log>
    8000402e:	4785                	li	a5,1
    80004030:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004032:	8526                	mv	a0,s1
    80004034:	ffffd097          	auipc	ra,0xffffd
    80004038:	c42080e7          	jalr	-958(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000403c:	54dc                	lw	a5,44(s1)
    8000403e:	06f04763          	bgtz	a5,800040ac <end_op+0xbc>
    acquire(&log.lock);
    80004042:	0001d497          	auipc	s1,0x1d
    80004046:	22e48493          	addi	s1,s1,558 # 80021270 <log>
    8000404a:	8526                	mv	a0,s1
    8000404c:	ffffd097          	auipc	ra,0xffffd
    80004050:	b76080e7          	jalr	-1162(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004054:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004058:	8526                	mv	a0,s1
    8000405a:	ffffe097          	auipc	ra,0xffffe
    8000405e:	170080e7          	jalr	368(ra) # 800021ca <wakeup>
    release(&log.lock);
    80004062:	8526                	mv	a0,s1
    80004064:	ffffd097          	auipc	ra,0xffffd
    80004068:	c12080e7          	jalr	-1006(ra) # 80000c76 <release>
}
    8000406c:	a03d                	j	8000409a <end_op+0xaa>
    panic("log.committing");
    8000406e:	00004517          	auipc	a0,0x4
    80004072:	5a250513          	addi	a0,a0,1442 # 80008610 <syscalls+0x1e0>
    80004076:	ffffc097          	auipc	ra,0xffffc
    8000407a:	4b4080e7          	jalr	1204(ra) # 8000052a <panic>
    wakeup(&log);
    8000407e:	0001d497          	auipc	s1,0x1d
    80004082:	1f248493          	addi	s1,s1,498 # 80021270 <log>
    80004086:	8526                	mv	a0,s1
    80004088:	ffffe097          	auipc	ra,0xffffe
    8000408c:	142080e7          	jalr	322(ra) # 800021ca <wakeup>
  release(&log.lock);
    80004090:	8526                	mv	a0,s1
    80004092:	ffffd097          	auipc	ra,0xffffd
    80004096:	be4080e7          	jalr	-1052(ra) # 80000c76 <release>
}
    8000409a:	70e2                	ld	ra,56(sp)
    8000409c:	7442                	ld	s0,48(sp)
    8000409e:	74a2                	ld	s1,40(sp)
    800040a0:	7902                	ld	s2,32(sp)
    800040a2:	69e2                	ld	s3,24(sp)
    800040a4:	6a42                	ld	s4,16(sp)
    800040a6:	6aa2                	ld	s5,8(sp)
    800040a8:	6121                	addi	sp,sp,64
    800040aa:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ac:	0001da97          	auipc	s5,0x1d
    800040b0:	1f4a8a93          	addi	s5,s5,500 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800040b4:	0001da17          	auipc	s4,0x1d
    800040b8:	1bca0a13          	addi	s4,s4,444 # 80021270 <log>
    800040bc:	018a2583          	lw	a1,24(s4)
    800040c0:	012585bb          	addw	a1,a1,s2
    800040c4:	2585                	addiw	a1,a1,1
    800040c6:	028a2503          	lw	a0,40(s4)
    800040ca:	fffff097          	auipc	ra,0xfffff
    800040ce:	cd2080e7          	jalr	-814(ra) # 80002d9c <bread>
    800040d2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800040d4:	000aa583          	lw	a1,0(s5)
    800040d8:	028a2503          	lw	a0,40(s4)
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	cc0080e7          	jalr	-832(ra) # 80002d9c <bread>
    800040e4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800040e6:	40000613          	li	a2,1024
    800040ea:	05850593          	addi	a1,a0,88
    800040ee:	05848513          	addi	a0,s1,88
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	c28080e7          	jalr	-984(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    800040fa:	8526                	mv	a0,s1
    800040fc:	fffff097          	auipc	ra,0xfffff
    80004100:	d92080e7          	jalr	-622(ra) # 80002e8e <bwrite>
    brelse(from);
    80004104:	854e                	mv	a0,s3
    80004106:	fffff097          	auipc	ra,0xfffff
    8000410a:	dc6080e7          	jalr	-570(ra) # 80002ecc <brelse>
    brelse(to);
    8000410e:	8526                	mv	a0,s1
    80004110:	fffff097          	auipc	ra,0xfffff
    80004114:	dbc080e7          	jalr	-580(ra) # 80002ecc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004118:	2905                	addiw	s2,s2,1
    8000411a:	0a91                	addi	s5,s5,4
    8000411c:	02ca2783          	lw	a5,44(s4)
    80004120:	f8f94ee3          	blt	s2,a5,800040bc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004124:	00000097          	auipc	ra,0x0
    80004128:	c6a080e7          	jalr	-918(ra) # 80003d8e <write_head>
    install_trans(0); // Now install writes to home locations
    8000412c:	4501                	li	a0,0
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	cda080e7          	jalr	-806(ra) # 80003e08 <install_trans>
    log.lh.n = 0;
    80004136:	0001d797          	auipc	a5,0x1d
    8000413a:	1607a323          	sw	zero,358(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000413e:	00000097          	auipc	ra,0x0
    80004142:	c50080e7          	jalr	-944(ra) # 80003d8e <write_head>
    80004146:	bdf5                	j	80004042 <end_op+0x52>

0000000080004148 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004148:	1101                	addi	sp,sp,-32
    8000414a:	ec06                	sd	ra,24(sp)
    8000414c:	e822                	sd	s0,16(sp)
    8000414e:	e426                	sd	s1,8(sp)
    80004150:	e04a                	sd	s2,0(sp)
    80004152:	1000                	addi	s0,sp,32
    80004154:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004156:	0001d917          	auipc	s2,0x1d
    8000415a:	11a90913          	addi	s2,s2,282 # 80021270 <log>
    8000415e:	854a                	mv	a0,s2
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	a62080e7          	jalr	-1438(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004168:	02c92603          	lw	a2,44(s2)
    8000416c:	47f5                	li	a5,29
    8000416e:	06c7c563          	blt	a5,a2,800041d8 <log_write+0x90>
    80004172:	0001d797          	auipc	a5,0x1d
    80004176:	11a7a783          	lw	a5,282(a5) # 8002128c <log+0x1c>
    8000417a:	37fd                	addiw	a5,a5,-1
    8000417c:	04f65e63          	bge	a2,a5,800041d8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004180:	0001d797          	auipc	a5,0x1d
    80004184:	1107a783          	lw	a5,272(a5) # 80021290 <log+0x20>
    80004188:	06f05063          	blez	a5,800041e8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000418c:	4781                	li	a5,0
    8000418e:	06c05563          	blez	a2,800041f8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004192:	44cc                	lw	a1,12(s1)
    80004194:	0001d717          	auipc	a4,0x1d
    80004198:	10c70713          	addi	a4,a4,268 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000419c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000419e:	4314                	lw	a3,0(a4)
    800041a0:	04b68c63          	beq	a3,a1,800041f8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800041a4:	2785                	addiw	a5,a5,1
    800041a6:	0711                	addi	a4,a4,4
    800041a8:	fef61be3          	bne	a2,a5,8000419e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800041ac:	0621                	addi	a2,a2,8
    800041ae:	060a                	slli	a2,a2,0x2
    800041b0:	0001d797          	auipc	a5,0x1d
    800041b4:	0c078793          	addi	a5,a5,192 # 80021270 <log>
    800041b8:	963e                	add	a2,a2,a5
    800041ba:	44dc                	lw	a5,12(s1)
    800041bc:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800041be:	8526                	mv	a0,s1
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	daa080e7          	jalr	-598(ra) # 80002f6a <bpin>
    log.lh.n++;
    800041c8:	0001d717          	auipc	a4,0x1d
    800041cc:	0a870713          	addi	a4,a4,168 # 80021270 <log>
    800041d0:	575c                	lw	a5,44(a4)
    800041d2:	2785                	addiw	a5,a5,1
    800041d4:	d75c                	sw	a5,44(a4)
    800041d6:	a835                	j	80004212 <log_write+0xca>
    panic("too big a transaction");
    800041d8:	00004517          	auipc	a0,0x4
    800041dc:	44850513          	addi	a0,a0,1096 # 80008620 <syscalls+0x1f0>
    800041e0:	ffffc097          	auipc	ra,0xffffc
    800041e4:	34a080e7          	jalr	842(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    800041e8:	00004517          	auipc	a0,0x4
    800041ec:	45050513          	addi	a0,a0,1104 # 80008638 <syscalls+0x208>
    800041f0:	ffffc097          	auipc	ra,0xffffc
    800041f4:	33a080e7          	jalr	826(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    800041f8:	00878713          	addi	a4,a5,8
    800041fc:	00271693          	slli	a3,a4,0x2
    80004200:	0001d717          	auipc	a4,0x1d
    80004204:	07070713          	addi	a4,a4,112 # 80021270 <log>
    80004208:	9736                	add	a4,a4,a3
    8000420a:	44d4                	lw	a3,12(s1)
    8000420c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000420e:	faf608e3          	beq	a2,a5,800041be <log_write+0x76>
  }
  release(&log.lock);
    80004212:	0001d517          	auipc	a0,0x1d
    80004216:	05e50513          	addi	a0,a0,94 # 80021270 <log>
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>
}
    80004222:	60e2                	ld	ra,24(sp)
    80004224:	6442                	ld	s0,16(sp)
    80004226:	64a2                	ld	s1,8(sp)
    80004228:	6902                	ld	s2,0(sp)
    8000422a:	6105                	addi	sp,sp,32
    8000422c:	8082                	ret

000000008000422e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000422e:	1101                	addi	sp,sp,-32
    80004230:	ec06                	sd	ra,24(sp)
    80004232:	e822                	sd	s0,16(sp)
    80004234:	e426                	sd	s1,8(sp)
    80004236:	e04a                	sd	s2,0(sp)
    80004238:	1000                	addi	s0,sp,32
    8000423a:	84aa                	mv	s1,a0
    8000423c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000423e:	00004597          	auipc	a1,0x4
    80004242:	41a58593          	addi	a1,a1,1050 # 80008658 <syscalls+0x228>
    80004246:	0521                	addi	a0,a0,8
    80004248:	ffffd097          	auipc	ra,0xffffd
    8000424c:	8ea080e7          	jalr	-1814(ra) # 80000b32 <initlock>
  lk->name = name;
    80004250:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004254:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004258:	0204a423          	sw	zero,40(s1)
}
    8000425c:	60e2                	ld	ra,24(sp)
    8000425e:	6442                	ld	s0,16(sp)
    80004260:	64a2                	ld	s1,8(sp)
    80004262:	6902                	ld	s2,0(sp)
    80004264:	6105                	addi	sp,sp,32
    80004266:	8082                	ret

0000000080004268 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004268:	1101                	addi	sp,sp,-32
    8000426a:	ec06                	sd	ra,24(sp)
    8000426c:	e822                	sd	s0,16(sp)
    8000426e:	e426                	sd	s1,8(sp)
    80004270:	e04a                	sd	s2,0(sp)
    80004272:	1000                	addi	s0,sp,32
    80004274:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004276:	00850913          	addi	s2,a0,8
    8000427a:	854a                	mv	a0,s2
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	946080e7          	jalr	-1722(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004284:	409c                	lw	a5,0(s1)
    80004286:	cb89                	beqz	a5,80004298 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004288:	85ca                	mv	a1,s2
    8000428a:	8526                	mv	a0,s1
    8000428c:	ffffe097          	auipc	ra,0xffffe
    80004290:	db2080e7          	jalr	-590(ra) # 8000203e <sleep>
  while (lk->locked) {
    80004294:	409c                	lw	a5,0(s1)
    80004296:	fbed                	bnez	a5,80004288 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004298:	4785                	li	a5,1
    8000429a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000429c:	ffffd097          	auipc	ra,0xffffd
    800042a0:	6e2080e7          	jalr	1762(ra) # 8000197e <myproc>
    800042a4:	591c                	lw	a5,48(a0)
    800042a6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042a8:	854a                	mv	a0,s2
    800042aa:	ffffd097          	auipc	ra,0xffffd
    800042ae:	9cc080e7          	jalr	-1588(ra) # 80000c76 <release>
}
    800042b2:	60e2                	ld	ra,24(sp)
    800042b4:	6442                	ld	s0,16(sp)
    800042b6:	64a2                	ld	s1,8(sp)
    800042b8:	6902                	ld	s2,0(sp)
    800042ba:	6105                	addi	sp,sp,32
    800042bc:	8082                	ret

00000000800042be <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800042be:	1101                	addi	sp,sp,-32
    800042c0:	ec06                	sd	ra,24(sp)
    800042c2:	e822                	sd	s0,16(sp)
    800042c4:	e426                	sd	s1,8(sp)
    800042c6:	e04a                	sd	s2,0(sp)
    800042c8:	1000                	addi	s0,sp,32
    800042ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042cc:	00850913          	addi	s2,a0,8
    800042d0:	854a                	mv	a0,s2
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	8f0080e7          	jalr	-1808(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    800042da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042de:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800042e2:	8526                	mv	a0,s1
    800042e4:	ffffe097          	auipc	ra,0xffffe
    800042e8:	ee6080e7          	jalr	-282(ra) # 800021ca <wakeup>
  release(&lk->lk);
    800042ec:	854a                	mv	a0,s2
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800042f6:	60e2                	ld	ra,24(sp)
    800042f8:	6442                	ld	s0,16(sp)
    800042fa:	64a2                	ld	s1,8(sp)
    800042fc:	6902                	ld	s2,0(sp)
    800042fe:	6105                	addi	sp,sp,32
    80004300:	8082                	ret

0000000080004302 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004302:	7179                	addi	sp,sp,-48
    80004304:	f406                	sd	ra,40(sp)
    80004306:	f022                	sd	s0,32(sp)
    80004308:	ec26                	sd	s1,24(sp)
    8000430a:	e84a                	sd	s2,16(sp)
    8000430c:	e44e                	sd	s3,8(sp)
    8000430e:	1800                	addi	s0,sp,48
    80004310:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004312:	00850913          	addi	s2,a0,8
    80004316:	854a                	mv	a0,s2
    80004318:	ffffd097          	auipc	ra,0xffffd
    8000431c:	8aa080e7          	jalr	-1878(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004320:	409c                	lw	a5,0(s1)
    80004322:	ef99                	bnez	a5,80004340 <holdingsleep+0x3e>
    80004324:	4481                	li	s1,0
  release(&lk->lk);
    80004326:	854a                	mv	a0,s2
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	94e080e7          	jalr	-1714(ra) # 80000c76 <release>
  return r;
}
    80004330:	8526                	mv	a0,s1
    80004332:	70a2                	ld	ra,40(sp)
    80004334:	7402                	ld	s0,32(sp)
    80004336:	64e2                	ld	s1,24(sp)
    80004338:	6942                	ld	s2,16(sp)
    8000433a:	69a2                	ld	s3,8(sp)
    8000433c:	6145                	addi	sp,sp,48
    8000433e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004340:	0284a983          	lw	s3,40(s1)
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	63a080e7          	jalr	1594(ra) # 8000197e <myproc>
    8000434c:	5904                	lw	s1,48(a0)
    8000434e:	413484b3          	sub	s1,s1,s3
    80004352:	0014b493          	seqz	s1,s1
    80004356:	bfc1                	j	80004326 <holdingsleep+0x24>

0000000080004358 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004358:	1141                	addi	sp,sp,-16
    8000435a:	e406                	sd	ra,8(sp)
    8000435c:	e022                	sd	s0,0(sp)
    8000435e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004360:	00004597          	auipc	a1,0x4
    80004364:	30858593          	addi	a1,a1,776 # 80008668 <syscalls+0x238>
    80004368:	0001d517          	auipc	a0,0x1d
    8000436c:	05050513          	addi	a0,a0,80 # 800213b8 <ftable>
    80004370:	ffffc097          	auipc	ra,0xffffc
    80004374:	7c2080e7          	jalr	1986(ra) # 80000b32 <initlock>
}
    80004378:	60a2                	ld	ra,8(sp)
    8000437a:	6402                	ld	s0,0(sp)
    8000437c:	0141                	addi	sp,sp,16
    8000437e:	8082                	ret

0000000080004380 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004380:	1101                	addi	sp,sp,-32
    80004382:	ec06                	sd	ra,24(sp)
    80004384:	e822                	sd	s0,16(sp)
    80004386:	e426                	sd	s1,8(sp)
    80004388:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000438a:	0001d517          	auipc	a0,0x1d
    8000438e:	02e50513          	addi	a0,a0,46 # 800213b8 <ftable>
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	830080e7          	jalr	-2000(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000439a:	0001d497          	auipc	s1,0x1d
    8000439e:	03648493          	addi	s1,s1,54 # 800213d0 <ftable+0x18>
    800043a2:	0001e717          	auipc	a4,0x1e
    800043a6:	fce70713          	addi	a4,a4,-50 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800043aa:	40dc                	lw	a5,4(s1)
    800043ac:	cf99                	beqz	a5,800043ca <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043ae:	02848493          	addi	s1,s1,40
    800043b2:	fee49ce3          	bne	s1,a4,800043aa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800043b6:	0001d517          	auipc	a0,0x1d
    800043ba:	00250513          	addi	a0,a0,2 # 800213b8 <ftable>
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	8b8080e7          	jalr	-1864(ra) # 80000c76 <release>
  return 0;
    800043c6:	4481                	li	s1,0
    800043c8:	a819                	j	800043de <filealloc+0x5e>
      f->ref = 1;
    800043ca:	4785                	li	a5,1
    800043cc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800043ce:	0001d517          	auipc	a0,0x1d
    800043d2:	fea50513          	addi	a0,a0,-22 # 800213b8 <ftable>
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	8a0080e7          	jalr	-1888(ra) # 80000c76 <release>
}
    800043de:	8526                	mv	a0,s1
    800043e0:	60e2                	ld	ra,24(sp)
    800043e2:	6442                	ld	s0,16(sp)
    800043e4:	64a2                	ld	s1,8(sp)
    800043e6:	6105                	addi	sp,sp,32
    800043e8:	8082                	ret

00000000800043ea <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800043ea:	1101                	addi	sp,sp,-32
    800043ec:	ec06                	sd	ra,24(sp)
    800043ee:	e822                	sd	s0,16(sp)
    800043f0:	e426                	sd	s1,8(sp)
    800043f2:	1000                	addi	s0,sp,32
    800043f4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800043f6:	0001d517          	auipc	a0,0x1d
    800043fa:	fc250513          	addi	a0,a0,-62 # 800213b8 <ftable>
    800043fe:	ffffc097          	auipc	ra,0xffffc
    80004402:	7c4080e7          	jalr	1988(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004406:	40dc                	lw	a5,4(s1)
    80004408:	02f05263          	blez	a5,8000442c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000440c:	2785                	addiw	a5,a5,1
    8000440e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004410:	0001d517          	auipc	a0,0x1d
    80004414:	fa850513          	addi	a0,a0,-88 # 800213b8 <ftable>
    80004418:	ffffd097          	auipc	ra,0xffffd
    8000441c:	85e080e7          	jalr	-1954(ra) # 80000c76 <release>
  return f;
}
    80004420:	8526                	mv	a0,s1
    80004422:	60e2                	ld	ra,24(sp)
    80004424:	6442                	ld	s0,16(sp)
    80004426:	64a2                	ld	s1,8(sp)
    80004428:	6105                	addi	sp,sp,32
    8000442a:	8082                	ret
    panic("filedup");
    8000442c:	00004517          	auipc	a0,0x4
    80004430:	24450513          	addi	a0,a0,580 # 80008670 <syscalls+0x240>
    80004434:	ffffc097          	auipc	ra,0xffffc
    80004438:	0f6080e7          	jalr	246(ra) # 8000052a <panic>

000000008000443c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000443c:	7139                	addi	sp,sp,-64
    8000443e:	fc06                	sd	ra,56(sp)
    80004440:	f822                	sd	s0,48(sp)
    80004442:	f426                	sd	s1,40(sp)
    80004444:	f04a                	sd	s2,32(sp)
    80004446:	ec4e                	sd	s3,24(sp)
    80004448:	e852                	sd	s4,16(sp)
    8000444a:	e456                	sd	s5,8(sp)
    8000444c:	0080                	addi	s0,sp,64
    8000444e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004450:	0001d517          	auipc	a0,0x1d
    80004454:	f6850513          	addi	a0,a0,-152 # 800213b8 <ftable>
    80004458:	ffffc097          	auipc	ra,0xffffc
    8000445c:	76a080e7          	jalr	1898(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004460:	40dc                	lw	a5,4(s1)
    80004462:	06f05163          	blez	a5,800044c4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004466:	37fd                	addiw	a5,a5,-1
    80004468:	0007871b          	sext.w	a4,a5
    8000446c:	c0dc                	sw	a5,4(s1)
    8000446e:	06e04363          	bgtz	a4,800044d4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004472:	0004a903          	lw	s2,0(s1)
    80004476:	0094ca83          	lbu	s5,9(s1)
    8000447a:	0104ba03          	ld	s4,16(s1)
    8000447e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004482:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004486:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000448a:	0001d517          	auipc	a0,0x1d
    8000448e:	f2e50513          	addi	a0,a0,-210 # 800213b8 <ftable>
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	7e4080e7          	jalr	2020(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    8000449a:	4785                	li	a5,1
    8000449c:	04f90d63          	beq	s2,a5,800044f6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044a0:	3979                	addiw	s2,s2,-2
    800044a2:	4785                	li	a5,1
    800044a4:	0527e063          	bltu	a5,s2,800044e4 <fileclose+0xa8>
    begin_op();
    800044a8:	00000097          	auipc	ra,0x0
    800044ac:	ac8080e7          	jalr	-1336(ra) # 80003f70 <begin_op>
    iput(ff.ip);
    800044b0:	854e                	mv	a0,s3
    800044b2:	fffff097          	auipc	ra,0xfffff
    800044b6:	2a6080e7          	jalr	678(ra) # 80003758 <iput>
    end_op();
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	b36080e7          	jalr	-1226(ra) # 80003ff0 <end_op>
    800044c2:	a00d                	j	800044e4 <fileclose+0xa8>
    panic("fileclose");
    800044c4:	00004517          	auipc	a0,0x4
    800044c8:	1b450513          	addi	a0,a0,436 # 80008678 <syscalls+0x248>
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	05e080e7          	jalr	94(ra) # 8000052a <panic>
    release(&ftable.lock);
    800044d4:	0001d517          	auipc	a0,0x1d
    800044d8:	ee450513          	addi	a0,a0,-284 # 800213b8 <ftable>
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	79a080e7          	jalr	1946(ra) # 80000c76 <release>
  }
}
    800044e4:	70e2                	ld	ra,56(sp)
    800044e6:	7442                	ld	s0,48(sp)
    800044e8:	74a2                	ld	s1,40(sp)
    800044ea:	7902                	ld	s2,32(sp)
    800044ec:	69e2                	ld	s3,24(sp)
    800044ee:	6a42                	ld	s4,16(sp)
    800044f0:	6aa2                	ld	s5,8(sp)
    800044f2:	6121                	addi	sp,sp,64
    800044f4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800044f6:	85d6                	mv	a1,s5
    800044f8:	8552                	mv	a0,s4
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	34c080e7          	jalr	844(ra) # 80004846 <pipeclose>
    80004502:	b7cd                	j	800044e4 <fileclose+0xa8>

0000000080004504 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004504:	715d                	addi	sp,sp,-80
    80004506:	e486                	sd	ra,72(sp)
    80004508:	e0a2                	sd	s0,64(sp)
    8000450a:	fc26                	sd	s1,56(sp)
    8000450c:	f84a                	sd	s2,48(sp)
    8000450e:	f44e                	sd	s3,40(sp)
    80004510:	0880                	addi	s0,sp,80
    80004512:	84aa                	mv	s1,a0
    80004514:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004516:	ffffd097          	auipc	ra,0xffffd
    8000451a:	468080e7          	jalr	1128(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000451e:	409c                	lw	a5,0(s1)
    80004520:	37f9                	addiw	a5,a5,-2
    80004522:	4705                	li	a4,1
    80004524:	04f76763          	bltu	a4,a5,80004572 <filestat+0x6e>
    80004528:	892a                	mv	s2,a0
    ilock(f->ip);
    8000452a:	6c88                	ld	a0,24(s1)
    8000452c:	fffff097          	auipc	ra,0xfffff
    80004530:	072080e7          	jalr	114(ra) # 8000359e <ilock>
    stati(f->ip, &st);
    80004534:	fb840593          	addi	a1,s0,-72
    80004538:	6c88                	ld	a0,24(s1)
    8000453a:	fffff097          	auipc	ra,0xfffff
    8000453e:	2ee080e7          	jalr	750(ra) # 80003828 <stati>
    iunlock(f->ip);
    80004542:	6c88                	ld	a0,24(s1)
    80004544:	fffff097          	auipc	ra,0xfffff
    80004548:	11c080e7          	jalr	284(ra) # 80003660 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000454c:	46e1                	li	a3,24
    8000454e:	fb840613          	addi	a2,s0,-72
    80004552:	85ce                	mv	a1,s3
    80004554:	05093503          	ld	a0,80(s2)
    80004558:	ffffd097          	auipc	ra,0xffffd
    8000455c:	0e6080e7          	jalr	230(ra) # 8000163e <copyout>
    80004560:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004564:	60a6                	ld	ra,72(sp)
    80004566:	6406                	ld	s0,64(sp)
    80004568:	74e2                	ld	s1,56(sp)
    8000456a:	7942                	ld	s2,48(sp)
    8000456c:	79a2                	ld	s3,40(sp)
    8000456e:	6161                	addi	sp,sp,80
    80004570:	8082                	ret
  return -1;
    80004572:	557d                	li	a0,-1
    80004574:	bfc5                	j	80004564 <filestat+0x60>

0000000080004576 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004576:	7179                	addi	sp,sp,-48
    80004578:	f406                	sd	ra,40(sp)
    8000457a:	f022                	sd	s0,32(sp)
    8000457c:	ec26                	sd	s1,24(sp)
    8000457e:	e84a                	sd	s2,16(sp)
    80004580:	e44e                	sd	s3,8(sp)
    80004582:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004584:	00854783          	lbu	a5,8(a0)
    80004588:	c3d5                	beqz	a5,8000462c <fileread+0xb6>
    8000458a:	84aa                	mv	s1,a0
    8000458c:	89ae                	mv	s3,a1
    8000458e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004590:	411c                	lw	a5,0(a0)
    80004592:	4705                	li	a4,1
    80004594:	04e78963          	beq	a5,a4,800045e6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004598:	470d                	li	a4,3
    8000459a:	04e78d63          	beq	a5,a4,800045f4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000459e:	4709                	li	a4,2
    800045a0:	06e79e63          	bne	a5,a4,8000461c <fileread+0xa6>
    ilock(f->ip);
    800045a4:	6d08                	ld	a0,24(a0)
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	ff8080e7          	jalr	-8(ra) # 8000359e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800045ae:	874a                	mv	a4,s2
    800045b0:	5094                	lw	a3,32(s1)
    800045b2:	864e                	mv	a2,s3
    800045b4:	4585                	li	a1,1
    800045b6:	6c88                	ld	a0,24(s1)
    800045b8:	fffff097          	auipc	ra,0xfffff
    800045bc:	29a080e7          	jalr	666(ra) # 80003852 <readi>
    800045c0:	892a                	mv	s2,a0
    800045c2:	00a05563          	blez	a0,800045cc <fileread+0x56>
      f->off += r;
    800045c6:	509c                	lw	a5,32(s1)
    800045c8:	9fa9                	addw	a5,a5,a0
    800045ca:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800045cc:	6c88                	ld	a0,24(s1)
    800045ce:	fffff097          	auipc	ra,0xfffff
    800045d2:	092080e7          	jalr	146(ra) # 80003660 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800045d6:	854a                	mv	a0,s2
    800045d8:	70a2                	ld	ra,40(sp)
    800045da:	7402                	ld	s0,32(sp)
    800045dc:	64e2                	ld	s1,24(sp)
    800045de:	6942                	ld	s2,16(sp)
    800045e0:	69a2                	ld	s3,8(sp)
    800045e2:	6145                	addi	sp,sp,48
    800045e4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800045e6:	6908                	ld	a0,16(a0)
    800045e8:	00000097          	auipc	ra,0x0
    800045ec:	3c0080e7          	jalr	960(ra) # 800049a8 <piperead>
    800045f0:	892a                	mv	s2,a0
    800045f2:	b7d5                	j	800045d6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800045f4:	02451783          	lh	a5,36(a0)
    800045f8:	03079693          	slli	a3,a5,0x30
    800045fc:	92c1                	srli	a3,a3,0x30
    800045fe:	4725                	li	a4,9
    80004600:	02d76863          	bltu	a4,a3,80004630 <fileread+0xba>
    80004604:	0792                	slli	a5,a5,0x4
    80004606:	0001d717          	auipc	a4,0x1d
    8000460a:	d1270713          	addi	a4,a4,-750 # 80021318 <devsw>
    8000460e:	97ba                	add	a5,a5,a4
    80004610:	639c                	ld	a5,0(a5)
    80004612:	c38d                	beqz	a5,80004634 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004614:	4505                	li	a0,1
    80004616:	9782                	jalr	a5
    80004618:	892a                	mv	s2,a0
    8000461a:	bf75                	j	800045d6 <fileread+0x60>
    panic("fileread");
    8000461c:	00004517          	auipc	a0,0x4
    80004620:	06c50513          	addi	a0,a0,108 # 80008688 <syscalls+0x258>
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	f06080e7          	jalr	-250(ra) # 8000052a <panic>
    return -1;
    8000462c:	597d                	li	s2,-1
    8000462e:	b765                	j	800045d6 <fileread+0x60>
      return -1;
    80004630:	597d                	li	s2,-1
    80004632:	b755                	j	800045d6 <fileread+0x60>
    80004634:	597d                	li	s2,-1
    80004636:	b745                	j	800045d6 <fileread+0x60>

0000000080004638 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004638:	715d                	addi	sp,sp,-80
    8000463a:	e486                	sd	ra,72(sp)
    8000463c:	e0a2                	sd	s0,64(sp)
    8000463e:	fc26                	sd	s1,56(sp)
    80004640:	f84a                	sd	s2,48(sp)
    80004642:	f44e                	sd	s3,40(sp)
    80004644:	f052                	sd	s4,32(sp)
    80004646:	ec56                	sd	s5,24(sp)
    80004648:	e85a                	sd	s6,16(sp)
    8000464a:	e45e                	sd	s7,8(sp)
    8000464c:	e062                	sd	s8,0(sp)
    8000464e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004650:	00954783          	lbu	a5,9(a0)
    80004654:	10078663          	beqz	a5,80004760 <filewrite+0x128>
    80004658:	892a                	mv	s2,a0
    8000465a:	8aae                	mv	s5,a1
    8000465c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000465e:	411c                	lw	a5,0(a0)
    80004660:	4705                	li	a4,1
    80004662:	02e78263          	beq	a5,a4,80004686 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004666:	470d                	li	a4,3
    80004668:	02e78663          	beq	a5,a4,80004694 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000466c:	4709                	li	a4,2
    8000466e:	0ee79163          	bne	a5,a4,80004750 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004672:	0ac05d63          	blez	a2,8000472c <filewrite+0xf4>
    int i = 0;
    80004676:	4981                	li	s3,0
    80004678:	6b05                	lui	s6,0x1
    8000467a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000467e:	6b85                	lui	s7,0x1
    80004680:	c00b8b9b          	addiw	s7,s7,-1024
    80004684:	a861                	j	8000471c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004686:	6908                	ld	a0,16(a0)
    80004688:	00000097          	auipc	ra,0x0
    8000468c:	22e080e7          	jalr	558(ra) # 800048b6 <pipewrite>
    80004690:	8a2a                	mv	s4,a0
    80004692:	a045                	j	80004732 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004694:	02451783          	lh	a5,36(a0)
    80004698:	03079693          	slli	a3,a5,0x30
    8000469c:	92c1                	srli	a3,a3,0x30
    8000469e:	4725                	li	a4,9
    800046a0:	0cd76263          	bltu	a4,a3,80004764 <filewrite+0x12c>
    800046a4:	0792                	slli	a5,a5,0x4
    800046a6:	0001d717          	auipc	a4,0x1d
    800046aa:	c7270713          	addi	a4,a4,-910 # 80021318 <devsw>
    800046ae:	97ba                	add	a5,a5,a4
    800046b0:	679c                	ld	a5,8(a5)
    800046b2:	cbdd                	beqz	a5,80004768 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800046b4:	4505                	li	a0,1
    800046b6:	9782                	jalr	a5
    800046b8:	8a2a                	mv	s4,a0
    800046ba:	a8a5                	j	80004732 <filewrite+0xfa>
    800046bc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800046c0:	00000097          	auipc	ra,0x0
    800046c4:	8b0080e7          	jalr	-1872(ra) # 80003f70 <begin_op>
      ilock(f->ip);
    800046c8:	01893503          	ld	a0,24(s2)
    800046cc:	fffff097          	auipc	ra,0xfffff
    800046d0:	ed2080e7          	jalr	-302(ra) # 8000359e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800046d4:	8762                	mv	a4,s8
    800046d6:	02092683          	lw	a3,32(s2)
    800046da:	01598633          	add	a2,s3,s5
    800046de:	4585                	li	a1,1
    800046e0:	01893503          	ld	a0,24(s2)
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	266080e7          	jalr	614(ra) # 8000394a <writei>
    800046ec:	84aa                	mv	s1,a0
    800046ee:	00a05763          	blez	a0,800046fc <filewrite+0xc4>
        f->off += r;
    800046f2:	02092783          	lw	a5,32(s2)
    800046f6:	9fa9                	addw	a5,a5,a0
    800046f8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800046fc:	01893503          	ld	a0,24(s2)
    80004700:	fffff097          	auipc	ra,0xfffff
    80004704:	f60080e7          	jalr	-160(ra) # 80003660 <iunlock>
      end_op();
    80004708:	00000097          	auipc	ra,0x0
    8000470c:	8e8080e7          	jalr	-1816(ra) # 80003ff0 <end_op>

      if(r != n1){
    80004710:	009c1f63          	bne	s8,s1,8000472e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004714:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004718:	0149db63          	bge	s3,s4,8000472e <filewrite+0xf6>
      int n1 = n - i;
    8000471c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004720:	84be                	mv	s1,a5
    80004722:	2781                	sext.w	a5,a5
    80004724:	f8fb5ce3          	bge	s6,a5,800046bc <filewrite+0x84>
    80004728:	84de                	mv	s1,s7
    8000472a:	bf49                	j	800046bc <filewrite+0x84>
    int i = 0;
    8000472c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000472e:	013a1f63          	bne	s4,s3,8000474c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004732:	8552                	mv	a0,s4
    80004734:	60a6                	ld	ra,72(sp)
    80004736:	6406                	ld	s0,64(sp)
    80004738:	74e2                	ld	s1,56(sp)
    8000473a:	7942                	ld	s2,48(sp)
    8000473c:	79a2                	ld	s3,40(sp)
    8000473e:	7a02                	ld	s4,32(sp)
    80004740:	6ae2                	ld	s5,24(sp)
    80004742:	6b42                	ld	s6,16(sp)
    80004744:	6ba2                	ld	s7,8(sp)
    80004746:	6c02                	ld	s8,0(sp)
    80004748:	6161                	addi	sp,sp,80
    8000474a:	8082                	ret
    ret = (i == n ? n : -1);
    8000474c:	5a7d                	li	s4,-1
    8000474e:	b7d5                	j	80004732 <filewrite+0xfa>
    panic("filewrite");
    80004750:	00004517          	auipc	a0,0x4
    80004754:	f4850513          	addi	a0,a0,-184 # 80008698 <syscalls+0x268>
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	dd2080e7          	jalr	-558(ra) # 8000052a <panic>
    return -1;
    80004760:	5a7d                	li	s4,-1
    80004762:	bfc1                	j	80004732 <filewrite+0xfa>
      return -1;
    80004764:	5a7d                	li	s4,-1
    80004766:	b7f1                	j	80004732 <filewrite+0xfa>
    80004768:	5a7d                	li	s4,-1
    8000476a:	b7e1                	j	80004732 <filewrite+0xfa>

000000008000476c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000476c:	7179                	addi	sp,sp,-48
    8000476e:	f406                	sd	ra,40(sp)
    80004770:	f022                	sd	s0,32(sp)
    80004772:	ec26                	sd	s1,24(sp)
    80004774:	e84a                	sd	s2,16(sp)
    80004776:	e44e                	sd	s3,8(sp)
    80004778:	e052                	sd	s4,0(sp)
    8000477a:	1800                	addi	s0,sp,48
    8000477c:	84aa                	mv	s1,a0
    8000477e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004780:	0005b023          	sd	zero,0(a1)
    80004784:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	bf8080e7          	jalr	-1032(ra) # 80004380 <filealloc>
    80004790:	e088                	sd	a0,0(s1)
    80004792:	c551                	beqz	a0,8000481e <pipealloc+0xb2>
    80004794:	00000097          	auipc	ra,0x0
    80004798:	bec080e7          	jalr	-1044(ra) # 80004380 <filealloc>
    8000479c:	00aa3023          	sd	a0,0(s4)
    800047a0:	c92d                	beqz	a0,80004812 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	330080e7          	jalr	816(ra) # 80000ad2 <kalloc>
    800047aa:	892a                	mv	s2,a0
    800047ac:	c125                	beqz	a0,8000480c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800047ae:	4985                	li	s3,1
    800047b0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800047b4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800047b8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800047bc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800047c0:	00004597          	auipc	a1,0x4
    800047c4:	ee858593          	addi	a1,a1,-280 # 800086a8 <syscalls+0x278>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	36a080e7          	jalr	874(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800047d0:	609c                	ld	a5,0(s1)
    800047d2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800047d6:	609c                	ld	a5,0(s1)
    800047d8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800047dc:	609c                	ld	a5,0(s1)
    800047de:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800047e2:	609c                	ld	a5,0(s1)
    800047e4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800047e8:	000a3783          	ld	a5,0(s4)
    800047ec:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800047f0:	000a3783          	ld	a5,0(s4)
    800047f4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800047f8:	000a3783          	ld	a5,0(s4)
    800047fc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004800:	000a3783          	ld	a5,0(s4)
    80004804:	0127b823          	sd	s2,16(a5)
  return 0;
    80004808:	4501                	li	a0,0
    8000480a:	a025                	j	80004832 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000480c:	6088                	ld	a0,0(s1)
    8000480e:	e501                	bnez	a0,80004816 <pipealloc+0xaa>
    80004810:	a039                	j	8000481e <pipealloc+0xb2>
    80004812:	6088                	ld	a0,0(s1)
    80004814:	c51d                	beqz	a0,80004842 <pipealloc+0xd6>
    fileclose(*f0);
    80004816:	00000097          	auipc	ra,0x0
    8000481a:	c26080e7          	jalr	-986(ra) # 8000443c <fileclose>
  if(*f1)
    8000481e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004822:	557d                	li	a0,-1
  if(*f1)
    80004824:	c799                	beqz	a5,80004832 <pipealloc+0xc6>
    fileclose(*f1);
    80004826:	853e                	mv	a0,a5
    80004828:	00000097          	auipc	ra,0x0
    8000482c:	c14080e7          	jalr	-1004(ra) # 8000443c <fileclose>
  return -1;
    80004830:	557d                	li	a0,-1
}
    80004832:	70a2                	ld	ra,40(sp)
    80004834:	7402                	ld	s0,32(sp)
    80004836:	64e2                	ld	s1,24(sp)
    80004838:	6942                	ld	s2,16(sp)
    8000483a:	69a2                	ld	s3,8(sp)
    8000483c:	6a02                	ld	s4,0(sp)
    8000483e:	6145                	addi	sp,sp,48
    80004840:	8082                	ret
  return -1;
    80004842:	557d                	li	a0,-1
    80004844:	b7fd                	j	80004832 <pipealloc+0xc6>

0000000080004846 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004846:	1101                	addi	sp,sp,-32
    80004848:	ec06                	sd	ra,24(sp)
    8000484a:	e822                	sd	s0,16(sp)
    8000484c:	e426                	sd	s1,8(sp)
    8000484e:	e04a                	sd	s2,0(sp)
    80004850:	1000                	addi	s0,sp,32
    80004852:	84aa                	mv	s1,a0
    80004854:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	36c080e7          	jalr	876(ra) # 80000bc2 <acquire>
  if(writable){
    8000485e:	02090d63          	beqz	s2,80004898 <pipeclose+0x52>
    pi->writeopen = 0;
    80004862:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004866:	21848513          	addi	a0,s1,536
    8000486a:	ffffe097          	auipc	ra,0xffffe
    8000486e:	960080e7          	jalr	-1696(ra) # 800021ca <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004872:	2204b783          	ld	a5,544(s1)
    80004876:	eb95                	bnez	a5,800048aa <pipeclose+0x64>
    release(&pi->lock);
    80004878:	8526                	mv	a0,s1
    8000487a:	ffffc097          	auipc	ra,0xffffc
    8000487e:	3fc080e7          	jalr	1020(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004882:	8526                	mv	a0,s1
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	152080e7          	jalr	338(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    8000488c:	60e2                	ld	ra,24(sp)
    8000488e:	6442                	ld	s0,16(sp)
    80004890:	64a2                	ld	s1,8(sp)
    80004892:	6902                	ld	s2,0(sp)
    80004894:	6105                	addi	sp,sp,32
    80004896:	8082                	ret
    pi->readopen = 0;
    80004898:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000489c:	21c48513          	addi	a0,s1,540
    800048a0:	ffffe097          	auipc	ra,0xffffe
    800048a4:	92a080e7          	jalr	-1750(ra) # 800021ca <wakeup>
    800048a8:	b7e9                	j	80004872 <pipeclose+0x2c>
    release(&pi->lock);
    800048aa:	8526                	mv	a0,s1
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	3ca080e7          	jalr	970(ra) # 80000c76 <release>
}
    800048b4:	bfe1                	j	8000488c <pipeclose+0x46>

00000000800048b6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800048b6:	711d                	addi	sp,sp,-96
    800048b8:	ec86                	sd	ra,88(sp)
    800048ba:	e8a2                	sd	s0,80(sp)
    800048bc:	e4a6                	sd	s1,72(sp)
    800048be:	e0ca                	sd	s2,64(sp)
    800048c0:	fc4e                	sd	s3,56(sp)
    800048c2:	f852                	sd	s4,48(sp)
    800048c4:	f456                	sd	s5,40(sp)
    800048c6:	f05a                	sd	s6,32(sp)
    800048c8:	ec5e                	sd	s7,24(sp)
    800048ca:	e862                	sd	s8,16(sp)
    800048cc:	1080                	addi	s0,sp,96
    800048ce:	84aa                	mv	s1,a0
    800048d0:	8aae                	mv	s5,a1
    800048d2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800048d4:	ffffd097          	auipc	ra,0xffffd
    800048d8:	0aa080e7          	jalr	170(ra) # 8000197e <myproc>
    800048dc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800048de:	8526                	mv	a0,s1
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	2e2080e7          	jalr	738(ra) # 80000bc2 <acquire>
  while(i < n){
    800048e8:	0b405363          	blez	s4,8000498e <pipewrite+0xd8>
  int i = 0;
    800048ec:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800048ee:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800048f0:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800048f4:	21c48b93          	addi	s7,s1,540
    800048f8:	a089                	j	8000493a <pipewrite+0x84>
      release(&pi->lock);
    800048fa:	8526                	mv	a0,s1
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	37a080e7          	jalr	890(ra) # 80000c76 <release>
      return -1;
    80004904:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004906:	854a                	mv	a0,s2
    80004908:	60e6                	ld	ra,88(sp)
    8000490a:	6446                	ld	s0,80(sp)
    8000490c:	64a6                	ld	s1,72(sp)
    8000490e:	6906                	ld	s2,64(sp)
    80004910:	79e2                	ld	s3,56(sp)
    80004912:	7a42                	ld	s4,48(sp)
    80004914:	7aa2                	ld	s5,40(sp)
    80004916:	7b02                	ld	s6,32(sp)
    80004918:	6be2                	ld	s7,24(sp)
    8000491a:	6c42                	ld	s8,16(sp)
    8000491c:	6125                	addi	sp,sp,96
    8000491e:	8082                	ret
      wakeup(&pi->nread);
    80004920:	8562                	mv	a0,s8
    80004922:	ffffe097          	auipc	ra,0xffffe
    80004926:	8a8080e7          	jalr	-1880(ra) # 800021ca <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000492a:	85a6                	mv	a1,s1
    8000492c:	855e                	mv	a0,s7
    8000492e:	ffffd097          	auipc	ra,0xffffd
    80004932:	710080e7          	jalr	1808(ra) # 8000203e <sleep>
  while(i < n){
    80004936:	05495d63          	bge	s2,s4,80004990 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    8000493a:	2204a783          	lw	a5,544(s1)
    8000493e:	dfd5                	beqz	a5,800048fa <pipewrite+0x44>
    80004940:	0289a783          	lw	a5,40(s3)
    80004944:	fbdd                	bnez	a5,800048fa <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004946:	2184a783          	lw	a5,536(s1)
    8000494a:	21c4a703          	lw	a4,540(s1)
    8000494e:	2007879b          	addiw	a5,a5,512
    80004952:	fcf707e3          	beq	a4,a5,80004920 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004956:	4685                	li	a3,1
    80004958:	01590633          	add	a2,s2,s5
    8000495c:	faf40593          	addi	a1,s0,-81
    80004960:	0509b503          	ld	a0,80(s3)
    80004964:	ffffd097          	auipc	ra,0xffffd
    80004968:	d66080e7          	jalr	-666(ra) # 800016ca <copyin>
    8000496c:	03650263          	beq	a0,s6,80004990 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004970:	21c4a783          	lw	a5,540(s1)
    80004974:	0017871b          	addiw	a4,a5,1
    80004978:	20e4ae23          	sw	a4,540(s1)
    8000497c:	1ff7f793          	andi	a5,a5,511
    80004980:	97a6                	add	a5,a5,s1
    80004982:	faf44703          	lbu	a4,-81(s0)
    80004986:	00e78c23          	sb	a4,24(a5)
      i++;
    8000498a:	2905                	addiw	s2,s2,1
    8000498c:	b76d                	j	80004936 <pipewrite+0x80>
  int i = 0;
    8000498e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004990:	21848513          	addi	a0,s1,536
    80004994:	ffffe097          	auipc	ra,0xffffe
    80004998:	836080e7          	jalr	-1994(ra) # 800021ca <wakeup>
  release(&pi->lock);
    8000499c:	8526                	mv	a0,s1
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	2d8080e7          	jalr	728(ra) # 80000c76 <release>
  return i;
    800049a6:	b785                	j	80004906 <pipewrite+0x50>

00000000800049a8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800049a8:	715d                	addi	sp,sp,-80
    800049aa:	e486                	sd	ra,72(sp)
    800049ac:	e0a2                	sd	s0,64(sp)
    800049ae:	fc26                	sd	s1,56(sp)
    800049b0:	f84a                	sd	s2,48(sp)
    800049b2:	f44e                	sd	s3,40(sp)
    800049b4:	f052                	sd	s4,32(sp)
    800049b6:	ec56                	sd	s5,24(sp)
    800049b8:	e85a                	sd	s6,16(sp)
    800049ba:	0880                	addi	s0,sp,80
    800049bc:	84aa                	mv	s1,a0
    800049be:	892e                	mv	s2,a1
    800049c0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800049c2:	ffffd097          	auipc	ra,0xffffd
    800049c6:	fbc080e7          	jalr	-68(ra) # 8000197e <myproc>
    800049ca:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800049cc:	8526                	mv	a0,s1
    800049ce:	ffffc097          	auipc	ra,0xffffc
    800049d2:	1f4080e7          	jalr	500(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800049d6:	2184a703          	lw	a4,536(s1)
    800049da:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800049de:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800049e2:	02f71463          	bne	a4,a5,80004a0a <piperead+0x62>
    800049e6:	2244a783          	lw	a5,548(s1)
    800049ea:	c385                	beqz	a5,80004a0a <piperead+0x62>
    if(pr->killed){
    800049ec:	028a2783          	lw	a5,40(s4)
    800049f0:	ebc1                	bnez	a5,80004a80 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800049f2:	85a6                	mv	a1,s1
    800049f4:	854e                	mv	a0,s3
    800049f6:	ffffd097          	auipc	ra,0xffffd
    800049fa:	648080e7          	jalr	1608(ra) # 8000203e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800049fe:	2184a703          	lw	a4,536(s1)
    80004a02:	21c4a783          	lw	a5,540(s1)
    80004a06:	fef700e3          	beq	a4,a5,800049e6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a0a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a0c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a0e:	05505363          	blez	s5,80004a54 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004a12:	2184a783          	lw	a5,536(s1)
    80004a16:	21c4a703          	lw	a4,540(s1)
    80004a1a:	02f70d63          	beq	a4,a5,80004a54 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a1e:	0017871b          	addiw	a4,a5,1
    80004a22:	20e4ac23          	sw	a4,536(s1)
    80004a26:	1ff7f793          	andi	a5,a5,511
    80004a2a:	97a6                	add	a5,a5,s1
    80004a2c:	0187c783          	lbu	a5,24(a5)
    80004a30:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a34:	4685                	li	a3,1
    80004a36:	fbf40613          	addi	a2,s0,-65
    80004a3a:	85ca                	mv	a1,s2
    80004a3c:	050a3503          	ld	a0,80(s4)
    80004a40:	ffffd097          	auipc	ra,0xffffd
    80004a44:	bfe080e7          	jalr	-1026(ra) # 8000163e <copyout>
    80004a48:	01650663          	beq	a0,s6,80004a54 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a4c:	2985                	addiw	s3,s3,1
    80004a4e:	0905                	addi	s2,s2,1
    80004a50:	fd3a91e3          	bne	s5,s3,80004a12 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004a54:	21c48513          	addi	a0,s1,540
    80004a58:	ffffd097          	auipc	ra,0xffffd
    80004a5c:	772080e7          	jalr	1906(ra) # 800021ca <wakeup>
  release(&pi->lock);
    80004a60:	8526                	mv	a0,s1
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	214080e7          	jalr	532(ra) # 80000c76 <release>
  return i;
}
    80004a6a:	854e                	mv	a0,s3
    80004a6c:	60a6                	ld	ra,72(sp)
    80004a6e:	6406                	ld	s0,64(sp)
    80004a70:	74e2                	ld	s1,56(sp)
    80004a72:	7942                	ld	s2,48(sp)
    80004a74:	79a2                	ld	s3,40(sp)
    80004a76:	7a02                	ld	s4,32(sp)
    80004a78:	6ae2                	ld	s5,24(sp)
    80004a7a:	6b42                	ld	s6,16(sp)
    80004a7c:	6161                	addi	sp,sp,80
    80004a7e:	8082                	ret
      release(&pi->lock);
    80004a80:	8526                	mv	a0,s1
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	1f4080e7          	jalr	500(ra) # 80000c76 <release>
      return -1;
    80004a8a:	59fd                	li	s3,-1
    80004a8c:	bff9                	j	80004a6a <piperead+0xc2>

0000000080004a8e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004a8e:	de010113          	addi	sp,sp,-544
    80004a92:	20113c23          	sd	ra,536(sp)
    80004a96:	20813823          	sd	s0,528(sp)
    80004a9a:	20913423          	sd	s1,520(sp)
    80004a9e:	21213023          	sd	s2,512(sp)
    80004aa2:	ffce                	sd	s3,504(sp)
    80004aa4:	fbd2                	sd	s4,496(sp)
    80004aa6:	f7d6                	sd	s5,488(sp)
    80004aa8:	f3da                	sd	s6,480(sp)
    80004aaa:	efde                	sd	s7,472(sp)
    80004aac:	ebe2                	sd	s8,464(sp)
    80004aae:	e7e6                	sd	s9,456(sp)
    80004ab0:	e3ea                	sd	s10,448(sp)
    80004ab2:	ff6e                	sd	s11,440(sp)
    80004ab4:	1400                	addi	s0,sp,544
    80004ab6:	892a                	mv	s2,a0
    80004ab8:	dea43423          	sd	a0,-536(s0)
    80004abc:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ac0:	ffffd097          	auipc	ra,0xffffd
    80004ac4:	ebe080e7          	jalr	-322(ra) # 8000197e <myproc>
    80004ac8:	84aa                	mv	s1,a0

  begin_op();
    80004aca:	fffff097          	auipc	ra,0xfffff
    80004ace:	4a6080e7          	jalr	1190(ra) # 80003f70 <begin_op>

  if((ip = namei(path)) == 0){
    80004ad2:	854a                	mv	a0,s2
    80004ad4:	fffff097          	auipc	ra,0xfffff
    80004ad8:	280080e7          	jalr	640(ra) # 80003d54 <namei>
    80004adc:	c93d                	beqz	a0,80004b52 <exec+0xc4>
    80004ade:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ae0:	fffff097          	auipc	ra,0xfffff
    80004ae4:	abe080e7          	jalr	-1346(ra) # 8000359e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ae8:	04000713          	li	a4,64
    80004aec:	4681                	li	a3,0
    80004aee:	e4840613          	addi	a2,s0,-440
    80004af2:	4581                	li	a1,0
    80004af4:	8556                	mv	a0,s5
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	d5c080e7          	jalr	-676(ra) # 80003852 <readi>
    80004afe:	04000793          	li	a5,64
    80004b02:	00f51a63          	bne	a0,a5,80004b16 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b06:	e4842703          	lw	a4,-440(s0)
    80004b0a:	464c47b7          	lui	a5,0x464c4
    80004b0e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b12:	04f70663          	beq	a4,a5,80004b5e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b16:	8556                	mv	a0,s5
    80004b18:	fffff097          	auipc	ra,0xfffff
    80004b1c:	ce8080e7          	jalr	-792(ra) # 80003800 <iunlockput>
    end_op();
    80004b20:	fffff097          	auipc	ra,0xfffff
    80004b24:	4d0080e7          	jalr	1232(ra) # 80003ff0 <end_op>
  }
  return -1;
    80004b28:	557d                	li	a0,-1
}
    80004b2a:	21813083          	ld	ra,536(sp)
    80004b2e:	21013403          	ld	s0,528(sp)
    80004b32:	20813483          	ld	s1,520(sp)
    80004b36:	20013903          	ld	s2,512(sp)
    80004b3a:	79fe                	ld	s3,504(sp)
    80004b3c:	7a5e                	ld	s4,496(sp)
    80004b3e:	7abe                	ld	s5,488(sp)
    80004b40:	7b1e                	ld	s6,480(sp)
    80004b42:	6bfe                	ld	s7,472(sp)
    80004b44:	6c5e                	ld	s8,464(sp)
    80004b46:	6cbe                	ld	s9,456(sp)
    80004b48:	6d1e                	ld	s10,448(sp)
    80004b4a:	7dfa                	ld	s11,440(sp)
    80004b4c:	22010113          	addi	sp,sp,544
    80004b50:	8082                	ret
    end_op();
    80004b52:	fffff097          	auipc	ra,0xfffff
    80004b56:	49e080e7          	jalr	1182(ra) # 80003ff0 <end_op>
    return -1;
    80004b5a:	557d                	li	a0,-1
    80004b5c:	b7f9                	j	80004b2a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004b5e:	8526                	mv	a0,s1
    80004b60:	ffffd097          	auipc	ra,0xffffd
    80004b64:	ee2080e7          	jalr	-286(ra) # 80001a42 <proc_pagetable>
    80004b68:	8b2a                	mv	s6,a0
    80004b6a:	d555                	beqz	a0,80004b16 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004b6c:	e6842783          	lw	a5,-408(s0)
    80004b70:	e8045703          	lhu	a4,-384(s0)
    80004b74:	c735                	beqz	a4,80004be0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004b76:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004b78:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004b7c:	6a05                	lui	s4,0x1
    80004b7e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004b82:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004b86:	6d85                	lui	s11,0x1
    80004b88:	7d7d                	lui	s10,0xfffff
    80004b8a:	ac1d                	j	80004dc0 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004b8c:	00004517          	auipc	a0,0x4
    80004b90:	b2450513          	addi	a0,a0,-1244 # 800086b0 <syscalls+0x280>
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	996080e7          	jalr	-1642(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004b9c:	874a                	mv	a4,s2
    80004b9e:	009c86bb          	addw	a3,s9,s1
    80004ba2:	4581                	li	a1,0
    80004ba4:	8556                	mv	a0,s5
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	cac080e7          	jalr	-852(ra) # 80003852 <readi>
    80004bae:	2501                	sext.w	a0,a0
    80004bb0:	1aa91863          	bne	s2,a0,80004d60 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004bb4:	009d84bb          	addw	s1,s11,s1
    80004bb8:	013d09bb          	addw	s3,s10,s3
    80004bbc:	1f74f263          	bgeu	s1,s7,80004da0 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004bc0:	02049593          	slli	a1,s1,0x20
    80004bc4:	9181                	srli	a1,a1,0x20
    80004bc6:	95e2                	add	a1,a1,s8
    80004bc8:	855a                	mv	a0,s6
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	482080e7          	jalr	1154(ra) # 8000104c <walkaddr>
    80004bd2:	862a                	mv	a2,a0
    if(pa == 0)
    80004bd4:	dd45                	beqz	a0,80004b8c <exec+0xfe>
      n = PGSIZE;
    80004bd6:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004bd8:	fd49f2e3          	bgeu	s3,s4,80004b9c <exec+0x10e>
      n = sz - i;
    80004bdc:	894e                	mv	s2,s3
    80004bde:	bf7d                	j	80004b9c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004be0:	4481                	li	s1,0
  iunlockput(ip);
    80004be2:	8556                	mv	a0,s5
    80004be4:	fffff097          	auipc	ra,0xfffff
    80004be8:	c1c080e7          	jalr	-996(ra) # 80003800 <iunlockput>
  end_op();
    80004bec:	fffff097          	auipc	ra,0xfffff
    80004bf0:	404080e7          	jalr	1028(ra) # 80003ff0 <end_op>
  p = myproc();
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	d8a080e7          	jalr	-630(ra) # 8000197e <myproc>
    80004bfc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004bfe:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c02:	6785                	lui	a5,0x1
    80004c04:	17fd                	addi	a5,a5,-1
    80004c06:	94be                	add	s1,s1,a5
    80004c08:	77fd                	lui	a5,0xfffff
    80004c0a:	8fe5                	and	a5,a5,s1
    80004c0c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c10:	6609                	lui	a2,0x2
    80004c12:	963e                	add	a2,a2,a5
    80004c14:	85be                	mv	a1,a5
    80004c16:	855a                	mv	a0,s6
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	7d6080e7          	jalr	2006(ra) # 800013ee <uvmalloc>
    80004c20:	8c2a                	mv	s8,a0
  ip = 0;
    80004c22:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c24:	12050e63          	beqz	a0,80004d60 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c28:	75f9                	lui	a1,0xffffe
    80004c2a:	95aa                	add	a1,a1,a0
    80004c2c:	855a                	mv	a0,s6
    80004c2e:	ffffd097          	auipc	ra,0xffffd
    80004c32:	9de080e7          	jalr	-1570(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004c36:	7afd                	lui	s5,0xfffff
    80004c38:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004c3a:	df043783          	ld	a5,-528(s0)
    80004c3e:	6388                	ld	a0,0(a5)
    80004c40:	c925                	beqz	a0,80004cb0 <exec+0x222>
    80004c42:	e8840993          	addi	s3,s0,-376
    80004c46:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004c4a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004c4c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	1f4080e7          	jalr	500(ra) # 80000e42 <strlen>
    80004c56:	0015079b          	addiw	a5,a0,1
    80004c5a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004c5e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004c62:	13596363          	bltu	s2,s5,80004d88 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004c66:	df043d83          	ld	s11,-528(s0)
    80004c6a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004c6e:	8552                	mv	a0,s4
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	1d2080e7          	jalr	466(ra) # 80000e42 <strlen>
    80004c78:	0015069b          	addiw	a3,a0,1
    80004c7c:	8652                	mv	a2,s4
    80004c7e:	85ca                	mv	a1,s2
    80004c80:	855a                	mv	a0,s6
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	9bc080e7          	jalr	-1604(ra) # 8000163e <copyout>
    80004c8a:	10054363          	bltz	a0,80004d90 <exec+0x302>
    ustack[argc] = sp;
    80004c8e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004c92:	0485                	addi	s1,s1,1
    80004c94:	008d8793          	addi	a5,s11,8
    80004c98:	def43823          	sd	a5,-528(s0)
    80004c9c:	008db503          	ld	a0,8(s11)
    80004ca0:	c911                	beqz	a0,80004cb4 <exec+0x226>
    if(argc >= MAXARG)
    80004ca2:	09a1                	addi	s3,s3,8
    80004ca4:	fb3c95e3          	bne	s9,s3,80004c4e <exec+0x1c0>
  sz = sz1;
    80004ca8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004cac:	4a81                	li	s5,0
    80004cae:	a84d                	j	80004d60 <exec+0x2d2>
  sp = sz;
    80004cb0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004cb2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004cb4:	00349793          	slli	a5,s1,0x3
    80004cb8:	f9040713          	addi	a4,s0,-112
    80004cbc:	97ba                	add	a5,a5,a4
    80004cbe:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004cc2:	00148693          	addi	a3,s1,1
    80004cc6:	068e                	slli	a3,a3,0x3
    80004cc8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ccc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004cd0:	01597663          	bgeu	s2,s5,80004cdc <exec+0x24e>
  sz = sz1;
    80004cd4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004cd8:	4a81                	li	s5,0
    80004cda:	a059                	j	80004d60 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004cdc:	e8840613          	addi	a2,s0,-376
    80004ce0:	85ca                	mv	a1,s2
    80004ce2:	855a                	mv	a0,s6
    80004ce4:	ffffd097          	auipc	ra,0xffffd
    80004ce8:	95a080e7          	jalr	-1702(ra) # 8000163e <copyout>
    80004cec:	0a054663          	bltz	a0,80004d98 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004cf0:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004cf4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004cf8:	de843783          	ld	a5,-536(s0)
    80004cfc:	0007c703          	lbu	a4,0(a5)
    80004d00:	cf11                	beqz	a4,80004d1c <exec+0x28e>
    80004d02:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d04:	02f00693          	li	a3,47
    80004d08:	a039                	j	80004d16 <exec+0x288>
      last = s+1;
    80004d0a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004d0e:	0785                	addi	a5,a5,1
    80004d10:	fff7c703          	lbu	a4,-1(a5)
    80004d14:	c701                	beqz	a4,80004d1c <exec+0x28e>
    if(*s == '/')
    80004d16:	fed71ce3          	bne	a4,a3,80004d0e <exec+0x280>
    80004d1a:	bfc5                	j	80004d0a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d1c:	4641                	li	a2,16
    80004d1e:	de843583          	ld	a1,-536(s0)
    80004d22:	158b8513          	addi	a0,s7,344
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	0ea080e7          	jalr	234(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004d2e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004d32:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004d36:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004d3a:	058bb783          	ld	a5,88(s7)
    80004d3e:	e6043703          	ld	a4,-416(s0)
    80004d42:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004d44:	058bb783          	ld	a5,88(s7)
    80004d48:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004d4c:	85ea                	mv	a1,s10
    80004d4e:	ffffd097          	auipc	ra,0xffffd
    80004d52:	d90080e7          	jalr	-624(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004d56:	0004851b          	sext.w	a0,s1
    80004d5a:	bbc1                	j	80004b2a <exec+0x9c>
    80004d5c:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004d60:	df843583          	ld	a1,-520(s0)
    80004d64:	855a                	mv	a0,s6
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	d78080e7          	jalr	-648(ra) # 80001ade <proc_freepagetable>
  if(ip){
    80004d6e:	da0a94e3          	bnez	s5,80004b16 <exec+0x88>
  return -1;
    80004d72:	557d                	li	a0,-1
    80004d74:	bb5d                	j	80004b2a <exec+0x9c>
    80004d76:	de943c23          	sd	s1,-520(s0)
    80004d7a:	b7dd                	j	80004d60 <exec+0x2d2>
    80004d7c:	de943c23          	sd	s1,-520(s0)
    80004d80:	b7c5                	j	80004d60 <exec+0x2d2>
    80004d82:	de943c23          	sd	s1,-520(s0)
    80004d86:	bfe9                	j	80004d60 <exec+0x2d2>
  sz = sz1;
    80004d88:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d8c:	4a81                	li	s5,0
    80004d8e:	bfc9                	j	80004d60 <exec+0x2d2>
  sz = sz1;
    80004d90:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d94:	4a81                	li	s5,0
    80004d96:	b7e9                	j	80004d60 <exec+0x2d2>
  sz = sz1;
    80004d98:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d9c:	4a81                	li	s5,0
    80004d9e:	b7c9                	j	80004d60 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004da0:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da4:	e0843783          	ld	a5,-504(s0)
    80004da8:	0017869b          	addiw	a3,a5,1
    80004dac:	e0d43423          	sd	a3,-504(s0)
    80004db0:	e0043783          	ld	a5,-512(s0)
    80004db4:	0387879b          	addiw	a5,a5,56
    80004db8:	e8045703          	lhu	a4,-384(s0)
    80004dbc:	e2e6d3e3          	bge	a3,a4,80004be2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004dc0:	2781                	sext.w	a5,a5
    80004dc2:	e0f43023          	sd	a5,-512(s0)
    80004dc6:	03800713          	li	a4,56
    80004dca:	86be                	mv	a3,a5
    80004dcc:	e1040613          	addi	a2,s0,-496
    80004dd0:	4581                	li	a1,0
    80004dd2:	8556                	mv	a0,s5
    80004dd4:	fffff097          	auipc	ra,0xfffff
    80004dd8:	a7e080e7          	jalr	-1410(ra) # 80003852 <readi>
    80004ddc:	03800793          	li	a5,56
    80004de0:	f6f51ee3          	bne	a0,a5,80004d5c <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004de4:	e1042783          	lw	a5,-496(s0)
    80004de8:	4705                	li	a4,1
    80004dea:	fae79de3          	bne	a5,a4,80004da4 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004dee:	e3843603          	ld	a2,-456(s0)
    80004df2:	e3043783          	ld	a5,-464(s0)
    80004df6:	f8f660e3          	bltu	a2,a5,80004d76 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004dfa:	e2043783          	ld	a5,-480(s0)
    80004dfe:	963e                	add	a2,a2,a5
    80004e00:	f6f66ee3          	bltu	a2,a5,80004d7c <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e04:	85a6                	mv	a1,s1
    80004e06:	855a                	mv	a0,s6
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	5e6080e7          	jalr	1510(ra) # 800013ee <uvmalloc>
    80004e10:	dea43c23          	sd	a0,-520(s0)
    80004e14:	d53d                	beqz	a0,80004d82 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004e16:	e2043c03          	ld	s8,-480(s0)
    80004e1a:	de043783          	ld	a5,-544(s0)
    80004e1e:	00fc77b3          	and	a5,s8,a5
    80004e22:	ff9d                	bnez	a5,80004d60 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e24:	e1842c83          	lw	s9,-488(s0)
    80004e28:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e2c:	f60b8ae3          	beqz	s7,80004da0 <exec+0x312>
    80004e30:	89de                	mv	s3,s7
    80004e32:	4481                	li	s1,0
    80004e34:	b371                	j	80004bc0 <exec+0x132>

0000000080004e36 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e36:	7179                	addi	sp,sp,-48
    80004e38:	f406                	sd	ra,40(sp)
    80004e3a:	f022                	sd	s0,32(sp)
    80004e3c:	ec26                	sd	s1,24(sp)
    80004e3e:	e84a                	sd	s2,16(sp)
    80004e40:	1800                	addi	s0,sp,48
    80004e42:	892e                	mv	s2,a1
    80004e44:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004e46:	fdc40593          	addi	a1,s0,-36
    80004e4a:	ffffe097          	auipc	ra,0xffffe
    80004e4e:	be4080e7          	jalr	-1052(ra) # 80002a2e <argint>
    80004e52:	04054063          	bltz	a0,80004e92 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004e56:	fdc42703          	lw	a4,-36(s0)
    80004e5a:	47bd                	li	a5,15
    80004e5c:	02e7ed63          	bltu	a5,a4,80004e96 <argfd+0x60>
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	b1e080e7          	jalr	-1250(ra) # 8000197e <myproc>
    80004e68:	fdc42703          	lw	a4,-36(s0)
    80004e6c:	01a70793          	addi	a5,a4,26
    80004e70:	078e                	slli	a5,a5,0x3
    80004e72:	953e                	add	a0,a0,a5
    80004e74:	611c                	ld	a5,0(a0)
    80004e76:	c395                	beqz	a5,80004e9a <argfd+0x64>
    return -1;
  if(pfd)
    80004e78:	00090463          	beqz	s2,80004e80 <argfd+0x4a>
    *pfd = fd;
    80004e7c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004e80:	4501                	li	a0,0
  if(pf)
    80004e82:	c091                	beqz	s1,80004e86 <argfd+0x50>
    *pf = f;
    80004e84:	e09c                	sd	a5,0(s1)
}
    80004e86:	70a2                	ld	ra,40(sp)
    80004e88:	7402                	ld	s0,32(sp)
    80004e8a:	64e2                	ld	s1,24(sp)
    80004e8c:	6942                	ld	s2,16(sp)
    80004e8e:	6145                	addi	sp,sp,48
    80004e90:	8082                	ret
    return -1;
    80004e92:	557d                	li	a0,-1
    80004e94:	bfcd                	j	80004e86 <argfd+0x50>
    return -1;
    80004e96:	557d                	li	a0,-1
    80004e98:	b7fd                	j	80004e86 <argfd+0x50>
    80004e9a:	557d                	li	a0,-1
    80004e9c:	b7ed                	j	80004e86 <argfd+0x50>

0000000080004e9e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004e9e:	1101                	addi	sp,sp,-32
    80004ea0:	ec06                	sd	ra,24(sp)
    80004ea2:	e822                	sd	s0,16(sp)
    80004ea4:	e426                	sd	s1,8(sp)
    80004ea6:	1000                	addi	s0,sp,32
    80004ea8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004eaa:	ffffd097          	auipc	ra,0xffffd
    80004eae:	ad4080e7          	jalr	-1324(ra) # 8000197e <myproc>
    80004eb2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004eb4:	0d050793          	addi	a5,a0,208
    80004eb8:	4501                	li	a0,0
    80004eba:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ebc:	6398                	ld	a4,0(a5)
    80004ebe:	cb19                	beqz	a4,80004ed4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004ec0:	2505                	addiw	a0,a0,1
    80004ec2:	07a1                	addi	a5,a5,8
    80004ec4:	fed51ce3          	bne	a0,a3,80004ebc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004ec8:	557d                	li	a0,-1
}
    80004eca:	60e2                	ld	ra,24(sp)
    80004ecc:	6442                	ld	s0,16(sp)
    80004ece:	64a2                	ld	s1,8(sp)
    80004ed0:	6105                	addi	sp,sp,32
    80004ed2:	8082                	ret
      p->ofile[fd] = f;
    80004ed4:	01a50793          	addi	a5,a0,26
    80004ed8:	078e                	slli	a5,a5,0x3
    80004eda:	963e                	add	a2,a2,a5
    80004edc:	e204                	sd	s1,0(a2)
      return fd;
    80004ede:	b7f5                	j	80004eca <fdalloc+0x2c>

0000000080004ee0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004ee0:	715d                	addi	sp,sp,-80
    80004ee2:	e486                	sd	ra,72(sp)
    80004ee4:	e0a2                	sd	s0,64(sp)
    80004ee6:	fc26                	sd	s1,56(sp)
    80004ee8:	f84a                	sd	s2,48(sp)
    80004eea:	f44e                	sd	s3,40(sp)
    80004eec:	f052                	sd	s4,32(sp)
    80004eee:	ec56                	sd	s5,24(sp)
    80004ef0:	0880                	addi	s0,sp,80
    80004ef2:	89ae                	mv	s3,a1
    80004ef4:	8ab2                	mv	s5,a2
    80004ef6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004ef8:	fb040593          	addi	a1,s0,-80
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	e76080e7          	jalr	-394(ra) # 80003d72 <nameiparent>
    80004f04:	892a                	mv	s2,a0
    80004f06:	12050e63          	beqz	a0,80005042 <create+0x162>
    return 0;

  ilock(dp);
    80004f0a:	ffffe097          	auipc	ra,0xffffe
    80004f0e:	694080e7          	jalr	1684(ra) # 8000359e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f12:	4601                	li	a2,0
    80004f14:	fb040593          	addi	a1,s0,-80
    80004f18:	854a                	mv	a0,s2
    80004f1a:	fffff097          	auipc	ra,0xfffff
    80004f1e:	b68080e7          	jalr	-1176(ra) # 80003a82 <dirlookup>
    80004f22:	84aa                	mv	s1,a0
    80004f24:	c921                	beqz	a0,80004f74 <create+0x94>
    iunlockput(dp);
    80004f26:	854a                	mv	a0,s2
    80004f28:	fffff097          	auipc	ra,0xfffff
    80004f2c:	8d8080e7          	jalr	-1832(ra) # 80003800 <iunlockput>
    ilock(ip);
    80004f30:	8526                	mv	a0,s1
    80004f32:	ffffe097          	auipc	ra,0xffffe
    80004f36:	66c080e7          	jalr	1644(ra) # 8000359e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f3a:	2981                	sext.w	s3,s3
    80004f3c:	4789                	li	a5,2
    80004f3e:	02f99463          	bne	s3,a5,80004f66 <create+0x86>
    80004f42:	0444d783          	lhu	a5,68(s1)
    80004f46:	37f9                	addiw	a5,a5,-2
    80004f48:	17c2                	slli	a5,a5,0x30
    80004f4a:	93c1                	srli	a5,a5,0x30
    80004f4c:	4705                	li	a4,1
    80004f4e:	00f76c63          	bltu	a4,a5,80004f66 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004f52:	8526                	mv	a0,s1
    80004f54:	60a6                	ld	ra,72(sp)
    80004f56:	6406                	ld	s0,64(sp)
    80004f58:	74e2                	ld	s1,56(sp)
    80004f5a:	7942                	ld	s2,48(sp)
    80004f5c:	79a2                	ld	s3,40(sp)
    80004f5e:	7a02                	ld	s4,32(sp)
    80004f60:	6ae2                	ld	s5,24(sp)
    80004f62:	6161                	addi	sp,sp,80
    80004f64:	8082                	ret
    iunlockput(ip);
    80004f66:	8526                	mv	a0,s1
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	898080e7          	jalr	-1896(ra) # 80003800 <iunlockput>
    return 0;
    80004f70:	4481                	li	s1,0
    80004f72:	b7c5                	j	80004f52 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004f74:	85ce                	mv	a1,s3
    80004f76:	00092503          	lw	a0,0(s2)
    80004f7a:	ffffe097          	auipc	ra,0xffffe
    80004f7e:	48c080e7          	jalr	1164(ra) # 80003406 <ialloc>
    80004f82:	84aa                	mv	s1,a0
    80004f84:	c521                	beqz	a0,80004fcc <create+0xec>
  ilock(ip);
    80004f86:	ffffe097          	auipc	ra,0xffffe
    80004f8a:	618080e7          	jalr	1560(ra) # 8000359e <ilock>
  ip->major = major;
    80004f8e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004f92:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004f96:	4a05                	li	s4,1
    80004f98:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80004f9c:	8526                	mv	a0,s1
    80004f9e:	ffffe097          	auipc	ra,0xffffe
    80004fa2:	536080e7          	jalr	1334(ra) # 800034d4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004fa6:	2981                	sext.w	s3,s3
    80004fa8:	03498a63          	beq	s3,s4,80004fdc <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80004fac:	40d0                	lw	a2,4(s1)
    80004fae:	fb040593          	addi	a1,s0,-80
    80004fb2:	854a                	mv	a0,s2
    80004fb4:	fffff097          	auipc	ra,0xfffff
    80004fb8:	cde080e7          	jalr	-802(ra) # 80003c92 <dirlink>
    80004fbc:	06054b63          	bltz	a0,80005032 <create+0x152>
  iunlockput(dp);
    80004fc0:	854a                	mv	a0,s2
    80004fc2:	fffff097          	auipc	ra,0xfffff
    80004fc6:	83e080e7          	jalr	-1986(ra) # 80003800 <iunlockput>
  return ip;
    80004fca:	b761                	j	80004f52 <create+0x72>
    panic("create: ialloc");
    80004fcc:	00003517          	auipc	a0,0x3
    80004fd0:	70450513          	addi	a0,a0,1796 # 800086d0 <syscalls+0x2a0>
    80004fd4:	ffffb097          	auipc	ra,0xffffb
    80004fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80004fdc:	04a95783          	lhu	a5,74(s2)
    80004fe0:	2785                	addiw	a5,a5,1
    80004fe2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004fe6:	854a                	mv	a0,s2
    80004fe8:	ffffe097          	auipc	ra,0xffffe
    80004fec:	4ec080e7          	jalr	1260(ra) # 800034d4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004ff0:	40d0                	lw	a2,4(s1)
    80004ff2:	00003597          	auipc	a1,0x3
    80004ff6:	6ee58593          	addi	a1,a1,1774 # 800086e0 <syscalls+0x2b0>
    80004ffa:	8526                	mv	a0,s1
    80004ffc:	fffff097          	auipc	ra,0xfffff
    80005000:	c96080e7          	jalr	-874(ra) # 80003c92 <dirlink>
    80005004:	00054f63          	bltz	a0,80005022 <create+0x142>
    80005008:	00492603          	lw	a2,4(s2)
    8000500c:	00003597          	auipc	a1,0x3
    80005010:	6dc58593          	addi	a1,a1,1756 # 800086e8 <syscalls+0x2b8>
    80005014:	8526                	mv	a0,s1
    80005016:	fffff097          	auipc	ra,0xfffff
    8000501a:	c7c080e7          	jalr	-900(ra) # 80003c92 <dirlink>
    8000501e:	f80557e3          	bgez	a0,80004fac <create+0xcc>
      panic("create dots");
    80005022:	00003517          	auipc	a0,0x3
    80005026:	6ce50513          	addi	a0,a0,1742 # 800086f0 <syscalls+0x2c0>
    8000502a:	ffffb097          	auipc	ra,0xffffb
    8000502e:	500080e7          	jalr	1280(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005032:	00003517          	auipc	a0,0x3
    80005036:	6ce50513          	addi	a0,a0,1742 # 80008700 <syscalls+0x2d0>
    8000503a:	ffffb097          	auipc	ra,0xffffb
    8000503e:	4f0080e7          	jalr	1264(ra) # 8000052a <panic>
    return 0;
    80005042:	84aa                	mv	s1,a0
    80005044:	b739                	j	80004f52 <create+0x72>

0000000080005046 <sys_dup>:
{
    80005046:	7179                	addi	sp,sp,-48
    80005048:	f406                	sd	ra,40(sp)
    8000504a:	f022                	sd	s0,32(sp)
    8000504c:	ec26                	sd	s1,24(sp)
    8000504e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005050:	fd840613          	addi	a2,s0,-40
    80005054:	4581                	li	a1,0
    80005056:	4501                	li	a0,0
    80005058:	00000097          	auipc	ra,0x0
    8000505c:	dde080e7          	jalr	-546(ra) # 80004e36 <argfd>
    return -1;
    80005060:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005062:	02054363          	bltz	a0,80005088 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005066:	fd843503          	ld	a0,-40(s0)
    8000506a:	00000097          	auipc	ra,0x0
    8000506e:	e34080e7          	jalr	-460(ra) # 80004e9e <fdalloc>
    80005072:	84aa                	mv	s1,a0
    return -1;
    80005074:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005076:	00054963          	bltz	a0,80005088 <sys_dup+0x42>
  filedup(f);
    8000507a:	fd843503          	ld	a0,-40(s0)
    8000507e:	fffff097          	auipc	ra,0xfffff
    80005082:	36c080e7          	jalr	876(ra) # 800043ea <filedup>
  return fd;
    80005086:	87a6                	mv	a5,s1
}
    80005088:	853e                	mv	a0,a5
    8000508a:	70a2                	ld	ra,40(sp)
    8000508c:	7402                	ld	s0,32(sp)
    8000508e:	64e2                	ld	s1,24(sp)
    80005090:	6145                	addi	sp,sp,48
    80005092:	8082                	ret

0000000080005094 <sys_read>:
{
    80005094:	7179                	addi	sp,sp,-48
    80005096:	f406                	sd	ra,40(sp)
    80005098:	f022                	sd	s0,32(sp)
    8000509a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000509c:	fe840613          	addi	a2,s0,-24
    800050a0:	4581                	li	a1,0
    800050a2:	4501                	li	a0,0
    800050a4:	00000097          	auipc	ra,0x0
    800050a8:	d92080e7          	jalr	-622(ra) # 80004e36 <argfd>
    return -1;
    800050ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050ae:	04054163          	bltz	a0,800050f0 <sys_read+0x5c>
    800050b2:	fe440593          	addi	a1,s0,-28
    800050b6:	4509                	li	a0,2
    800050b8:	ffffe097          	auipc	ra,0xffffe
    800050bc:	976080e7          	jalr	-1674(ra) # 80002a2e <argint>
    return -1;
    800050c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050c2:	02054763          	bltz	a0,800050f0 <sys_read+0x5c>
    800050c6:	fd840593          	addi	a1,s0,-40
    800050ca:	4505                	li	a0,1
    800050cc:	ffffe097          	auipc	ra,0xffffe
    800050d0:	984080e7          	jalr	-1660(ra) # 80002a50 <argaddr>
    return -1;
    800050d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050d6:	00054d63          	bltz	a0,800050f0 <sys_read+0x5c>
  return fileread(f, p, n);
    800050da:	fe442603          	lw	a2,-28(s0)
    800050de:	fd843583          	ld	a1,-40(s0)
    800050e2:	fe843503          	ld	a0,-24(s0)
    800050e6:	fffff097          	auipc	ra,0xfffff
    800050ea:	490080e7          	jalr	1168(ra) # 80004576 <fileread>
    800050ee:	87aa                	mv	a5,a0
}
    800050f0:	853e                	mv	a0,a5
    800050f2:	70a2                	ld	ra,40(sp)
    800050f4:	7402                	ld	s0,32(sp)
    800050f6:	6145                	addi	sp,sp,48
    800050f8:	8082                	ret

00000000800050fa <sys_write>:
{
    800050fa:	7179                	addi	sp,sp,-48
    800050fc:	f406                	sd	ra,40(sp)
    800050fe:	f022                	sd	s0,32(sp)
    80005100:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005102:	fe840613          	addi	a2,s0,-24
    80005106:	4581                	li	a1,0
    80005108:	4501                	li	a0,0
    8000510a:	00000097          	auipc	ra,0x0
    8000510e:	d2c080e7          	jalr	-724(ra) # 80004e36 <argfd>
    return -1;
    80005112:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005114:	04054163          	bltz	a0,80005156 <sys_write+0x5c>
    80005118:	fe440593          	addi	a1,s0,-28
    8000511c:	4509                	li	a0,2
    8000511e:	ffffe097          	auipc	ra,0xffffe
    80005122:	910080e7          	jalr	-1776(ra) # 80002a2e <argint>
    return -1;
    80005126:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005128:	02054763          	bltz	a0,80005156 <sys_write+0x5c>
    8000512c:	fd840593          	addi	a1,s0,-40
    80005130:	4505                	li	a0,1
    80005132:	ffffe097          	auipc	ra,0xffffe
    80005136:	91e080e7          	jalr	-1762(ra) # 80002a50 <argaddr>
    return -1;
    8000513a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000513c:	00054d63          	bltz	a0,80005156 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005140:	fe442603          	lw	a2,-28(s0)
    80005144:	fd843583          	ld	a1,-40(s0)
    80005148:	fe843503          	ld	a0,-24(s0)
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	4ec080e7          	jalr	1260(ra) # 80004638 <filewrite>
    80005154:	87aa                	mv	a5,a0
}
    80005156:	853e                	mv	a0,a5
    80005158:	70a2                	ld	ra,40(sp)
    8000515a:	7402                	ld	s0,32(sp)
    8000515c:	6145                	addi	sp,sp,48
    8000515e:	8082                	ret

0000000080005160 <sys_close>:
{
    80005160:	1101                	addi	sp,sp,-32
    80005162:	ec06                	sd	ra,24(sp)
    80005164:	e822                	sd	s0,16(sp)
    80005166:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005168:	fe040613          	addi	a2,s0,-32
    8000516c:	fec40593          	addi	a1,s0,-20
    80005170:	4501                	li	a0,0
    80005172:	00000097          	auipc	ra,0x0
    80005176:	cc4080e7          	jalr	-828(ra) # 80004e36 <argfd>
    return -1;
    8000517a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000517c:	02054463          	bltz	a0,800051a4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005180:	ffffc097          	auipc	ra,0xffffc
    80005184:	7fe080e7          	jalr	2046(ra) # 8000197e <myproc>
    80005188:	fec42783          	lw	a5,-20(s0)
    8000518c:	07e9                	addi	a5,a5,26
    8000518e:	078e                	slli	a5,a5,0x3
    80005190:	97aa                	add	a5,a5,a0
    80005192:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005196:	fe043503          	ld	a0,-32(s0)
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	2a2080e7          	jalr	674(ra) # 8000443c <fileclose>
  return 0;
    800051a2:	4781                	li	a5,0
}
    800051a4:	853e                	mv	a0,a5
    800051a6:	60e2                	ld	ra,24(sp)
    800051a8:	6442                	ld	s0,16(sp)
    800051aa:	6105                	addi	sp,sp,32
    800051ac:	8082                	ret

00000000800051ae <sys_fstat>:
{
    800051ae:	1101                	addi	sp,sp,-32
    800051b0:	ec06                	sd	ra,24(sp)
    800051b2:	e822                	sd	s0,16(sp)
    800051b4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051b6:	fe840613          	addi	a2,s0,-24
    800051ba:	4581                	li	a1,0
    800051bc:	4501                	li	a0,0
    800051be:	00000097          	auipc	ra,0x0
    800051c2:	c78080e7          	jalr	-904(ra) # 80004e36 <argfd>
    return -1;
    800051c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051c8:	02054563          	bltz	a0,800051f2 <sys_fstat+0x44>
    800051cc:	fe040593          	addi	a1,s0,-32
    800051d0:	4505                	li	a0,1
    800051d2:	ffffe097          	auipc	ra,0xffffe
    800051d6:	87e080e7          	jalr	-1922(ra) # 80002a50 <argaddr>
    return -1;
    800051da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051dc:	00054b63          	bltz	a0,800051f2 <sys_fstat+0x44>
  return filestat(f, st);
    800051e0:	fe043583          	ld	a1,-32(s0)
    800051e4:	fe843503          	ld	a0,-24(s0)
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	31c080e7          	jalr	796(ra) # 80004504 <filestat>
    800051f0:	87aa                	mv	a5,a0
}
    800051f2:	853e                	mv	a0,a5
    800051f4:	60e2                	ld	ra,24(sp)
    800051f6:	6442                	ld	s0,16(sp)
    800051f8:	6105                	addi	sp,sp,32
    800051fa:	8082                	ret

00000000800051fc <sys_link>:
{
    800051fc:	7169                	addi	sp,sp,-304
    800051fe:	f606                	sd	ra,296(sp)
    80005200:	f222                	sd	s0,288(sp)
    80005202:	ee26                	sd	s1,280(sp)
    80005204:	ea4a                	sd	s2,272(sp)
    80005206:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005208:	08000613          	li	a2,128
    8000520c:	ed040593          	addi	a1,s0,-304
    80005210:	4501                	li	a0,0
    80005212:	ffffe097          	auipc	ra,0xffffe
    80005216:	860080e7          	jalr	-1952(ra) # 80002a72 <argstr>
    return -1;
    8000521a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000521c:	10054e63          	bltz	a0,80005338 <sys_link+0x13c>
    80005220:	08000613          	li	a2,128
    80005224:	f5040593          	addi	a1,s0,-176
    80005228:	4505                	li	a0,1
    8000522a:	ffffe097          	auipc	ra,0xffffe
    8000522e:	848080e7          	jalr	-1976(ra) # 80002a72 <argstr>
    return -1;
    80005232:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005234:	10054263          	bltz	a0,80005338 <sys_link+0x13c>
  begin_op();
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	d38080e7          	jalr	-712(ra) # 80003f70 <begin_op>
  if((ip = namei(old)) == 0){
    80005240:	ed040513          	addi	a0,s0,-304
    80005244:	fffff097          	auipc	ra,0xfffff
    80005248:	b10080e7          	jalr	-1264(ra) # 80003d54 <namei>
    8000524c:	84aa                	mv	s1,a0
    8000524e:	c551                	beqz	a0,800052da <sys_link+0xde>
  ilock(ip);
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	34e080e7          	jalr	846(ra) # 8000359e <ilock>
  if(ip->type == T_DIR){
    80005258:	04449703          	lh	a4,68(s1)
    8000525c:	4785                	li	a5,1
    8000525e:	08f70463          	beq	a4,a5,800052e6 <sys_link+0xea>
  ip->nlink++;
    80005262:	04a4d783          	lhu	a5,74(s1)
    80005266:	2785                	addiw	a5,a5,1
    80005268:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000526c:	8526                	mv	a0,s1
    8000526e:	ffffe097          	auipc	ra,0xffffe
    80005272:	266080e7          	jalr	614(ra) # 800034d4 <iupdate>
  iunlock(ip);
    80005276:	8526                	mv	a0,s1
    80005278:	ffffe097          	auipc	ra,0xffffe
    8000527c:	3e8080e7          	jalr	1000(ra) # 80003660 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005280:	fd040593          	addi	a1,s0,-48
    80005284:	f5040513          	addi	a0,s0,-176
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	aea080e7          	jalr	-1302(ra) # 80003d72 <nameiparent>
    80005290:	892a                	mv	s2,a0
    80005292:	c935                	beqz	a0,80005306 <sys_link+0x10a>
  ilock(dp);
    80005294:	ffffe097          	auipc	ra,0xffffe
    80005298:	30a080e7          	jalr	778(ra) # 8000359e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000529c:	00092703          	lw	a4,0(s2)
    800052a0:	409c                	lw	a5,0(s1)
    800052a2:	04f71d63          	bne	a4,a5,800052fc <sys_link+0x100>
    800052a6:	40d0                	lw	a2,4(s1)
    800052a8:	fd040593          	addi	a1,s0,-48
    800052ac:	854a                	mv	a0,s2
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	9e4080e7          	jalr	-1564(ra) # 80003c92 <dirlink>
    800052b6:	04054363          	bltz	a0,800052fc <sys_link+0x100>
  iunlockput(dp);
    800052ba:	854a                	mv	a0,s2
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	544080e7          	jalr	1348(ra) # 80003800 <iunlockput>
  iput(ip);
    800052c4:	8526                	mv	a0,s1
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	492080e7          	jalr	1170(ra) # 80003758 <iput>
  end_op();
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	d22080e7          	jalr	-734(ra) # 80003ff0 <end_op>
  return 0;
    800052d6:	4781                	li	a5,0
    800052d8:	a085                	j	80005338 <sys_link+0x13c>
    end_op();
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	d16080e7          	jalr	-746(ra) # 80003ff0 <end_op>
    return -1;
    800052e2:	57fd                	li	a5,-1
    800052e4:	a891                	j	80005338 <sys_link+0x13c>
    iunlockput(ip);
    800052e6:	8526                	mv	a0,s1
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	518080e7          	jalr	1304(ra) # 80003800 <iunlockput>
    end_op();
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	d00080e7          	jalr	-768(ra) # 80003ff0 <end_op>
    return -1;
    800052f8:	57fd                	li	a5,-1
    800052fa:	a83d                	j	80005338 <sys_link+0x13c>
    iunlockput(dp);
    800052fc:	854a                	mv	a0,s2
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	502080e7          	jalr	1282(ra) # 80003800 <iunlockput>
  ilock(ip);
    80005306:	8526                	mv	a0,s1
    80005308:	ffffe097          	auipc	ra,0xffffe
    8000530c:	296080e7          	jalr	662(ra) # 8000359e <ilock>
  ip->nlink--;
    80005310:	04a4d783          	lhu	a5,74(s1)
    80005314:	37fd                	addiw	a5,a5,-1
    80005316:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000531a:	8526                	mv	a0,s1
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	1b8080e7          	jalr	440(ra) # 800034d4 <iupdate>
  iunlockput(ip);
    80005324:	8526                	mv	a0,s1
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	4da080e7          	jalr	1242(ra) # 80003800 <iunlockput>
  end_op();
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	cc2080e7          	jalr	-830(ra) # 80003ff0 <end_op>
  return -1;
    80005336:	57fd                	li	a5,-1
}
    80005338:	853e                	mv	a0,a5
    8000533a:	70b2                	ld	ra,296(sp)
    8000533c:	7412                	ld	s0,288(sp)
    8000533e:	64f2                	ld	s1,280(sp)
    80005340:	6952                	ld	s2,272(sp)
    80005342:	6155                	addi	sp,sp,304
    80005344:	8082                	ret

0000000080005346 <sys_unlink>:
{
    80005346:	7151                	addi	sp,sp,-240
    80005348:	f586                	sd	ra,232(sp)
    8000534a:	f1a2                	sd	s0,224(sp)
    8000534c:	eda6                	sd	s1,216(sp)
    8000534e:	e9ca                	sd	s2,208(sp)
    80005350:	e5ce                	sd	s3,200(sp)
    80005352:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005354:	08000613          	li	a2,128
    80005358:	f3040593          	addi	a1,s0,-208
    8000535c:	4501                	li	a0,0
    8000535e:	ffffd097          	auipc	ra,0xffffd
    80005362:	714080e7          	jalr	1812(ra) # 80002a72 <argstr>
    80005366:	18054163          	bltz	a0,800054e8 <sys_unlink+0x1a2>
  begin_op();
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	c06080e7          	jalr	-1018(ra) # 80003f70 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005372:	fb040593          	addi	a1,s0,-80
    80005376:	f3040513          	addi	a0,s0,-208
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	9f8080e7          	jalr	-1544(ra) # 80003d72 <nameiparent>
    80005382:	84aa                	mv	s1,a0
    80005384:	c979                	beqz	a0,8000545a <sys_unlink+0x114>
  ilock(dp);
    80005386:	ffffe097          	auipc	ra,0xffffe
    8000538a:	218080e7          	jalr	536(ra) # 8000359e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000538e:	00003597          	auipc	a1,0x3
    80005392:	35258593          	addi	a1,a1,850 # 800086e0 <syscalls+0x2b0>
    80005396:	fb040513          	addi	a0,s0,-80
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	6ce080e7          	jalr	1742(ra) # 80003a68 <namecmp>
    800053a2:	14050a63          	beqz	a0,800054f6 <sys_unlink+0x1b0>
    800053a6:	00003597          	auipc	a1,0x3
    800053aa:	34258593          	addi	a1,a1,834 # 800086e8 <syscalls+0x2b8>
    800053ae:	fb040513          	addi	a0,s0,-80
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	6b6080e7          	jalr	1718(ra) # 80003a68 <namecmp>
    800053ba:	12050e63          	beqz	a0,800054f6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800053be:	f2c40613          	addi	a2,s0,-212
    800053c2:	fb040593          	addi	a1,s0,-80
    800053c6:	8526                	mv	a0,s1
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	6ba080e7          	jalr	1722(ra) # 80003a82 <dirlookup>
    800053d0:	892a                	mv	s2,a0
    800053d2:	12050263          	beqz	a0,800054f6 <sys_unlink+0x1b0>
  ilock(ip);
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	1c8080e7          	jalr	456(ra) # 8000359e <ilock>
  if(ip->nlink < 1)
    800053de:	04a91783          	lh	a5,74(s2)
    800053e2:	08f05263          	blez	a5,80005466 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800053e6:	04491703          	lh	a4,68(s2)
    800053ea:	4785                	li	a5,1
    800053ec:	08f70563          	beq	a4,a5,80005476 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800053f0:	4641                	li	a2,16
    800053f2:	4581                	li	a1,0
    800053f4:	fc040513          	addi	a0,s0,-64
    800053f8:	ffffc097          	auipc	ra,0xffffc
    800053fc:	8c6080e7          	jalr	-1850(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005400:	4741                	li	a4,16
    80005402:	f2c42683          	lw	a3,-212(s0)
    80005406:	fc040613          	addi	a2,s0,-64
    8000540a:	4581                	li	a1,0
    8000540c:	8526                	mv	a0,s1
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	53c080e7          	jalr	1340(ra) # 8000394a <writei>
    80005416:	47c1                	li	a5,16
    80005418:	0af51563          	bne	a0,a5,800054c2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000541c:	04491703          	lh	a4,68(s2)
    80005420:	4785                	li	a5,1
    80005422:	0af70863          	beq	a4,a5,800054d2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005426:	8526                	mv	a0,s1
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	3d8080e7          	jalr	984(ra) # 80003800 <iunlockput>
  ip->nlink--;
    80005430:	04a95783          	lhu	a5,74(s2)
    80005434:	37fd                	addiw	a5,a5,-1
    80005436:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000543a:	854a                	mv	a0,s2
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	098080e7          	jalr	152(ra) # 800034d4 <iupdate>
  iunlockput(ip);
    80005444:	854a                	mv	a0,s2
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	3ba080e7          	jalr	954(ra) # 80003800 <iunlockput>
  end_op();
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	ba2080e7          	jalr	-1118(ra) # 80003ff0 <end_op>
  return 0;
    80005456:	4501                	li	a0,0
    80005458:	a84d                	j	8000550a <sys_unlink+0x1c4>
    end_op();
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	b96080e7          	jalr	-1130(ra) # 80003ff0 <end_op>
    return -1;
    80005462:	557d                	li	a0,-1
    80005464:	a05d                	j	8000550a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005466:	00003517          	auipc	a0,0x3
    8000546a:	2aa50513          	addi	a0,a0,682 # 80008710 <syscalls+0x2e0>
    8000546e:	ffffb097          	auipc	ra,0xffffb
    80005472:	0bc080e7          	jalr	188(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005476:	04c92703          	lw	a4,76(s2)
    8000547a:	02000793          	li	a5,32
    8000547e:	f6e7f9e3          	bgeu	a5,a4,800053f0 <sys_unlink+0xaa>
    80005482:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005486:	4741                	li	a4,16
    80005488:	86ce                	mv	a3,s3
    8000548a:	f1840613          	addi	a2,s0,-232
    8000548e:	4581                	li	a1,0
    80005490:	854a                	mv	a0,s2
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	3c0080e7          	jalr	960(ra) # 80003852 <readi>
    8000549a:	47c1                	li	a5,16
    8000549c:	00f51b63          	bne	a0,a5,800054b2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800054a0:	f1845783          	lhu	a5,-232(s0)
    800054a4:	e7a1                	bnez	a5,800054ec <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054a6:	29c1                	addiw	s3,s3,16
    800054a8:	04c92783          	lw	a5,76(s2)
    800054ac:	fcf9ede3          	bltu	s3,a5,80005486 <sys_unlink+0x140>
    800054b0:	b781                	j	800053f0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800054b2:	00003517          	auipc	a0,0x3
    800054b6:	27650513          	addi	a0,a0,630 # 80008728 <syscalls+0x2f8>
    800054ba:	ffffb097          	auipc	ra,0xffffb
    800054be:	070080e7          	jalr	112(ra) # 8000052a <panic>
    panic("unlink: writei");
    800054c2:	00003517          	auipc	a0,0x3
    800054c6:	27e50513          	addi	a0,a0,638 # 80008740 <syscalls+0x310>
    800054ca:	ffffb097          	auipc	ra,0xffffb
    800054ce:	060080e7          	jalr	96(ra) # 8000052a <panic>
    dp->nlink--;
    800054d2:	04a4d783          	lhu	a5,74(s1)
    800054d6:	37fd                	addiw	a5,a5,-1
    800054d8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054dc:	8526                	mv	a0,s1
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	ff6080e7          	jalr	-10(ra) # 800034d4 <iupdate>
    800054e6:	b781                	j	80005426 <sys_unlink+0xe0>
    return -1;
    800054e8:	557d                	li	a0,-1
    800054ea:	a005                	j	8000550a <sys_unlink+0x1c4>
    iunlockput(ip);
    800054ec:	854a                	mv	a0,s2
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	312080e7          	jalr	786(ra) # 80003800 <iunlockput>
  iunlockput(dp);
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	308080e7          	jalr	776(ra) # 80003800 <iunlockput>
  end_op();
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	af0080e7          	jalr	-1296(ra) # 80003ff0 <end_op>
  return -1;
    80005508:	557d                	li	a0,-1
}
    8000550a:	70ae                	ld	ra,232(sp)
    8000550c:	740e                	ld	s0,224(sp)
    8000550e:	64ee                	ld	s1,216(sp)
    80005510:	694e                	ld	s2,208(sp)
    80005512:	69ae                	ld	s3,200(sp)
    80005514:	616d                	addi	sp,sp,240
    80005516:	8082                	ret

0000000080005518 <sys_open>:

uint64
sys_open(void)
{
    80005518:	7131                	addi	sp,sp,-192
    8000551a:	fd06                	sd	ra,184(sp)
    8000551c:	f922                	sd	s0,176(sp)
    8000551e:	f526                	sd	s1,168(sp)
    80005520:	f14a                	sd	s2,160(sp)
    80005522:	ed4e                	sd	s3,152(sp)
    80005524:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005526:	08000613          	li	a2,128
    8000552a:	f5040593          	addi	a1,s0,-176
    8000552e:	4501                	li	a0,0
    80005530:	ffffd097          	auipc	ra,0xffffd
    80005534:	542080e7          	jalr	1346(ra) # 80002a72 <argstr>
    return -1;
    80005538:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000553a:	0c054163          	bltz	a0,800055fc <sys_open+0xe4>
    8000553e:	f4c40593          	addi	a1,s0,-180
    80005542:	4505                	li	a0,1
    80005544:	ffffd097          	auipc	ra,0xffffd
    80005548:	4ea080e7          	jalr	1258(ra) # 80002a2e <argint>
    8000554c:	0a054863          	bltz	a0,800055fc <sys_open+0xe4>

  begin_op();
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	a20080e7          	jalr	-1504(ra) # 80003f70 <begin_op>

  if(omode & O_CREATE){
    80005558:	f4c42783          	lw	a5,-180(s0)
    8000555c:	2007f793          	andi	a5,a5,512
    80005560:	cbdd                	beqz	a5,80005616 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005562:	4681                	li	a3,0
    80005564:	4601                	li	a2,0
    80005566:	4589                	li	a1,2
    80005568:	f5040513          	addi	a0,s0,-176
    8000556c:	00000097          	auipc	ra,0x0
    80005570:	974080e7          	jalr	-1676(ra) # 80004ee0 <create>
    80005574:	892a                	mv	s2,a0
    if(ip == 0){
    80005576:	c959                	beqz	a0,8000560c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005578:	04491703          	lh	a4,68(s2)
    8000557c:	478d                	li	a5,3
    8000557e:	00f71763          	bne	a4,a5,8000558c <sys_open+0x74>
    80005582:	04695703          	lhu	a4,70(s2)
    80005586:	47a5                	li	a5,9
    80005588:	0ce7ec63          	bltu	a5,a4,80005660 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	df4080e7          	jalr	-524(ra) # 80004380 <filealloc>
    80005594:	89aa                	mv	s3,a0
    80005596:	10050263          	beqz	a0,8000569a <sys_open+0x182>
    8000559a:	00000097          	auipc	ra,0x0
    8000559e:	904080e7          	jalr	-1788(ra) # 80004e9e <fdalloc>
    800055a2:	84aa                	mv	s1,a0
    800055a4:	0e054663          	bltz	a0,80005690 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800055a8:	04491703          	lh	a4,68(s2)
    800055ac:	478d                	li	a5,3
    800055ae:	0cf70463          	beq	a4,a5,80005676 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800055b2:	4789                	li	a5,2
    800055b4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800055b8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800055bc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800055c0:	f4c42783          	lw	a5,-180(s0)
    800055c4:	0017c713          	xori	a4,a5,1
    800055c8:	8b05                	andi	a4,a4,1
    800055ca:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800055ce:	0037f713          	andi	a4,a5,3
    800055d2:	00e03733          	snez	a4,a4
    800055d6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800055da:	4007f793          	andi	a5,a5,1024
    800055de:	c791                	beqz	a5,800055ea <sys_open+0xd2>
    800055e0:	04491703          	lh	a4,68(s2)
    800055e4:	4789                	li	a5,2
    800055e6:	08f70f63          	beq	a4,a5,80005684 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800055ea:	854a                	mv	a0,s2
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	074080e7          	jalr	116(ra) # 80003660 <iunlock>
  end_op();
    800055f4:	fffff097          	auipc	ra,0xfffff
    800055f8:	9fc080e7          	jalr	-1540(ra) # 80003ff0 <end_op>

  return fd;
}
    800055fc:	8526                	mv	a0,s1
    800055fe:	70ea                	ld	ra,184(sp)
    80005600:	744a                	ld	s0,176(sp)
    80005602:	74aa                	ld	s1,168(sp)
    80005604:	790a                	ld	s2,160(sp)
    80005606:	69ea                	ld	s3,152(sp)
    80005608:	6129                	addi	sp,sp,192
    8000560a:	8082                	ret
      end_op();
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	9e4080e7          	jalr	-1564(ra) # 80003ff0 <end_op>
      return -1;
    80005614:	b7e5                	j	800055fc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005616:	f5040513          	addi	a0,s0,-176
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	73a080e7          	jalr	1850(ra) # 80003d54 <namei>
    80005622:	892a                	mv	s2,a0
    80005624:	c905                	beqz	a0,80005654 <sys_open+0x13c>
    ilock(ip);
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	f78080e7          	jalr	-136(ra) # 8000359e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000562e:	04491703          	lh	a4,68(s2)
    80005632:	4785                	li	a5,1
    80005634:	f4f712e3          	bne	a4,a5,80005578 <sys_open+0x60>
    80005638:	f4c42783          	lw	a5,-180(s0)
    8000563c:	dba1                	beqz	a5,8000558c <sys_open+0x74>
      iunlockput(ip);
    8000563e:	854a                	mv	a0,s2
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	1c0080e7          	jalr	448(ra) # 80003800 <iunlockput>
      end_op();
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	9a8080e7          	jalr	-1624(ra) # 80003ff0 <end_op>
      return -1;
    80005650:	54fd                	li	s1,-1
    80005652:	b76d                	j	800055fc <sys_open+0xe4>
      end_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	99c080e7          	jalr	-1636(ra) # 80003ff0 <end_op>
      return -1;
    8000565c:	54fd                	li	s1,-1
    8000565e:	bf79                	j	800055fc <sys_open+0xe4>
    iunlockput(ip);
    80005660:	854a                	mv	a0,s2
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	19e080e7          	jalr	414(ra) # 80003800 <iunlockput>
    end_op();
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	986080e7          	jalr	-1658(ra) # 80003ff0 <end_op>
    return -1;
    80005672:	54fd                	li	s1,-1
    80005674:	b761                	j	800055fc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005676:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000567a:	04691783          	lh	a5,70(s2)
    8000567e:	02f99223          	sh	a5,36(s3)
    80005682:	bf2d                	j	800055bc <sys_open+0xa4>
    itrunc(ip);
    80005684:	854a                	mv	a0,s2
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	026080e7          	jalr	38(ra) # 800036ac <itrunc>
    8000568e:	bfb1                	j	800055ea <sys_open+0xd2>
      fileclose(f);
    80005690:	854e                	mv	a0,s3
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	daa080e7          	jalr	-598(ra) # 8000443c <fileclose>
    iunlockput(ip);
    8000569a:	854a                	mv	a0,s2
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	164080e7          	jalr	356(ra) # 80003800 <iunlockput>
    end_op();
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	94c080e7          	jalr	-1716(ra) # 80003ff0 <end_op>
    return -1;
    800056ac:	54fd                	li	s1,-1
    800056ae:	b7b9                	j	800055fc <sys_open+0xe4>

00000000800056b0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800056b0:	7175                	addi	sp,sp,-144
    800056b2:	e506                	sd	ra,136(sp)
    800056b4:	e122                	sd	s0,128(sp)
    800056b6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	8b8080e7          	jalr	-1864(ra) # 80003f70 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800056c0:	08000613          	li	a2,128
    800056c4:	f7040593          	addi	a1,s0,-144
    800056c8:	4501                	li	a0,0
    800056ca:	ffffd097          	auipc	ra,0xffffd
    800056ce:	3a8080e7          	jalr	936(ra) # 80002a72 <argstr>
    800056d2:	02054963          	bltz	a0,80005704 <sys_mkdir+0x54>
    800056d6:	4681                	li	a3,0
    800056d8:	4601                	li	a2,0
    800056da:	4585                	li	a1,1
    800056dc:	f7040513          	addi	a0,s0,-144
    800056e0:	00000097          	auipc	ra,0x0
    800056e4:	800080e7          	jalr	-2048(ra) # 80004ee0 <create>
    800056e8:	cd11                	beqz	a0,80005704 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	116080e7          	jalr	278(ra) # 80003800 <iunlockput>
  end_op();
    800056f2:	fffff097          	auipc	ra,0xfffff
    800056f6:	8fe080e7          	jalr	-1794(ra) # 80003ff0 <end_op>
  return 0;
    800056fa:	4501                	li	a0,0
}
    800056fc:	60aa                	ld	ra,136(sp)
    800056fe:	640a                	ld	s0,128(sp)
    80005700:	6149                	addi	sp,sp,144
    80005702:	8082                	ret
    end_op();
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	8ec080e7          	jalr	-1812(ra) # 80003ff0 <end_op>
    return -1;
    8000570c:	557d                	li	a0,-1
    8000570e:	b7fd                	j	800056fc <sys_mkdir+0x4c>

0000000080005710 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005710:	7135                	addi	sp,sp,-160
    80005712:	ed06                	sd	ra,152(sp)
    80005714:	e922                	sd	s0,144(sp)
    80005716:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	858080e7          	jalr	-1960(ra) # 80003f70 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005720:	08000613          	li	a2,128
    80005724:	f7040593          	addi	a1,s0,-144
    80005728:	4501                	li	a0,0
    8000572a:	ffffd097          	auipc	ra,0xffffd
    8000572e:	348080e7          	jalr	840(ra) # 80002a72 <argstr>
    80005732:	04054a63          	bltz	a0,80005786 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005736:	f6c40593          	addi	a1,s0,-148
    8000573a:	4505                	li	a0,1
    8000573c:	ffffd097          	auipc	ra,0xffffd
    80005740:	2f2080e7          	jalr	754(ra) # 80002a2e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005744:	04054163          	bltz	a0,80005786 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005748:	f6840593          	addi	a1,s0,-152
    8000574c:	4509                	li	a0,2
    8000574e:	ffffd097          	auipc	ra,0xffffd
    80005752:	2e0080e7          	jalr	736(ra) # 80002a2e <argint>
     argint(1, &major) < 0 ||
    80005756:	02054863          	bltz	a0,80005786 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000575a:	f6841683          	lh	a3,-152(s0)
    8000575e:	f6c41603          	lh	a2,-148(s0)
    80005762:	458d                	li	a1,3
    80005764:	f7040513          	addi	a0,s0,-144
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	778080e7          	jalr	1912(ra) # 80004ee0 <create>
     argint(2, &minor) < 0 ||
    80005770:	c919                	beqz	a0,80005786 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	08e080e7          	jalr	142(ra) # 80003800 <iunlockput>
  end_op();
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	876080e7          	jalr	-1930(ra) # 80003ff0 <end_op>
  return 0;
    80005782:	4501                	li	a0,0
    80005784:	a031                	j	80005790 <sys_mknod+0x80>
    end_op();
    80005786:	fffff097          	auipc	ra,0xfffff
    8000578a:	86a080e7          	jalr	-1942(ra) # 80003ff0 <end_op>
    return -1;
    8000578e:	557d                	li	a0,-1
}
    80005790:	60ea                	ld	ra,152(sp)
    80005792:	644a                	ld	s0,144(sp)
    80005794:	610d                	addi	sp,sp,160
    80005796:	8082                	ret

0000000080005798 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005798:	7135                	addi	sp,sp,-160
    8000579a:	ed06                	sd	ra,152(sp)
    8000579c:	e922                	sd	s0,144(sp)
    8000579e:	e526                	sd	s1,136(sp)
    800057a0:	e14a                	sd	s2,128(sp)
    800057a2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800057a4:	ffffc097          	auipc	ra,0xffffc
    800057a8:	1da080e7          	jalr	474(ra) # 8000197e <myproc>
    800057ac:	892a                	mv	s2,a0
  
  begin_op();
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	7c2080e7          	jalr	1986(ra) # 80003f70 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800057b6:	08000613          	li	a2,128
    800057ba:	f6040593          	addi	a1,s0,-160
    800057be:	4501                	li	a0,0
    800057c0:	ffffd097          	auipc	ra,0xffffd
    800057c4:	2b2080e7          	jalr	690(ra) # 80002a72 <argstr>
    800057c8:	04054b63          	bltz	a0,8000581e <sys_chdir+0x86>
    800057cc:	f6040513          	addi	a0,s0,-160
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	584080e7          	jalr	1412(ra) # 80003d54 <namei>
    800057d8:	84aa                	mv	s1,a0
    800057da:	c131                	beqz	a0,8000581e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	dc2080e7          	jalr	-574(ra) # 8000359e <ilock>
  if(ip->type != T_DIR){
    800057e4:	04449703          	lh	a4,68(s1)
    800057e8:	4785                	li	a5,1
    800057ea:	04f71063          	bne	a4,a5,8000582a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800057ee:	8526                	mv	a0,s1
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	e70080e7          	jalr	-400(ra) # 80003660 <iunlock>
  iput(p->cwd);
    800057f8:	15093503          	ld	a0,336(s2)
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	f5c080e7          	jalr	-164(ra) # 80003758 <iput>
  end_op();
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	7ec080e7          	jalr	2028(ra) # 80003ff0 <end_op>
  p->cwd = ip;
    8000580c:	14993823          	sd	s1,336(s2)
  return 0;
    80005810:	4501                	li	a0,0
}
    80005812:	60ea                	ld	ra,152(sp)
    80005814:	644a                	ld	s0,144(sp)
    80005816:	64aa                	ld	s1,136(sp)
    80005818:	690a                	ld	s2,128(sp)
    8000581a:	610d                	addi	sp,sp,160
    8000581c:	8082                	ret
    end_op();
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	7d2080e7          	jalr	2002(ra) # 80003ff0 <end_op>
    return -1;
    80005826:	557d                	li	a0,-1
    80005828:	b7ed                	j	80005812 <sys_chdir+0x7a>
    iunlockput(ip);
    8000582a:	8526                	mv	a0,s1
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	fd4080e7          	jalr	-44(ra) # 80003800 <iunlockput>
    end_op();
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	7bc080e7          	jalr	1980(ra) # 80003ff0 <end_op>
    return -1;
    8000583c:	557d                	li	a0,-1
    8000583e:	bfd1                	j	80005812 <sys_chdir+0x7a>

0000000080005840 <sys_exec>:

uint64
sys_exec(void)
{
    80005840:	7145                	addi	sp,sp,-464
    80005842:	e786                	sd	ra,456(sp)
    80005844:	e3a2                	sd	s0,448(sp)
    80005846:	ff26                	sd	s1,440(sp)
    80005848:	fb4a                	sd	s2,432(sp)
    8000584a:	f74e                	sd	s3,424(sp)
    8000584c:	f352                	sd	s4,416(sp)
    8000584e:	ef56                	sd	s5,408(sp)
    80005850:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005852:	08000613          	li	a2,128
    80005856:	f4040593          	addi	a1,s0,-192
    8000585a:	4501                	li	a0,0
    8000585c:	ffffd097          	auipc	ra,0xffffd
    80005860:	216080e7          	jalr	534(ra) # 80002a72 <argstr>
    return -1;
    80005864:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005866:	0c054a63          	bltz	a0,8000593a <sys_exec+0xfa>
    8000586a:	e3840593          	addi	a1,s0,-456
    8000586e:	4505                	li	a0,1
    80005870:	ffffd097          	auipc	ra,0xffffd
    80005874:	1e0080e7          	jalr	480(ra) # 80002a50 <argaddr>
    80005878:	0c054163          	bltz	a0,8000593a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000587c:	10000613          	li	a2,256
    80005880:	4581                	li	a1,0
    80005882:	e4040513          	addi	a0,s0,-448
    80005886:	ffffb097          	auipc	ra,0xffffb
    8000588a:	438080e7          	jalr	1080(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000588e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005892:	89a6                	mv	s3,s1
    80005894:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005896:	02000a13          	li	s4,32
    8000589a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000589e:	00391793          	slli	a5,s2,0x3
    800058a2:	e3040593          	addi	a1,s0,-464
    800058a6:	e3843503          	ld	a0,-456(s0)
    800058aa:	953e                	add	a0,a0,a5
    800058ac:	ffffd097          	auipc	ra,0xffffd
    800058b0:	0e8080e7          	jalr	232(ra) # 80002994 <fetchaddr>
    800058b4:	02054a63          	bltz	a0,800058e8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800058b8:	e3043783          	ld	a5,-464(s0)
    800058bc:	c3b9                	beqz	a5,80005902 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800058be:	ffffb097          	auipc	ra,0xffffb
    800058c2:	214080e7          	jalr	532(ra) # 80000ad2 <kalloc>
    800058c6:	85aa                	mv	a1,a0
    800058c8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800058cc:	cd11                	beqz	a0,800058e8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800058ce:	6605                	lui	a2,0x1
    800058d0:	e3043503          	ld	a0,-464(s0)
    800058d4:	ffffd097          	auipc	ra,0xffffd
    800058d8:	112080e7          	jalr	274(ra) # 800029e6 <fetchstr>
    800058dc:	00054663          	bltz	a0,800058e8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800058e0:	0905                	addi	s2,s2,1
    800058e2:	09a1                	addi	s3,s3,8
    800058e4:	fb491be3          	bne	s2,s4,8000589a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800058e8:	10048913          	addi	s2,s1,256
    800058ec:	6088                	ld	a0,0(s1)
    800058ee:	c529                	beqz	a0,80005938 <sys_exec+0xf8>
    kfree(argv[i]);
    800058f0:	ffffb097          	auipc	ra,0xffffb
    800058f4:	0e6080e7          	jalr	230(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800058f8:	04a1                	addi	s1,s1,8
    800058fa:	ff2499e3          	bne	s1,s2,800058ec <sys_exec+0xac>
  return -1;
    800058fe:	597d                	li	s2,-1
    80005900:	a82d                	j	8000593a <sys_exec+0xfa>
      argv[i] = 0;
    80005902:	0a8e                	slli	s5,s5,0x3
    80005904:	fc040793          	addi	a5,s0,-64
    80005908:	9abe                	add	s5,s5,a5
    8000590a:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    8000590e:	e4040593          	addi	a1,s0,-448
    80005912:	f4040513          	addi	a0,s0,-192
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	178080e7          	jalr	376(ra) # 80004a8e <exec>
    8000591e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005920:	10048993          	addi	s3,s1,256
    80005924:	6088                	ld	a0,0(s1)
    80005926:	c911                	beqz	a0,8000593a <sys_exec+0xfa>
    kfree(argv[i]);
    80005928:	ffffb097          	auipc	ra,0xffffb
    8000592c:	0ae080e7          	jalr	174(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005930:	04a1                	addi	s1,s1,8
    80005932:	ff3499e3          	bne	s1,s3,80005924 <sys_exec+0xe4>
    80005936:	a011                	j	8000593a <sys_exec+0xfa>
  return -1;
    80005938:	597d                	li	s2,-1
}
    8000593a:	854a                	mv	a0,s2
    8000593c:	60be                	ld	ra,456(sp)
    8000593e:	641e                	ld	s0,448(sp)
    80005940:	74fa                	ld	s1,440(sp)
    80005942:	795a                	ld	s2,432(sp)
    80005944:	79ba                	ld	s3,424(sp)
    80005946:	7a1a                	ld	s4,416(sp)
    80005948:	6afa                	ld	s5,408(sp)
    8000594a:	6179                	addi	sp,sp,464
    8000594c:	8082                	ret

000000008000594e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000594e:	7139                	addi	sp,sp,-64
    80005950:	fc06                	sd	ra,56(sp)
    80005952:	f822                	sd	s0,48(sp)
    80005954:	f426                	sd	s1,40(sp)
    80005956:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005958:	ffffc097          	auipc	ra,0xffffc
    8000595c:	026080e7          	jalr	38(ra) # 8000197e <myproc>
    80005960:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005962:	fd840593          	addi	a1,s0,-40
    80005966:	4501                	li	a0,0
    80005968:	ffffd097          	auipc	ra,0xffffd
    8000596c:	0e8080e7          	jalr	232(ra) # 80002a50 <argaddr>
    return -1;
    80005970:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005972:	0e054063          	bltz	a0,80005a52 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005976:	fc840593          	addi	a1,s0,-56
    8000597a:	fd040513          	addi	a0,s0,-48
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	dee080e7          	jalr	-530(ra) # 8000476c <pipealloc>
    return -1;
    80005986:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005988:	0c054563          	bltz	a0,80005a52 <sys_pipe+0x104>
  fd0 = -1;
    8000598c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005990:	fd043503          	ld	a0,-48(s0)
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	50a080e7          	jalr	1290(ra) # 80004e9e <fdalloc>
    8000599c:	fca42223          	sw	a0,-60(s0)
    800059a0:	08054c63          	bltz	a0,80005a38 <sys_pipe+0xea>
    800059a4:	fc843503          	ld	a0,-56(s0)
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	4f6080e7          	jalr	1270(ra) # 80004e9e <fdalloc>
    800059b0:	fca42023          	sw	a0,-64(s0)
    800059b4:	06054863          	bltz	a0,80005a24 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800059b8:	4691                	li	a3,4
    800059ba:	fc440613          	addi	a2,s0,-60
    800059be:	fd843583          	ld	a1,-40(s0)
    800059c2:	68a8                	ld	a0,80(s1)
    800059c4:	ffffc097          	auipc	ra,0xffffc
    800059c8:	c7a080e7          	jalr	-902(ra) # 8000163e <copyout>
    800059cc:	02054063          	bltz	a0,800059ec <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800059d0:	4691                	li	a3,4
    800059d2:	fc040613          	addi	a2,s0,-64
    800059d6:	fd843583          	ld	a1,-40(s0)
    800059da:	0591                	addi	a1,a1,4
    800059dc:	68a8                	ld	a0,80(s1)
    800059de:	ffffc097          	auipc	ra,0xffffc
    800059e2:	c60080e7          	jalr	-928(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800059e6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800059e8:	06055563          	bgez	a0,80005a52 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800059ec:	fc442783          	lw	a5,-60(s0)
    800059f0:	07e9                	addi	a5,a5,26
    800059f2:	078e                	slli	a5,a5,0x3
    800059f4:	97a6                	add	a5,a5,s1
    800059f6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800059fa:	fc042503          	lw	a0,-64(s0)
    800059fe:	0569                	addi	a0,a0,26
    80005a00:	050e                	slli	a0,a0,0x3
    80005a02:	9526                	add	a0,a0,s1
    80005a04:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a08:	fd043503          	ld	a0,-48(s0)
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	a30080e7          	jalr	-1488(ra) # 8000443c <fileclose>
    fileclose(wf);
    80005a14:	fc843503          	ld	a0,-56(s0)
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	a24080e7          	jalr	-1500(ra) # 8000443c <fileclose>
    return -1;
    80005a20:	57fd                	li	a5,-1
    80005a22:	a805                	j	80005a52 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a24:	fc442783          	lw	a5,-60(s0)
    80005a28:	0007c863          	bltz	a5,80005a38 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a2c:	01a78513          	addi	a0,a5,26
    80005a30:	050e                	slli	a0,a0,0x3
    80005a32:	9526                	add	a0,a0,s1
    80005a34:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a38:	fd043503          	ld	a0,-48(s0)
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	a00080e7          	jalr	-1536(ra) # 8000443c <fileclose>
    fileclose(wf);
    80005a44:	fc843503          	ld	a0,-56(s0)
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	9f4080e7          	jalr	-1548(ra) # 8000443c <fileclose>
    return -1;
    80005a50:	57fd                	li	a5,-1
}
    80005a52:	853e                	mv	a0,a5
    80005a54:	70e2                	ld	ra,56(sp)
    80005a56:	7442                	ld	s0,48(sp)
    80005a58:	74a2                	ld	s1,40(sp)
    80005a5a:	6121                	addi	sp,sp,64
    80005a5c:	8082                	ret
	...

0000000080005a60 <kernelvec>:
    80005a60:	7111                	addi	sp,sp,-256
    80005a62:	e006                	sd	ra,0(sp)
    80005a64:	e40a                	sd	sp,8(sp)
    80005a66:	e80e                	sd	gp,16(sp)
    80005a68:	ec12                	sd	tp,24(sp)
    80005a6a:	f016                	sd	t0,32(sp)
    80005a6c:	f41a                	sd	t1,40(sp)
    80005a6e:	f81e                	sd	t2,48(sp)
    80005a70:	fc22                	sd	s0,56(sp)
    80005a72:	e0a6                	sd	s1,64(sp)
    80005a74:	e4aa                	sd	a0,72(sp)
    80005a76:	e8ae                	sd	a1,80(sp)
    80005a78:	ecb2                	sd	a2,88(sp)
    80005a7a:	f0b6                	sd	a3,96(sp)
    80005a7c:	f4ba                	sd	a4,104(sp)
    80005a7e:	f8be                	sd	a5,112(sp)
    80005a80:	fcc2                	sd	a6,120(sp)
    80005a82:	e146                	sd	a7,128(sp)
    80005a84:	e54a                	sd	s2,136(sp)
    80005a86:	e94e                	sd	s3,144(sp)
    80005a88:	ed52                	sd	s4,152(sp)
    80005a8a:	f156                	sd	s5,160(sp)
    80005a8c:	f55a                	sd	s6,168(sp)
    80005a8e:	f95e                	sd	s7,176(sp)
    80005a90:	fd62                	sd	s8,184(sp)
    80005a92:	e1e6                	sd	s9,192(sp)
    80005a94:	e5ea                	sd	s10,200(sp)
    80005a96:	e9ee                	sd	s11,208(sp)
    80005a98:	edf2                	sd	t3,216(sp)
    80005a9a:	f1f6                	sd	t4,224(sp)
    80005a9c:	f5fa                	sd	t5,232(sp)
    80005a9e:	f9fe                	sd	t6,240(sp)
    80005aa0:	dc1fc0ef          	jal	ra,80002860 <kerneltrap>
    80005aa4:	6082                	ld	ra,0(sp)
    80005aa6:	6122                	ld	sp,8(sp)
    80005aa8:	61c2                	ld	gp,16(sp)
    80005aaa:	7282                	ld	t0,32(sp)
    80005aac:	7322                	ld	t1,40(sp)
    80005aae:	73c2                	ld	t2,48(sp)
    80005ab0:	7462                	ld	s0,56(sp)
    80005ab2:	6486                	ld	s1,64(sp)
    80005ab4:	6526                	ld	a0,72(sp)
    80005ab6:	65c6                	ld	a1,80(sp)
    80005ab8:	6666                	ld	a2,88(sp)
    80005aba:	7686                	ld	a3,96(sp)
    80005abc:	7726                	ld	a4,104(sp)
    80005abe:	77c6                	ld	a5,112(sp)
    80005ac0:	7866                	ld	a6,120(sp)
    80005ac2:	688a                	ld	a7,128(sp)
    80005ac4:	692a                	ld	s2,136(sp)
    80005ac6:	69ca                	ld	s3,144(sp)
    80005ac8:	6a6a                	ld	s4,152(sp)
    80005aca:	7a8a                	ld	s5,160(sp)
    80005acc:	7b2a                	ld	s6,168(sp)
    80005ace:	7bca                	ld	s7,176(sp)
    80005ad0:	7c6a                	ld	s8,184(sp)
    80005ad2:	6c8e                	ld	s9,192(sp)
    80005ad4:	6d2e                	ld	s10,200(sp)
    80005ad6:	6dce                	ld	s11,208(sp)
    80005ad8:	6e6e                	ld	t3,216(sp)
    80005ada:	7e8e                	ld	t4,224(sp)
    80005adc:	7f2e                	ld	t5,232(sp)
    80005ade:	7fce                	ld	t6,240(sp)
    80005ae0:	6111                	addi	sp,sp,256
    80005ae2:	10200073          	sret
    80005ae6:	00000013          	nop
    80005aea:	00000013          	nop
    80005aee:	0001                	nop

0000000080005af0 <timervec>:
    80005af0:	34051573          	csrrw	a0,mscratch,a0
    80005af4:	e10c                	sd	a1,0(a0)
    80005af6:	e510                	sd	a2,8(a0)
    80005af8:	e914                	sd	a3,16(a0)
    80005afa:	6d0c                	ld	a1,24(a0)
    80005afc:	7110                	ld	a2,32(a0)
    80005afe:	6194                	ld	a3,0(a1)
    80005b00:	96b2                	add	a3,a3,a2
    80005b02:	e194                	sd	a3,0(a1)
    80005b04:	4589                	li	a1,2
    80005b06:	14459073          	csrw	sip,a1
    80005b0a:	6914                	ld	a3,16(a0)
    80005b0c:	6510                	ld	a2,8(a0)
    80005b0e:	610c                	ld	a1,0(a0)
    80005b10:	34051573          	csrrw	a0,mscratch,a0
    80005b14:	30200073          	mret
	...

0000000080005b1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b1a:	1141                	addi	sp,sp,-16
    80005b1c:	e422                	sd	s0,8(sp)
    80005b1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b20:	0c0007b7          	lui	a5,0xc000
    80005b24:	4705                	li	a4,1
    80005b26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b28:	c3d8                	sw	a4,4(a5)
}
    80005b2a:	6422                	ld	s0,8(sp)
    80005b2c:	0141                	addi	sp,sp,16
    80005b2e:	8082                	ret

0000000080005b30 <plicinithart>:

void
plicinithart(void)
{
    80005b30:	1141                	addi	sp,sp,-16
    80005b32:	e406                	sd	ra,8(sp)
    80005b34:	e022                	sd	s0,0(sp)
    80005b36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b38:	ffffc097          	auipc	ra,0xffffc
    80005b3c:	e1a080e7          	jalr	-486(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005b40:	0085171b          	slliw	a4,a0,0x8
    80005b44:	0c0027b7          	lui	a5,0xc002
    80005b48:	97ba                	add	a5,a5,a4
    80005b4a:	40200713          	li	a4,1026
    80005b4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005b52:	00d5151b          	slliw	a0,a0,0xd
    80005b56:	0c2017b7          	lui	a5,0xc201
    80005b5a:	953e                	add	a0,a0,a5
    80005b5c:	00052023          	sw	zero,0(a0)
}
    80005b60:	60a2                	ld	ra,8(sp)
    80005b62:	6402                	ld	s0,0(sp)
    80005b64:	0141                	addi	sp,sp,16
    80005b66:	8082                	ret

0000000080005b68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005b68:	1141                	addi	sp,sp,-16
    80005b6a:	e406                	sd	ra,8(sp)
    80005b6c:	e022                	sd	s0,0(sp)
    80005b6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b70:	ffffc097          	auipc	ra,0xffffc
    80005b74:	de2080e7          	jalr	-542(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005b78:	00d5179b          	slliw	a5,a0,0xd
    80005b7c:	0c201537          	lui	a0,0xc201
    80005b80:	953e                	add	a0,a0,a5
  return irq;
}
    80005b82:	4148                	lw	a0,4(a0)
    80005b84:	60a2                	ld	ra,8(sp)
    80005b86:	6402                	ld	s0,0(sp)
    80005b88:	0141                	addi	sp,sp,16
    80005b8a:	8082                	ret

0000000080005b8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005b8c:	1101                	addi	sp,sp,-32
    80005b8e:	ec06                	sd	ra,24(sp)
    80005b90:	e822                	sd	s0,16(sp)
    80005b92:	e426                	sd	s1,8(sp)
    80005b94:	1000                	addi	s0,sp,32
    80005b96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005b98:	ffffc097          	auipc	ra,0xffffc
    80005b9c:	dba080e7          	jalr	-582(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ba0:	00d5151b          	slliw	a0,a0,0xd
    80005ba4:	0c2017b7          	lui	a5,0xc201
    80005ba8:	97aa                	add	a5,a5,a0
    80005baa:	c3c4                	sw	s1,4(a5)
}
    80005bac:	60e2                	ld	ra,24(sp)
    80005bae:	6442                	ld	s0,16(sp)
    80005bb0:	64a2                	ld	s1,8(sp)
    80005bb2:	6105                	addi	sp,sp,32
    80005bb4:	8082                	ret

0000000080005bb6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005bb6:	1141                	addi	sp,sp,-16
    80005bb8:	e406                	sd	ra,8(sp)
    80005bba:	e022                	sd	s0,0(sp)
    80005bbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005bbe:	479d                	li	a5,7
    80005bc0:	06a7c963          	blt	a5,a0,80005c32 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005bc4:	0001d797          	auipc	a5,0x1d
    80005bc8:	43c78793          	addi	a5,a5,1084 # 80023000 <disk>
    80005bcc:	00a78733          	add	a4,a5,a0
    80005bd0:	6789                	lui	a5,0x2
    80005bd2:	97ba                	add	a5,a5,a4
    80005bd4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005bd8:	e7ad                	bnez	a5,80005c42 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005bda:	00451793          	slli	a5,a0,0x4
    80005bde:	0001f717          	auipc	a4,0x1f
    80005be2:	42270713          	addi	a4,a4,1058 # 80025000 <disk+0x2000>
    80005be6:	6314                	ld	a3,0(a4)
    80005be8:	96be                	add	a3,a3,a5
    80005bea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005bee:	6314                	ld	a3,0(a4)
    80005bf0:	96be                	add	a3,a3,a5
    80005bf2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005bf6:	6314                	ld	a3,0(a4)
    80005bf8:	96be                	add	a3,a3,a5
    80005bfa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005bfe:	6318                	ld	a4,0(a4)
    80005c00:	97ba                	add	a5,a5,a4
    80005c02:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005c06:	0001d797          	auipc	a5,0x1d
    80005c0a:	3fa78793          	addi	a5,a5,1018 # 80023000 <disk>
    80005c0e:	97aa                	add	a5,a5,a0
    80005c10:	6509                	lui	a0,0x2
    80005c12:	953e                	add	a0,a0,a5
    80005c14:	4785                	li	a5,1
    80005c16:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005c1a:	0001f517          	auipc	a0,0x1f
    80005c1e:	3fe50513          	addi	a0,a0,1022 # 80025018 <disk+0x2018>
    80005c22:	ffffc097          	auipc	ra,0xffffc
    80005c26:	5a8080e7          	jalr	1448(ra) # 800021ca <wakeup>
}
    80005c2a:	60a2                	ld	ra,8(sp)
    80005c2c:	6402                	ld	s0,0(sp)
    80005c2e:	0141                	addi	sp,sp,16
    80005c30:	8082                	ret
    panic("free_desc 1");
    80005c32:	00003517          	auipc	a0,0x3
    80005c36:	b1e50513          	addi	a0,a0,-1250 # 80008750 <syscalls+0x320>
    80005c3a:	ffffb097          	auipc	ra,0xffffb
    80005c3e:	8f0080e7          	jalr	-1808(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005c42:	00003517          	auipc	a0,0x3
    80005c46:	b1e50513          	addi	a0,a0,-1250 # 80008760 <syscalls+0x330>
    80005c4a:	ffffb097          	auipc	ra,0xffffb
    80005c4e:	8e0080e7          	jalr	-1824(ra) # 8000052a <panic>

0000000080005c52 <virtio_disk_init>:
{
    80005c52:	1101                	addi	sp,sp,-32
    80005c54:	ec06                	sd	ra,24(sp)
    80005c56:	e822                	sd	s0,16(sp)
    80005c58:	e426                	sd	s1,8(sp)
    80005c5a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005c5c:	00003597          	auipc	a1,0x3
    80005c60:	b1458593          	addi	a1,a1,-1260 # 80008770 <syscalls+0x340>
    80005c64:	0001f517          	auipc	a0,0x1f
    80005c68:	4c450513          	addi	a0,a0,1220 # 80025128 <disk+0x2128>
    80005c6c:	ffffb097          	auipc	ra,0xffffb
    80005c70:	ec6080e7          	jalr	-314(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005c74:	100017b7          	lui	a5,0x10001
    80005c78:	4398                	lw	a4,0(a5)
    80005c7a:	2701                	sext.w	a4,a4
    80005c7c:	747277b7          	lui	a5,0x74727
    80005c80:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005c84:	0ef71163          	bne	a4,a5,80005d66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005c88:	100017b7          	lui	a5,0x10001
    80005c8c:	43dc                	lw	a5,4(a5)
    80005c8e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005c90:	4705                	li	a4,1
    80005c92:	0ce79a63          	bne	a5,a4,80005d66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005c96:	100017b7          	lui	a5,0x10001
    80005c9a:	479c                	lw	a5,8(a5)
    80005c9c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005c9e:	4709                	li	a4,2
    80005ca0:	0ce79363          	bne	a5,a4,80005d66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ca4:	100017b7          	lui	a5,0x10001
    80005ca8:	47d8                	lw	a4,12(a5)
    80005caa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cac:	554d47b7          	lui	a5,0x554d4
    80005cb0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005cb4:	0af71963          	bne	a4,a5,80005d66 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cb8:	100017b7          	lui	a5,0x10001
    80005cbc:	4705                	li	a4,1
    80005cbe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cc0:	470d                	li	a4,3
    80005cc2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005cc4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005cc6:	c7ffe737          	lui	a4,0xc7ffe
    80005cca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005cce:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005cd0:	2701                	sext.w	a4,a4
    80005cd2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cd4:	472d                	li	a4,11
    80005cd6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cd8:	473d                	li	a4,15
    80005cda:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005cdc:	6705                	lui	a4,0x1
    80005cde:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ce0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ce4:	5bdc                	lw	a5,52(a5)
    80005ce6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ce8:	c7d9                	beqz	a5,80005d76 <virtio_disk_init+0x124>
  if(max < NUM)
    80005cea:	471d                	li	a4,7
    80005cec:	08f77d63          	bgeu	a4,a5,80005d86 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005cf0:	100014b7          	lui	s1,0x10001
    80005cf4:	47a1                	li	a5,8
    80005cf6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005cf8:	6609                	lui	a2,0x2
    80005cfa:	4581                	li	a1,0
    80005cfc:	0001d517          	auipc	a0,0x1d
    80005d00:	30450513          	addi	a0,a0,772 # 80023000 <disk>
    80005d04:	ffffb097          	auipc	ra,0xffffb
    80005d08:	fba080e7          	jalr	-70(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d0c:	0001d717          	auipc	a4,0x1d
    80005d10:	2f470713          	addi	a4,a4,756 # 80023000 <disk>
    80005d14:	00c75793          	srli	a5,a4,0xc
    80005d18:	2781                	sext.w	a5,a5
    80005d1a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005d1c:	0001f797          	auipc	a5,0x1f
    80005d20:	2e478793          	addi	a5,a5,740 # 80025000 <disk+0x2000>
    80005d24:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005d26:	0001d717          	auipc	a4,0x1d
    80005d2a:	35a70713          	addi	a4,a4,858 # 80023080 <disk+0x80>
    80005d2e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005d30:	0001e717          	auipc	a4,0x1e
    80005d34:	2d070713          	addi	a4,a4,720 # 80024000 <disk+0x1000>
    80005d38:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005d3a:	4705                	li	a4,1
    80005d3c:	00e78c23          	sb	a4,24(a5)
    80005d40:	00e78ca3          	sb	a4,25(a5)
    80005d44:	00e78d23          	sb	a4,26(a5)
    80005d48:	00e78da3          	sb	a4,27(a5)
    80005d4c:	00e78e23          	sb	a4,28(a5)
    80005d50:	00e78ea3          	sb	a4,29(a5)
    80005d54:	00e78f23          	sb	a4,30(a5)
    80005d58:	00e78fa3          	sb	a4,31(a5)
}
    80005d5c:	60e2                	ld	ra,24(sp)
    80005d5e:	6442                	ld	s0,16(sp)
    80005d60:	64a2                	ld	s1,8(sp)
    80005d62:	6105                	addi	sp,sp,32
    80005d64:	8082                	ret
    panic("could not find virtio disk");
    80005d66:	00003517          	auipc	a0,0x3
    80005d6a:	a1a50513          	addi	a0,a0,-1510 # 80008780 <syscalls+0x350>
    80005d6e:	ffffa097          	auipc	ra,0xffffa
    80005d72:	7bc080e7          	jalr	1980(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80005d76:	00003517          	auipc	a0,0x3
    80005d7a:	a2a50513          	addi	a0,a0,-1494 # 800087a0 <syscalls+0x370>
    80005d7e:	ffffa097          	auipc	ra,0xffffa
    80005d82:	7ac080e7          	jalr	1964(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80005d86:	00003517          	auipc	a0,0x3
    80005d8a:	a3a50513          	addi	a0,a0,-1478 # 800087c0 <syscalls+0x390>
    80005d8e:	ffffa097          	auipc	ra,0xffffa
    80005d92:	79c080e7          	jalr	1948(ra) # 8000052a <panic>

0000000080005d96 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005d96:	7119                	addi	sp,sp,-128
    80005d98:	fc86                	sd	ra,120(sp)
    80005d9a:	f8a2                	sd	s0,112(sp)
    80005d9c:	f4a6                	sd	s1,104(sp)
    80005d9e:	f0ca                	sd	s2,96(sp)
    80005da0:	ecce                	sd	s3,88(sp)
    80005da2:	e8d2                	sd	s4,80(sp)
    80005da4:	e4d6                	sd	s5,72(sp)
    80005da6:	e0da                	sd	s6,64(sp)
    80005da8:	fc5e                	sd	s7,56(sp)
    80005daa:	f862                	sd	s8,48(sp)
    80005dac:	f466                	sd	s9,40(sp)
    80005dae:	f06a                	sd	s10,32(sp)
    80005db0:	ec6e                	sd	s11,24(sp)
    80005db2:	0100                	addi	s0,sp,128
    80005db4:	8aaa                	mv	s5,a0
    80005db6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005db8:	00c52c83          	lw	s9,12(a0)
    80005dbc:	001c9c9b          	slliw	s9,s9,0x1
    80005dc0:	1c82                	slli	s9,s9,0x20
    80005dc2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005dc6:	0001f517          	auipc	a0,0x1f
    80005dca:	36250513          	addi	a0,a0,866 # 80025128 <disk+0x2128>
    80005dce:	ffffb097          	auipc	ra,0xffffb
    80005dd2:	df4080e7          	jalr	-524(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80005dd6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005dd8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005dda:	0001dc17          	auipc	s8,0x1d
    80005dde:	226c0c13          	addi	s8,s8,550 # 80023000 <disk>
    80005de2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005de4:	4b0d                	li	s6,3
    80005de6:	a0ad                	j	80005e50 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005de8:	00fc0733          	add	a4,s8,a5
    80005dec:	975e                	add	a4,a4,s7
    80005dee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005df2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005df4:	0207c563          	bltz	a5,80005e1e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005df8:	2905                	addiw	s2,s2,1
    80005dfa:	0611                	addi	a2,a2,4
    80005dfc:	19690d63          	beq	s2,s6,80005f96 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005e00:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005e02:	0001f717          	auipc	a4,0x1f
    80005e06:	21670713          	addi	a4,a4,534 # 80025018 <disk+0x2018>
    80005e0a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005e0c:	00074683          	lbu	a3,0(a4)
    80005e10:	fee1                	bnez	a3,80005de8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e12:	2785                	addiw	a5,a5,1
    80005e14:	0705                	addi	a4,a4,1
    80005e16:	fe979be3          	bne	a5,s1,80005e0c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e1a:	57fd                	li	a5,-1
    80005e1c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005e1e:	01205d63          	blez	s2,80005e38 <virtio_disk_rw+0xa2>
    80005e22:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005e24:	000a2503          	lw	a0,0(s4)
    80005e28:	00000097          	auipc	ra,0x0
    80005e2c:	d8e080e7          	jalr	-626(ra) # 80005bb6 <free_desc>
      for(int j = 0; j < i; j++)
    80005e30:	2d85                	addiw	s11,s11,1
    80005e32:	0a11                	addi	s4,s4,4
    80005e34:	ffb918e3          	bne	s2,s11,80005e24 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005e38:	0001f597          	auipc	a1,0x1f
    80005e3c:	2f058593          	addi	a1,a1,752 # 80025128 <disk+0x2128>
    80005e40:	0001f517          	auipc	a0,0x1f
    80005e44:	1d850513          	addi	a0,a0,472 # 80025018 <disk+0x2018>
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	1f6080e7          	jalr	502(ra) # 8000203e <sleep>
  for(int i = 0; i < 3; i++){
    80005e50:	f8040a13          	addi	s4,s0,-128
{
    80005e54:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005e56:	894e                	mv	s2,s3
    80005e58:	b765                	j	80005e00 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005e5a:	0001f697          	auipc	a3,0x1f
    80005e5e:	1a66b683          	ld	a3,422(a3) # 80025000 <disk+0x2000>
    80005e62:	96ba                	add	a3,a3,a4
    80005e64:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005e68:	0001d817          	auipc	a6,0x1d
    80005e6c:	19880813          	addi	a6,a6,408 # 80023000 <disk>
    80005e70:	0001f697          	auipc	a3,0x1f
    80005e74:	19068693          	addi	a3,a3,400 # 80025000 <disk+0x2000>
    80005e78:	6290                	ld	a2,0(a3)
    80005e7a:	963a                	add	a2,a2,a4
    80005e7c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80005e80:	0015e593          	ori	a1,a1,1
    80005e84:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005e88:	f8842603          	lw	a2,-120(s0)
    80005e8c:	628c                	ld	a1,0(a3)
    80005e8e:	972e                	add	a4,a4,a1
    80005e90:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005e94:	20050593          	addi	a1,a0,512
    80005e98:	0592                	slli	a1,a1,0x4
    80005e9a:	95c2                	add	a1,a1,a6
    80005e9c:	577d                	li	a4,-1
    80005e9e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005ea2:	00461713          	slli	a4,a2,0x4
    80005ea6:	6290                	ld	a2,0(a3)
    80005ea8:	963a                	add	a2,a2,a4
    80005eaa:	03078793          	addi	a5,a5,48
    80005eae:	97c2                	add	a5,a5,a6
    80005eb0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80005eb2:	629c                	ld	a5,0(a3)
    80005eb4:	97ba                	add	a5,a5,a4
    80005eb6:	4605                	li	a2,1
    80005eb8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005eba:	629c                	ld	a5,0(a3)
    80005ebc:	97ba                	add	a5,a5,a4
    80005ebe:	4809                	li	a6,2
    80005ec0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005ec4:	629c                	ld	a5,0(a3)
    80005ec6:	973e                	add	a4,a4,a5
    80005ec8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005ecc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80005ed0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005ed4:	6698                	ld	a4,8(a3)
    80005ed6:	00275783          	lhu	a5,2(a4)
    80005eda:	8b9d                	andi	a5,a5,7
    80005edc:	0786                	slli	a5,a5,0x1
    80005ede:	97ba                	add	a5,a5,a4
    80005ee0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80005ee4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005ee8:	6698                	ld	a4,8(a3)
    80005eea:	00275783          	lhu	a5,2(a4)
    80005eee:	2785                	addiw	a5,a5,1
    80005ef0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005ef4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005ef8:	100017b7          	lui	a5,0x10001
    80005efc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005f00:	004aa783          	lw	a5,4(s5)
    80005f04:	02c79163          	bne	a5,a2,80005f26 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80005f08:	0001f917          	auipc	s2,0x1f
    80005f0c:	22090913          	addi	s2,s2,544 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80005f10:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005f12:	85ca                	mv	a1,s2
    80005f14:	8556                	mv	a0,s5
    80005f16:	ffffc097          	auipc	ra,0xffffc
    80005f1a:	128080e7          	jalr	296(ra) # 8000203e <sleep>
  while(b->disk == 1) {
    80005f1e:	004aa783          	lw	a5,4(s5)
    80005f22:	fe9788e3          	beq	a5,s1,80005f12 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80005f26:	f8042903          	lw	s2,-128(s0)
    80005f2a:	20090793          	addi	a5,s2,512
    80005f2e:	00479713          	slli	a4,a5,0x4
    80005f32:	0001d797          	auipc	a5,0x1d
    80005f36:	0ce78793          	addi	a5,a5,206 # 80023000 <disk>
    80005f3a:	97ba                	add	a5,a5,a4
    80005f3c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80005f40:	0001f997          	auipc	s3,0x1f
    80005f44:	0c098993          	addi	s3,s3,192 # 80025000 <disk+0x2000>
    80005f48:	00491713          	slli	a4,s2,0x4
    80005f4c:	0009b783          	ld	a5,0(s3)
    80005f50:	97ba                	add	a5,a5,a4
    80005f52:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005f56:	854a                	mv	a0,s2
    80005f58:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005f5c:	00000097          	auipc	ra,0x0
    80005f60:	c5a080e7          	jalr	-934(ra) # 80005bb6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005f64:	8885                	andi	s1,s1,1
    80005f66:	f0ed                	bnez	s1,80005f48 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005f68:	0001f517          	auipc	a0,0x1f
    80005f6c:	1c050513          	addi	a0,a0,448 # 80025128 <disk+0x2128>
    80005f70:	ffffb097          	auipc	ra,0xffffb
    80005f74:	d06080e7          	jalr	-762(ra) # 80000c76 <release>
}
    80005f78:	70e6                	ld	ra,120(sp)
    80005f7a:	7446                	ld	s0,112(sp)
    80005f7c:	74a6                	ld	s1,104(sp)
    80005f7e:	7906                	ld	s2,96(sp)
    80005f80:	69e6                	ld	s3,88(sp)
    80005f82:	6a46                	ld	s4,80(sp)
    80005f84:	6aa6                	ld	s5,72(sp)
    80005f86:	6b06                	ld	s6,64(sp)
    80005f88:	7be2                	ld	s7,56(sp)
    80005f8a:	7c42                	ld	s8,48(sp)
    80005f8c:	7ca2                	ld	s9,40(sp)
    80005f8e:	7d02                	ld	s10,32(sp)
    80005f90:	6de2                	ld	s11,24(sp)
    80005f92:	6109                	addi	sp,sp,128
    80005f94:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005f96:	f8042503          	lw	a0,-128(s0)
    80005f9a:	20050793          	addi	a5,a0,512
    80005f9e:	0792                	slli	a5,a5,0x4
  if(write)
    80005fa0:	0001d817          	auipc	a6,0x1d
    80005fa4:	06080813          	addi	a6,a6,96 # 80023000 <disk>
    80005fa8:	00f80733          	add	a4,a6,a5
    80005fac:	01a036b3          	snez	a3,s10
    80005fb0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80005fb4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005fb8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005fbc:	7679                	lui	a2,0xffffe
    80005fbe:	963e                	add	a2,a2,a5
    80005fc0:	0001f697          	auipc	a3,0x1f
    80005fc4:	04068693          	addi	a3,a3,64 # 80025000 <disk+0x2000>
    80005fc8:	6298                	ld	a4,0(a3)
    80005fca:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005fcc:	0a878593          	addi	a1,a5,168
    80005fd0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005fd2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005fd4:	6298                	ld	a4,0(a3)
    80005fd6:	9732                	add	a4,a4,a2
    80005fd8:	45c1                	li	a1,16
    80005fda:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005fdc:	6298                	ld	a4,0(a3)
    80005fde:	9732                	add	a4,a4,a2
    80005fe0:	4585                	li	a1,1
    80005fe2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005fe6:	f8442703          	lw	a4,-124(s0)
    80005fea:	628c                	ld	a1,0(a3)
    80005fec:	962e                	add	a2,a2,a1
    80005fee:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80005ff2:	0712                	slli	a4,a4,0x4
    80005ff4:	6290                	ld	a2,0(a3)
    80005ff6:	963a                	add	a2,a2,a4
    80005ff8:	058a8593          	addi	a1,s5,88
    80005ffc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005ffe:	6294                	ld	a3,0(a3)
    80006000:	96ba                	add	a3,a3,a4
    80006002:	40000613          	li	a2,1024
    80006006:	c690                	sw	a2,8(a3)
  if(write)
    80006008:	e40d19e3          	bnez	s10,80005e5a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000600c:	0001f697          	auipc	a3,0x1f
    80006010:	ff46b683          	ld	a3,-12(a3) # 80025000 <disk+0x2000>
    80006014:	96ba                	add	a3,a3,a4
    80006016:	4609                	li	a2,2
    80006018:	00c69623          	sh	a2,12(a3)
    8000601c:	b5b1                	j	80005e68 <virtio_disk_rw+0xd2>

000000008000601e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000601e:	1101                	addi	sp,sp,-32
    80006020:	ec06                	sd	ra,24(sp)
    80006022:	e822                	sd	s0,16(sp)
    80006024:	e426                	sd	s1,8(sp)
    80006026:	e04a                	sd	s2,0(sp)
    80006028:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000602a:	0001f517          	auipc	a0,0x1f
    8000602e:	0fe50513          	addi	a0,a0,254 # 80025128 <disk+0x2128>
    80006032:	ffffb097          	auipc	ra,0xffffb
    80006036:	b90080e7          	jalr	-1136(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000603a:	10001737          	lui	a4,0x10001
    8000603e:	533c                	lw	a5,96(a4)
    80006040:	8b8d                	andi	a5,a5,3
    80006042:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006044:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006048:	0001f797          	auipc	a5,0x1f
    8000604c:	fb878793          	addi	a5,a5,-72 # 80025000 <disk+0x2000>
    80006050:	6b94                	ld	a3,16(a5)
    80006052:	0207d703          	lhu	a4,32(a5)
    80006056:	0026d783          	lhu	a5,2(a3)
    8000605a:	06f70163          	beq	a4,a5,800060bc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000605e:	0001d917          	auipc	s2,0x1d
    80006062:	fa290913          	addi	s2,s2,-94 # 80023000 <disk>
    80006066:	0001f497          	auipc	s1,0x1f
    8000606a:	f9a48493          	addi	s1,s1,-102 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000606e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006072:	6898                	ld	a4,16(s1)
    80006074:	0204d783          	lhu	a5,32(s1)
    80006078:	8b9d                	andi	a5,a5,7
    8000607a:	078e                	slli	a5,a5,0x3
    8000607c:	97ba                	add	a5,a5,a4
    8000607e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006080:	20078713          	addi	a4,a5,512
    80006084:	0712                	slli	a4,a4,0x4
    80006086:	974a                	add	a4,a4,s2
    80006088:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000608c:	e731                	bnez	a4,800060d8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000608e:	20078793          	addi	a5,a5,512
    80006092:	0792                	slli	a5,a5,0x4
    80006094:	97ca                	add	a5,a5,s2
    80006096:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006098:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000609c:	ffffc097          	auipc	ra,0xffffc
    800060a0:	12e080e7          	jalr	302(ra) # 800021ca <wakeup>

    disk.used_idx += 1;
    800060a4:	0204d783          	lhu	a5,32(s1)
    800060a8:	2785                	addiw	a5,a5,1
    800060aa:	17c2                	slli	a5,a5,0x30
    800060ac:	93c1                	srli	a5,a5,0x30
    800060ae:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800060b2:	6898                	ld	a4,16(s1)
    800060b4:	00275703          	lhu	a4,2(a4)
    800060b8:	faf71be3          	bne	a4,a5,8000606e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800060bc:	0001f517          	auipc	a0,0x1f
    800060c0:	06c50513          	addi	a0,a0,108 # 80025128 <disk+0x2128>
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	bb2080e7          	jalr	-1102(ra) # 80000c76 <release>
}
    800060cc:	60e2                	ld	ra,24(sp)
    800060ce:	6442                	ld	s0,16(sp)
    800060d0:	64a2                	ld	s1,8(sp)
    800060d2:	6902                	ld	s2,0(sp)
    800060d4:	6105                	addi	sp,sp,32
    800060d6:	8082                	ret
      panic("virtio_disk_intr status");
    800060d8:	00002517          	auipc	a0,0x2
    800060dc:	70850513          	addi	a0,a0,1800 # 800087e0 <syscalls+0x3b0>
    800060e0:	ffffa097          	auipc	ra,0xffffa
    800060e4:	44a080e7          	jalr	1098(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
