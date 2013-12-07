%option noyywrap
%x IFILE

%{
	struct bufstack {
		struct bufstack *prev;
		YY_BUFFER_STATE bs;
		int lineno;
		int depth;
		char *fname;
		FILE *f;
	} *curbs = 0;
	char *curfilename;
	int push_file(char *fn);
	int pop_file(void);
	int circular_include(char *fn);
%}

%%
^"#"[ \t]*include[ \t]*[\"<] { BEGIN IFILE; }
<IFILE>[^ \t\n\">]+ {
						int c;
						while((c = input()) && c != '\n');
						yylineno ++;
						if(curbs) {
							for(c = 0; c <= curbs->depth; ++ c) {
								fprintf(yyout," ");
							}
						}
						fprintf(yyout,"|-%s\n", yytext);
						if(!push_file(yytext)) {
							//fprintf(stderr, "warning:%s is circular included\n", yytext);
							//yyterminate();
						}
						BEGIN INITIAL;
					}
<IFILE>.|\n {
				fprintf(stderr, "%4d bad include line\n", yylineno);
				yyterminate();
			}

<<EOF>> { if(!pop_file()) yyterminate(); }
^. { /*fprintf(yyout, "%4d %s", yylineno, yytext);*/ }
^\n { /*fprintf(yyout, "%4d %s", yylineno ++, yytext);*/  }
\n { /*ECHO;*/ yylineno ++; }
. { /*ECHO;*/ }

%%
int main(int argc, char **argv) {
	if(argc < 2) {
		fprintf(stderr, "need filename\n");
		return 1;
	}
	if(push_file(argv[1])) {
		fprintf(stdout, "|-%s\n", argv[1]);
		yylex();
	}
	return 0;
}
int push_file(char *fn) {
	FILE *f = fopen(fn, "r");
	struct bufstack *bs = malloc(sizeof(struct bufstack));
	if(!f) {
		perror(fn);
		return 0;
	}
	if(!bs) {
		perror("malloc");
		exit(1);
	}
	int first = 0;
	if(curbs) {
		if(circular_include(fn)) {
			return 0;
		}
		curbs->lineno = yylineno;
	} else {
		first = 1;
	}
	bs->prev = curbs;
	bs->bs = yy_create_buffer(f, YY_BUF_SIZE);
	bs->f = f;
	bs->fname = fn;
	if(first) {
		bs->depth = 1;
	} else {
		bs->depth = curbs->depth + 1;
	}
	yy_switch_to_buffer(bs->bs);
	curbs = bs;
	yylineno = 1;
	curfilename = fn;
	return 1;
}
int pop_file(void) {
	struct bufstack *bs = curbs;
	struct bufstack *prevbs;
	if(!bs) {
		return 0;
	}
	fclose(bs->f);
	yy_delete_buffer(bs->bs);
	prevbs = bs->prev;
	free(bs);
	curbs = prevbs;
	if(!prevbs) {
		return 0;
	}
	yy_switch_to_buffer(prevbs->bs);
	yylineno = curbs->lineno;
	curfilename = curbs->fname;
	return 1;
}
int circular_include(char *fn) {
	struct bufstack *bs = curbs;
	struct bufstack *prevbs;
	if(!bs) {
		return 0;
	}
	while(1) {
		prevbs = bs->prev;
		if(!prevbs) {
			return 0;
		}
		if(strcmp(prevbs->fname, fn) == 0) {
			return 1;
		}
		bs = prevbs;
	}
	return 0;
}
