CC			= gcc
LD			= ld

# -g -- 生成符号表以供调试使用
# -m32 -- 编译成32位目标文件
# -Wall -- 打开绝大多数警告
# -Wno-implicit-function-declaration -- 
# -std=c11 -- 遵循C11标准
# -std=gnu11 -- 遵循C11标准并且打开GNU的相关扩展
# -ffreestanding -- 采用独立环境
# -fno-pic -- 解决“对‘_GLOBAL_OFFSET_TABLE_’未定义的引用”问题
# -nostdinc -- 项目中的头文件可能会和开发环境中的系统头文件文件名称发生冲突，采用这个编译选项时不检索系统默认的头文件目录，但之后需要手动添加需检索的提供独立环境头文件的目录。
# -Iinclude -- 指定包含文件目录
# -fomit-frame-pointer -- 函数操作时不保存栈帧到寄存器(%ebp)（如果使用这个编译参数，则在gdb中调试会出错，因为gdb调试依赖栈帧）
CFLAGS		= -g -m32 -Wall -Wno-implicit-function-declaration -std=gnu11 -ffreestanding -fno-pic -nostdinc #-fomit-frame-pointer

# -Ttext -- 设置 .text 节的地址
# -m -- 设置仿真
LDFLAGS		= -Ttext 0x100000 -m elf_i386

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
%: %.o
	$(LD) $^ -o $@ $(LDFLAGS)

LOOP_DEVICE_NUMBER			= 12
LOOP_DEVICE					= /dev/loop$(LOOP_DEVICE_NUMBER)
LOOP_DEVICE_MOUNT_ROOT_DIR	= /mnt/vdisk

KERNEL_NAME			= kernel
DISK_IMAGE			= hd.img
DISK_IMAGE_SECTORS	= 20160

all: mkimage

boot.o: boot.S

kernel.o: kernel.c

$(KERNEL_NAME): boot.o kernel.o
	$(LD) $^ -o $@ $(LDFLAGS)

mkimage: $(KERNEL_NAME) $(DISK_IMAGE)
	make mount
	sudo cp $(KERNEL_NAME) $(LOOP_DEVICE_MOUNT_ROOT_DIR)/p1
	make umount

$(DISK_IMAGE):
	dd if=/dev/zero of=$(DISK_IMAGE) bs=512 count=$(DISK_IMAGE_SECTORS)
	parted $(DISK_IMAGE) 'mklabel msdos mkpart primary fat16 1MB -1 set 1 boot on'
	sudo losetup -P $(LOOP_DEVICE) $(DISK_IMAGE)
	sudo mkfs.msdos $(LOOP_DEVICE)p1
	sudo mount $(LOOP_DEVICE)p1 $(LOOP_DEVICE_MOUNT_ROOT_DIR)/p1
	sudo grub-install --boot-directory=$(LOOP_DEVICE_MOUNT_ROOT_DIR)/p1 --target=i386-pc $(LOOP_DEVICE)
	echo "echo \"multiboot2 (hd0,msdos1)/$(KERNEL_NAME)\nboot\" > $(LOOP_DEVICE_MOUNT_ROOT_DIR)/p1/grub/grub.cfg" | sudo sh
	sync
	make umount

mount:
	sudo losetup -P $(LOOP_DEVICE) $(DISK_IMAGE)
	sudo mount $(LOOP_DEVICE)p1 $(LOOP_DEVICE_MOUNT_ROOT_DIR)/p1

umount:
	sudo umount $(LOOP_DEVICE_MOUNT_ROOT_DIR)/p1
	sudo losetup -d $(LOOP_DEVICE)

clean:
	rm -f *.o $(KERNEL_NAME) $(DISK_IMAGE)