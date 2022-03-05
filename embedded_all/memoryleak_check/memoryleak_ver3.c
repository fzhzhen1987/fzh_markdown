#include <stdio.h>
#include <stdlib.h>

#if 1
void *_malloc(size_t size, const char *filename, int line) {
	void *p = malloc(size);

	printf("[+] %p, %s, %d\n", p, filename, line);
	return p;
}

void _free(void *ptr, const char *filename, int line) {
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

