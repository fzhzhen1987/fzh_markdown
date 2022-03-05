#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#if 1
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
#endif

int main() {

	void *p1 = malloc(5);
	void *p2 = malloc(10);
	void *p3 = malloc(15);

	free(p1);
	free(p2);

}

