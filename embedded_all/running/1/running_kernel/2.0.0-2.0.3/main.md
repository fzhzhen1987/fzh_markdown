# 2.0.0-2.0.3 内存总览

- [2.0.0 内存管理硬件知识](#1)  
- [2.0.1 内存管理总览](#2)  
- [2.0.2 内存管理总览](#3)  
- [2.0.3 内存管理常用术语](#4)  

<h4 id="1">[2.0.0 内存管理硬件知识]</h>  

1. 关于地址  
	1. 虚拟地址  
	1. 物理地址  
		> CPU通过外部总线,去访问物理内存所需要的地址为物理地址.  
	- 虚拟地址转化物理地址小贴士  
		> 假如系统提供分页机制,那么虚拟地址必须通过查页表的方式来转化为物理地址.  
		> 在没有启动分页机制情况下,那么虚拟地址就变为物理地址.  

1. 内存管理的硬件结构  
	1. 在MMU启动状态下,CPU访问的地址是虚拟地址,需要通过MMU完成虚拟地址转化为物理地址,过程如下:  
		> 1. CPU访问虚拟地址,通过MMU将虚拟地址转化为物理地址,此操作需要查询页表(主存中)  
		>	`假如查找二级页表,从虚拟地址到物理地址通常需要访问2次页表,也就是说需要访问2次内存.太慢了!!!!!`  
		> 1. TLB被称为快表,缓存了上一次虚拟地址到物理地址 转换的页表的表项(存储页表转换的表项).  
		>	`假如在TLB中可以找到上一次转换的页表项,就不需要访问主存中的页表了,学名为: TLB hit`  
		>	`假如在TLB中没有找到所要的页表项,那只能去访问主存来查询页表,学名为: TLB miss`  
		> <details>
		> <summary>虚拟地址转化为物理地址图</summary>
		> <img src= 1_CPU_虚拟到物理.png />
		> </details>  

	1. 当虚拟地址已转换为物理地址,之后就要到1级缓存中查找  
		> `物理索引/物理标签(tag): PIPT.通过地址编码的方式访问Cache`  
		> `通常Cache使用组相联方式,所以访问Cache的地址会被分为三个部分:标记域,索引域,偏移域 `  

	1. 当1级缓存未找到数据将到2级缓存中查找,若还未找到数据将到主存储中查找.  
		> <details>
		> <summary>查看缓存中数据是否存在</summary>
		> <img src= 2_查看缓存中是否存在.png />
		> </details>

	1. 当物理内存短缺时,内核会触发页面回收机制,将不常用的页面交换到SWAP分区中.  

1. 关于虚拟地址到物理地址的转换,也就是MMU如何访问页表(ARM 32: 虚拟地址长度为32位)  
	- 注意:在二级页表中没有中间目录项(PMD).  
	1. [31:20] 12bit 为L1索引: 对应内核的 PGD(页面目录)  
	1. [19:12] 8bit 为L2索引: 对应内核的 PT(页面表)  
	1. [11:0] 12bit 为页索引  
	1. 页表基地址寄存器(TTBRx): 存放1级页表的基地址.  
		> - 1级页表有4096个表项,每个表项存放2级页表的基地址: 可以通过L1索引(12bit位)访问1级页表  
		> - 2级页表通常动态分配,此例中有256个表项: 可以通过L2索引值(8bit位)访问2级页表.  
		> - 2级页表的表项中存储的是: 物理地址的[31:12] 高20位.与虚拟地址的[11:0] 低12位组成最终的物理地址.  
		> <details>
		> <summary>MMU转换虚拟地址到物理地址</summary>
		> <img src= 3_虚拟地址转换物理地址.png />
		> </details>

<h4 id="2">[2.0.1 内存管理总览: 模块总览]</h>  

- 前提知识: 32位系统: 用户空间3GB,内核空间1GB  

<details>
<summary>内存模块总览</summary>
<img src= 4_内存模块总览.png />
</details>

1. malloc: 用户空间在堆上分配内存  

1. brk: malloc是通过使用brk分配内存,对应内核中的sys_brk系统调用  
	> 假设用户通过malloc申请内存,就会使用用户空间的brk,就需要调用到内核中对应的sys_brk.  
	> 用户空间分配的内存为虚拟内存,所以堆上分配的内存也是虚拟内存.  
	> 内核把这些虚拟内存称为进程地址空间.  

1. vma管理: 内核使用vm_area_struct来描述 进程地址空间.  
	> vma管理主要功能: 创建,插入,删除,合并等操作.  
	> 当sys_brk创建完成vma后,会返回vma的开始地址到用户空间,此时用户空间会感觉得到了可使用的内存,  
	> 但是这些内存空间是虚拟的,没有真实得到.  
	> 用户写虚拟地址会发现无法写入,虚拟地址没有和真是的物理地址建立关系.  

1. 缺页中断: 建立虚拟地址和物理地址之间的映射关系.  
	> 缺页中断实现按需分配.  
	> 用户角度看会得到的物理页面分为: 匿名页面或page cache  

1. 匿名页面: 没有关系任何文件的页面.  
	> malloc 堆上分配内存,mmap 匿名映射分配的内存,都是匿名页面.  

1. page cache: 关联了具体文件的缓存的页面.  
	> 比如: 播放器看电影,系统读取文件产生的文件缓存  

1. 页面分配器(页框分配为单位): 伙伴系统  
	> 内存充足时,分配很简单.  
	> 内存不足时,尝试异步模式页面回收,内存规整(memory compaction),OOM killer杀死进程.  
	> 当页面分配器分配好页面之后,就要涉及到页表的管理  

1. 页表管理: 内核页表和用户进程页表  
	> 预览问题:  
	> 进程页表分配在哪里.存放在哪里  
	> 一级页表 二级页表如何分配  
	> 内核提供了很多和页面相关的函数和宏,关注和页表相关的一些宏和函数.  

1. slab: 管理特定大小的对象缓存,对固定大小的数据结构的内存分配有特效.  
1. 页面回收: 当系统内存短缺时,需要回收一部分内存.  
	> 回收对象:page cache或者匿名页面  
	> kswapd内核线程,当系统内存低于某个值,会被唤醒去扫面LRU链表,  
	> 通常匿名页面和page cache会被添加到LRU(最近最少使用)链表,本质是个先进先出链表.  
	> Linux将链表做了细分: 活跃链表,不活跃链表,匿名链表,page cache链表.  
	> page cache易被回收: 干净的page cache直接drop.脏的page cache需要写回磁盘(write back).  
	> 匿名页面不能被直接drop,因为匿名页面保存进程私有数据,需要写到交换分区保存(swap out).  
	> 当进程重新需要这些数据,缺页中断会将磁盘上的数据重新读取到新的页面(swap in).  

1. 反向映射: 可以从page数据结构中找到所有映射此page的虚拟地址空间.  
	> 回收匿名页面或page cache时必须把所有映射此页面的用户pte  
	> (用户进程地址空间和物理页面建立映射的pte,不包含内核自己线性映射pte)都要断开映射关系,才能回收这个页面.  

1. KSM: 用来合并匿名页面,不能合并page cache.  
	> 当两个匿名页面内容一致的时候,利用写时复制,将两个页面合并成一个只读页面,此时就可以释放一个只读页面.  

1. Huge Page: 分配2M或者1G大小的页(服务器中应用多).
	> Huge Page可以减少tlb miss的次数.  
	> 2级页表为例,1次tlb miss就要访问内存2次.  

1. 页迁移: 匿名页面可以迁移.  
	> migrte_pages 在NUMA系统上页面迁移,迁移一个进程的页面到指定的内存节点.  
	> 页迁移被用在: 内存规整,内存热插拔.  

1. 内存规整: 长时间运行系统会产生内存碎片.  
	> 内核需要连续的大块内存.用户一般是通过缺页中断申请分配页.  

1. OOM Killer: 杀死进程得到内存.  

<details>
<summary>内存模块总览</summary>
<img src= 4_内存模块总览.png />
</details>

<h4 id="3">[2.0.2 内存管理总览:进程]</h>  

<details>
<summary>内存管理从进程角度图</summary>
<img src= 5_内存进程总览.png />
</details>

1. 用户空间:内核空间 = 3:1(此比例可以修改)  

1. 物理内存  
	> 当物理内存大于1GB,内核空间如何去访问那些大于1GB的内存:  
	> 在内核角度来看,将物理内存分为2段:  
	> 低地址段:线性地址 线性映射 将物理内存直接映射到3G开始的地址空间(内核虚拟地址-偏移量=物理地址,偏移量被称为page offset)  
	> 高地址段:高端地址 高端映射 通过动态映射将内核高端虚拟地址和高端物理地址相关联  
	>
	> 如何划分高低地址段: 内核提供宏去确定分水岭,可修改(arm32大概是760MB)  

1. struct page: 抽象描述实实在在的物理内存页面(非常重要)  

1. mem_map[]: 存放每一个struct page,可以从数组找到page,找到页帧号.  

1. ZONE: 内存区域.  
	> 物理内存划分为2个区域:线性和高端,ZONE同理.  

1. task_struct: 包含了成员struct mm,中的mmap和pgd.  

1. VMA不是连续的,是离散的.用链表和红黑树管理.  



<h4 id="4">[2.0.3 内存管理常用术语]</h>  



