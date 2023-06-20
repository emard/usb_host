
/*
 * Scaled down version of C Library printf.
 * Only %s %u %d (==%u) %o %x %D are recognized.
 * Used to print diagnostic information
 * directly on console tty.
 * Since it is not interrupt driven,
 * all system activities are pretty much suspended.
 * Printf should not be used for chit-chat.
 */

typedef unsigned int   uint32_t;
typedef unsigned char  uint8_t;
typedef uint32_t       time_t;

void timer_sleep(time_t);
time_t timer_now(void);
 
uint32_t *uart = (uint32_t *)0x20000000;

void putchar(char c)
{
	while((uart[1] & 0x01) == 0);
	*uart = c;
}

void puts(char *s)
{
	while(*s) putchar(*s++);
}

void putw(unsigned long w)
{
	char *digit = "0123456789abcdef";
	char str[9];
	int i;
	
	str[8] = 0;
	for(i=7;i>=0;i--) {
		str[i] = digit[(w & 0xf)];
		w >>= 4;
		if(w==0) break;
	}
	puts(str+i);
}

void printf(char *fmt, unsigned int x1)
{
	int c;
	unsigned int *adx;
	char *s;

	adx = &x1;
loop:
	while((c = *fmt++) != '%') {
		if(c == '\0')
			return;
		putchar(c);
	}
	c = *fmt++;
	if(c == 'd' || c == 'u' || c == 'o' || c == 'x') {
		putw((unsigned long)*adx);
		//printn((long)*adx, c=='o'? 8: (c=='x'? 16:10));
	}
	else if(c == 'c') {
		putchar(*adx);
	}
	else if(c == 's') {
		s = *(char **)adx;
		adx++;
		while(c = *s++)
			putchar(c);
	}
	adx++;
	goto loop;
}

int is_sim(void)
{
	return uart[1] & 0x4;
}

void timer_sleep(time_t ms)
{
    if (is_sim()) return;

	time_t end = uart[2] + ms;
	while (uart[2] != end) ;
}

time_t timer_now(void)
{
	return uart[2];
}

void* memset(void *dest, uint8_t val, uint32_t len)
{
    uint8_t *ptr = dest;

    while (len-- > 0)
        *ptr++ = val;
    return dest;
}
