CC = m68k-elf-gcc
AS = m68k-elf-as
OBJC = m68k-elf-objcopy
LD = m68k-elf-ld
RM = rm -f
ASMZ80 = zasm
BINTOS = bintos
PCMTORAW = pcmtoraw
WAVTORAW = wavtoraw

OPTION =
INCS = -I. -I$(GENDEV)/m68k-elf/include -I$(GENDEV)/m68k-elf/m68k-elf/include -Isrc -Ires
CCFLAGS = $(OPTION) -std=c99 -m68000 -O2 -c -fomit-frame-pointer -w
HWCCFLAGS = $(OPTION) -m68000 -O1 -c -fomit-frame-pointer -w
Z80FLAGS = -vb2
ASFLAGS = -m68000 --register-prefix-optional
LIBS =  -L$(GENDEV)/m68k-elf/lib -L$(GENDEV)/m68k-elf/lib/gcc/m68k-elf/4.5.2 -L$(GENDEV)/m68k-elf/m68k-elf/lib -lmd -lnosys 
LINKFLAGS = -T $(GENDEV)/ldscripts/sgdk.ld -nostdlib 
ARCHIVES = $(GENDEV)/m68k-elf/lib/libmd.a $(GENDEV)/m68k-elf/lib/gcc/m68k-elf/4.8.2/libgcc.a 

RESOURCES=
BOOT_RESOURCES=

BOOTSS=$(wildcard boot/*.s)
BOOTSS+=$(wildcard src/boot/*.s)
BOOT_RESOURCES+=$(BOOTSS:.s=.o)

BMPS=$(wildcard res/*.bmp)
VGMS=$(wildcard res/*.vgm)
RAWS=$(wildcard res/*.raw)
PCMS=$(wildcard res/*.pcm)
MVSS=$(wildcard res/*.mvs)
TFDS=$(wildcard res/*.tfd)
WAVS=$(wildcard res/*.wav)
WAVPCMS=$(wildcard res/*.wavpcm)
BMPS+=$(wildcard *.bmp)
VGMS+=$(wildcard *.vgm)
RAWS+=$(wildcard *.raw)
PCMS+=$(wildcard *.pcm)
MVSS+=$(wildcard *.mvs)
TFDS+=$(wildcard *.tfd)
WAVS+=$(wildcard *.wav)
WAVPCMS+=$(wildcard res/*.wavpcm)
RESOURCES+=$(BMPS:.bmp=.o)
RESOURCES+=$(VGMS:.vgm=.o)
RESOURCES+=$(RAWS:.raw=.o)
RESOURCES+=$(PCMS:.pcm=.o)
RESOURCES+=$(MVSS:.mvs=.o)
RESOURCES+=$(TFDS:.tfd=.o)
RESOURCES+=$(WAVS:.wav=.o)
RESOURCES+=$(WAVPCMS:.wavpcm=.o)

CS=$(wildcard src/*.c)
SS=$(wildcard src/*.s)
S80S=$(wildcard src/*.s80)
CS+=$(wildcard res/*.c)
SS+=$(wildcard res/*.s)
S80S+=$(wildcard res/*.s80)
CS+=$(wildcard *.c)
SS+=$(wildcard *.s)
S80S+=$(wildcard *.s80)
RESOURCES+=$(CS:.c=.o)
RESOURCES+=$(SS:.s=.o)
RESOURCES+=$(S80S:.s80=.o)

OBJS = $(RESOURCES)

all: out.bin 

boot/sega.o: boot/rom_head.bin
	$(AS) $(ASFLAGS) boot/sega.s -o $@

%.bin: %.elf
	$(OBJC) -O binary $< temp.bin
	dd if=temp.bin of=$@ bs=8K conv=sync
	rm temp.bin

%.elf: $(OBJS) $(BOOT_RESOURCES)
	$(CC) -o $@ $(LINKFLAGS) $(BOOT_RESOURCES) $(ARCHIVES) $(OBJS) $(LIBS)

%.o80: %.s80
	$(ASMZ80) $(Z80FLAGS) -o $@ $<

%.c: %.o80
	$(BINTOS) $<

%.o: %.c
	$(CC) $(CCFLAGS) $(INCS) -c $< -o $@

%.o: %.s 
	$(AS) $(ASFLAGS) $< -o $@

%.s: %.bmp
	bintos -bmp $<

%.rawpcm: %.pcm
	$(PCMTORAW) $< $@

%.raw: %.wav
	$(WAVTORAW) $< $@ 16000

%.pcm: %.wavpcm
	$(WAVTORAW) $< $@ 22050

#%.tfc: %.tfd
#	$(TFMCOM) $<

#%.o80: %.s80
#	$(ASMZ80) $(FLAGSZ80) $< $@ out.lst

%.s: %.tfd
	$(BINTOS) -align 32768 $<

%.s: %.mvs
	$(BINTOS) -align 256 $<

%.s: %.esf
	$(BINTOS) -align 32768 $<

%.s: %.eif
	$(BINTOS) -align 256 $<

%.s: %.vgm 
	$(BINTOS) -align 256 $<

%.s: %.raw
	$(BINTOS) -align 256 -sizealign 256 $<

%.s: %.rawpcm
	$(BINTOS) -align 128 -sizealign 128 -nullfill 136 $<

%.s: %.rawpcm
	$(BINTOS) -align 128 -sizealign 128 -nullfill 136 $<

boot/rom_head.bin: boot/rom_head.o
	$(LD) $(LINKFLAGS) --oformat binary -o $@ $<
	

clean:
	$(RM) $(RESOURCES)
	$(RM) *.o *.bin *.elf *.map
	$(RM) boot/*.o boot/*.bin
