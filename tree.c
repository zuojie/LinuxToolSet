#include <sys/stat.h>
#include <stdio.h>
#include <unistd.h>
#include <dirent.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

void dfs(const char *path, int level) {
	struct stat buf;
	DIR *dirp;
	struct dirent *dir_entp;
	dirp = opendir(path);
	char pre_path[2048];
	char tmp_path[2048];
	if(path[0] != '/') {
		getcwd(pre_path, 2048);
		strcat(pre_path, "/");
		strcat(pre_path, path);
		strcat(pre_path, "/");
	} else {
		strcpy(pre_path, path);
		strcat(pre_path, "/");
	}
	if(dirp == NULL) {
		fprintf(stderr, "%s not exists!\n", path);
		return;
	}
	while(1) {
		strcpy(tmp_path, pre_path);
		dir_entp = readdir(dirp);
		if(dir_entp == NULL) {
			break;
		}
		if(strcmp(dir_entp->d_name, "..") == 0 || strcmp(dir_entp->d_name, ".") == 0) {
			continue;
		}
		strcat(tmp_path, dir_entp->d_name);
		if(lstat(tmp_path, &buf)) {
			fprintf(stderr, "lstat error: %s for %s\n", strerror(errno), tmp_path);
			return;
		}
		for (int i = 0; i < level; ++ i) putchar(' ');
		putchar('|');
		putchar('-');
		printf("%s\n", dir_entp->d_name);
		if(S_ISDIR(buf.st_mode)) {
			dfs(tmp_path, level + 1);
		}
	}
	closedir(dirp);
}

int main(int argc, char **argv) {
	if(argc != 2) {
		fprintf(stderr, "Usage: tree <path>\n");
		exit(1);
	}
	char *path = argv[1];
	printf("%s\n", path);
	dfs(path, 0);
	return EXIT_SUCCESS;
}
