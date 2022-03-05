#define _GNU_SOURCE
#include <dlfcn.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#if 0
void *_malloc(size_t size, const char *filename, int line) {
	void *p = malloc(size);
	char buff[128] = {0};

	sprintf(buff, "./checkleak/%p.mem", p);	//将内存名作为文件名写入buff
	FILE *fp = fopen(buff, "w");
	fprintf(fp, "[+]%s: %d addr: %p, size: %ld\n", filename, line, p, size);

	fclose(fp);

	return p;
}

void _free(void *ptr, const char *filename, int line) {
	char buff[128] = {0};

	sprintf(buff, "./checkleak/%p.mem", ptr);	//将内存名作为文件名写入buff
	if (unlink(buff) < 0) {	//文件不存在,被释放两次 *不考虑多线程
		printf("double free: %p\n", ptr);
		return;
	}

	free(ptr);

	printf("[-] %p, %s, %d\n", ptr, filename, line);
}

#define malloc(size) _malloc(size, __FILE__, __LINE__)
#define free(ptr) _free(ptr, __FILE__, __LINE__)

#else
//dlsym,dlopen

typedef void *(*malloc_t)(size_t size);
typedef void (*free_t)(void *ptr);
//定义两个函数指针类型定义,因此可以使用malloc_t定义变量

malloc_t malloc_f = NULL;
free_t free_f = NULL;

int enable_malloc_hook = 1;
int enable_free_hook = 1;

void *malloc(size_t size) {
	void *p = NULL;

	if (enable_malloc_hook) {
		enable_malloc_hook = 0;

		p = malloc_f(size);

		void *caller = __builtin_return_address(0);	//获得上一级调用位置的地址

		char buff[128] = {0};

		sprintf(buff, "./checkleak/%p.mem", p);	//将内存名作为文件名写入buff
		FILE *fp = fopen(buff, "w");
		fprintf(fp, "[+]%p addr: %p, size: %ld\n", caller, p, size);

		fflush(fp);

		enable_malloc_hook = 1;
	} else {	//当递归发生时,不使用printf打印
		p = malloc_f(size);
	}

	return p;
}

void free(void *ptr) {
	if (enable_free_hook) {
		enable_free_hook = 0;

		char buff[128] = {0};

		sprintf(buff, "./checkleak/%p.mem", ptr);	//将内存名作为文件名写入buff
		if (unlink(buff) < 0) {	//文件不存在,被释放两次 *不考虑多线程
			printf("double free: %p\n", ptr);
			return;
		}

		free_f(ptr);

		enable_free_hook = 1;
	} else {
		free_f(ptr);
	}
}

void init_hook(void) {

	if (malloc_f == NULL) {
		malloc_f = (malloc_t)dlsym(RTLD_NEXT, "malloc");
	}

	if (free_f == NULL) {
		free_f = (free_t)dlsym(RTLD_NEXT, "free");
	}
}

#endif

int main() {

	init_hook();
	void *p1 = malloc(5);
	void *p2 = malloc(10);
	void *p3 = malloc(15);

	free(p1);
	free(p2);

}
