
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
static void test_exceptions(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00007517          	auipc	a0,0x7
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0207028 <free_area>
ffffffffc020005c:	00007617          	auipc	a2,0x7
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16 # ffffffffc0205ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	707010ef          	jal	ffffffffc0201f72 <memset>
    dtb_init();
ffffffffc0200070:	418000ef          	jal	ffffffffc0200488 <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	406000ef          	jal	ffffffffc020047a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00003517          	auipc	a0,0x3
ffffffffc020007c:	e5050513          	addi	a0,a0,-432 # ffffffffc0202ec8 <etext+0xf44>
ffffffffc0200080:	0de000ef          	jal	ffffffffc020015e <cputs>

    print_kerninfo();
ffffffffc0200084:	136000ef          	jal	ffffffffc02001ba <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	752000ef          	jal	ffffffffc02007da <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	77c010ef          	jal	ffffffffc0201808 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	74a000ef          	jal	ffffffffc02007da <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	3a4000ef          	jal	ffffffffc0200438 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	736000ef          	jal	ffffffffc02007ce <intr_enable>
}

void grade_backtrace(void) { grade_backtrace0(0, (uintptr_t)kern_init, 0xffff0000); }

void test_exceptions(void) {
    cprintf("\n=== Starting Exception Tests ===\n\n");
ffffffffc020009c:	00002517          	auipc	a0,0x2
ffffffffc02000a0:	eec50513          	addi	a0,a0,-276 # ffffffffc0201f88 <etext+0x4>
ffffffffc02000a4:	084000ef          	jal	ffffffffc0200128 <cprintf>
    
    // 测试1: 触发非法指令异常
    cprintf("1. Testing CAUSE_ILLEGAL_INSTRUCTION...\n");
ffffffffc02000a8:	00002517          	auipc	a0,0x2
ffffffffc02000ac:	f0850513          	addi	a0,a0,-248 # ffffffffc0201fb0 <etext+0x2c>
ffffffffc02000b0:	078000ef          	jal	ffffffffc0200128 <cprintf>
    __asm__ volatile (
ffffffffc02000b4:	00000000          	.word	0x00000000
ffffffffc02000b8:	0001                	nop
        ".word 0x00000000 \n"
        "nop                "
    );
    cprintf("Illegal instruction test completed.\n\n");
ffffffffc02000ba:	00002517          	auipc	a0,0x2
ffffffffc02000be:	f2650513          	addi	a0,a0,-218 # ffffffffc0201fe0 <etext+0x5c>
ffffffffc02000c2:	066000ef          	jal	ffffffffc0200128 <cprintf>
    
    // 测试2: 触发断点异常  
    cprintf("2. Testing CAUSE_BREAKPOINT...\n");
ffffffffc02000c6:	00002517          	auipc	a0,0x2
ffffffffc02000ca:	f4250513          	addi	a0,a0,-190 # ffffffffc0202008 <etext+0x84>
ffffffffc02000ce:	05a000ef          	jal	ffffffffc0200128 <cprintf>
    __asm__ volatile (
ffffffffc02000d2:	9002                	ebreak
ffffffffc02000d4:	0001                	nop
        "ebreak \n"
        "nop      "
    );
    cprintf("Breakpoint test completed.\n\n");
ffffffffc02000d6:	00002517          	auipc	a0,0x2
ffffffffc02000da:	f5250513          	addi	a0,a0,-174 # ffffffffc0202028 <etext+0xa4>
ffffffffc02000de:	04a000ef          	jal	ffffffffc0200128 <cprintf>
    
    cprintf("=== All Exception Tests Completed ===\n\n");
ffffffffc02000e2:	00002517          	auipc	a0,0x2
ffffffffc02000e6:	f6650513          	addi	a0,a0,-154 # ffffffffc0202048 <etext+0xc4>
ffffffffc02000ea:	03e000ef          	jal	ffffffffc0200128 <cprintf>
    while (1)
ffffffffc02000ee:	a001                	j	ffffffffc02000ee <kern_init+0x9a>

ffffffffc02000f0 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000f0:	1101                	addi	sp,sp,-32
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
ffffffffc02000f4:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc02000f6:	386000ef          	jal	ffffffffc020047c <cons_putc>
    (*cnt) ++;
ffffffffc02000fa:	65a2                	ld	a1,8(sp)
}
ffffffffc02000fc:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc02000fe:	419c                	lw	a5,0(a1)
ffffffffc0200100:	2785                	addiw	a5,a5,1
ffffffffc0200102:	c19c                	sw	a5,0(a1)
}
ffffffffc0200104:	6105                	addi	sp,sp,32
ffffffffc0200106:	8082                	ret

ffffffffc0200108 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200108:	1101                	addi	sp,sp,-32
ffffffffc020010a:	862a                	mv	a2,a0
ffffffffc020010c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020010e:	00000517          	auipc	a0,0x0
ffffffffc0200112:	fe250513          	addi	a0,a0,-30 # ffffffffc02000f0 <cputch>
ffffffffc0200116:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200118:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020011a:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020011c:	12f010ef          	jal	ffffffffc0201a4a <vprintfmt>
    return cnt;
}
ffffffffc0200120:	60e2                	ld	ra,24(sp)
ffffffffc0200122:	4532                	lw	a0,12(sp)
ffffffffc0200124:	6105                	addi	sp,sp,32
ffffffffc0200126:	8082                	ret

ffffffffc0200128 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200128:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020012a:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc020012e:	f42e                	sd	a1,40(sp)
ffffffffc0200130:	f832                	sd	a2,48(sp)
ffffffffc0200132:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200134:	862a                	mv	a2,a0
ffffffffc0200136:	004c                	addi	a1,sp,4
ffffffffc0200138:	00000517          	auipc	a0,0x0
ffffffffc020013c:	fb850513          	addi	a0,a0,-72 # ffffffffc02000f0 <cputch>
ffffffffc0200140:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200142:	ec06                	sd	ra,24(sp)
ffffffffc0200144:	e0ba                	sd	a4,64(sp)
ffffffffc0200146:	e4be                	sd	a5,72(sp)
ffffffffc0200148:	e8c2                	sd	a6,80(sp)
ffffffffc020014a:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc020014c:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc020014e:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200150:	0fb010ef          	jal	ffffffffc0201a4a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200154:	60e2                	ld	ra,24(sp)
ffffffffc0200156:	4512                	lw	a0,4(sp)
ffffffffc0200158:	6125                	addi	sp,sp,96
ffffffffc020015a:	8082                	ret

ffffffffc020015c <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020015c:	a605                	j	ffffffffc020047c <cons_putc>

ffffffffc020015e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020015e:	1101                	addi	sp,sp,-32
ffffffffc0200160:	e822                	sd	s0,16(sp)
ffffffffc0200162:	ec06                	sd	ra,24(sp)
ffffffffc0200164:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200166:	00054503          	lbu	a0,0(a0)
ffffffffc020016a:	c51d                	beqz	a0,ffffffffc0200198 <cputs+0x3a>
ffffffffc020016c:	e426                	sd	s1,8(sp)
ffffffffc020016e:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc0200170:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200172:	30a000ef          	jal	ffffffffc020047c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200176:	00044503          	lbu	a0,0(s0)
ffffffffc020017a:	0405                	addi	s0,s0,1
ffffffffc020017c:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc020017e:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc0200180:	f96d                	bnez	a0,ffffffffc0200172 <cputs+0x14>
    cons_putc(c);
ffffffffc0200182:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc0200184:	0027841b          	addiw	s0,a5,2
ffffffffc0200188:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc020018a:	2f2000ef          	jal	ffffffffc020047c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020018e:	60e2                	ld	ra,24(sp)
ffffffffc0200190:	8522                	mv	a0,s0
ffffffffc0200192:	6442                	ld	s0,16(sp)
ffffffffc0200194:	6105                	addi	sp,sp,32
ffffffffc0200196:	8082                	ret
    cons_putc(c);
ffffffffc0200198:	4529                	li	a0,10
ffffffffc020019a:	2e2000ef          	jal	ffffffffc020047c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019e:	4405                	li	s0,1
}
ffffffffc02001a0:	60e2                	ld	ra,24(sp)
ffffffffc02001a2:	8522                	mv	a0,s0
ffffffffc02001a4:	6442                	ld	s0,16(sp)
ffffffffc02001a6:	6105                	addi	sp,sp,32
ffffffffc02001a8:	8082                	ret

ffffffffc02001aa <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02001aa:	1141                	addi	sp,sp,-16
ffffffffc02001ac:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001ae:	2d6000ef          	jal	ffffffffc0200484 <cons_getc>
ffffffffc02001b2:	dd75                	beqz	a0,ffffffffc02001ae <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001b4:	60a2                	ld	ra,8(sp)
ffffffffc02001b6:	0141                	addi	sp,sp,16
ffffffffc02001b8:	8082                	ret

ffffffffc02001ba <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001ba:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001bc:	00002517          	auipc	a0,0x2
ffffffffc02001c0:	eb450513          	addi	a0,a0,-332 # ffffffffc0202070 <etext+0xec>
void print_kerninfo(void) {
ffffffffc02001c4:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001c6:	f63ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001ca:	00000597          	auipc	a1,0x0
ffffffffc02001ce:	e8a58593          	addi	a1,a1,-374 # ffffffffc0200054 <kern_init>
ffffffffc02001d2:	00002517          	auipc	a0,0x2
ffffffffc02001d6:	ebe50513          	addi	a0,a0,-322 # ffffffffc0202090 <etext+0x10c>
ffffffffc02001da:	f4fff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001de:	00002597          	auipc	a1,0x2
ffffffffc02001e2:	da658593          	addi	a1,a1,-602 # ffffffffc0201f84 <etext>
ffffffffc02001e6:	00002517          	auipc	a0,0x2
ffffffffc02001ea:	eca50513          	addi	a0,a0,-310 # ffffffffc02020b0 <etext+0x12c>
ffffffffc02001ee:	f3bff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001f2:	00007597          	auipc	a1,0x7
ffffffffc02001f6:	e3658593          	addi	a1,a1,-458 # ffffffffc0207028 <free_area>
ffffffffc02001fa:	00002517          	auipc	a0,0x2
ffffffffc02001fe:	ed650513          	addi	a0,a0,-298 # ffffffffc02020d0 <etext+0x14c>
ffffffffc0200202:	f27ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200206:	00007597          	auipc	a1,0x7
ffffffffc020020a:	29a58593          	addi	a1,a1,666 # ffffffffc02074a0 <end>
ffffffffc020020e:	00002517          	auipc	a0,0x2
ffffffffc0200212:	ee250513          	addi	a0,a0,-286 # ffffffffc02020f0 <etext+0x16c>
ffffffffc0200216:	f13ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020021a:	00000717          	auipc	a4,0x0
ffffffffc020021e:	e3a70713          	addi	a4,a4,-454 # ffffffffc0200054 <kern_init>
ffffffffc0200222:	00007797          	auipc	a5,0x7
ffffffffc0200226:	67d78793          	addi	a5,a5,1661 # ffffffffc020789f <end+0x3ff>
ffffffffc020022a:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020022c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200230:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200232:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200236:	95be                	add	a1,a1,a5
ffffffffc0200238:	85a9                	srai	a1,a1,0xa
ffffffffc020023a:	00002517          	auipc	a0,0x2
ffffffffc020023e:	ed650513          	addi	a0,a0,-298 # ffffffffc0202110 <etext+0x18c>
}
ffffffffc0200242:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200244:	b5d5                	j	ffffffffc0200128 <cprintf>

ffffffffc0200246 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200246:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200248:	00002617          	auipc	a2,0x2
ffffffffc020024c:	ef860613          	addi	a2,a2,-264 # ffffffffc0202140 <etext+0x1bc>
ffffffffc0200250:	04d00593          	li	a1,77
ffffffffc0200254:	00002517          	auipc	a0,0x2
ffffffffc0200258:	f0450513          	addi	a0,a0,-252 # ffffffffc0202158 <etext+0x1d4>
void print_stackframe(void) {
ffffffffc020025c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020025e:	17c000ef          	jal	ffffffffc02003da <__panic>

ffffffffc0200262 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200262:	1101                	addi	sp,sp,-32
ffffffffc0200264:	e822                	sd	s0,16(sp)
ffffffffc0200266:	e426                	sd	s1,8(sp)
ffffffffc0200268:	ec06                	sd	ra,24(sp)
ffffffffc020026a:	00003417          	auipc	s0,0x3
ffffffffc020026e:	c7e40413          	addi	s0,s0,-898 # ffffffffc0202ee8 <commands>
ffffffffc0200272:	00003497          	auipc	s1,0x3
ffffffffc0200276:	cbe48493          	addi	s1,s1,-834 # ffffffffc0202f30 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020027a:	6410                	ld	a2,8(s0)
ffffffffc020027c:	600c                	ld	a1,0(s0)
ffffffffc020027e:	00002517          	auipc	a0,0x2
ffffffffc0200282:	ef250513          	addi	a0,a0,-270 # ffffffffc0202170 <etext+0x1ec>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200286:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200288:	ea1ff0ef          	jal	ffffffffc0200128 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020028c:	fe9417e3          	bne	s0,s1,ffffffffc020027a <mon_help+0x18>
    }
    return 0;
}
ffffffffc0200290:	60e2                	ld	ra,24(sp)
ffffffffc0200292:	6442                	ld	s0,16(sp)
ffffffffc0200294:	64a2                	ld	s1,8(sp)
ffffffffc0200296:	4501                	li	a0,0
ffffffffc0200298:	6105                	addi	sp,sp,32
ffffffffc020029a:	8082                	ret

ffffffffc020029c <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020029c:	1141                	addi	sp,sp,-16
ffffffffc020029e:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002a0:	f1bff0ef          	jal	ffffffffc02001ba <print_kerninfo>
    return 0;
}
ffffffffc02002a4:	60a2                	ld	ra,8(sp)
ffffffffc02002a6:	4501                	li	a0,0
ffffffffc02002a8:	0141                	addi	sp,sp,16
ffffffffc02002aa:	8082                	ret

ffffffffc02002ac <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ac:	1141                	addi	sp,sp,-16
ffffffffc02002ae:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002b0:	f97ff0ef          	jal	ffffffffc0200246 <print_stackframe>
    return 0;
}
ffffffffc02002b4:	60a2                	ld	ra,8(sp)
ffffffffc02002b6:	4501                	li	a0,0
ffffffffc02002b8:	0141                	addi	sp,sp,16
ffffffffc02002ba:	8082                	ret

ffffffffc02002bc <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002bc:	7131                	addi	sp,sp,-192
ffffffffc02002be:	e952                	sd	s4,144(sp)
ffffffffc02002c0:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002c2:	00002517          	auipc	a0,0x2
ffffffffc02002c6:	ebe50513          	addi	a0,a0,-322 # ffffffffc0202180 <etext+0x1fc>
kmonitor(struct trapframe *tf) {
ffffffffc02002ca:	fd06                	sd	ra,184(sp)
ffffffffc02002cc:	f922                	sd	s0,176(sp)
ffffffffc02002ce:	f526                	sd	s1,168(sp)
ffffffffc02002d0:	ed4e                	sd	s3,152(sp)
ffffffffc02002d2:	e556                	sd	s5,136(sp)
ffffffffc02002d4:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002d6:	e53ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002da:	00002517          	auipc	a0,0x2
ffffffffc02002de:	ece50513          	addi	a0,a0,-306 # ffffffffc02021a8 <etext+0x224>
ffffffffc02002e2:	e47ff0ef          	jal	ffffffffc0200128 <cprintf>
    if (tf != NULL) {
ffffffffc02002e6:	000a0563          	beqz	s4,ffffffffc02002f0 <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc02002ea:	8552                	mv	a0,s4
ffffffffc02002ec:	6ce000ef          	jal	ffffffffc02009ba <print_trapframe>
ffffffffc02002f0:	00003a97          	auipc	s5,0x3
ffffffffc02002f4:	bf8a8a93          	addi	s5,s5,-1032 # ffffffffc0202ee8 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc02002f8:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002fa:	00002517          	auipc	a0,0x2
ffffffffc02002fe:	ed650513          	addi	a0,a0,-298 # ffffffffc02021d0 <etext+0x24c>
ffffffffc0200302:	2af010ef          	jal	ffffffffc0201db0 <readline>
ffffffffc0200306:	842a                	mv	s0,a0
ffffffffc0200308:	d96d                	beqz	a0,ffffffffc02002fa <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030a:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020030e:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200310:	e99d                	bnez	a1,ffffffffc0200346 <kmonitor+0x8a>
    int argc = 0;
ffffffffc0200312:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc0200314:	fe0b03e3          	beqz	s6,ffffffffc02002fa <kmonitor+0x3e>
ffffffffc0200318:	00003497          	auipc	s1,0x3
ffffffffc020031c:	bd048493          	addi	s1,s1,-1072 # ffffffffc0202ee8 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200320:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200322:	6582                	ld	a1,0(sp)
ffffffffc0200324:	6088                	ld	a0,0(s1)
ffffffffc0200326:	3df010ef          	jal	ffffffffc0201f04 <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032a:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032c:	c149                	beqz	a0,ffffffffc02003ae <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032e:	2405                	addiw	s0,s0,1
ffffffffc0200330:	04e1                	addi	s1,s1,24
ffffffffc0200332:	fef418e3          	bne	s0,a5,ffffffffc0200322 <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200336:	6582                	ld	a1,0(sp)
ffffffffc0200338:	00002517          	auipc	a0,0x2
ffffffffc020033c:	ec850513          	addi	a0,a0,-312 # ffffffffc0202200 <etext+0x27c>
ffffffffc0200340:	de9ff0ef          	jal	ffffffffc0200128 <cprintf>
    return 0;
ffffffffc0200344:	bf5d                	j	ffffffffc02002fa <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200346:	00002517          	auipc	a0,0x2
ffffffffc020034a:	e9250513          	addi	a0,a0,-366 # ffffffffc02021d8 <etext+0x254>
ffffffffc020034e:	413010ef          	jal	ffffffffc0201f60 <strchr>
ffffffffc0200352:	c901                	beqz	a0,ffffffffc0200362 <kmonitor+0xa6>
ffffffffc0200354:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200358:	00040023          	sb	zero,0(s0)
ffffffffc020035c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035e:	d9d5                	beqz	a1,ffffffffc0200312 <kmonitor+0x56>
ffffffffc0200360:	b7dd                	j	ffffffffc0200346 <kmonitor+0x8a>
        if (*buf == '\0') {
ffffffffc0200362:	00044783          	lbu	a5,0(s0)
ffffffffc0200366:	d7d5                	beqz	a5,ffffffffc0200312 <kmonitor+0x56>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	03348b63          	beq	s1,s3,ffffffffc020039e <kmonitor+0xe2>
        argv[argc ++] = buf;
ffffffffc020036c:	00349793          	slli	a5,s1,0x3
ffffffffc0200370:	978a                	add	a5,a5,sp
ffffffffc0200372:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200374:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200378:	2485                	addiw	s1,s1,1
ffffffffc020037a:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037c:	e591                	bnez	a1,ffffffffc0200388 <kmonitor+0xcc>
ffffffffc020037e:	bf59                	j	ffffffffc0200314 <kmonitor+0x58>
ffffffffc0200380:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200384:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200386:	d5d1                	beqz	a1,ffffffffc0200312 <kmonitor+0x56>
ffffffffc0200388:	00002517          	auipc	a0,0x2
ffffffffc020038c:	e5050513          	addi	a0,a0,-432 # ffffffffc02021d8 <etext+0x254>
ffffffffc0200390:	3d1010ef          	jal	ffffffffc0201f60 <strchr>
ffffffffc0200394:	d575                	beqz	a0,ffffffffc0200380 <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200396:	00044583          	lbu	a1,0(s0)
ffffffffc020039a:	dda5                	beqz	a1,ffffffffc0200312 <kmonitor+0x56>
ffffffffc020039c:	b76d                	j	ffffffffc0200346 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	45c1                	li	a1,16
ffffffffc02003a0:	00002517          	auipc	a0,0x2
ffffffffc02003a4:	e4050513          	addi	a0,a0,-448 # ffffffffc02021e0 <etext+0x25c>
ffffffffc02003a8:	d81ff0ef          	jal	ffffffffc0200128 <cprintf>
ffffffffc02003ac:	b7c1                	j	ffffffffc020036c <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003ae:	00141793          	slli	a5,s0,0x1
ffffffffc02003b2:	97a2                	add	a5,a5,s0
ffffffffc02003b4:	078e                	slli	a5,a5,0x3
ffffffffc02003b6:	97d6                	add	a5,a5,s5
ffffffffc02003b8:	6b9c                	ld	a5,16(a5)
ffffffffc02003ba:	fffb051b          	addiw	a0,s6,-1
ffffffffc02003be:	8652                	mv	a2,s4
ffffffffc02003c0:	002c                	addi	a1,sp,8
ffffffffc02003c2:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003c4:	f2055be3          	bgez	a0,ffffffffc02002fa <kmonitor+0x3e>
}
ffffffffc02003c8:	70ea                	ld	ra,184(sp)
ffffffffc02003ca:	744a                	ld	s0,176(sp)
ffffffffc02003cc:	74aa                	ld	s1,168(sp)
ffffffffc02003ce:	69ea                	ld	s3,152(sp)
ffffffffc02003d0:	6a4a                	ld	s4,144(sp)
ffffffffc02003d2:	6aaa                	ld	s5,136(sp)
ffffffffc02003d4:	6b0a                	ld	s6,128(sp)
ffffffffc02003d6:	6129                	addi	sp,sp,192
ffffffffc02003d8:	8082                	ret

ffffffffc02003da <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003da:	00007317          	auipc	t1,0x7
ffffffffc02003de:	06632303          	lw	t1,102(t1) # ffffffffc0207440 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003e2:	715d                	addi	sp,sp,-80
ffffffffc02003e4:	ec06                	sd	ra,24(sp)
ffffffffc02003e6:	f436                	sd	a3,40(sp)
ffffffffc02003e8:	f83a                	sd	a4,48(sp)
ffffffffc02003ea:	fc3e                	sd	a5,56(sp)
ffffffffc02003ec:	e0c2                	sd	a6,64(sp)
ffffffffc02003ee:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003f0:	02031e63          	bnez	t1,ffffffffc020042c <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003f4:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003f6:	103c                	addi	a5,sp,40
ffffffffc02003f8:	e822                	sd	s0,16(sp)
ffffffffc02003fa:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003fc:	862e                	mv	a2,a1
ffffffffc02003fe:	85aa                	mv	a1,a0
ffffffffc0200400:	00002517          	auipc	a0,0x2
ffffffffc0200404:	ea850513          	addi	a0,a0,-344 # ffffffffc02022a8 <etext+0x324>
    is_panic = 1;
ffffffffc0200408:	00007697          	auipc	a3,0x7
ffffffffc020040c:	02e6ac23          	sw	a4,56(a3) # ffffffffc0207440 <is_panic>
    va_start(ap, fmt);
ffffffffc0200410:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200412:	d17ff0ef          	jal	ffffffffc0200128 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200416:	65a2                	ld	a1,8(sp)
ffffffffc0200418:	8522                	mv	a0,s0
ffffffffc020041a:	cefff0ef          	jal	ffffffffc0200108 <vcprintf>
    cprintf("\n");
ffffffffc020041e:	00002517          	auipc	a0,0x2
ffffffffc0200422:	eaa50513          	addi	a0,a0,-342 # ffffffffc02022c8 <etext+0x344>
ffffffffc0200426:	d03ff0ef          	jal	ffffffffc0200128 <cprintf>
ffffffffc020042a:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020042c:	3a8000ef          	jal	ffffffffc02007d4 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200430:	4501                	li	a0,0
ffffffffc0200432:	e8bff0ef          	jal	ffffffffc02002bc <kmonitor>
    while (1) {
ffffffffc0200436:	bfed                	j	ffffffffc0200430 <__panic+0x56>

ffffffffc0200438 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200438:	1141                	addi	sp,sp,-16
ffffffffc020043a:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020043c:	02000793          	li	a5,32
ffffffffc0200440:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200444:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200448:	67e1                	lui	a5,0x18
ffffffffc020044a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020044e:	953e                	add	a0,a0,a5
ffffffffc0200450:	231010ef          	jal	ffffffffc0201e80 <sbi_set_timer>
}
ffffffffc0200454:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200456:	00007797          	auipc	a5,0x7
ffffffffc020045a:	fe07b923          	sd	zero,-14(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020045e:	00002517          	auipc	a0,0x2
ffffffffc0200462:	e7250513          	addi	a0,a0,-398 # ffffffffc02022d0 <etext+0x34c>
}
ffffffffc0200466:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200468:	b1c1                	j	ffffffffc0200128 <cprintf>

ffffffffc020046a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020046a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020046e:	67e1                	lui	a5,0x18
ffffffffc0200470:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200474:	953e                	add	a0,a0,a5
ffffffffc0200476:	20b0106f          	j	ffffffffc0201e80 <sbi_set_timer>

ffffffffc020047a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020047a:	8082                	ret

ffffffffc020047c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020047c:	0ff57513          	zext.b	a0,a0
ffffffffc0200480:	1e70106f          	j	ffffffffc0201e66 <sbi_console_putchar>

ffffffffc0200484 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200484:	2170106f          	j	ffffffffc0201e9a <sbi_console_getchar>

ffffffffc0200488 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200488:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020048a:	00002517          	auipc	a0,0x2
ffffffffc020048e:	e6650513          	addi	a0,a0,-410 # ffffffffc02022f0 <etext+0x36c>
void dtb_init(void) {
ffffffffc0200492:	f406                	sd	ra,40(sp)
ffffffffc0200494:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200496:	c93ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020049a:	00007597          	auipc	a1,0x7
ffffffffc020049e:	b665b583          	ld	a1,-1178(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc02004a2:	00002517          	auipc	a0,0x2
ffffffffc02004a6:	e5e50513          	addi	a0,a0,-418 # ffffffffc0202300 <etext+0x37c>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004aa:	00007417          	auipc	s0,0x7
ffffffffc02004ae:	b5e40413          	addi	s0,s0,-1186 # ffffffffc0207008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004b2:	c77ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004b6:	600c                	ld	a1,0(s0)
ffffffffc02004b8:	00002517          	auipc	a0,0x2
ffffffffc02004bc:	e5850513          	addi	a0,a0,-424 # ffffffffc0202310 <etext+0x38c>
ffffffffc02004c0:	c69ff0ef          	jal	ffffffffc0200128 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004c4:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004c6:	00002517          	auipc	a0,0x2
ffffffffc02004ca:	e6250513          	addi	a0,a0,-414 # ffffffffc0202328 <etext+0x3a4>
    if (boot_dtb == 0) {
ffffffffc02004ce:	10070163          	beqz	a4,ffffffffc02005d0 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004d2:	57f5                	li	a5,-3
ffffffffc02004d4:	07fa                	slli	a5,a5,0x1e
ffffffffc02004d6:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004d8:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc02004da:	d00e06b7          	lui	a3,0xd00e0
ffffffffc02004de:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed8a4d>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e2:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004e6:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ea:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ee:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f6:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f8:	8e49                	or	a2,a2,a0
ffffffffc02004fa:	0ff7f793          	zext.b	a5,a5
ffffffffc02004fe:	8dd1                	or	a1,a1,a2
ffffffffc0200500:	07a2                	slli	a5,a5,0x8
ffffffffc0200502:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc0200508:	0cd59863          	bne	a1,a3,ffffffffc02005d8 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020050c:	4710                	lw	a2,8(a4)
ffffffffc020050e:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200510:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200512:	0086541b          	srliw	s0,a2,0x8
ffffffffc0200516:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051a:	01865e1b          	srliw	t3,a2,0x18
ffffffffc020051e:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0186151b          	slliw	a0,a2,0x18
ffffffffc0200526:	0186959b          	slliw	a1,a3,0x18
ffffffffc020052a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200532:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0106d69b          	srliw	a3,a3,0x10
ffffffffc020053a:	01c56533          	or	a0,a0,t3
ffffffffc020053e:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200542:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200546:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020054a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020054e:	0ff6f693          	zext.b	a3,a3
ffffffffc0200552:	8c49                	or	s0,s0,a0
ffffffffc0200554:	0622                	slli	a2,a2,0x8
ffffffffc0200556:	8fcd                	or	a5,a5,a1
ffffffffc0200558:	06a2                	slli	a3,a3,0x8
ffffffffc020055a:	8c51                	or	s0,s0,a2
ffffffffc020055c:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020055e:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200560:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200562:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200564:	9381                	srli	a5,a5,0x20
ffffffffc0200566:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200568:	4301                	li	t1,0
        switch (token) {
ffffffffc020056a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020056c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020056e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200572:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200574:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200576:	0087579b          	srliw	a5,a4,0x8
ffffffffc020057a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020057e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200582:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200586:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058e:	8ed1                	or	a3,a3,a2
ffffffffc0200590:	0ff77713          	zext.b	a4,a4
ffffffffc0200594:	8fd5                	or	a5,a5,a3
ffffffffc0200596:	0722                	slli	a4,a4,0x8
ffffffffc0200598:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020059a:	05178763          	beq	a5,a7,ffffffffc02005e8 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020059e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc02005a0:	00f8e963          	bltu	a7,a5,ffffffffc02005b2 <dtb_init+0x12a>
ffffffffc02005a4:	07c78d63          	beq	a5,t3,ffffffffc020061e <dtb_init+0x196>
ffffffffc02005a8:	4709                	li	a4,2
ffffffffc02005aa:	00e79763          	bne	a5,a4,ffffffffc02005b8 <dtb_init+0x130>
ffffffffc02005ae:	4301                	li	t1,0
ffffffffc02005b0:	b7d1                	j	ffffffffc0200574 <dtb_init+0xec>
ffffffffc02005b2:	4711                	li	a4,4
ffffffffc02005b4:	fce780e3          	beq	a5,a4,ffffffffc0200574 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005b8:	00002517          	auipc	a0,0x2
ffffffffc02005bc:	e3850513          	addi	a0,a0,-456 # ffffffffc02023f0 <etext+0x46c>
ffffffffc02005c0:	b69ff0ef          	jal	ffffffffc0200128 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005c4:	64e2                	ld	s1,24(sp)
ffffffffc02005c6:	6942                	ld	s2,16(sp)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	e6050513          	addi	a0,a0,-416 # ffffffffc0202428 <etext+0x4a4>
}
ffffffffc02005d0:	7402                	ld	s0,32(sp)
ffffffffc02005d2:	70a2                	ld	ra,40(sp)
ffffffffc02005d4:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc02005d6:	be89                	j	ffffffffc0200128 <cprintf>
}
ffffffffc02005d8:	7402                	ld	s0,32(sp)
ffffffffc02005da:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02005dc:	00002517          	auipc	a0,0x2
ffffffffc02005e0:	d6c50513          	addi	a0,a0,-660 # ffffffffc0202348 <etext+0x3c4>
}
ffffffffc02005e4:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02005e6:	b689                	j	ffffffffc0200128 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005e8:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ea:	0087579b          	srliw	a5,a4,0x8
ffffffffc02005ee:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f2:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f6:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005fa:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005fe:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200602:	8ed1                	or	a3,a3,a2
ffffffffc0200604:	0ff77713          	zext.b	a4,a4
ffffffffc0200608:	8fd5                	or	a5,a5,a3
ffffffffc020060a:	0722                	slli	a4,a4,0x8
ffffffffc020060c:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020060e:	04031463          	bnez	t1,ffffffffc0200656 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200612:	1782                	slli	a5,a5,0x20
ffffffffc0200614:	9381                	srli	a5,a5,0x20
ffffffffc0200616:	043d                	addi	s0,s0,15
ffffffffc0200618:	943e                	add	s0,s0,a5
ffffffffc020061a:	9871                	andi	s0,s0,-4
                break;
ffffffffc020061c:	bfa1                	j	ffffffffc0200574 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc020061e:	8522                	mv	a0,s0
ffffffffc0200620:	e01a                	sd	t1,0(sp)
ffffffffc0200622:	0af010ef          	jal	ffffffffc0201ed0 <strlen>
ffffffffc0200626:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200628:	4619                	li	a2,6
ffffffffc020062a:	8522                	mv	a0,s0
ffffffffc020062c:	00002597          	auipc	a1,0x2
ffffffffc0200630:	d4458593          	addi	a1,a1,-700 # ffffffffc0202370 <etext+0x3ec>
ffffffffc0200634:	105010ef          	jal	ffffffffc0201f38 <strncmp>
ffffffffc0200638:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020063a:	0411                	addi	s0,s0,4
ffffffffc020063c:	0004879b          	sext.w	a5,s1
ffffffffc0200640:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200642:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200646:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200648:	00a36333          	or	t1,t1,a0
                break;
ffffffffc020064c:	00ff0837          	lui	a6,0xff0
ffffffffc0200650:	488d                	li	a7,3
ffffffffc0200652:	4e05                	li	t3,1
ffffffffc0200654:	b705                	j	ffffffffc0200574 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200656:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200658:	00002597          	auipc	a1,0x2
ffffffffc020065c:	d2058593          	addi	a1,a1,-736 # ffffffffc0202378 <etext+0x3f4>
ffffffffc0200660:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200662:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200666:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020066e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200672:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200676:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067a:	8ed1                	or	a3,a3,a2
ffffffffc020067c:	0ff77713          	zext.b	a4,a4
ffffffffc0200680:	0722                	slli	a4,a4,0x8
ffffffffc0200682:	8d55                	or	a0,a0,a3
ffffffffc0200684:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200686:	1502                	slli	a0,a0,0x20
ffffffffc0200688:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020068a:	954a                	add	a0,a0,s2
ffffffffc020068c:	e01a                	sd	t1,0(sp)
ffffffffc020068e:	077010ef          	jal	ffffffffc0201f04 <strcmp>
ffffffffc0200692:	67a2                	ld	a5,8(sp)
ffffffffc0200694:	473d                	li	a4,15
ffffffffc0200696:	6302                	ld	t1,0(sp)
ffffffffc0200698:	00ff0837          	lui	a6,0xff0
ffffffffc020069c:	488d                	li	a7,3
ffffffffc020069e:	4e05                	li	t3,1
ffffffffc02006a0:	f6f779e3          	bgeu	a4,a5,ffffffffc0200612 <dtb_init+0x18a>
ffffffffc02006a4:	f53d                	bnez	a0,ffffffffc0200612 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006a6:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006aa:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006ae:	00002517          	auipc	a0,0x2
ffffffffc02006b2:	cd250513          	addi	a0,a0,-814 # ffffffffc0202380 <etext+0x3fc>
           fdt32_to_cpu(x >> 32);
ffffffffc02006b6:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0087d31b          	srliw	t1,a5,0x8
ffffffffc02006be:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02006c2:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0187959b          	slliw	a1,a5,0x18
ffffffffc02006ce:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d6:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006da:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006de:	01037333          	and	t1,t1,a6
ffffffffc02006e2:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e6:	01e5e5b3          	or	a1,a1,t5
ffffffffc02006ea:	0ff7f793          	zext.b	a5,a5
ffffffffc02006ee:	01de6e33          	or	t3,t3,t4
ffffffffc02006f2:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006f6:	01067633          	and	a2,a2,a6
ffffffffc02006fa:	0086d31b          	srliw	t1,a3,0x8
ffffffffc02006fe:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200702:	07a2                	slli	a5,a5,0x8
ffffffffc0200704:	0108d89b          	srliw	a7,a7,0x10
ffffffffc0200708:	0186df1b          	srliw	t5,a3,0x18
ffffffffc020070c:	01875e9b          	srliw	t4,a4,0x18
ffffffffc0200710:	8ddd                	or	a1,a1,a5
ffffffffc0200712:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	0186979b          	slliw	a5,a3,0x18
ffffffffc020071a:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071e:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200722:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200726:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	08a2                	slli	a7,a7,0x8
ffffffffc0200738:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073c:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200740:	0ff6f693          	zext.b	a3,a3
ffffffffc0200744:	01de6833          	or	a6,t3,t4
ffffffffc0200748:	0ff77713          	zext.b	a4,a4
ffffffffc020074c:	01166633          	or	a2,a2,a7
ffffffffc0200750:	0067e7b3          	or	a5,a5,t1
ffffffffc0200754:	06a2                	slli	a3,a3,0x8
ffffffffc0200756:	01046433          	or	s0,s0,a6
ffffffffc020075a:	0722                	slli	a4,a4,0x8
ffffffffc020075c:	8fd5                	or	a5,a5,a3
ffffffffc020075e:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200760:	1582                	slli	a1,a1,0x20
ffffffffc0200762:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200764:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200766:	9201                	srli	a2,a2,0x20
ffffffffc0200768:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020076a:	1402                	slli	s0,s0,0x20
ffffffffc020076c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200770:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200772:	9b7ff0ef          	jal	ffffffffc0200128 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200776:	85a6                	mv	a1,s1
ffffffffc0200778:	00002517          	auipc	a0,0x2
ffffffffc020077c:	c2850513          	addi	a0,a0,-984 # ffffffffc02023a0 <etext+0x41c>
ffffffffc0200780:	9a9ff0ef          	jal	ffffffffc0200128 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200784:	01445613          	srli	a2,s0,0x14
ffffffffc0200788:	85a2                	mv	a1,s0
ffffffffc020078a:	00002517          	auipc	a0,0x2
ffffffffc020078e:	c2e50513          	addi	a0,a0,-978 # ffffffffc02023b8 <etext+0x434>
ffffffffc0200792:	997ff0ef          	jal	ffffffffc0200128 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200796:	009405b3          	add	a1,s0,s1
ffffffffc020079a:	15fd                	addi	a1,a1,-1
ffffffffc020079c:	00002517          	auipc	a0,0x2
ffffffffc02007a0:	c3c50513          	addi	a0,a0,-964 # ffffffffc02023d8 <etext+0x454>
ffffffffc02007a4:	985ff0ef          	jal	ffffffffc0200128 <cprintf>
        memory_base = mem_base;
ffffffffc02007a8:	00007797          	auipc	a5,0x7
ffffffffc02007ac:	ca97b823          	sd	s1,-848(a5) # ffffffffc0207458 <memory_base>
        memory_size = mem_size;
ffffffffc02007b0:	00007797          	auipc	a5,0x7
ffffffffc02007b4:	ca87b023          	sd	s0,-864(a5) # ffffffffc0207450 <memory_size>
ffffffffc02007b8:	b531                	j	ffffffffc02005c4 <dtb_init+0x13c>

ffffffffc02007ba <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02007ba:	00007517          	auipc	a0,0x7
ffffffffc02007be:	c9e53503          	ld	a0,-866(a0) # ffffffffc0207458 <memory_base>
ffffffffc02007c2:	8082                	ret

ffffffffc02007c4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02007c4:	00007517          	auipc	a0,0x7
ffffffffc02007c8:	c8c53503          	ld	a0,-884(a0) # ffffffffc0207450 <memory_size>
ffffffffc02007cc:	8082                	ret

ffffffffc02007ce <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007ce:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02007d2:	8082                	ret

ffffffffc02007d4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007d4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02007d8:	8082                	ret

ffffffffc02007da <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02007da:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02007de:	00000797          	auipc	a5,0x0
ffffffffc02007e2:	39e78793          	addi	a5,a5,926 # ffffffffc0200b7c <__alltraps>
ffffffffc02007e6:	10579073          	csrw	stvec,a5
}
ffffffffc02007ea:	8082                	ret

ffffffffc02007ec <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02007ec:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc02007ee:	1141                	addi	sp,sp,-16
ffffffffc02007f0:	e022                	sd	s0,0(sp)
ffffffffc02007f2:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02007f4:	00002517          	auipc	a0,0x2
ffffffffc02007f8:	c4c50513          	addi	a0,a0,-948 # ffffffffc0202440 <etext+0x4bc>
void print_regs(struct pushregs *gpr) {
ffffffffc02007fc:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02007fe:	92bff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200802:	640c                	ld	a1,8(s0)
ffffffffc0200804:	00002517          	auipc	a0,0x2
ffffffffc0200808:	c5450513          	addi	a0,a0,-940 # ffffffffc0202458 <etext+0x4d4>
ffffffffc020080c:	91dff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200810:	680c                	ld	a1,16(s0)
ffffffffc0200812:	00002517          	auipc	a0,0x2
ffffffffc0200816:	c5e50513          	addi	a0,a0,-930 # ffffffffc0202470 <etext+0x4ec>
ffffffffc020081a:	90fff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020081e:	6c0c                	ld	a1,24(s0)
ffffffffc0200820:	00002517          	auipc	a0,0x2
ffffffffc0200824:	c6850513          	addi	a0,a0,-920 # ffffffffc0202488 <etext+0x504>
ffffffffc0200828:	901ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020082c:	700c                	ld	a1,32(s0)
ffffffffc020082e:	00002517          	auipc	a0,0x2
ffffffffc0200832:	c7250513          	addi	a0,a0,-910 # ffffffffc02024a0 <etext+0x51c>
ffffffffc0200836:	8f3ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020083a:	740c                	ld	a1,40(s0)
ffffffffc020083c:	00002517          	auipc	a0,0x2
ffffffffc0200840:	c7c50513          	addi	a0,a0,-900 # ffffffffc02024b8 <etext+0x534>
ffffffffc0200844:	8e5ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200848:	780c                	ld	a1,48(s0)
ffffffffc020084a:	00002517          	auipc	a0,0x2
ffffffffc020084e:	c8650513          	addi	a0,a0,-890 # ffffffffc02024d0 <etext+0x54c>
ffffffffc0200852:	8d7ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200856:	7c0c                	ld	a1,56(s0)
ffffffffc0200858:	00002517          	auipc	a0,0x2
ffffffffc020085c:	c9050513          	addi	a0,a0,-880 # ffffffffc02024e8 <etext+0x564>
ffffffffc0200860:	8c9ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200864:	602c                	ld	a1,64(s0)
ffffffffc0200866:	00002517          	auipc	a0,0x2
ffffffffc020086a:	c9a50513          	addi	a0,a0,-870 # ffffffffc0202500 <etext+0x57c>
ffffffffc020086e:	8bbff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200872:	642c                	ld	a1,72(s0)
ffffffffc0200874:	00002517          	auipc	a0,0x2
ffffffffc0200878:	ca450513          	addi	a0,a0,-860 # ffffffffc0202518 <etext+0x594>
ffffffffc020087c:	8adff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200880:	682c                	ld	a1,80(s0)
ffffffffc0200882:	00002517          	auipc	a0,0x2
ffffffffc0200886:	cae50513          	addi	a0,a0,-850 # ffffffffc0202530 <etext+0x5ac>
ffffffffc020088a:	89fff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020088e:	6c2c                	ld	a1,88(s0)
ffffffffc0200890:	00002517          	auipc	a0,0x2
ffffffffc0200894:	cb850513          	addi	a0,a0,-840 # ffffffffc0202548 <etext+0x5c4>
ffffffffc0200898:	891ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020089c:	702c                	ld	a1,96(s0)
ffffffffc020089e:	00002517          	auipc	a0,0x2
ffffffffc02008a2:	cc250513          	addi	a0,a0,-830 # ffffffffc0202560 <etext+0x5dc>
ffffffffc02008a6:	883ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02008aa:	742c                	ld	a1,104(s0)
ffffffffc02008ac:	00002517          	auipc	a0,0x2
ffffffffc02008b0:	ccc50513          	addi	a0,a0,-820 # ffffffffc0202578 <etext+0x5f4>
ffffffffc02008b4:	875ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02008b8:	782c                	ld	a1,112(s0)
ffffffffc02008ba:	00002517          	auipc	a0,0x2
ffffffffc02008be:	cd650513          	addi	a0,a0,-810 # ffffffffc0202590 <etext+0x60c>
ffffffffc02008c2:	867ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02008c6:	7c2c                	ld	a1,120(s0)
ffffffffc02008c8:	00002517          	auipc	a0,0x2
ffffffffc02008cc:	ce050513          	addi	a0,a0,-800 # ffffffffc02025a8 <etext+0x624>
ffffffffc02008d0:	859ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc02008d4:	604c                	ld	a1,128(s0)
ffffffffc02008d6:	00002517          	auipc	a0,0x2
ffffffffc02008da:	cea50513          	addi	a0,a0,-790 # ffffffffc02025c0 <etext+0x63c>
ffffffffc02008de:	84bff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc02008e2:	644c                	ld	a1,136(s0)
ffffffffc02008e4:	00002517          	auipc	a0,0x2
ffffffffc02008e8:	cf450513          	addi	a0,a0,-780 # ffffffffc02025d8 <etext+0x654>
ffffffffc02008ec:	83dff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc02008f0:	684c                	ld	a1,144(s0)
ffffffffc02008f2:	00002517          	auipc	a0,0x2
ffffffffc02008f6:	cfe50513          	addi	a0,a0,-770 # ffffffffc02025f0 <etext+0x66c>
ffffffffc02008fa:	82fff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02008fe:	6c4c                	ld	a1,152(s0)
ffffffffc0200900:	00002517          	auipc	a0,0x2
ffffffffc0200904:	d0850513          	addi	a0,a0,-760 # ffffffffc0202608 <etext+0x684>
ffffffffc0200908:	821ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020090c:	704c                	ld	a1,160(s0)
ffffffffc020090e:	00002517          	auipc	a0,0x2
ffffffffc0200912:	d1250513          	addi	a0,a0,-750 # ffffffffc0202620 <etext+0x69c>
ffffffffc0200916:	813ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020091a:	744c                	ld	a1,168(s0)
ffffffffc020091c:	00002517          	auipc	a0,0x2
ffffffffc0200920:	d1c50513          	addi	a0,a0,-740 # ffffffffc0202638 <etext+0x6b4>
ffffffffc0200924:	805ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200928:	784c                	ld	a1,176(s0)
ffffffffc020092a:	00002517          	auipc	a0,0x2
ffffffffc020092e:	d2650513          	addi	a0,a0,-730 # ffffffffc0202650 <etext+0x6cc>
ffffffffc0200932:	ff6ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200936:	7c4c                	ld	a1,184(s0)
ffffffffc0200938:	00002517          	auipc	a0,0x2
ffffffffc020093c:	d3050513          	addi	a0,a0,-720 # ffffffffc0202668 <etext+0x6e4>
ffffffffc0200940:	fe8ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200944:	606c                	ld	a1,192(s0)
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	d3a50513          	addi	a0,a0,-710 # ffffffffc0202680 <etext+0x6fc>
ffffffffc020094e:	fdaff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200952:	646c                	ld	a1,200(s0)
ffffffffc0200954:	00002517          	auipc	a0,0x2
ffffffffc0200958:	d4450513          	addi	a0,a0,-700 # ffffffffc0202698 <etext+0x714>
ffffffffc020095c:	fccff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200960:	686c                	ld	a1,208(s0)
ffffffffc0200962:	00002517          	auipc	a0,0x2
ffffffffc0200966:	d4e50513          	addi	a0,a0,-690 # ffffffffc02026b0 <etext+0x72c>
ffffffffc020096a:	fbeff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc020096e:	6c6c                	ld	a1,216(s0)
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	d5850513          	addi	a0,a0,-680 # ffffffffc02026c8 <etext+0x744>
ffffffffc0200978:	fb0ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020097c:	706c                	ld	a1,224(s0)
ffffffffc020097e:	00002517          	auipc	a0,0x2
ffffffffc0200982:	d6250513          	addi	a0,a0,-670 # ffffffffc02026e0 <etext+0x75c>
ffffffffc0200986:	fa2ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020098a:	746c                	ld	a1,232(s0)
ffffffffc020098c:	00002517          	auipc	a0,0x2
ffffffffc0200990:	d6c50513          	addi	a0,a0,-660 # ffffffffc02026f8 <etext+0x774>
ffffffffc0200994:	f94ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200998:	786c                	ld	a1,240(s0)
ffffffffc020099a:	00002517          	auipc	a0,0x2
ffffffffc020099e:	d7650513          	addi	a0,a0,-650 # ffffffffc0202710 <etext+0x78c>
ffffffffc02009a2:	f86ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009a6:	7c6c                	ld	a1,248(s0)
}
ffffffffc02009a8:	6402                	ld	s0,0(sp)
ffffffffc02009aa:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009ac:	00002517          	auipc	a0,0x2
ffffffffc02009b0:	d7c50513          	addi	a0,a0,-644 # ffffffffc0202728 <etext+0x7a4>
}
ffffffffc02009b4:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009b6:	f72ff06f          	j	ffffffffc0200128 <cprintf>

ffffffffc02009ba <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc02009ba:	1141                	addi	sp,sp,-16
ffffffffc02009bc:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009be:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc02009c0:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	d7e50513          	addi	a0,a0,-642 # ffffffffc0202740 <etext+0x7bc>
void print_trapframe(struct trapframe *tf) {
ffffffffc02009ca:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009cc:	f5cff0ef          	jal	ffffffffc0200128 <cprintf>
    print_regs(&tf->gpr);
ffffffffc02009d0:	8522                	mv	a0,s0
ffffffffc02009d2:	e1bff0ef          	jal	ffffffffc02007ec <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc02009d6:	10043583          	ld	a1,256(s0)
ffffffffc02009da:	00002517          	auipc	a0,0x2
ffffffffc02009de:	d7e50513          	addi	a0,a0,-642 # ffffffffc0202758 <etext+0x7d4>
ffffffffc02009e2:	f46ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc02009e6:	10843583          	ld	a1,264(s0)
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	d8650513          	addi	a0,a0,-634 # ffffffffc0202770 <etext+0x7ec>
ffffffffc02009f2:	f36ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc02009f6:	11043583          	ld	a1,272(s0)
ffffffffc02009fa:	00002517          	auipc	a0,0x2
ffffffffc02009fe:	d8e50513          	addi	a0,a0,-626 # ffffffffc0202788 <etext+0x804>
ffffffffc0200a02:	f26ff0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a06:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a0a:	6402                	ld	s0,0(sp)
ffffffffc0200a0c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a0e:	00002517          	auipc	a0,0x2
ffffffffc0200a12:	d9250513          	addi	a0,a0,-622 # ffffffffc02027a0 <etext+0x81c>
}
ffffffffc0200a16:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a18:	f10ff06f          	j	ffffffffc0200128 <cprintf>

ffffffffc0200a1c <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    static int num = 0;
    switch (cause) {
ffffffffc0200a1c:	11853783          	ld	a5,280(a0)
ffffffffc0200a20:	472d                	li	a4,11
ffffffffc0200a22:	0786                	slli	a5,a5,0x1
ffffffffc0200a24:	8385                	srli	a5,a5,0x1
ffffffffc0200a26:	0af76463          	bltu	a4,a5,ffffffffc0200ace <interrupt_handler+0xb2>
ffffffffc0200a2a:	00002717          	auipc	a4,0x2
ffffffffc0200a2e:	50670713          	addi	a4,a4,1286 # ffffffffc0202f30 <commands+0x48>
ffffffffc0200a32:	078a                	slli	a5,a5,0x2
ffffffffc0200a34:	97ba                	add	a5,a5,a4
ffffffffc0200a36:	439c                	lw	a5,0(a5)
ffffffffc0200a38:	97ba                	add	a5,a5,a4
ffffffffc0200a3a:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a3c:	00002517          	auipc	a0,0x2
ffffffffc0200a40:	ddc50513          	addi	a0,a0,-548 # ffffffffc0202818 <etext+0x894>
ffffffffc0200a44:	ee4ff06f          	j	ffffffffc0200128 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200a48:	00002517          	auipc	a0,0x2
ffffffffc0200a4c:	db050513          	addi	a0,a0,-592 # ffffffffc02027f8 <etext+0x874>
ffffffffc0200a50:	ed8ff06f          	j	ffffffffc0200128 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a54:	00002517          	auipc	a0,0x2
ffffffffc0200a58:	d6450513          	addi	a0,a0,-668 # ffffffffc02027b8 <etext+0x834>
ffffffffc0200a5c:	eccff06f          	j	ffffffffc0200128 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200a60:	00002517          	auipc	a0,0x2
ffffffffc0200a64:	dd850513          	addi	a0,a0,-552 # ffffffffc0202838 <etext+0x8b4>
ffffffffc0200a68:	ec0ff06f          	j	ffffffffc0200128 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a6c:	1141                	addi	sp,sp,-16
ffffffffc0200a6e:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200a70:	9fbff0ef          	jal	ffffffffc020046a <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200a74:	00007697          	auipc	a3,0x7
ffffffffc0200a78:	9d46b683          	ld	a3,-1580(a3) # ffffffffc0207448 <ticks>
ffffffffc0200a7c:	28f5c737          	lui	a4,0x28f5c
ffffffffc0200a80:	28f70713          	addi	a4,a4,655 # 28f5c28f <kern_entry-0xffffffff972a3d71>
ffffffffc0200a84:	5c28f7b7          	lui	a5,0x5c28f
ffffffffc0200a88:	5c378793          	addi	a5,a5,1475 # 5c28f5c3 <kern_entry-0xffffffff63f70a3d>
ffffffffc0200a8c:	0685                	addi	a3,a3,1
ffffffffc0200a8e:	1702                	slli	a4,a4,0x20
ffffffffc0200a90:	973e                	add	a4,a4,a5
ffffffffc0200a92:	0026d793          	srli	a5,a3,0x2
ffffffffc0200a96:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc0200a9a:	06400593          	li	a1,100
ffffffffc0200a9e:	00007717          	auipc	a4,0x7
ffffffffc0200aa2:	9ad73523          	sd	a3,-1622(a4) # ffffffffc0207448 <ticks>
ffffffffc0200aa6:	8389                	srli	a5,a5,0x2
ffffffffc0200aa8:	02b787b3          	mul	a5,a5,a1
ffffffffc0200aac:	02f68263          	beq	a3,a5,ffffffffc0200ad0 <interrupt_handler+0xb4>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200ab0:	60a2                	ld	ra,8(sp)
ffffffffc0200ab2:	0141                	addi	sp,sp,16
ffffffffc0200ab4:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200ab6:	00002517          	auipc	a0,0x2
ffffffffc0200aba:	daa50513          	addi	a0,a0,-598 # ffffffffc0202860 <etext+0x8dc>
ffffffffc0200abe:	e6aff06f          	j	ffffffffc0200128 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200ac2:	00002517          	auipc	a0,0x2
ffffffffc0200ac6:	d1650513          	addi	a0,a0,-746 # ffffffffc02027d8 <etext+0x854>
ffffffffc0200aca:	e5eff06f          	j	ffffffffc0200128 <cprintf>
            print_trapframe(tf);
ffffffffc0200ace:	b5f5                	j	ffffffffc02009ba <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200ad0:	00002517          	auipc	a0,0x2
ffffffffc0200ad4:	d8050513          	addi	a0,a0,-640 # ffffffffc0202850 <etext+0x8cc>
ffffffffc0200ad8:	e50ff0ef          	jal	ffffffffc0200128 <cprintf>
                if (++num == 10) {
ffffffffc0200adc:	00007797          	auipc	a5,0x7
ffffffffc0200ae0:	9847a783          	lw	a5,-1660(a5) # ffffffffc0207460 <num.0>
ffffffffc0200ae4:	4729                	li	a4,10
ffffffffc0200ae6:	2785                	addiw	a5,a5,1
ffffffffc0200ae8:	00007697          	auipc	a3,0x7
ffffffffc0200aec:	96f6ac23          	sw	a5,-1672(a3) # ffffffffc0207460 <num.0>
ffffffffc0200af0:	fce790e3          	bne	a5,a4,ffffffffc0200ab0 <interrupt_handler+0x94>
}
ffffffffc0200af4:	60a2                	ld	ra,8(sp)
ffffffffc0200af6:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200af8:	3be0106f          	j	ffffffffc0201eb6 <sbi_shutdown>

ffffffffc0200afc <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200afc:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b00:	1101                	addi	sp,sp,-32
ffffffffc0200b02:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc0200b04:	468d                	li	a3,3
ffffffffc0200b06:	04d78663          	beq	a5,a3,ffffffffc0200b52 <exception_handler+0x56>
ffffffffc0200b0a:	02f6ed63          	bltu	a3,a5,ffffffffc0200b44 <exception_handler+0x48>
ffffffffc0200b0e:	4689                	li	a3,2
ffffffffc0200b10:	02d79763          	bne	a5,a3,ffffffffc0200b3e <exception_handler+0x42>
             /* LAB3 CHALLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Illegal instruction at 0x%08x\n", tf->epc);
ffffffffc0200b14:	10853583          	ld	a1,264(a0)
ffffffffc0200b18:	e42a                	sd	a0,8(sp)
ffffffffc0200b1a:	00002517          	auipc	a0,0x2
ffffffffc0200b1e:	d6650513          	addi	a0,a0,-666 # ffffffffc0202880 <etext+0x8fc>
ffffffffc0200b22:	e06ff0ef          	jal	ffffffffc0200128 <cprintf>
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200b26:	00002517          	auipc	a0,0x2
ffffffffc0200b2a:	d7a50513          	addi	a0,a0,-646 # ffffffffc02028a0 <etext+0x91c>
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
            cprintf("Exception type: Breakpoint\n");
ffffffffc0200b2e:	dfaff0ef          	jal	ffffffffc0200128 <cprintf>
            tf->epc += 4; // 假设指令长度为4字
ffffffffc0200b32:	6722                	ld	a4,8(sp)
ffffffffc0200b34:	10873783          	ld	a5,264(a4)
ffffffffc0200b38:	0791                	addi	a5,a5,4
ffffffffc0200b3a:	10f73423          	sd	a5,264(a4)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b3e:	60e2                	ld	ra,24(sp)
ffffffffc0200b40:	6105                	addi	sp,sp,32
ffffffffc0200b42:	8082                	ret
    switch (tf->cause) {
ffffffffc0200b44:	17f1                	addi	a5,a5,-4
ffffffffc0200b46:	471d                	li	a4,7
ffffffffc0200b48:	fef77be3          	bgeu	a4,a5,ffffffffc0200b3e <exception_handler+0x42>
}
ffffffffc0200b4c:	60e2                	ld	ra,24(sp)
ffffffffc0200b4e:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200b50:	b5ad                	j	ffffffffc02009ba <print_trapframe>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200b52:	10853583          	ld	a1,264(a0)
ffffffffc0200b56:	e42a                	sd	a0,8(sp)
ffffffffc0200b58:	00002517          	auipc	a0,0x2
ffffffffc0200b5c:	d7050513          	addi	a0,a0,-656 # ffffffffc02028c8 <etext+0x944>
ffffffffc0200b60:	dc8ff0ef          	jal	ffffffffc0200128 <cprintf>
            cprintf("Exception type: Breakpoint\n");
ffffffffc0200b64:	00002517          	auipc	a0,0x2
ffffffffc0200b68:	d8450513          	addi	a0,a0,-636 # ffffffffc02028e8 <etext+0x964>
ffffffffc0200b6c:	b7c9                	j	ffffffffc0200b2e <exception_handler+0x32>

ffffffffc0200b6e <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b6e:	11853783          	ld	a5,280(a0)
ffffffffc0200b72:	0007c363          	bltz	a5,ffffffffc0200b78 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200b76:	b759                	j	ffffffffc0200afc <exception_handler>
        interrupt_handler(tf);
ffffffffc0200b78:	b555                	j	ffffffffc0200a1c <interrupt_handler>
	...

ffffffffc0200b7c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200b7c:	14011073          	csrw	sscratch,sp
ffffffffc0200b80:	712d                	addi	sp,sp,-288
ffffffffc0200b82:	e002                	sd	zero,0(sp)
ffffffffc0200b84:	e406                	sd	ra,8(sp)
ffffffffc0200b86:	ec0e                	sd	gp,24(sp)
ffffffffc0200b88:	f012                	sd	tp,32(sp)
ffffffffc0200b8a:	f416                	sd	t0,40(sp)
ffffffffc0200b8c:	f81a                	sd	t1,48(sp)
ffffffffc0200b8e:	fc1e                	sd	t2,56(sp)
ffffffffc0200b90:	e0a2                	sd	s0,64(sp)
ffffffffc0200b92:	e4a6                	sd	s1,72(sp)
ffffffffc0200b94:	e8aa                	sd	a0,80(sp)
ffffffffc0200b96:	ecae                	sd	a1,88(sp)
ffffffffc0200b98:	f0b2                	sd	a2,96(sp)
ffffffffc0200b9a:	f4b6                	sd	a3,104(sp)
ffffffffc0200b9c:	f8ba                	sd	a4,112(sp)
ffffffffc0200b9e:	fcbe                	sd	a5,120(sp)
ffffffffc0200ba0:	e142                	sd	a6,128(sp)
ffffffffc0200ba2:	e546                	sd	a7,136(sp)
ffffffffc0200ba4:	e94a                	sd	s2,144(sp)
ffffffffc0200ba6:	ed4e                	sd	s3,152(sp)
ffffffffc0200ba8:	f152                	sd	s4,160(sp)
ffffffffc0200baa:	f556                	sd	s5,168(sp)
ffffffffc0200bac:	f95a                	sd	s6,176(sp)
ffffffffc0200bae:	fd5e                	sd	s7,184(sp)
ffffffffc0200bb0:	e1e2                	sd	s8,192(sp)
ffffffffc0200bb2:	e5e6                	sd	s9,200(sp)
ffffffffc0200bb4:	e9ea                	sd	s10,208(sp)
ffffffffc0200bb6:	edee                	sd	s11,216(sp)
ffffffffc0200bb8:	f1f2                	sd	t3,224(sp)
ffffffffc0200bba:	f5f6                	sd	t4,232(sp)
ffffffffc0200bbc:	f9fa                	sd	t5,240(sp)
ffffffffc0200bbe:	fdfe                	sd	t6,248(sp)
ffffffffc0200bc0:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200bc4:	100024f3          	csrr	s1,sstatus
ffffffffc0200bc8:	14102973          	csrr	s2,sepc
ffffffffc0200bcc:	143029f3          	csrr	s3,stval
ffffffffc0200bd0:	14202a73          	csrr	s4,scause
ffffffffc0200bd4:	e822                	sd	s0,16(sp)
ffffffffc0200bd6:	e226                	sd	s1,256(sp)
ffffffffc0200bd8:	e64a                	sd	s2,264(sp)
ffffffffc0200bda:	ea4e                	sd	s3,272(sp)
ffffffffc0200bdc:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200bde:	850a                	mv	a0,sp
    jal trap
ffffffffc0200be0:	f8fff0ef          	jal	ffffffffc0200b6e <trap>

ffffffffc0200be4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200be4:	6492                	ld	s1,256(sp)
ffffffffc0200be6:	6932                	ld	s2,264(sp)
ffffffffc0200be8:	10049073          	csrw	sstatus,s1
ffffffffc0200bec:	14191073          	csrw	sepc,s2
ffffffffc0200bf0:	60a2                	ld	ra,8(sp)
ffffffffc0200bf2:	61e2                	ld	gp,24(sp)
ffffffffc0200bf4:	7202                	ld	tp,32(sp)
ffffffffc0200bf6:	72a2                	ld	t0,40(sp)
ffffffffc0200bf8:	7342                	ld	t1,48(sp)
ffffffffc0200bfa:	73e2                	ld	t2,56(sp)
ffffffffc0200bfc:	6406                	ld	s0,64(sp)
ffffffffc0200bfe:	64a6                	ld	s1,72(sp)
ffffffffc0200c00:	6546                	ld	a0,80(sp)
ffffffffc0200c02:	65e6                	ld	a1,88(sp)
ffffffffc0200c04:	7606                	ld	a2,96(sp)
ffffffffc0200c06:	76a6                	ld	a3,104(sp)
ffffffffc0200c08:	7746                	ld	a4,112(sp)
ffffffffc0200c0a:	77e6                	ld	a5,120(sp)
ffffffffc0200c0c:	680a                	ld	a6,128(sp)
ffffffffc0200c0e:	68aa                	ld	a7,136(sp)
ffffffffc0200c10:	694a                	ld	s2,144(sp)
ffffffffc0200c12:	69ea                	ld	s3,152(sp)
ffffffffc0200c14:	7a0a                	ld	s4,160(sp)
ffffffffc0200c16:	7aaa                	ld	s5,168(sp)
ffffffffc0200c18:	7b4a                	ld	s6,176(sp)
ffffffffc0200c1a:	7bea                	ld	s7,184(sp)
ffffffffc0200c1c:	6c0e                	ld	s8,192(sp)
ffffffffc0200c1e:	6cae                	ld	s9,200(sp)
ffffffffc0200c20:	6d4e                	ld	s10,208(sp)
ffffffffc0200c22:	6dee                	ld	s11,216(sp)
ffffffffc0200c24:	7e0e                	ld	t3,224(sp)
ffffffffc0200c26:	7eae                	ld	t4,232(sp)
ffffffffc0200c28:	7f4e                	ld	t5,240(sp)
ffffffffc0200c2a:	7fee                	ld	t6,248(sp)
ffffffffc0200c2c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c2e:	10200073          	sret

ffffffffc0200c32 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c32:	00006797          	auipc	a5,0x6
ffffffffc0200c36:	3f678793          	addi	a5,a5,1014 # ffffffffc0207028 <free_area>
ffffffffc0200c3a:	e79c                	sd	a5,8(a5)
ffffffffc0200c3c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c3e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c42:	8082                	ret

ffffffffc0200c44 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c44:	00006517          	auipc	a0,0x6
ffffffffc0200c48:	3f456503          	lwu	a0,1012(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200c4c:	8082                	ret

ffffffffc0200c4e <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200c4e:	711d                	addi	sp,sp,-96
ffffffffc0200c50:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c52:	00006917          	auipc	s2,0x6
ffffffffc0200c56:	3d690913          	addi	s2,s2,982 # ffffffffc0207028 <free_area>
ffffffffc0200c5a:	00893783          	ld	a5,8(s2)
ffffffffc0200c5e:	ec86                	sd	ra,88(sp)
ffffffffc0200c60:	e8a2                	sd	s0,80(sp)
ffffffffc0200c62:	e4a6                	sd	s1,72(sp)
ffffffffc0200c64:	fc4e                	sd	s3,56(sp)
ffffffffc0200c66:	f852                	sd	s4,48(sp)
ffffffffc0200c68:	f456                	sd	s5,40(sp)
ffffffffc0200c6a:	f05a                	sd	s6,32(sp)
ffffffffc0200c6c:	ec5e                	sd	s7,24(sp)
ffffffffc0200c6e:	e862                	sd	s8,16(sp)
ffffffffc0200c70:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c72:	31278b63          	beq	a5,s2,ffffffffc0200f88 <default_check+0x33a>
    int count = 0, total = 0;
ffffffffc0200c76:	4401                	li	s0,0
ffffffffc0200c78:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c7a:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200c7e:	8b09                	andi	a4,a4,2
ffffffffc0200c80:	30070863          	beqz	a4,ffffffffc0200f90 <default_check+0x342>
        count ++, total += p->property;
ffffffffc0200c84:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c88:	679c                	ld	a5,8(a5)
ffffffffc0200c8a:	2485                	addiw	s1,s1,1
ffffffffc0200c8c:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c8e:	ff2796e3          	bne	a5,s2,ffffffffc0200c7a <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200c92:	89a2                	mv	s3,s0
ffffffffc0200c94:	33f000ef          	jal	ffffffffc02017d2 <nr_free_pages>
ffffffffc0200c98:	75351c63          	bne	a0,s3,ffffffffc02013f0 <default_check+0x7a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c9c:	4505                	li	a0,1
ffffffffc0200c9e:	2c3000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200ca2:	8aaa                	mv	s5,a0
ffffffffc0200ca4:	48050663          	beqz	a0,ffffffffc0201130 <default_check+0x4e2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ca8:	4505                	li	a0,1
ffffffffc0200caa:	2b7000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200cae:	89aa                	mv	s3,a0
ffffffffc0200cb0:	76050063          	beqz	a0,ffffffffc0201410 <default_check+0x7c2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cb4:	4505                	li	a0,1
ffffffffc0200cb6:	2ab000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200cba:	8a2a                	mv	s4,a0
ffffffffc0200cbc:	4e050a63          	beqz	a0,ffffffffc02011b0 <default_check+0x562>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200cc0:	40aa87b3          	sub	a5,s5,a0
ffffffffc0200cc4:	40a98733          	sub	a4,s3,a0
ffffffffc0200cc8:	0017b793          	seqz	a5,a5
ffffffffc0200ccc:	00173713          	seqz	a4,a4
ffffffffc0200cd0:	8fd9                	or	a5,a5,a4
ffffffffc0200cd2:	32079f63          	bnez	a5,ffffffffc0201010 <default_check+0x3c2>
ffffffffc0200cd6:	333a8d63          	beq	s5,s3,ffffffffc0201010 <default_check+0x3c2>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200cda:	000aa783          	lw	a5,0(s5)
ffffffffc0200cde:	2c079963          	bnez	a5,ffffffffc0200fb0 <default_check+0x362>
ffffffffc0200ce2:	0009a783          	lw	a5,0(s3)
ffffffffc0200ce6:	2c079563          	bnez	a5,ffffffffc0200fb0 <default_check+0x362>
ffffffffc0200cea:	411c                	lw	a5,0(a0)
ffffffffc0200cec:	2c079263          	bnez	a5,ffffffffc0200fb0 <default_check+0x362>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cf0:	00006797          	auipc	a5,0x6
ffffffffc0200cf4:	7a07b783          	ld	a5,1952(a5) # ffffffffc0207490 <pages>
ffffffffc0200cf8:	ccccd737          	lui	a4,0xccccd
ffffffffc0200cfc:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac582d>
ffffffffc0200d00:	02071693          	slli	a3,a4,0x20
ffffffffc0200d04:	96ba                	add	a3,a3,a4
ffffffffc0200d06:	40fa8733          	sub	a4,s5,a5
ffffffffc0200d0a:	870d                	srai	a4,a4,0x3
ffffffffc0200d0c:	02d70733          	mul	a4,a4,a3
ffffffffc0200d10:	00002517          	auipc	a0,0x2
ffffffffc0200d14:	41853503          	ld	a0,1048(a0) # ffffffffc0203128 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200d18:	00006697          	auipc	a3,0x6
ffffffffc0200d1c:	7706b683          	ld	a3,1904(a3) # ffffffffc0207488 <npage>
ffffffffc0200d20:	06b2                	slli	a3,a3,0xc
ffffffffc0200d22:	972a                	add	a4,a4,a0

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d24:	0732                	slli	a4,a4,0xc
ffffffffc0200d26:	2cd77563          	bgeu	a4,a3,ffffffffc0200ff0 <default_check+0x3a2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d2a:	ccccd5b7          	lui	a1,0xccccd
ffffffffc0200d2e:	ccd58593          	addi	a1,a1,-819 # ffffffffcccccccd <end+0xcac582d>
ffffffffc0200d32:	02059613          	slli	a2,a1,0x20
ffffffffc0200d36:	40f98733          	sub	a4,s3,a5
ffffffffc0200d3a:	962e                	add	a2,a2,a1
ffffffffc0200d3c:	870d                	srai	a4,a4,0x3
ffffffffc0200d3e:	02c70733          	mul	a4,a4,a2
ffffffffc0200d42:	972a                	add	a4,a4,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d44:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d46:	4ed77563          	bgeu	a4,a3,ffffffffc0201230 <default_check+0x5e2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d4a:	40fa07b3          	sub	a5,s4,a5
ffffffffc0200d4e:	878d                	srai	a5,a5,0x3
ffffffffc0200d50:	02c787b3          	mul	a5,a5,a2
ffffffffc0200d54:	97aa                	add	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d56:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d58:	32d7fc63          	bgeu	a5,a3,ffffffffc0201090 <default_check+0x442>
    assert(alloc_page() == NULL);
ffffffffc0200d5c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d5e:	00093c03          	ld	s8,0(s2)
ffffffffc0200d62:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200d66:	00006b17          	auipc	s6,0x6
ffffffffc0200d6a:	2d2b2b03          	lw	s6,722(s6) # ffffffffc0207038 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200d6e:	01293023          	sd	s2,0(s2)
ffffffffc0200d72:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200d76:	00006797          	auipc	a5,0x6
ffffffffc0200d7a:	2c07a123          	sw	zero,706(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200d7e:	1e3000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200d82:	2e051763          	bnez	a0,ffffffffc0201070 <default_check+0x422>
    free_page(p0);
ffffffffc0200d86:	8556                	mv	a0,s5
ffffffffc0200d88:	4585                	li	a1,1
ffffffffc0200d8a:	211000ef          	jal	ffffffffc020179a <free_pages>
    free_page(p1);
ffffffffc0200d8e:	854e                	mv	a0,s3
ffffffffc0200d90:	4585                	li	a1,1
ffffffffc0200d92:	209000ef          	jal	ffffffffc020179a <free_pages>
    free_page(p2);
ffffffffc0200d96:	8552                	mv	a0,s4
ffffffffc0200d98:	4585                	li	a1,1
ffffffffc0200d9a:	201000ef          	jal	ffffffffc020179a <free_pages>
    assert(nr_free == 3);
ffffffffc0200d9e:	00006717          	auipc	a4,0x6
ffffffffc0200da2:	29a72703          	lw	a4,666(a4) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200da6:	478d                	li	a5,3
ffffffffc0200da8:	2af71463          	bne	a4,a5,ffffffffc0201050 <default_check+0x402>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200dac:	4505                	li	a0,1
ffffffffc0200dae:	1b3000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200db2:	89aa                	mv	s3,a0
ffffffffc0200db4:	26050e63          	beqz	a0,ffffffffc0201030 <default_check+0x3e2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200db8:	4505                	li	a0,1
ffffffffc0200dba:	1a7000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200dbe:	8aaa                	mv	s5,a0
ffffffffc0200dc0:	3c050863          	beqz	a0,ffffffffc0201190 <default_check+0x542>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200dc4:	4505                	li	a0,1
ffffffffc0200dc6:	19b000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200dca:	8a2a                	mv	s4,a0
ffffffffc0200dcc:	3a050263          	beqz	a0,ffffffffc0201170 <default_check+0x522>
    assert(alloc_page() == NULL);
ffffffffc0200dd0:	4505                	li	a0,1
ffffffffc0200dd2:	18f000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200dd6:	36051d63          	bnez	a0,ffffffffc0201150 <default_check+0x502>
    free_page(p0);
ffffffffc0200dda:	4585                	li	a1,1
ffffffffc0200ddc:	854e                	mv	a0,s3
ffffffffc0200dde:	1bd000ef          	jal	ffffffffc020179a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200de2:	00893783          	ld	a5,8(s2)
ffffffffc0200de6:	1f278563          	beq	a5,s2,ffffffffc0200fd0 <default_check+0x382>
    assert((p = alloc_page()) == p0);
ffffffffc0200dea:	4505                	li	a0,1
ffffffffc0200dec:	175000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200df0:	8caa                	mv	s9,a0
ffffffffc0200df2:	30a99f63          	bne	s3,a0,ffffffffc0201110 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200df6:	4505                	li	a0,1
ffffffffc0200df8:	169000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200dfc:	2e051a63          	bnez	a0,ffffffffc02010f0 <default_check+0x4a2>
    assert(nr_free == 0);
ffffffffc0200e00:	00006797          	auipc	a5,0x6
ffffffffc0200e04:	2387a783          	lw	a5,568(a5) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200e08:	2c079463          	bnez	a5,ffffffffc02010d0 <default_check+0x482>
    free_page(p);
ffffffffc0200e0c:	8566                	mv	a0,s9
ffffffffc0200e0e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200e10:	01893023          	sd	s8,0(s2)
ffffffffc0200e14:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200e18:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200e1c:	17f000ef          	jal	ffffffffc020179a <free_pages>
    free_page(p1);
ffffffffc0200e20:	8556                	mv	a0,s5
ffffffffc0200e22:	4585                	li	a1,1
ffffffffc0200e24:	177000ef          	jal	ffffffffc020179a <free_pages>
    free_page(p2);
ffffffffc0200e28:	8552                	mv	a0,s4
ffffffffc0200e2a:	4585                	li	a1,1
ffffffffc0200e2c:	16f000ef          	jal	ffffffffc020179a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200e30:	4515                	li	a0,5
ffffffffc0200e32:	12f000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200e36:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200e38:	26050c63          	beqz	a0,ffffffffc02010b0 <default_check+0x462>
ffffffffc0200e3c:	651c                	ld	a5,8(a0)
ffffffffc0200e3e:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200e40:	8b85                	andi	a5,a5,1
ffffffffc0200e42:	54079763          	bnez	a5,ffffffffc0201390 <default_check+0x742>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200e46:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e48:	00093b83          	ld	s7,0(s2)
ffffffffc0200e4c:	00893b03          	ld	s6,8(s2)
ffffffffc0200e50:	01293023          	sd	s2,0(s2)
ffffffffc0200e54:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200e58:	109000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200e5c:	50051a63          	bnez	a0,ffffffffc0201370 <default_check+0x722>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200e60:	05098a13          	addi	s4,s3,80
ffffffffc0200e64:	8552                	mv	a0,s4
ffffffffc0200e66:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200e68:	00006c17          	auipc	s8,0x6
ffffffffc0200e6c:	1d0c2c03          	lw	s8,464(s8) # ffffffffc0207038 <free_area+0x10>
    nr_free = 0;
ffffffffc0200e70:	00006797          	auipc	a5,0x6
ffffffffc0200e74:	1c07a423          	sw	zero,456(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200e78:	123000ef          	jal	ffffffffc020179a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e7c:	4511                	li	a0,4
ffffffffc0200e7e:	0e3000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200e82:	4c051763          	bnez	a0,ffffffffc0201350 <default_check+0x702>
ffffffffc0200e86:	0589b783          	ld	a5,88(s3)
ffffffffc0200e8a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200e8c:	8b85                	andi	a5,a5,1
ffffffffc0200e8e:	4a078163          	beqz	a5,ffffffffc0201330 <default_check+0x6e2>
ffffffffc0200e92:	0609a503          	lw	a0,96(s3)
ffffffffc0200e96:	478d                	li	a5,3
ffffffffc0200e98:	48f51c63          	bne	a0,a5,ffffffffc0201330 <default_check+0x6e2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200e9c:	0c5000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200ea0:	8aaa                	mv	s5,a0
ffffffffc0200ea2:	46050763          	beqz	a0,ffffffffc0201310 <default_check+0x6c2>
    assert(alloc_page() == NULL);
ffffffffc0200ea6:	4505                	li	a0,1
ffffffffc0200ea8:	0b9000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200eac:	44051263          	bnez	a0,ffffffffc02012f0 <default_check+0x6a2>
    assert(p0 + 2 == p1);
ffffffffc0200eb0:	435a1063          	bne	s4,s5,ffffffffc02012d0 <default_check+0x682>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200eb4:	4585                	li	a1,1
ffffffffc0200eb6:	854e                	mv	a0,s3
ffffffffc0200eb8:	0e3000ef          	jal	ffffffffc020179a <free_pages>
    free_pages(p1, 3);
ffffffffc0200ebc:	8552                	mv	a0,s4
ffffffffc0200ebe:	458d                	li	a1,3
ffffffffc0200ec0:	0db000ef          	jal	ffffffffc020179a <free_pages>
ffffffffc0200ec4:	0089b783          	ld	a5,8(s3)
ffffffffc0200ec8:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200eca:	8b85                	andi	a5,a5,1
ffffffffc0200ecc:	3e078263          	beqz	a5,ffffffffc02012b0 <default_check+0x662>
ffffffffc0200ed0:	0109aa83          	lw	s5,16(s3)
ffffffffc0200ed4:	4785                	li	a5,1
ffffffffc0200ed6:	3cfa9d63          	bne	s5,a5,ffffffffc02012b0 <default_check+0x662>
ffffffffc0200eda:	008a3783          	ld	a5,8(s4)
ffffffffc0200ede:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200ee0:	8b85                	andi	a5,a5,1
ffffffffc0200ee2:	3a078763          	beqz	a5,ffffffffc0201290 <default_check+0x642>
ffffffffc0200ee6:	010a2703          	lw	a4,16(s4)
ffffffffc0200eea:	478d                	li	a5,3
ffffffffc0200eec:	3af71263          	bne	a4,a5,ffffffffc0201290 <default_check+0x642>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200ef0:	8556                	mv	a0,s5
ffffffffc0200ef2:	06f000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200ef6:	36a99d63          	bne	s3,a0,ffffffffc0201270 <default_check+0x622>
    free_page(p0);
ffffffffc0200efa:	85d6                	mv	a1,s5
ffffffffc0200efc:	09f000ef          	jal	ffffffffc020179a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200f00:	4509                	li	a0,2
ffffffffc0200f02:	05f000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200f06:	34aa1563          	bne	s4,a0,ffffffffc0201250 <default_check+0x602>

    free_pages(p0, 2);
ffffffffc0200f0a:	4589                	li	a1,2
ffffffffc0200f0c:	08f000ef          	jal	ffffffffc020179a <free_pages>
    free_page(p2);
ffffffffc0200f10:	02898513          	addi	a0,s3,40
ffffffffc0200f14:	85d6                	mv	a1,s5
ffffffffc0200f16:	085000ef          	jal	ffffffffc020179a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f1a:	4515                	li	a0,5
ffffffffc0200f1c:	045000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200f20:	89aa                	mv	s3,a0
ffffffffc0200f22:	48050763          	beqz	a0,ffffffffc02013b0 <default_check+0x762>
    assert(alloc_page() == NULL);
ffffffffc0200f26:	8556                	mv	a0,s5
ffffffffc0200f28:	039000ef          	jal	ffffffffc0201760 <alloc_pages>
ffffffffc0200f2c:	2e051263          	bnez	a0,ffffffffc0201210 <default_check+0x5c2>

    assert(nr_free == 0);
ffffffffc0200f30:	00006797          	auipc	a5,0x6
ffffffffc0200f34:	1087a783          	lw	a5,264(a5) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200f38:	2a079c63          	bnez	a5,ffffffffc02011f0 <default_check+0x5a2>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200f3c:	854e                	mv	a0,s3
ffffffffc0200f3e:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0200f40:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0200f44:	01793023          	sd	s7,0(s2)
ffffffffc0200f48:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0200f4c:	04f000ef          	jal	ffffffffc020179a <free_pages>
    return listelm->next;
ffffffffc0200f50:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f54:	01278963          	beq	a5,s2,ffffffffc0200f66 <default_check+0x318>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200f58:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f5c:	679c                	ld	a5,8(a5)
ffffffffc0200f5e:	34fd                	addiw	s1,s1,-1
ffffffffc0200f60:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f62:	ff279be3          	bne	a5,s2,ffffffffc0200f58 <default_check+0x30a>
    }
    assert(count == 0);
ffffffffc0200f66:	26049563          	bnez	s1,ffffffffc02011d0 <default_check+0x582>
    assert(total == 0);
ffffffffc0200f6a:	46041363          	bnez	s0,ffffffffc02013d0 <default_check+0x782>
}
ffffffffc0200f6e:	60e6                	ld	ra,88(sp)
ffffffffc0200f70:	6446                	ld	s0,80(sp)
ffffffffc0200f72:	64a6                	ld	s1,72(sp)
ffffffffc0200f74:	6906                	ld	s2,64(sp)
ffffffffc0200f76:	79e2                	ld	s3,56(sp)
ffffffffc0200f78:	7a42                	ld	s4,48(sp)
ffffffffc0200f7a:	7aa2                	ld	s5,40(sp)
ffffffffc0200f7c:	7b02                	ld	s6,32(sp)
ffffffffc0200f7e:	6be2                	ld	s7,24(sp)
ffffffffc0200f80:	6c42                	ld	s8,16(sp)
ffffffffc0200f82:	6ca2                	ld	s9,8(sp)
ffffffffc0200f84:	6125                	addi	sp,sp,96
ffffffffc0200f86:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f88:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200f8a:	4401                	li	s0,0
ffffffffc0200f8c:	4481                	li	s1,0
ffffffffc0200f8e:	b319                	j	ffffffffc0200c94 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0200f90:	00002697          	auipc	a3,0x2
ffffffffc0200f94:	97868693          	addi	a3,a3,-1672 # ffffffffc0202908 <etext+0x984>
ffffffffc0200f98:	00002617          	auipc	a2,0x2
ffffffffc0200f9c:	98060613          	addi	a2,a2,-1664 # ffffffffc0202918 <etext+0x994>
ffffffffc0200fa0:	0f000593          	li	a1,240
ffffffffc0200fa4:	00002517          	auipc	a0,0x2
ffffffffc0200fa8:	98c50513          	addi	a0,a0,-1652 # ffffffffc0202930 <etext+0x9ac>
ffffffffc0200fac:	c2eff0ef          	jal	ffffffffc02003da <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200fb0:	00002697          	auipc	a3,0x2
ffffffffc0200fb4:	a4068693          	addi	a3,a3,-1472 # ffffffffc02029f0 <etext+0xa6c>
ffffffffc0200fb8:	00002617          	auipc	a2,0x2
ffffffffc0200fbc:	96060613          	addi	a2,a2,-1696 # ffffffffc0202918 <etext+0x994>
ffffffffc0200fc0:	0be00593          	li	a1,190
ffffffffc0200fc4:	00002517          	auipc	a0,0x2
ffffffffc0200fc8:	96c50513          	addi	a0,a0,-1684 # ffffffffc0202930 <etext+0x9ac>
ffffffffc0200fcc:	c0eff0ef          	jal	ffffffffc02003da <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200fd0:	00002697          	auipc	a3,0x2
ffffffffc0200fd4:	ae868693          	addi	a3,a3,-1304 # ffffffffc0202ab8 <etext+0xb34>
ffffffffc0200fd8:	00002617          	auipc	a2,0x2
ffffffffc0200fdc:	94060613          	addi	a2,a2,-1728 # ffffffffc0202918 <etext+0x994>
ffffffffc0200fe0:	0d900593          	li	a1,217
ffffffffc0200fe4:	00002517          	auipc	a0,0x2
ffffffffc0200fe8:	94c50513          	addi	a0,a0,-1716 # ffffffffc0202930 <etext+0x9ac>
ffffffffc0200fec:	beeff0ef          	jal	ffffffffc02003da <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ff0:	00002697          	auipc	a3,0x2
ffffffffc0200ff4:	a4068693          	addi	a3,a3,-1472 # ffffffffc0202a30 <etext+0xaac>
ffffffffc0200ff8:	00002617          	auipc	a2,0x2
ffffffffc0200ffc:	92060613          	addi	a2,a2,-1760 # ffffffffc0202918 <etext+0x994>
ffffffffc0201000:	0c000593          	li	a1,192
ffffffffc0201004:	00002517          	auipc	a0,0x2
ffffffffc0201008:	92c50513          	addi	a0,a0,-1748 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020100c:	bceff0ef          	jal	ffffffffc02003da <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201010:	00002697          	auipc	a3,0x2
ffffffffc0201014:	9b868693          	addi	a3,a3,-1608 # ffffffffc02029c8 <etext+0xa44>
ffffffffc0201018:	00002617          	auipc	a2,0x2
ffffffffc020101c:	90060613          	addi	a2,a2,-1792 # ffffffffc0202918 <etext+0x994>
ffffffffc0201020:	0bd00593          	li	a1,189
ffffffffc0201024:	00002517          	auipc	a0,0x2
ffffffffc0201028:	90c50513          	addi	a0,a0,-1780 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020102c:	baeff0ef          	jal	ffffffffc02003da <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201030:	00002697          	auipc	a3,0x2
ffffffffc0201034:	93868693          	addi	a3,a3,-1736 # ffffffffc0202968 <etext+0x9e4>
ffffffffc0201038:	00002617          	auipc	a2,0x2
ffffffffc020103c:	8e060613          	addi	a2,a2,-1824 # ffffffffc0202918 <etext+0x994>
ffffffffc0201040:	0d200593          	li	a1,210
ffffffffc0201044:	00002517          	auipc	a0,0x2
ffffffffc0201048:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020104c:	b8eff0ef          	jal	ffffffffc02003da <__panic>
    assert(nr_free == 3);
ffffffffc0201050:	00002697          	auipc	a3,0x2
ffffffffc0201054:	a5868693          	addi	a3,a3,-1448 # ffffffffc0202aa8 <etext+0xb24>
ffffffffc0201058:	00002617          	auipc	a2,0x2
ffffffffc020105c:	8c060613          	addi	a2,a2,-1856 # ffffffffc0202918 <etext+0x994>
ffffffffc0201060:	0d000593          	li	a1,208
ffffffffc0201064:	00002517          	auipc	a0,0x2
ffffffffc0201068:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020106c:	b6eff0ef          	jal	ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201070:	00002697          	auipc	a3,0x2
ffffffffc0201074:	a2068693          	addi	a3,a3,-1504 # ffffffffc0202a90 <etext+0xb0c>
ffffffffc0201078:	00002617          	auipc	a2,0x2
ffffffffc020107c:	8a060613          	addi	a2,a2,-1888 # ffffffffc0202918 <etext+0x994>
ffffffffc0201080:	0cb00593          	li	a1,203
ffffffffc0201084:	00002517          	auipc	a0,0x2
ffffffffc0201088:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020108c:	b4eff0ef          	jal	ffffffffc02003da <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201090:	00002697          	auipc	a3,0x2
ffffffffc0201094:	9e068693          	addi	a3,a3,-1568 # ffffffffc0202a70 <etext+0xaec>
ffffffffc0201098:	00002617          	auipc	a2,0x2
ffffffffc020109c:	88060613          	addi	a2,a2,-1920 # ffffffffc0202918 <etext+0x994>
ffffffffc02010a0:	0c200593          	li	a1,194
ffffffffc02010a4:	00002517          	auipc	a0,0x2
ffffffffc02010a8:	88c50513          	addi	a0,a0,-1908 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02010ac:	b2eff0ef          	jal	ffffffffc02003da <__panic>
    assert(p0 != NULL);
ffffffffc02010b0:	00002697          	auipc	a3,0x2
ffffffffc02010b4:	a5068693          	addi	a3,a3,-1456 # ffffffffc0202b00 <etext+0xb7c>
ffffffffc02010b8:	00002617          	auipc	a2,0x2
ffffffffc02010bc:	86060613          	addi	a2,a2,-1952 # ffffffffc0202918 <etext+0x994>
ffffffffc02010c0:	0f800593          	li	a1,248
ffffffffc02010c4:	00002517          	auipc	a0,0x2
ffffffffc02010c8:	86c50513          	addi	a0,a0,-1940 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02010cc:	b0eff0ef          	jal	ffffffffc02003da <__panic>
    assert(nr_free == 0);
ffffffffc02010d0:	00002697          	auipc	a3,0x2
ffffffffc02010d4:	a2068693          	addi	a3,a3,-1504 # ffffffffc0202af0 <etext+0xb6c>
ffffffffc02010d8:	00002617          	auipc	a2,0x2
ffffffffc02010dc:	84060613          	addi	a2,a2,-1984 # ffffffffc0202918 <etext+0x994>
ffffffffc02010e0:	0df00593          	li	a1,223
ffffffffc02010e4:	00002517          	auipc	a0,0x2
ffffffffc02010e8:	84c50513          	addi	a0,a0,-1972 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02010ec:	aeeff0ef          	jal	ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010f0:	00002697          	auipc	a3,0x2
ffffffffc02010f4:	9a068693          	addi	a3,a3,-1632 # ffffffffc0202a90 <etext+0xb0c>
ffffffffc02010f8:	00002617          	auipc	a2,0x2
ffffffffc02010fc:	82060613          	addi	a2,a2,-2016 # ffffffffc0202918 <etext+0x994>
ffffffffc0201100:	0dd00593          	li	a1,221
ffffffffc0201104:	00002517          	auipc	a0,0x2
ffffffffc0201108:	82c50513          	addi	a0,a0,-2004 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020110c:	aceff0ef          	jal	ffffffffc02003da <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201110:	00002697          	auipc	a3,0x2
ffffffffc0201114:	9c068693          	addi	a3,a3,-1600 # ffffffffc0202ad0 <etext+0xb4c>
ffffffffc0201118:	00002617          	auipc	a2,0x2
ffffffffc020111c:	80060613          	addi	a2,a2,-2048 # ffffffffc0202918 <etext+0x994>
ffffffffc0201120:	0dc00593          	li	a1,220
ffffffffc0201124:	00002517          	auipc	a0,0x2
ffffffffc0201128:	80c50513          	addi	a0,a0,-2036 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020112c:	aaeff0ef          	jal	ffffffffc02003da <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201130:	00002697          	auipc	a3,0x2
ffffffffc0201134:	83868693          	addi	a3,a3,-1992 # ffffffffc0202968 <etext+0x9e4>
ffffffffc0201138:	00001617          	auipc	a2,0x1
ffffffffc020113c:	7e060613          	addi	a2,a2,2016 # ffffffffc0202918 <etext+0x994>
ffffffffc0201140:	0b900593          	li	a1,185
ffffffffc0201144:	00001517          	auipc	a0,0x1
ffffffffc0201148:	7ec50513          	addi	a0,a0,2028 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020114c:	a8eff0ef          	jal	ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201150:	00002697          	auipc	a3,0x2
ffffffffc0201154:	94068693          	addi	a3,a3,-1728 # ffffffffc0202a90 <etext+0xb0c>
ffffffffc0201158:	00001617          	auipc	a2,0x1
ffffffffc020115c:	7c060613          	addi	a2,a2,1984 # ffffffffc0202918 <etext+0x994>
ffffffffc0201160:	0d600593          	li	a1,214
ffffffffc0201164:	00001517          	auipc	a0,0x1
ffffffffc0201168:	7cc50513          	addi	a0,a0,1996 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020116c:	a6eff0ef          	jal	ffffffffc02003da <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201170:	00002697          	auipc	a3,0x2
ffffffffc0201174:	83868693          	addi	a3,a3,-1992 # ffffffffc02029a8 <etext+0xa24>
ffffffffc0201178:	00001617          	auipc	a2,0x1
ffffffffc020117c:	7a060613          	addi	a2,a2,1952 # ffffffffc0202918 <etext+0x994>
ffffffffc0201180:	0d400593          	li	a1,212
ffffffffc0201184:	00001517          	auipc	a0,0x1
ffffffffc0201188:	7ac50513          	addi	a0,a0,1964 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020118c:	a4eff0ef          	jal	ffffffffc02003da <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201190:	00001697          	auipc	a3,0x1
ffffffffc0201194:	7f868693          	addi	a3,a3,2040 # ffffffffc0202988 <etext+0xa04>
ffffffffc0201198:	00001617          	auipc	a2,0x1
ffffffffc020119c:	78060613          	addi	a2,a2,1920 # ffffffffc0202918 <etext+0x994>
ffffffffc02011a0:	0d300593          	li	a1,211
ffffffffc02011a4:	00001517          	auipc	a0,0x1
ffffffffc02011a8:	78c50513          	addi	a0,a0,1932 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02011ac:	a2eff0ef          	jal	ffffffffc02003da <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011b0:	00001697          	auipc	a3,0x1
ffffffffc02011b4:	7f868693          	addi	a3,a3,2040 # ffffffffc02029a8 <etext+0xa24>
ffffffffc02011b8:	00001617          	auipc	a2,0x1
ffffffffc02011bc:	76060613          	addi	a2,a2,1888 # ffffffffc0202918 <etext+0x994>
ffffffffc02011c0:	0bb00593          	li	a1,187
ffffffffc02011c4:	00001517          	auipc	a0,0x1
ffffffffc02011c8:	76c50513          	addi	a0,a0,1900 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02011cc:	a0eff0ef          	jal	ffffffffc02003da <__panic>
    assert(count == 0);
ffffffffc02011d0:	00002697          	auipc	a3,0x2
ffffffffc02011d4:	a8068693          	addi	a3,a3,-1408 # ffffffffc0202c50 <etext+0xccc>
ffffffffc02011d8:	00001617          	auipc	a2,0x1
ffffffffc02011dc:	74060613          	addi	a2,a2,1856 # ffffffffc0202918 <etext+0x994>
ffffffffc02011e0:	12500593          	li	a1,293
ffffffffc02011e4:	00001517          	auipc	a0,0x1
ffffffffc02011e8:	74c50513          	addi	a0,a0,1868 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02011ec:	9eeff0ef          	jal	ffffffffc02003da <__panic>
    assert(nr_free == 0);
ffffffffc02011f0:	00002697          	auipc	a3,0x2
ffffffffc02011f4:	90068693          	addi	a3,a3,-1792 # ffffffffc0202af0 <etext+0xb6c>
ffffffffc02011f8:	00001617          	auipc	a2,0x1
ffffffffc02011fc:	72060613          	addi	a2,a2,1824 # ffffffffc0202918 <etext+0x994>
ffffffffc0201200:	11a00593          	li	a1,282
ffffffffc0201204:	00001517          	auipc	a0,0x1
ffffffffc0201208:	72c50513          	addi	a0,a0,1836 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020120c:	9ceff0ef          	jal	ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201210:	00002697          	auipc	a3,0x2
ffffffffc0201214:	88068693          	addi	a3,a3,-1920 # ffffffffc0202a90 <etext+0xb0c>
ffffffffc0201218:	00001617          	auipc	a2,0x1
ffffffffc020121c:	70060613          	addi	a2,a2,1792 # ffffffffc0202918 <etext+0x994>
ffffffffc0201220:	11800593          	li	a1,280
ffffffffc0201224:	00001517          	auipc	a0,0x1
ffffffffc0201228:	70c50513          	addi	a0,a0,1804 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020122c:	9aeff0ef          	jal	ffffffffc02003da <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201230:	00002697          	auipc	a3,0x2
ffffffffc0201234:	82068693          	addi	a3,a3,-2016 # ffffffffc0202a50 <etext+0xacc>
ffffffffc0201238:	00001617          	auipc	a2,0x1
ffffffffc020123c:	6e060613          	addi	a2,a2,1760 # ffffffffc0202918 <etext+0x994>
ffffffffc0201240:	0c100593          	li	a1,193
ffffffffc0201244:	00001517          	auipc	a0,0x1
ffffffffc0201248:	6ec50513          	addi	a0,a0,1772 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020124c:	98eff0ef          	jal	ffffffffc02003da <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201250:	00002697          	auipc	a3,0x2
ffffffffc0201254:	9c068693          	addi	a3,a3,-1600 # ffffffffc0202c10 <etext+0xc8c>
ffffffffc0201258:	00001617          	auipc	a2,0x1
ffffffffc020125c:	6c060613          	addi	a2,a2,1728 # ffffffffc0202918 <etext+0x994>
ffffffffc0201260:	11200593          	li	a1,274
ffffffffc0201264:	00001517          	auipc	a0,0x1
ffffffffc0201268:	6cc50513          	addi	a0,a0,1740 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020126c:	96eff0ef          	jal	ffffffffc02003da <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201270:	00002697          	auipc	a3,0x2
ffffffffc0201274:	98068693          	addi	a3,a3,-1664 # ffffffffc0202bf0 <etext+0xc6c>
ffffffffc0201278:	00001617          	auipc	a2,0x1
ffffffffc020127c:	6a060613          	addi	a2,a2,1696 # ffffffffc0202918 <etext+0x994>
ffffffffc0201280:	11000593          	li	a1,272
ffffffffc0201284:	00001517          	auipc	a0,0x1
ffffffffc0201288:	6ac50513          	addi	a0,a0,1708 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020128c:	94eff0ef          	jal	ffffffffc02003da <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201290:	00002697          	auipc	a3,0x2
ffffffffc0201294:	93868693          	addi	a3,a3,-1736 # ffffffffc0202bc8 <etext+0xc44>
ffffffffc0201298:	00001617          	auipc	a2,0x1
ffffffffc020129c:	68060613          	addi	a2,a2,1664 # ffffffffc0202918 <etext+0x994>
ffffffffc02012a0:	10e00593          	li	a1,270
ffffffffc02012a4:	00001517          	auipc	a0,0x1
ffffffffc02012a8:	68c50513          	addi	a0,a0,1676 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02012ac:	92eff0ef          	jal	ffffffffc02003da <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02012b0:	00002697          	auipc	a3,0x2
ffffffffc02012b4:	8f068693          	addi	a3,a3,-1808 # ffffffffc0202ba0 <etext+0xc1c>
ffffffffc02012b8:	00001617          	auipc	a2,0x1
ffffffffc02012bc:	66060613          	addi	a2,a2,1632 # ffffffffc0202918 <etext+0x994>
ffffffffc02012c0:	10d00593          	li	a1,269
ffffffffc02012c4:	00001517          	auipc	a0,0x1
ffffffffc02012c8:	66c50513          	addi	a0,a0,1644 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02012cc:	90eff0ef          	jal	ffffffffc02003da <__panic>
    assert(p0 + 2 == p1);
ffffffffc02012d0:	00002697          	auipc	a3,0x2
ffffffffc02012d4:	8c068693          	addi	a3,a3,-1856 # ffffffffc0202b90 <etext+0xc0c>
ffffffffc02012d8:	00001617          	auipc	a2,0x1
ffffffffc02012dc:	64060613          	addi	a2,a2,1600 # ffffffffc0202918 <etext+0x994>
ffffffffc02012e0:	10800593          	li	a1,264
ffffffffc02012e4:	00001517          	auipc	a0,0x1
ffffffffc02012e8:	64c50513          	addi	a0,a0,1612 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02012ec:	8eeff0ef          	jal	ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012f0:	00001697          	auipc	a3,0x1
ffffffffc02012f4:	7a068693          	addi	a3,a3,1952 # ffffffffc0202a90 <etext+0xb0c>
ffffffffc02012f8:	00001617          	auipc	a2,0x1
ffffffffc02012fc:	62060613          	addi	a2,a2,1568 # ffffffffc0202918 <etext+0x994>
ffffffffc0201300:	10700593          	li	a1,263
ffffffffc0201304:	00001517          	auipc	a0,0x1
ffffffffc0201308:	62c50513          	addi	a0,a0,1580 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020130c:	8ceff0ef          	jal	ffffffffc02003da <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201310:	00002697          	auipc	a3,0x2
ffffffffc0201314:	86068693          	addi	a3,a3,-1952 # ffffffffc0202b70 <etext+0xbec>
ffffffffc0201318:	00001617          	auipc	a2,0x1
ffffffffc020131c:	60060613          	addi	a2,a2,1536 # ffffffffc0202918 <etext+0x994>
ffffffffc0201320:	10600593          	li	a1,262
ffffffffc0201324:	00001517          	auipc	a0,0x1
ffffffffc0201328:	60c50513          	addi	a0,a0,1548 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020132c:	8aeff0ef          	jal	ffffffffc02003da <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201330:	00002697          	auipc	a3,0x2
ffffffffc0201334:	81068693          	addi	a3,a3,-2032 # ffffffffc0202b40 <etext+0xbbc>
ffffffffc0201338:	00001617          	auipc	a2,0x1
ffffffffc020133c:	5e060613          	addi	a2,a2,1504 # ffffffffc0202918 <etext+0x994>
ffffffffc0201340:	10500593          	li	a1,261
ffffffffc0201344:	00001517          	auipc	a0,0x1
ffffffffc0201348:	5ec50513          	addi	a0,a0,1516 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020134c:	88eff0ef          	jal	ffffffffc02003da <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201350:	00001697          	auipc	a3,0x1
ffffffffc0201354:	7d868693          	addi	a3,a3,2008 # ffffffffc0202b28 <etext+0xba4>
ffffffffc0201358:	00001617          	auipc	a2,0x1
ffffffffc020135c:	5c060613          	addi	a2,a2,1472 # ffffffffc0202918 <etext+0x994>
ffffffffc0201360:	10400593          	li	a1,260
ffffffffc0201364:	00001517          	auipc	a0,0x1
ffffffffc0201368:	5cc50513          	addi	a0,a0,1484 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020136c:	86eff0ef          	jal	ffffffffc02003da <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201370:	00001697          	auipc	a3,0x1
ffffffffc0201374:	72068693          	addi	a3,a3,1824 # ffffffffc0202a90 <etext+0xb0c>
ffffffffc0201378:	00001617          	auipc	a2,0x1
ffffffffc020137c:	5a060613          	addi	a2,a2,1440 # ffffffffc0202918 <etext+0x994>
ffffffffc0201380:	0fe00593          	li	a1,254
ffffffffc0201384:	00001517          	auipc	a0,0x1
ffffffffc0201388:	5ac50513          	addi	a0,a0,1452 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020138c:	84eff0ef          	jal	ffffffffc02003da <__panic>
    assert(!PageProperty(p0));
ffffffffc0201390:	00001697          	auipc	a3,0x1
ffffffffc0201394:	78068693          	addi	a3,a3,1920 # ffffffffc0202b10 <etext+0xb8c>
ffffffffc0201398:	00001617          	auipc	a2,0x1
ffffffffc020139c:	58060613          	addi	a2,a2,1408 # ffffffffc0202918 <etext+0x994>
ffffffffc02013a0:	0f900593          	li	a1,249
ffffffffc02013a4:	00001517          	auipc	a0,0x1
ffffffffc02013a8:	58c50513          	addi	a0,a0,1420 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02013ac:	82eff0ef          	jal	ffffffffc02003da <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02013b0:	00002697          	auipc	a3,0x2
ffffffffc02013b4:	88068693          	addi	a3,a3,-1920 # ffffffffc0202c30 <etext+0xcac>
ffffffffc02013b8:	00001617          	auipc	a2,0x1
ffffffffc02013bc:	56060613          	addi	a2,a2,1376 # ffffffffc0202918 <etext+0x994>
ffffffffc02013c0:	11700593          	li	a1,279
ffffffffc02013c4:	00001517          	auipc	a0,0x1
ffffffffc02013c8:	56c50513          	addi	a0,a0,1388 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02013cc:	80eff0ef          	jal	ffffffffc02003da <__panic>
    assert(total == 0);
ffffffffc02013d0:	00002697          	auipc	a3,0x2
ffffffffc02013d4:	89068693          	addi	a3,a3,-1904 # ffffffffc0202c60 <etext+0xcdc>
ffffffffc02013d8:	00001617          	auipc	a2,0x1
ffffffffc02013dc:	54060613          	addi	a2,a2,1344 # ffffffffc0202918 <etext+0x994>
ffffffffc02013e0:	12600593          	li	a1,294
ffffffffc02013e4:	00001517          	auipc	a0,0x1
ffffffffc02013e8:	54c50513          	addi	a0,a0,1356 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02013ec:	feffe0ef          	jal	ffffffffc02003da <__panic>
    assert(total == nr_free_pages());
ffffffffc02013f0:	00001697          	auipc	a3,0x1
ffffffffc02013f4:	55868693          	addi	a3,a3,1368 # ffffffffc0202948 <etext+0x9c4>
ffffffffc02013f8:	00001617          	auipc	a2,0x1
ffffffffc02013fc:	52060613          	addi	a2,a2,1312 # ffffffffc0202918 <etext+0x994>
ffffffffc0201400:	0f300593          	li	a1,243
ffffffffc0201404:	00001517          	auipc	a0,0x1
ffffffffc0201408:	52c50513          	addi	a0,a0,1324 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020140c:	fcffe0ef          	jal	ffffffffc02003da <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201410:	00001697          	auipc	a3,0x1
ffffffffc0201414:	57868693          	addi	a3,a3,1400 # ffffffffc0202988 <etext+0xa04>
ffffffffc0201418:	00001617          	auipc	a2,0x1
ffffffffc020141c:	50060613          	addi	a2,a2,1280 # ffffffffc0202918 <etext+0x994>
ffffffffc0201420:	0ba00593          	li	a1,186
ffffffffc0201424:	00001517          	auipc	a0,0x1
ffffffffc0201428:	50c50513          	addi	a0,a0,1292 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020142c:	faffe0ef          	jal	ffffffffc02003da <__panic>

ffffffffc0201430 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201430:	1141                	addi	sp,sp,-16
ffffffffc0201432:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201434:	14058c63          	beqz	a1,ffffffffc020158c <default_free_pages+0x15c>
    for (; p != base + n; p ++) {
ffffffffc0201438:	00259713          	slli	a4,a1,0x2
ffffffffc020143c:	972e                	add	a4,a4,a1
ffffffffc020143e:	070e                	slli	a4,a4,0x3
ffffffffc0201440:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201444:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201446:	c30d                	beqz	a4,ffffffffc0201468 <default_free_pages+0x38>
ffffffffc0201448:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020144a:	8b05                	andi	a4,a4,1
ffffffffc020144c:	12071063          	bnez	a4,ffffffffc020156c <default_free_pages+0x13c>
ffffffffc0201450:	6798                	ld	a4,8(a5)
ffffffffc0201452:	8b09                	andi	a4,a4,2
ffffffffc0201454:	10071c63          	bnez	a4,ffffffffc020156c <default_free_pages+0x13c>
        p->flags = 0;
ffffffffc0201458:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020145c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201460:	02878793          	addi	a5,a5,40
ffffffffc0201464:	fed792e3          	bne	a5,a3,ffffffffc0201448 <default_free_pages+0x18>
    base->property = n;
ffffffffc0201468:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020146a:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020146e:	4789                	li	a5,2
ffffffffc0201470:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201474:	00006717          	auipc	a4,0x6
ffffffffc0201478:	bc472703          	lw	a4,-1084(a4) # ffffffffc0207038 <free_area+0x10>
ffffffffc020147c:	00006697          	auipc	a3,0x6
ffffffffc0201480:	bac68693          	addi	a3,a3,-1108 # ffffffffc0207028 <free_area>
    return list->next == list;
ffffffffc0201484:	669c                	ld	a5,8(a3)
ffffffffc0201486:	9f2d                	addw	a4,a4,a1
ffffffffc0201488:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020148a:	0ad78563          	beq	a5,a3,ffffffffc0201534 <default_free_pages+0x104>
            struct Page* page = le2page(le, page_link);
ffffffffc020148e:	fe878713          	addi	a4,a5,-24
ffffffffc0201492:	4581                	li	a1,0
ffffffffc0201494:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201498:	00e56a63          	bltu	a0,a4,ffffffffc02014ac <default_free_pages+0x7c>
    return listelm->next;
ffffffffc020149c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020149e:	06d70263          	beq	a4,a3,ffffffffc0201502 <default_free_pages+0xd2>
    struct Page *p = base;
ffffffffc02014a2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014a4:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02014a8:	fee57ae3          	bgeu	a0,a4,ffffffffc020149c <default_free_pages+0x6c>
ffffffffc02014ac:	c199                	beqz	a1,ffffffffc02014b2 <default_free_pages+0x82>
ffffffffc02014ae:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02014b2:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02014b4:	e390                	sd	a2,0(a5)
ffffffffc02014b6:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc02014b8:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02014ba:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc02014bc:	02d70063          	beq	a4,a3,ffffffffc02014dc <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc02014c0:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02014c4:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc02014c8:	02081613          	slli	a2,a6,0x20
ffffffffc02014cc:	9201                	srli	a2,a2,0x20
ffffffffc02014ce:	00261793          	slli	a5,a2,0x2
ffffffffc02014d2:	97b2                	add	a5,a5,a2
ffffffffc02014d4:	078e                	slli	a5,a5,0x3
ffffffffc02014d6:	97ae                	add	a5,a5,a1
ffffffffc02014d8:	02f50f63          	beq	a0,a5,ffffffffc0201516 <default_free_pages+0xe6>
    return listelm->next;
ffffffffc02014dc:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02014de:	00d70f63          	beq	a4,a3,ffffffffc02014fc <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02014e2:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02014e4:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02014e8:	02059613          	slli	a2,a1,0x20
ffffffffc02014ec:	9201                	srli	a2,a2,0x20
ffffffffc02014ee:	00261793          	slli	a5,a2,0x2
ffffffffc02014f2:	97b2                	add	a5,a5,a2
ffffffffc02014f4:	078e                	slli	a5,a5,0x3
ffffffffc02014f6:	97aa                	add	a5,a5,a0
ffffffffc02014f8:	04f68a63          	beq	a3,a5,ffffffffc020154c <default_free_pages+0x11c>
}
ffffffffc02014fc:	60a2                	ld	ra,8(sp)
ffffffffc02014fe:	0141                	addi	sp,sp,16
ffffffffc0201500:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201502:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201504:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201506:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201508:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020150a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020150c:	02d70d63          	beq	a4,a3,ffffffffc0201546 <default_free_pages+0x116>
ffffffffc0201510:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201512:	87ba                	mv	a5,a4
ffffffffc0201514:	bf41                	j	ffffffffc02014a4 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc0201516:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201518:	5675                	li	a2,-3
ffffffffc020151a:	010787bb          	addw	a5,a5,a6
ffffffffc020151e:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201522:	60c8b02f          	amoand.d	zero,a2,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201526:	6d10                	ld	a2,24(a0)
ffffffffc0201528:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc020152a:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020152c:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc020152e:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201530:	e390                	sd	a2,0(a5)
ffffffffc0201532:	b775                	j	ffffffffc02014de <default_free_pages+0xae>
}
ffffffffc0201534:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201536:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc020153a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020153c:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020153e:	e398                	sd	a4,0(a5)
ffffffffc0201540:	e798                	sd	a4,8(a5)
}
ffffffffc0201542:	0141                	addi	sp,sp,16
ffffffffc0201544:	8082                	ret
ffffffffc0201546:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201548:	873e                	mv	a4,a5
ffffffffc020154a:	bf8d                	j	ffffffffc02014bc <default_free_pages+0x8c>
            base->property += p->property;
ffffffffc020154c:	ff872783          	lw	a5,-8(a4)
ffffffffc0201550:	56f5                	li	a3,-3
ffffffffc0201552:	9fad                	addw	a5,a5,a1
ffffffffc0201554:	c91c                	sw	a5,16(a0)
ffffffffc0201556:	ff070793          	addi	a5,a4,-16
ffffffffc020155a:	60d7b02f          	amoand.d	zero,a3,(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020155e:	6314                	ld	a3,0(a4)
ffffffffc0201560:	671c                	ld	a5,8(a4)
}
ffffffffc0201562:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201564:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201566:	e394                	sd	a3,0(a5)
ffffffffc0201568:	0141                	addi	sp,sp,16
ffffffffc020156a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020156c:	00001697          	auipc	a3,0x1
ffffffffc0201570:	70c68693          	addi	a3,a3,1804 # ffffffffc0202c78 <etext+0xcf4>
ffffffffc0201574:	00001617          	auipc	a2,0x1
ffffffffc0201578:	3a460613          	addi	a2,a2,932 # ffffffffc0202918 <etext+0x994>
ffffffffc020157c:	08300593          	li	a1,131
ffffffffc0201580:	00001517          	auipc	a0,0x1
ffffffffc0201584:	3b050513          	addi	a0,a0,944 # ffffffffc0202930 <etext+0x9ac>
ffffffffc0201588:	e53fe0ef          	jal	ffffffffc02003da <__panic>
    assert(n > 0);
ffffffffc020158c:	00001697          	auipc	a3,0x1
ffffffffc0201590:	6e468693          	addi	a3,a3,1764 # ffffffffc0202c70 <etext+0xcec>
ffffffffc0201594:	00001617          	auipc	a2,0x1
ffffffffc0201598:	38460613          	addi	a2,a2,900 # ffffffffc0202918 <etext+0x994>
ffffffffc020159c:	08000593          	li	a1,128
ffffffffc02015a0:	00001517          	auipc	a0,0x1
ffffffffc02015a4:	39050513          	addi	a0,a0,912 # ffffffffc0202930 <etext+0x9ac>
ffffffffc02015a8:	e33fe0ef          	jal	ffffffffc02003da <__panic>

ffffffffc02015ac <default_alloc_pages>:
    assert(n > 0);
ffffffffc02015ac:	cd41                	beqz	a0,ffffffffc0201644 <default_alloc_pages+0x98>
    if (n > nr_free) {
ffffffffc02015ae:	00006597          	auipc	a1,0x6
ffffffffc02015b2:	a8a5a583          	lw	a1,-1398(a1) # ffffffffc0207038 <free_area+0x10>
ffffffffc02015b6:	86aa                	mv	a3,a0
ffffffffc02015b8:	02059793          	slli	a5,a1,0x20
ffffffffc02015bc:	9381                	srli	a5,a5,0x20
ffffffffc02015be:	00a7ef63          	bltu	a5,a0,ffffffffc02015dc <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc02015c2:	00006617          	auipc	a2,0x6
ffffffffc02015c6:	a6660613          	addi	a2,a2,-1434 # ffffffffc0207028 <free_area>
ffffffffc02015ca:	87b2                	mv	a5,a2
ffffffffc02015cc:	a029                	j	ffffffffc02015d6 <default_alloc_pages+0x2a>
        if (p->property >= n) {
ffffffffc02015ce:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02015d2:	00d77763          	bgeu	a4,a3,ffffffffc02015e0 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02015d6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02015d8:	fec79be3          	bne	a5,a2,ffffffffc02015ce <default_alloc_pages+0x22>
        return NULL;
ffffffffc02015dc:	4501                	li	a0,0
}
ffffffffc02015de:	8082                	ret
        if (page->property > n) {
ffffffffc02015e0:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02015e4:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015e8:	6798                	ld	a4,8(a5)
ffffffffc02015ea:	02089313          	slli	t1,a7,0x20
ffffffffc02015ee:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc02015f2:	00e83423          	sd	a4,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    next->prev = prev;
ffffffffc02015f6:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc02015fa:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc02015fe:	0266fc63          	bgeu	a3,t1,ffffffffc0201636 <default_alloc_pages+0x8a>
            struct Page *p = page + n;
ffffffffc0201602:	00269713          	slli	a4,a3,0x2
ffffffffc0201606:	9736                	add	a4,a4,a3
ffffffffc0201608:	070e                	slli	a4,a4,0x3
            p->property = page->property - n;
ffffffffc020160a:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc020160e:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201610:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201614:	00870313          	addi	t1,a4,8
ffffffffc0201618:	4889                	li	a7,2
ffffffffc020161a:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020161e:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc0201622:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc0201626:	0068b023          	sd	t1,0(a7)
ffffffffc020162a:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc020162e:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc0201632:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc0201636:	9d95                	subw	a1,a1,a3
ffffffffc0201638:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020163a:	5775                	li	a4,-3
ffffffffc020163c:	17c1                	addi	a5,a5,-16
ffffffffc020163e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201642:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201644:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201646:	00001697          	auipc	a3,0x1
ffffffffc020164a:	62a68693          	addi	a3,a3,1578 # ffffffffc0202c70 <etext+0xcec>
ffffffffc020164e:	00001617          	auipc	a2,0x1
ffffffffc0201652:	2ca60613          	addi	a2,a2,714 # ffffffffc0202918 <etext+0x994>
ffffffffc0201656:	06200593          	li	a1,98
ffffffffc020165a:	00001517          	auipc	a0,0x1
ffffffffc020165e:	2d650513          	addi	a0,a0,726 # ffffffffc0202930 <etext+0x9ac>
default_alloc_pages(size_t n) {
ffffffffc0201662:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201664:	d77fe0ef          	jal	ffffffffc02003da <__panic>

ffffffffc0201668 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201668:	1141                	addi	sp,sp,-16
ffffffffc020166a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020166c:	c9f1                	beqz	a1,ffffffffc0201740 <default_init_memmap+0xd8>
    for (; p != base + n; p ++) {
ffffffffc020166e:	00259713          	slli	a4,a1,0x2
ffffffffc0201672:	972e                	add	a4,a4,a1
ffffffffc0201674:	070e                	slli	a4,a4,0x3
ffffffffc0201676:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020167a:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020167c:	cf11                	beqz	a4,ffffffffc0201698 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020167e:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201680:	8b05                	andi	a4,a4,1
ffffffffc0201682:	cf59                	beqz	a4,ffffffffc0201720 <default_init_memmap+0xb8>
        p->flags = p->property = 0;
ffffffffc0201684:	0007a823          	sw	zero,16(a5)
ffffffffc0201688:	0007b423          	sd	zero,8(a5)
ffffffffc020168c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201690:	02878793          	addi	a5,a5,40
ffffffffc0201694:	fed795e3          	bne	a5,a3,ffffffffc020167e <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201698:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020169a:	4789                	li	a5,2
ffffffffc020169c:	00850713          	addi	a4,a0,8
ffffffffc02016a0:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02016a4:	00006717          	auipc	a4,0x6
ffffffffc02016a8:	99472703          	lw	a4,-1644(a4) # ffffffffc0207038 <free_area+0x10>
ffffffffc02016ac:	00006697          	auipc	a3,0x6
ffffffffc02016b0:	97c68693          	addi	a3,a3,-1668 # ffffffffc0207028 <free_area>
    return list->next == list;
ffffffffc02016b4:	669c                	ld	a5,8(a3)
ffffffffc02016b6:	9f2d                	addw	a4,a4,a1
ffffffffc02016b8:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02016ba:	04d78663          	beq	a5,a3,ffffffffc0201706 <default_init_memmap+0x9e>
            struct Page* page = le2page(le, page_link);
ffffffffc02016be:	fe878713          	addi	a4,a5,-24
ffffffffc02016c2:	4581                	li	a1,0
ffffffffc02016c4:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02016c8:	00e56a63          	bltu	a0,a4,ffffffffc02016dc <default_init_memmap+0x74>
    return listelm->next;
ffffffffc02016cc:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02016ce:	02d70263          	beq	a4,a3,ffffffffc02016f2 <default_init_memmap+0x8a>
    struct Page *p = base;
ffffffffc02016d2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016d4:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016d8:	fee57ae3          	bgeu	a0,a4,ffffffffc02016cc <default_init_memmap+0x64>
ffffffffc02016dc:	c199                	beqz	a1,ffffffffc02016e2 <default_init_memmap+0x7a>
ffffffffc02016de:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016e2:	6398                	ld	a4,0(a5)
}
ffffffffc02016e4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02016e6:	e390                	sd	a2,0(a5)
ffffffffc02016e8:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02016ea:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02016ec:	f11c                	sd	a5,32(a0)
ffffffffc02016ee:	0141                	addi	sp,sp,16
ffffffffc02016f0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016f2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016f4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02016f6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02016f8:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02016fa:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016fc:	00d70e63          	beq	a4,a3,ffffffffc0201718 <default_init_memmap+0xb0>
ffffffffc0201700:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201702:	87ba                	mv	a5,a4
ffffffffc0201704:	bfc1                	j	ffffffffc02016d4 <default_init_memmap+0x6c>
}
ffffffffc0201706:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201708:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc020170c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020170e:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201710:	e398                	sd	a4,0(a5)
ffffffffc0201712:	e798                	sd	a4,8(a5)
}
ffffffffc0201714:	0141                	addi	sp,sp,16
ffffffffc0201716:	8082                	ret
ffffffffc0201718:	60a2                	ld	ra,8(sp)
ffffffffc020171a:	e290                	sd	a2,0(a3)
ffffffffc020171c:	0141                	addi	sp,sp,16
ffffffffc020171e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201720:	00001697          	auipc	a3,0x1
ffffffffc0201724:	58068693          	addi	a3,a3,1408 # ffffffffc0202ca0 <etext+0xd1c>
ffffffffc0201728:	00001617          	auipc	a2,0x1
ffffffffc020172c:	1f060613          	addi	a2,a2,496 # ffffffffc0202918 <etext+0x994>
ffffffffc0201730:	04900593          	li	a1,73
ffffffffc0201734:	00001517          	auipc	a0,0x1
ffffffffc0201738:	1fc50513          	addi	a0,a0,508 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020173c:	c9ffe0ef          	jal	ffffffffc02003da <__panic>
    assert(n > 0);
ffffffffc0201740:	00001697          	auipc	a3,0x1
ffffffffc0201744:	53068693          	addi	a3,a3,1328 # ffffffffc0202c70 <etext+0xcec>
ffffffffc0201748:	00001617          	auipc	a2,0x1
ffffffffc020174c:	1d060613          	addi	a2,a2,464 # ffffffffc0202918 <etext+0x994>
ffffffffc0201750:	04600593          	li	a1,70
ffffffffc0201754:	00001517          	auipc	a0,0x1
ffffffffc0201758:	1dc50513          	addi	a0,a0,476 # ffffffffc0202930 <etext+0x9ac>
ffffffffc020175c:	c7ffe0ef          	jal	ffffffffc02003da <__panic>

ffffffffc0201760 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201760:	100027f3          	csrr	a5,sstatus
ffffffffc0201764:	8b89                	andi	a5,a5,2
ffffffffc0201766:	e799                	bnez	a5,ffffffffc0201774 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201768:	00006797          	auipc	a5,0x6
ffffffffc020176c:	d007b783          	ld	a5,-768(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc0201770:	6f9c                	ld	a5,24(a5)
ffffffffc0201772:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201774:	1101                	addi	sp,sp,-32
ffffffffc0201776:	ec06                	sd	ra,24(sp)
ffffffffc0201778:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020177a:	85aff0ef          	jal	ffffffffc02007d4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020177e:	00006797          	auipc	a5,0x6
ffffffffc0201782:	cea7b783          	ld	a5,-790(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc0201786:	6522                	ld	a0,8(sp)
ffffffffc0201788:	6f9c                	ld	a5,24(a5)
ffffffffc020178a:	9782                	jalr	a5
ffffffffc020178c:	e42a                	sd	a0,8(sp)
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020178e:	840ff0ef          	jal	ffffffffc02007ce <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201792:	60e2                	ld	ra,24(sp)
ffffffffc0201794:	6522                	ld	a0,8(sp)
ffffffffc0201796:	6105                	addi	sp,sp,32
ffffffffc0201798:	8082                	ret

ffffffffc020179a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020179a:	100027f3          	csrr	a5,sstatus
ffffffffc020179e:	8b89                	andi	a5,a5,2
ffffffffc02017a0:	e799                	bnez	a5,ffffffffc02017ae <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02017a2:	00006797          	auipc	a5,0x6
ffffffffc02017a6:	cc67b783          	ld	a5,-826(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc02017aa:	739c                	ld	a5,32(a5)
ffffffffc02017ac:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02017ae:	1101                	addi	sp,sp,-32
ffffffffc02017b0:	ec06                	sd	ra,24(sp)
ffffffffc02017b2:	e42e                	sd	a1,8(sp)
ffffffffc02017b4:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02017b6:	81eff0ef          	jal	ffffffffc02007d4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02017ba:	00006797          	auipc	a5,0x6
ffffffffc02017be:	cae7b783          	ld	a5,-850(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc02017c2:	65a2                	ld	a1,8(sp)
ffffffffc02017c4:	6502                	ld	a0,0(sp)
ffffffffc02017c6:	739c                	ld	a5,32(a5)
ffffffffc02017c8:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02017ca:	60e2                	ld	ra,24(sp)
ffffffffc02017cc:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02017ce:	800ff06f          	j	ffffffffc02007ce <intr_enable>

ffffffffc02017d2 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017d2:	100027f3          	csrr	a5,sstatus
ffffffffc02017d6:	8b89                	andi	a5,a5,2
ffffffffc02017d8:	e799                	bnez	a5,ffffffffc02017e6 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02017da:	00006797          	auipc	a5,0x6
ffffffffc02017de:	c8e7b783          	ld	a5,-882(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc02017e2:	779c                	ld	a5,40(a5)
ffffffffc02017e4:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02017e6:	1101                	addi	sp,sp,-32
ffffffffc02017e8:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02017ea:	febfe0ef          	jal	ffffffffc02007d4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02017ee:	00006797          	auipc	a5,0x6
ffffffffc02017f2:	c7a7b783          	ld	a5,-902(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc02017f6:	779c                	ld	a5,40(a5)
ffffffffc02017f8:	9782                	jalr	a5
ffffffffc02017fa:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02017fc:	fd3fe0ef          	jal	ffffffffc02007ce <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201800:	60e2                	ld	ra,24(sp)
ffffffffc0201802:	6522                	ld	a0,8(sp)
ffffffffc0201804:	6105                	addi	sp,sp,32
ffffffffc0201806:	8082                	ret

ffffffffc0201808 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201808:	00001797          	auipc	a5,0x1
ffffffffc020180c:	75878793          	addi	a5,a5,1880 # ffffffffc0202f60 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201810:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201812:	7139                	addi	sp,sp,-64
ffffffffc0201814:	fc06                	sd	ra,56(sp)
ffffffffc0201816:	f822                	sd	s0,48(sp)
ffffffffc0201818:	f426                	sd	s1,40(sp)
ffffffffc020181a:	ec4e                	sd	s3,24(sp)
ffffffffc020181c:	f04a                	sd	s2,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020181e:	00006417          	auipc	s0,0x6
ffffffffc0201822:	c4a40413          	addi	s0,s0,-950 # ffffffffc0207468 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201826:	00001517          	auipc	a0,0x1
ffffffffc020182a:	4a250513          	addi	a0,a0,1186 # ffffffffc0202cc8 <etext+0xd44>
    pmm_manager = &default_pmm_manager;
ffffffffc020182e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201830:	8f9fe0ef          	jal	ffffffffc0200128 <cprintf>
    pmm_manager->init();
ffffffffc0201834:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201836:	00006497          	auipc	s1,0x6
ffffffffc020183a:	c4a48493          	addi	s1,s1,-950 # ffffffffc0207480 <va_pa_offset>
    pmm_manager->init();
ffffffffc020183e:	679c                	ld	a5,8(a5)
ffffffffc0201840:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201842:	57f5                	li	a5,-3
ffffffffc0201844:	07fa                	slli	a5,a5,0x1e
ffffffffc0201846:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201848:	f73fe0ef          	jal	ffffffffc02007ba <get_memory_base>
ffffffffc020184c:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020184e:	f77fe0ef          	jal	ffffffffc02007c4 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201852:	16050063          	beqz	a0,ffffffffc02019b2 <pmm_init+0x1aa>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201856:	00a98933          	add	s2,s3,a0
ffffffffc020185a:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc020185c:	00001517          	auipc	a0,0x1
ffffffffc0201860:	4b450513          	addi	a0,a0,1204 # ffffffffc0202d10 <etext+0xd8c>
ffffffffc0201864:	8c5fe0ef          	jal	ffffffffc0200128 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201868:	65a2                	ld	a1,8(sp)
ffffffffc020186a:	864e                	mv	a2,s3
ffffffffc020186c:	fff90693          	addi	a3,s2,-1
ffffffffc0201870:	00001517          	auipc	a0,0x1
ffffffffc0201874:	4b850513          	addi	a0,a0,1208 # ffffffffc0202d28 <etext+0xda4>
ffffffffc0201878:	8b1fe0ef          	jal	ffffffffc0200128 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc020187c:	c80007b7          	lui	a5,0xc8000
ffffffffc0201880:	864a                	mv	a2,s2
ffffffffc0201882:	0d27e563          	bltu	a5,s2,ffffffffc020194c <pmm_init+0x144>
ffffffffc0201886:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201888:	00007697          	auipc	a3,0x7
ffffffffc020188c:	c1768693          	addi	a3,a3,-1001 # ffffffffc020849f <end+0xfff>
ffffffffc0201890:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc0201892:	8231                	srli	a2,a2,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201894:	00006817          	auipc	a6,0x6
ffffffffc0201898:	bfc80813          	addi	a6,a6,-1028 # ffffffffc0207490 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020189c:	00006517          	auipc	a0,0x6
ffffffffc02018a0:	bec50513          	addi	a0,a0,-1044 # ffffffffc0207488 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018a4:	00d83023          	sd	a3,0(a6)
    npage = maxpa / PGSIZE;
ffffffffc02018a8:	e110                	sd	a2,0(a0)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018aa:	00080737          	lui	a4,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018ae:	87b6                	mv	a5,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018b0:	02e60a63          	beq	a2,a4,ffffffffc02018e4 <pmm_init+0xdc>
ffffffffc02018b4:	4701                	li	a4,0
ffffffffc02018b6:	4781                	li	a5,0
ffffffffc02018b8:	4305                	li	t1,1
ffffffffc02018ba:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc02018be:	96ba                	add	a3,a3,a4
ffffffffc02018c0:	06a1                	addi	a3,a3,8
ffffffffc02018c2:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018c6:	6110                	ld	a2,0(a0)
ffffffffc02018c8:	0785                	addi	a5,a5,1 # fffffffffffff001 <end+0x3fdf7b61>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018ca:	00083683          	ld	a3,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018ce:	011605b3          	add	a1,a2,a7
ffffffffc02018d2:	02870713          	addi	a4,a4,40 # 80028 <kern_entry-0xffffffffc017ffd8>
ffffffffc02018d6:	feb7e4e3          	bltu	a5,a1,ffffffffc02018be <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018da:	00259793          	slli	a5,a1,0x2
ffffffffc02018de:	97ae                	add	a5,a5,a1
ffffffffc02018e0:	078e                	slli	a5,a5,0x3
ffffffffc02018e2:	97b6                	add	a5,a5,a3
ffffffffc02018e4:	c0200737          	lui	a4,0xc0200
ffffffffc02018e8:	0ae7e863          	bltu	a5,a4,ffffffffc0201998 <pmm_init+0x190>
ffffffffc02018ec:	608c                	ld	a1,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02018ee:	777d                	lui	a4,0xfffff
ffffffffc02018f0:	00e97933          	and	s2,s2,a4
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018f4:	8f8d                	sub	a5,a5,a1
    if (freemem < mem_end) {
ffffffffc02018f6:	0527ed63          	bltu	a5,s2,ffffffffc0201950 <pmm_init+0x148>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02018fa:	601c                	ld	a5,0(s0)
ffffffffc02018fc:	7b9c                	ld	a5,48(a5)
ffffffffc02018fe:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201900:	00001517          	auipc	a0,0x1
ffffffffc0201904:	4b050513          	addi	a0,a0,1200 # ffffffffc0202db0 <etext+0xe2c>
ffffffffc0201908:	821fe0ef          	jal	ffffffffc0200128 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020190c:	00004597          	auipc	a1,0x4
ffffffffc0201910:	6f458593          	addi	a1,a1,1780 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201914:	00006797          	auipc	a5,0x6
ffffffffc0201918:	b6b7b223          	sd	a1,-1180(a5) # ffffffffc0207478 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020191c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201920:	0af5e563          	bltu	a1,a5,ffffffffc02019ca <pmm_init+0x1c2>
ffffffffc0201924:	609c                	ld	a5,0(s1)
}
ffffffffc0201926:	7442                	ld	s0,48(sp)
ffffffffc0201928:	70e2                	ld	ra,56(sp)
ffffffffc020192a:	74a2                	ld	s1,40(sp)
ffffffffc020192c:	7902                	ld	s2,32(sp)
ffffffffc020192e:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201930:	40f586b3          	sub	a3,a1,a5
ffffffffc0201934:	00006797          	auipc	a5,0x6
ffffffffc0201938:	b2d7be23          	sd	a3,-1220(a5) # ffffffffc0207470 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020193c:	00001517          	auipc	a0,0x1
ffffffffc0201940:	49450513          	addi	a0,a0,1172 # ffffffffc0202dd0 <etext+0xe4c>
ffffffffc0201944:	8636                	mv	a2,a3
}
ffffffffc0201946:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201948:	fe0fe06f          	j	ffffffffc0200128 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc020194c:	863e                	mv	a2,a5
ffffffffc020194e:	bf25                	j	ffffffffc0201886 <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201950:	6585                	lui	a1,0x1
ffffffffc0201952:	15fd                	addi	a1,a1,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201954:	97ae                	add	a5,a5,a1
ffffffffc0201956:	8ff9                	and	a5,a5,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201958:	00c7d713          	srli	a4,a5,0xc
ffffffffc020195c:	02c77263          	bgeu	a4,a2,ffffffffc0201980 <pmm_init+0x178>
    pmm_manager->init_memmap(base, n);
ffffffffc0201960:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201962:	fff805b7          	lui	a1,0xfff80
ffffffffc0201966:	972e                	add	a4,a4,a1
ffffffffc0201968:	00271513          	slli	a0,a4,0x2
ffffffffc020196c:	953a                	add	a0,a0,a4
ffffffffc020196e:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201970:	40f90933          	sub	s2,s2,a5
ffffffffc0201974:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201976:	00c95593          	srli	a1,s2,0xc
ffffffffc020197a:	9536                	add	a0,a0,a3
ffffffffc020197c:	9702                	jalr	a4
}
ffffffffc020197e:	bfb5                	j	ffffffffc02018fa <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0201980:	00001617          	auipc	a2,0x1
ffffffffc0201984:	40060613          	addi	a2,a2,1024 # ffffffffc0202d80 <etext+0xdfc>
ffffffffc0201988:	06b00593          	li	a1,107
ffffffffc020198c:	00001517          	auipc	a0,0x1
ffffffffc0201990:	41450513          	addi	a0,a0,1044 # ffffffffc0202da0 <etext+0xe1c>
ffffffffc0201994:	a47fe0ef          	jal	ffffffffc02003da <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201998:	86be                	mv	a3,a5
ffffffffc020199a:	00001617          	auipc	a2,0x1
ffffffffc020199e:	3be60613          	addi	a2,a2,958 # ffffffffc0202d58 <etext+0xdd4>
ffffffffc02019a2:	07100593          	li	a1,113
ffffffffc02019a6:	00001517          	auipc	a0,0x1
ffffffffc02019aa:	35a50513          	addi	a0,a0,858 # ffffffffc0202d00 <etext+0xd7c>
ffffffffc02019ae:	a2dfe0ef          	jal	ffffffffc02003da <__panic>
        panic("DTB memory info not available");
ffffffffc02019b2:	00001617          	auipc	a2,0x1
ffffffffc02019b6:	32e60613          	addi	a2,a2,814 # ffffffffc0202ce0 <etext+0xd5c>
ffffffffc02019ba:	05a00593          	li	a1,90
ffffffffc02019be:	00001517          	auipc	a0,0x1
ffffffffc02019c2:	34250513          	addi	a0,a0,834 # ffffffffc0202d00 <etext+0xd7c>
ffffffffc02019c6:	a15fe0ef          	jal	ffffffffc02003da <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02019ca:	86ae                	mv	a3,a1
ffffffffc02019cc:	00001617          	auipc	a2,0x1
ffffffffc02019d0:	38c60613          	addi	a2,a2,908 # ffffffffc0202d58 <etext+0xdd4>
ffffffffc02019d4:	08c00593          	li	a1,140
ffffffffc02019d8:	00001517          	auipc	a0,0x1
ffffffffc02019dc:	32850513          	addi	a0,a0,808 # ffffffffc0202d00 <etext+0xd7c>
ffffffffc02019e0:	9fbfe0ef          	jal	ffffffffc02003da <__panic>

ffffffffc02019e4 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019e4:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02019e6:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019ea:	f022                	sd	s0,32(sp)
ffffffffc02019ec:	ec26                	sd	s1,24(sp)
ffffffffc02019ee:	e84a                	sd	s2,16(sp)
ffffffffc02019f0:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02019f2:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019f6:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02019f8:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02019fc:	fff7041b          	addiw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf7b5f>
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a00:	84aa                	mv	s1,a0
ffffffffc0201a02:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0201a04:	03067d63          	bgeu	a2,a6,ffffffffc0201a3e <printnum+0x5a>
ffffffffc0201a08:	e44e                	sd	s3,8(sp)
ffffffffc0201a0a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a0c:	4785                	li	a5,1
ffffffffc0201a0e:	00e7d763          	bge	a5,a4,ffffffffc0201a1c <printnum+0x38>
            putch(padc, putdat);
ffffffffc0201a12:	85ca                	mv	a1,s2
ffffffffc0201a14:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201a16:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a18:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a1a:	fc65                	bnez	s0,ffffffffc0201a12 <printnum+0x2e>
ffffffffc0201a1c:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a1e:	00001797          	auipc	a5,0x1
ffffffffc0201a22:	3f278793          	addi	a5,a5,1010 # ffffffffc0202e10 <etext+0xe8c>
ffffffffc0201a26:	97d2                	add	a5,a5,s4
}
ffffffffc0201a28:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a2a:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201a2e:	70a2                	ld	ra,40(sp)
ffffffffc0201a30:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a32:	85ca                	mv	a1,s2
ffffffffc0201a34:	87a6                	mv	a5,s1
}
ffffffffc0201a36:	6942                	ld	s2,16(sp)
ffffffffc0201a38:	64e2                	ld	s1,24(sp)
ffffffffc0201a3a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a3c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a3e:	03065633          	divu	a2,a2,a6
ffffffffc0201a42:	8722                	mv	a4,s0
ffffffffc0201a44:	fa1ff0ef          	jal	ffffffffc02019e4 <printnum>
ffffffffc0201a48:	bfd9                	j	ffffffffc0201a1e <printnum+0x3a>

ffffffffc0201a4a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a4a:	7119                	addi	sp,sp,-128
ffffffffc0201a4c:	f4a6                	sd	s1,104(sp)
ffffffffc0201a4e:	f0ca                	sd	s2,96(sp)
ffffffffc0201a50:	ecce                	sd	s3,88(sp)
ffffffffc0201a52:	e8d2                	sd	s4,80(sp)
ffffffffc0201a54:	e4d6                	sd	s5,72(sp)
ffffffffc0201a56:	e0da                	sd	s6,64(sp)
ffffffffc0201a58:	f862                	sd	s8,48(sp)
ffffffffc0201a5a:	fc86                	sd	ra,120(sp)
ffffffffc0201a5c:	f8a2                	sd	s0,112(sp)
ffffffffc0201a5e:	fc5e                	sd	s7,56(sp)
ffffffffc0201a60:	f466                	sd	s9,40(sp)
ffffffffc0201a62:	f06a                	sd	s10,32(sp)
ffffffffc0201a64:	ec6e                	sd	s11,24(sp)
ffffffffc0201a66:	84aa                	mv	s1,a0
ffffffffc0201a68:	8c32                	mv	s8,a2
ffffffffc0201a6a:	8a36                	mv	s4,a3
ffffffffc0201a6c:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a6e:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a72:	05500b13          	li	s6,85
ffffffffc0201a76:	00001a97          	auipc	s5,0x1
ffffffffc0201a7a:	522a8a93          	addi	s5,s5,1314 # ffffffffc0202f98 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a7e:	000c4503          	lbu	a0,0(s8)
ffffffffc0201a82:	001c0413          	addi	s0,s8,1
ffffffffc0201a86:	01350a63          	beq	a0,s3,ffffffffc0201a9a <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201a8a:	cd0d                	beqz	a0,ffffffffc0201ac4 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201a8c:	85ca                	mv	a1,s2
ffffffffc0201a8e:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a90:	00044503          	lbu	a0,0(s0)
ffffffffc0201a94:	0405                	addi	s0,s0,1
ffffffffc0201a96:	ff351ae3          	bne	a0,s3,ffffffffc0201a8a <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0201a9a:	5cfd                	li	s9,-1
ffffffffc0201a9c:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0201a9e:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201aa2:	4b81                	li	s7,0
ffffffffc0201aa4:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aa6:	00044683          	lbu	a3,0(s0)
ffffffffc0201aaa:	00140c13          	addi	s8,s0,1
ffffffffc0201aae:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201ab2:	0ff5f593          	zext.b	a1,a1
ffffffffc0201ab6:	02bb6663          	bltu	s6,a1,ffffffffc0201ae2 <vprintfmt+0x98>
ffffffffc0201aba:	058a                	slli	a1,a1,0x2
ffffffffc0201abc:	95d6                	add	a1,a1,s5
ffffffffc0201abe:	4198                	lw	a4,0(a1)
ffffffffc0201ac0:	9756                	add	a4,a4,s5
ffffffffc0201ac2:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201ac4:	70e6                	ld	ra,120(sp)
ffffffffc0201ac6:	7446                	ld	s0,112(sp)
ffffffffc0201ac8:	74a6                	ld	s1,104(sp)
ffffffffc0201aca:	7906                	ld	s2,96(sp)
ffffffffc0201acc:	69e6                	ld	s3,88(sp)
ffffffffc0201ace:	6a46                	ld	s4,80(sp)
ffffffffc0201ad0:	6aa6                	ld	s5,72(sp)
ffffffffc0201ad2:	6b06                	ld	s6,64(sp)
ffffffffc0201ad4:	7be2                	ld	s7,56(sp)
ffffffffc0201ad6:	7c42                	ld	s8,48(sp)
ffffffffc0201ad8:	7ca2                	ld	s9,40(sp)
ffffffffc0201ada:	7d02                	ld	s10,32(sp)
ffffffffc0201adc:	6de2                	ld	s11,24(sp)
ffffffffc0201ade:	6109                	addi	sp,sp,128
ffffffffc0201ae0:	8082                	ret
            putch('%', putdat);
ffffffffc0201ae2:	85ca                	mv	a1,s2
ffffffffc0201ae4:	02500513          	li	a0,37
ffffffffc0201ae8:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201aea:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201aee:	02500713          	li	a4,37
ffffffffc0201af2:	8c22                	mv	s8,s0
ffffffffc0201af4:	f8e785e3          	beq	a5,a4,ffffffffc0201a7e <vprintfmt+0x34>
ffffffffc0201af8:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201afc:	1c7d                	addi	s8,s8,-1
ffffffffc0201afe:	fee79de3          	bne	a5,a4,ffffffffc0201af8 <vprintfmt+0xae>
ffffffffc0201b02:	bfb5                	j	ffffffffc0201a7e <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0201b04:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201b08:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0201b0a:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201b0e:	fd06071b          	addiw	a4,a2,-48
ffffffffc0201b12:	24e56a63          	bltu	a0,a4,ffffffffc0201d66 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0201b16:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b18:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0201b1a:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0201b1e:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b22:	0197073b          	addw	a4,a4,s9
ffffffffc0201b26:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b2a:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b2c:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b30:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b32:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201b36:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201b3a:	feb570e3          	bgeu	a0,a1,ffffffffc0201b1a <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0201b3e:	f60d54e3          	bgez	s10,ffffffffc0201aa6 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201b42:	8d66                	mv	s10,s9
ffffffffc0201b44:	5cfd                	li	s9,-1
ffffffffc0201b46:	b785                	j	ffffffffc0201aa6 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b48:	8db6                	mv	s11,a3
ffffffffc0201b4a:	8462                	mv	s0,s8
ffffffffc0201b4c:	bfa9                	j	ffffffffc0201aa6 <vprintfmt+0x5c>
ffffffffc0201b4e:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201b50:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201b52:	bf91                	j	ffffffffc0201aa6 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201b54:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b56:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b5a:	00f74463          	blt	a4,a5,ffffffffc0201b62 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0201b5e:	1a078763          	beqz	a5,ffffffffc0201d0c <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0201b62:	000a3603          	ld	a2,0(s4)
ffffffffc0201b66:	46c1                	li	a3,16
ffffffffc0201b68:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b6a:	000d879b          	sext.w	a5,s11
ffffffffc0201b6e:	876a                	mv	a4,s10
ffffffffc0201b70:	85ca                	mv	a1,s2
ffffffffc0201b72:	8526                	mv	a0,s1
ffffffffc0201b74:	e71ff0ef          	jal	ffffffffc02019e4 <printnum>
            break;
ffffffffc0201b78:	b719                	j	ffffffffc0201a7e <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b7a:	000a2503          	lw	a0,0(s4)
ffffffffc0201b7e:	85ca                	mv	a1,s2
ffffffffc0201b80:	0a21                	addi	s4,s4,8
ffffffffc0201b82:	9482                	jalr	s1
            break;
ffffffffc0201b84:	bded                	j	ffffffffc0201a7e <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201b86:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b88:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b8c:	00f74463          	blt	a4,a5,ffffffffc0201b94 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201b90:	16078963          	beqz	a5,ffffffffc0201d02 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0201b94:	000a3603          	ld	a2,0(s4)
ffffffffc0201b98:	46a9                	li	a3,10
ffffffffc0201b9a:	8a2e                	mv	s4,a1
ffffffffc0201b9c:	b7f9                	j	ffffffffc0201b6a <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0201b9e:	85ca                	mv	a1,s2
ffffffffc0201ba0:	03000513          	li	a0,48
ffffffffc0201ba4:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0201ba6:	85ca                	mv	a1,s2
ffffffffc0201ba8:	07800513          	li	a0,120
ffffffffc0201bac:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bae:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201bb2:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bb4:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201bb6:	bf55                	j	ffffffffc0201b6a <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0201bb8:	85ca                	mv	a1,s2
ffffffffc0201bba:	02500513          	li	a0,37
ffffffffc0201bbe:	9482                	jalr	s1
            break;
ffffffffc0201bc0:	bd7d                	j	ffffffffc0201a7e <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201bc2:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bc6:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201bc8:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201bca:	bf95                	j	ffffffffc0201b3e <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0201bcc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bce:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bd2:	00f74463          	blt	a4,a5,ffffffffc0201bda <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0201bd6:	12078163          	beqz	a5,ffffffffc0201cf8 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0201bda:	000a3603          	ld	a2,0(s4)
ffffffffc0201bde:	46a1                	li	a3,8
ffffffffc0201be0:	8a2e                	mv	s4,a1
ffffffffc0201be2:	b761                	j	ffffffffc0201b6a <vprintfmt+0x120>
            if (width < 0)
ffffffffc0201be4:	876a                	mv	a4,s10
ffffffffc0201be6:	000d5363          	bgez	s10,ffffffffc0201bec <vprintfmt+0x1a2>
ffffffffc0201bea:	4701                	li	a4,0
ffffffffc0201bec:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bf0:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201bf2:	bd55                	j	ffffffffc0201aa6 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0201bf4:	000d841b          	sext.w	s0,s11
ffffffffc0201bf8:	fd340793          	addi	a5,s0,-45
ffffffffc0201bfc:	00f037b3          	snez	a5,a5
ffffffffc0201c00:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c04:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0201c08:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c0a:	008a0793          	addi	a5,s4,8
ffffffffc0201c0e:	e43e                	sd	a5,8(sp)
ffffffffc0201c10:	100d8c63          	beqz	s11,ffffffffc0201d28 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201c14:	12071363          	bnez	a4,ffffffffc0201d3a <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c18:	000dc783          	lbu	a5,0(s11)
ffffffffc0201c1c:	0007851b          	sext.w	a0,a5
ffffffffc0201c20:	c78d                	beqz	a5,ffffffffc0201c4a <vprintfmt+0x200>
ffffffffc0201c22:	0d85                	addi	s11,s11,1
ffffffffc0201c24:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c26:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c2a:	000cc563          	bltz	s9,ffffffffc0201c34 <vprintfmt+0x1ea>
ffffffffc0201c2e:	3cfd                	addiw	s9,s9,-1
ffffffffc0201c30:	008c8d63          	beq	s9,s0,ffffffffc0201c4a <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c34:	020b9663          	bnez	s7,ffffffffc0201c60 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0201c38:	85ca                	mv	a1,s2
ffffffffc0201c3a:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c3c:	000dc783          	lbu	a5,0(s11)
ffffffffc0201c40:	0d85                	addi	s11,s11,1
ffffffffc0201c42:	3d7d                	addiw	s10,s10,-1
ffffffffc0201c44:	0007851b          	sext.w	a0,a5
ffffffffc0201c48:	f3ed                	bnez	a5,ffffffffc0201c2a <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0201c4a:	01a05963          	blez	s10,ffffffffc0201c5c <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0201c4e:	85ca                	mv	a1,s2
ffffffffc0201c50:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201c54:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0201c56:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0201c58:	fe0d1be3          	bnez	s10,ffffffffc0201c4e <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c5c:	6a22                	ld	s4,8(sp)
ffffffffc0201c5e:	b505                	j	ffffffffc0201a7e <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c60:	3781                	addiw	a5,a5,-32
ffffffffc0201c62:	fcfa7be3          	bgeu	s4,a5,ffffffffc0201c38 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0201c66:	03f00513          	li	a0,63
ffffffffc0201c6a:	85ca                	mv	a1,s2
ffffffffc0201c6c:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c6e:	000dc783          	lbu	a5,0(s11)
ffffffffc0201c72:	0d85                	addi	s11,s11,1
ffffffffc0201c74:	3d7d                	addiw	s10,s10,-1
ffffffffc0201c76:	0007851b          	sext.w	a0,a5
ffffffffc0201c7a:	dbe1                	beqz	a5,ffffffffc0201c4a <vprintfmt+0x200>
ffffffffc0201c7c:	fa0cd9e3          	bgez	s9,ffffffffc0201c2e <vprintfmt+0x1e4>
ffffffffc0201c80:	b7c5                	j	ffffffffc0201c60 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0201c82:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c86:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0201c88:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c8a:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201c8e:	8fb9                	xor	a5,a5,a4
ffffffffc0201c90:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c94:	02d64563          	blt	a2,a3,ffffffffc0201cbe <vprintfmt+0x274>
ffffffffc0201c98:	00001797          	auipc	a5,0x1
ffffffffc0201c9c:	45878793          	addi	a5,a5,1112 # ffffffffc02030f0 <error_string>
ffffffffc0201ca0:	00369713          	slli	a4,a3,0x3
ffffffffc0201ca4:	97ba                	add	a5,a5,a4
ffffffffc0201ca6:	639c                	ld	a5,0(a5)
ffffffffc0201ca8:	cb99                	beqz	a5,ffffffffc0201cbe <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201caa:	86be                	mv	a3,a5
ffffffffc0201cac:	00001617          	auipc	a2,0x1
ffffffffc0201cb0:	19460613          	addi	a2,a2,404 # ffffffffc0202e40 <etext+0xebc>
ffffffffc0201cb4:	85ca                	mv	a1,s2
ffffffffc0201cb6:	8526                	mv	a0,s1
ffffffffc0201cb8:	0d8000ef          	jal	ffffffffc0201d90 <printfmt>
ffffffffc0201cbc:	b3c9                	j	ffffffffc0201a7e <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201cbe:	00001617          	auipc	a2,0x1
ffffffffc0201cc2:	17260613          	addi	a2,a2,370 # ffffffffc0202e30 <etext+0xeac>
ffffffffc0201cc6:	85ca                	mv	a1,s2
ffffffffc0201cc8:	8526                	mv	a0,s1
ffffffffc0201cca:	0c6000ef          	jal	ffffffffc0201d90 <printfmt>
ffffffffc0201cce:	bb45                	j	ffffffffc0201a7e <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201cd0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201cd2:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201cd6:	00f74363          	blt	a4,a5,ffffffffc0201cdc <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0201cda:	cf81                	beqz	a5,ffffffffc0201cf2 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0201cdc:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201ce0:	02044b63          	bltz	s0,ffffffffc0201d16 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201ce4:	8622                	mv	a2,s0
ffffffffc0201ce6:	8a5e                	mv	s4,s7
ffffffffc0201ce8:	46a9                	li	a3,10
ffffffffc0201cea:	b541                	j	ffffffffc0201b6a <vprintfmt+0x120>
            lflag ++;
ffffffffc0201cec:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cee:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201cf0:	bb5d                	j	ffffffffc0201aa6 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0201cf2:	000a2403          	lw	s0,0(s4)
ffffffffc0201cf6:	b7ed                	j	ffffffffc0201ce0 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0201cf8:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cfc:	46a1                	li	a3,8
ffffffffc0201cfe:	8a2e                	mv	s4,a1
ffffffffc0201d00:	b5ad                	j	ffffffffc0201b6a <vprintfmt+0x120>
ffffffffc0201d02:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d06:	46a9                	li	a3,10
ffffffffc0201d08:	8a2e                	mv	s4,a1
ffffffffc0201d0a:	b585                	j	ffffffffc0201b6a <vprintfmt+0x120>
ffffffffc0201d0c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d10:	46c1                	li	a3,16
ffffffffc0201d12:	8a2e                	mv	s4,a1
ffffffffc0201d14:	bd99                	j	ffffffffc0201b6a <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0201d16:	85ca                	mv	a1,s2
ffffffffc0201d18:	02d00513          	li	a0,45
ffffffffc0201d1c:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0201d1e:	40800633          	neg	a2,s0
ffffffffc0201d22:	8a5e                	mv	s4,s7
ffffffffc0201d24:	46a9                	li	a3,10
ffffffffc0201d26:	b591                	j	ffffffffc0201b6a <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0201d28:	e329                	bnez	a4,ffffffffc0201d6a <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d2a:	02800793          	li	a5,40
ffffffffc0201d2e:	853e                	mv	a0,a5
ffffffffc0201d30:	00001d97          	auipc	s11,0x1
ffffffffc0201d34:	0f9d8d93          	addi	s11,s11,249 # ffffffffc0202e29 <etext+0xea5>
ffffffffc0201d38:	b5f5                	j	ffffffffc0201c24 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d3a:	85e6                	mv	a1,s9
ffffffffc0201d3c:	856e                	mv	a0,s11
ffffffffc0201d3e:	1aa000ef          	jal	ffffffffc0201ee8 <strnlen>
ffffffffc0201d42:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201d46:	01a05863          	blez	s10,ffffffffc0201d56 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0201d4a:	85ca                	mv	a1,s2
ffffffffc0201d4c:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d4e:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0201d50:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d52:	fe0d1ce3          	bnez	s10,ffffffffc0201d4a <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d56:	000dc783          	lbu	a5,0(s11)
ffffffffc0201d5a:	0007851b          	sext.w	a0,a5
ffffffffc0201d5e:	ec0792e3          	bnez	a5,ffffffffc0201c22 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d62:	6a22                	ld	s4,8(sp)
ffffffffc0201d64:	bb29                	j	ffffffffc0201a7e <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d66:	8462                	mv	s0,s8
ffffffffc0201d68:	bbd9                	j	ffffffffc0201b3e <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d6a:	85e6                	mv	a1,s9
ffffffffc0201d6c:	00001517          	auipc	a0,0x1
ffffffffc0201d70:	0bc50513          	addi	a0,a0,188 # ffffffffc0202e28 <etext+0xea4>
ffffffffc0201d74:	174000ef          	jal	ffffffffc0201ee8 <strnlen>
ffffffffc0201d78:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d7c:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0201d80:	00001d97          	auipc	s11,0x1
ffffffffc0201d84:	0a8d8d93          	addi	s11,s11,168 # ffffffffc0202e28 <etext+0xea4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d88:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d8a:	fda040e3          	bgtz	s10,ffffffffc0201d4a <vprintfmt+0x300>
ffffffffc0201d8e:	bd51                	j	ffffffffc0201c22 <vprintfmt+0x1d8>

ffffffffc0201d90 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d90:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d92:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d96:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d98:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d9a:	ec06                	sd	ra,24(sp)
ffffffffc0201d9c:	f83a                	sd	a4,48(sp)
ffffffffc0201d9e:	fc3e                	sd	a5,56(sp)
ffffffffc0201da0:	e0c2                	sd	a6,64(sp)
ffffffffc0201da2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201da4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201da6:	ca5ff0ef          	jal	ffffffffc0201a4a <vprintfmt>
}
ffffffffc0201daa:	60e2                	ld	ra,24(sp)
ffffffffc0201dac:	6161                	addi	sp,sp,80
ffffffffc0201dae:	8082                	ret

ffffffffc0201db0 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201db0:	7179                	addi	sp,sp,-48
ffffffffc0201db2:	f406                	sd	ra,40(sp)
ffffffffc0201db4:	f022                	sd	s0,32(sp)
ffffffffc0201db6:	ec26                	sd	s1,24(sp)
ffffffffc0201db8:	e84a                	sd	s2,16(sp)
ffffffffc0201dba:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc0201dbc:	c901                	beqz	a0,ffffffffc0201dcc <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc0201dbe:	85aa                	mv	a1,a0
ffffffffc0201dc0:	00001517          	auipc	a0,0x1
ffffffffc0201dc4:	08050513          	addi	a0,a0,128 # ffffffffc0202e40 <etext+0xebc>
ffffffffc0201dc8:	b60fe0ef          	jal	ffffffffc0200128 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc0201dcc:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dce:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc0201dd0:	00005997          	auipc	s3,0x5
ffffffffc0201dd4:	27098993          	addi	s3,s3,624 # ffffffffc0207040 <buf>
        c = getchar();
ffffffffc0201dd8:	bd2fe0ef          	jal	ffffffffc02001aa <getchar>
ffffffffc0201ddc:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201dde:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201de2:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201de6:	ff650693          	addi	a3,a0,-10
ffffffffc0201dea:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0201dee:	02054963          	bltz	a0,ffffffffc0201e20 <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201df2:	02a95f63          	bge	s2,a0,ffffffffc0201e30 <readline+0x80>
ffffffffc0201df6:	cf0d                	beqz	a4,ffffffffc0201e30 <readline+0x80>
            cputchar(c);
ffffffffc0201df8:	b64fe0ef          	jal	ffffffffc020015c <cputchar>
            buf[i ++] = c;
ffffffffc0201dfc:	009987b3          	add	a5,s3,s1
ffffffffc0201e00:	00878023          	sb	s0,0(a5)
ffffffffc0201e04:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc0201e06:	ba4fe0ef          	jal	ffffffffc02001aa <getchar>
ffffffffc0201e0a:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0201e0c:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e10:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc0201e14:	ff650693          	addi	a3,a0,-10
ffffffffc0201e18:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0201e1c:	fc055be3          	bgez	a0,ffffffffc0201df2 <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc0201e20:	70a2                	ld	ra,40(sp)
ffffffffc0201e22:	7402                	ld	s0,32(sp)
ffffffffc0201e24:	64e2                	ld	s1,24(sp)
ffffffffc0201e26:	6942                	ld	s2,16(sp)
ffffffffc0201e28:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0201e2a:	4501                	li	a0,0
}
ffffffffc0201e2c:	6145                	addi	sp,sp,48
ffffffffc0201e2e:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc0201e30:	eb81                	bnez	a5,ffffffffc0201e40 <readline+0x90>
            cputchar(c);
ffffffffc0201e32:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc0201e34:	00905663          	blez	s1,ffffffffc0201e40 <readline+0x90>
            cputchar(c);
ffffffffc0201e38:	b24fe0ef          	jal	ffffffffc020015c <cputchar>
            i --;
ffffffffc0201e3c:	34fd                	addiw	s1,s1,-1
ffffffffc0201e3e:	bf69                	j	ffffffffc0201dd8 <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc0201e40:	c291                	beqz	a3,ffffffffc0201e44 <readline+0x94>
ffffffffc0201e42:	fa59                	bnez	a2,ffffffffc0201dd8 <readline+0x28>
            cputchar(c);
ffffffffc0201e44:	8522                	mv	a0,s0
ffffffffc0201e46:	b16fe0ef          	jal	ffffffffc020015c <cputchar>
            buf[i] = '\0';
ffffffffc0201e4a:	00005517          	auipc	a0,0x5
ffffffffc0201e4e:	1f650513          	addi	a0,a0,502 # ffffffffc0207040 <buf>
ffffffffc0201e52:	94aa                	add	s1,s1,a0
ffffffffc0201e54:	00048023          	sb	zero,0(s1)
}
ffffffffc0201e58:	70a2                	ld	ra,40(sp)
ffffffffc0201e5a:	7402                	ld	s0,32(sp)
ffffffffc0201e5c:	64e2                	ld	s1,24(sp)
ffffffffc0201e5e:	6942                	ld	s2,16(sp)
ffffffffc0201e60:	69a2                	ld	s3,8(sp)
ffffffffc0201e62:	6145                	addi	sp,sp,48
ffffffffc0201e64:	8082                	ret

ffffffffc0201e66 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e66:	00005717          	auipc	a4,0x5
ffffffffc0201e6a:	1ba73703          	ld	a4,442(a4) # ffffffffc0207020 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e6e:	4781                	li	a5,0
ffffffffc0201e70:	88ba                	mv	a7,a4
ffffffffc0201e72:	852a                	mv	a0,a0
ffffffffc0201e74:	85be                	mv	a1,a5
ffffffffc0201e76:	863e                	mv	a2,a5
ffffffffc0201e78:	00000073          	ecall
ffffffffc0201e7c:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e7e:	8082                	ret

ffffffffc0201e80 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e80:	00005717          	auipc	a4,0x5
ffffffffc0201e84:	61873703          	ld	a4,1560(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201e88:	4781                	li	a5,0
ffffffffc0201e8a:	88ba                	mv	a7,a4
ffffffffc0201e8c:	852a                	mv	a0,a0
ffffffffc0201e8e:	85be                	mv	a1,a5
ffffffffc0201e90:	863e                	mv	a2,a5
ffffffffc0201e92:	00000073          	ecall
ffffffffc0201e96:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e98:	8082                	ret

ffffffffc0201e9a <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e9a:	00005797          	auipc	a5,0x5
ffffffffc0201e9e:	17e7b783          	ld	a5,382(a5) # ffffffffc0207018 <SBI_CONSOLE_GETCHAR>
ffffffffc0201ea2:	4501                	li	a0,0
ffffffffc0201ea4:	88be                	mv	a7,a5
ffffffffc0201ea6:	852a                	mv	a0,a0
ffffffffc0201ea8:	85aa                	mv	a1,a0
ffffffffc0201eaa:	862a                	mv	a2,a0
ffffffffc0201eac:	00000073          	ecall
ffffffffc0201eb0:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201eb2:	2501                	sext.w	a0,a0
ffffffffc0201eb4:	8082                	ret

ffffffffc0201eb6 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201eb6:	00005717          	auipc	a4,0x5
ffffffffc0201eba:	15a73703          	ld	a4,346(a4) # ffffffffc0207010 <SBI_SHUTDOWN>
ffffffffc0201ebe:	4781                	li	a5,0
ffffffffc0201ec0:	88ba                	mv	a7,a4
ffffffffc0201ec2:	853e                	mv	a0,a5
ffffffffc0201ec4:	85be                	mv	a1,a5
ffffffffc0201ec6:	863e                	mv	a2,a5
ffffffffc0201ec8:	00000073          	ecall
ffffffffc0201ecc:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201ece:	8082                	ret

ffffffffc0201ed0 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201ed0:	00054783          	lbu	a5,0(a0)
ffffffffc0201ed4:	cb81                	beqz	a5,ffffffffc0201ee4 <strlen+0x14>
    size_t cnt = 0;
ffffffffc0201ed6:	4781                	li	a5,0
        cnt ++;
ffffffffc0201ed8:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0201eda:	00f50733          	add	a4,a0,a5
ffffffffc0201ede:	00074703          	lbu	a4,0(a4)
ffffffffc0201ee2:	fb7d                	bnez	a4,ffffffffc0201ed8 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0201ee4:	853e                	mv	a0,a5
ffffffffc0201ee6:	8082                	ret

ffffffffc0201ee8 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201ee8:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201eea:	e589                	bnez	a1,ffffffffc0201ef4 <strnlen+0xc>
ffffffffc0201eec:	a811                	j	ffffffffc0201f00 <strnlen+0x18>
        cnt ++;
ffffffffc0201eee:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201ef0:	00f58863          	beq	a1,a5,ffffffffc0201f00 <strnlen+0x18>
ffffffffc0201ef4:	00f50733          	add	a4,a0,a5
ffffffffc0201ef8:	00074703          	lbu	a4,0(a4)
ffffffffc0201efc:	fb6d                	bnez	a4,ffffffffc0201eee <strnlen+0x6>
ffffffffc0201efe:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201f00:	852e                	mv	a0,a1
ffffffffc0201f02:	8082                	ret

ffffffffc0201f04 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f04:	00054783          	lbu	a5,0(a0)
ffffffffc0201f08:	e791                	bnez	a5,ffffffffc0201f14 <strcmp+0x10>
ffffffffc0201f0a:	a01d                	j	ffffffffc0201f30 <strcmp+0x2c>
ffffffffc0201f0c:	00054783          	lbu	a5,0(a0)
ffffffffc0201f10:	cb99                	beqz	a5,ffffffffc0201f26 <strcmp+0x22>
ffffffffc0201f12:	0585                	addi	a1,a1,1 # fffffffffff80001 <end+0x3fd78b61>
ffffffffc0201f14:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201f18:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f1a:	fef709e3          	beq	a4,a5,ffffffffc0201f0c <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f1e:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201f22:	9d19                	subw	a0,a0,a4
ffffffffc0201f24:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f26:	0015c703          	lbu	a4,1(a1)
ffffffffc0201f2a:	4501                	li	a0,0
}
ffffffffc0201f2c:	9d19                	subw	a0,a0,a4
ffffffffc0201f2e:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f30:	0005c703          	lbu	a4,0(a1)
ffffffffc0201f34:	4501                	li	a0,0
ffffffffc0201f36:	b7f5                	j	ffffffffc0201f22 <strcmp+0x1e>

ffffffffc0201f38 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f38:	ce01                	beqz	a2,ffffffffc0201f50 <strncmp+0x18>
ffffffffc0201f3a:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201f3e:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f40:	cb91                	beqz	a5,ffffffffc0201f54 <strncmp+0x1c>
ffffffffc0201f42:	0005c703          	lbu	a4,0(a1)
ffffffffc0201f46:	00f71763          	bne	a4,a5,ffffffffc0201f54 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201f4a:	0505                	addi	a0,a0,1
ffffffffc0201f4c:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f4e:	f675                	bnez	a2,ffffffffc0201f3a <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f50:	4501                	li	a0,0
ffffffffc0201f52:	8082                	ret
ffffffffc0201f54:	00054503          	lbu	a0,0(a0)
ffffffffc0201f58:	0005c783          	lbu	a5,0(a1)
ffffffffc0201f5c:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201f5e:	8082                	ret

ffffffffc0201f60 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f60:	a021                	j	ffffffffc0201f68 <strchr+0x8>
        if (*s == c) {
ffffffffc0201f62:	00f58763          	beq	a1,a5,ffffffffc0201f70 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0201f66:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201f68:	00054783          	lbu	a5,0(a0)
ffffffffc0201f6c:	fbfd                	bnez	a5,ffffffffc0201f62 <strchr+0x2>
    }
    return NULL;
ffffffffc0201f6e:	4501                	li	a0,0
}
ffffffffc0201f70:	8082                	ret

ffffffffc0201f72 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201f72:	ca01                	beqz	a2,ffffffffc0201f82 <memset+0x10>
ffffffffc0201f74:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201f76:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201f78:	0785                	addi	a5,a5,1
ffffffffc0201f7a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201f7e:	fef61de3          	bne	a2,a5,ffffffffc0201f78 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f82:	8082                	ret
