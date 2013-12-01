ws [ \t]
non_ws [^ \t\n]
word {ws}*{non_ws}+
words {word}{ws}+
%option noyywrap

%{
int chars = 0;
int words = 0;
int line = 0;
int tot_chars = 0;
int tot_words = 0;
int tot_line = 0;
%}

%%
{word}{ws}* {chars += yyleng; ++ words;}
{word}{ws}*\n {chars += yyleng; ++ words; ++ line;}
{words}{word}{ws}* {chars += yyleng; words += 2;}
{words}{2}{word}{ws}* {chars += yyleng; words += 3;}
{words}{3}{word}{ws}* {chars += yyleng; words += 4;}
{ws}+ {chars += yyleng;}
\n+ {chars += yyleng; line += yyleng;}

%%
int main(int argc, char **argv) {
	if(argc < 2) {
		yylex();
		fprintf(stdout, "%8d%8d%8d\n", line, words, chars);
		return 0;
	}
	int i;
	for(i = 1; i < argc; ++ i) {
		FILE *f = fopen(argv[i], "r");
		if(!f) {
			perror(argv[i]);
			return 1;
		}
		yyrestart(f);
		yylex();
		fclose(f);
		fprintf(stdout, "%8d%8d%8d %s\n", line, words, chars, argv[i]);
		tot_chars += chars;
		chars = 0;
		tot_words += words;
		words = 0;
		tot_line += line;
		line = 0;
	}
	if(argc > 1) {
		fprintf(stdout, "%8d%8d%8d\n", tot_line, tot_words, tot_chars);
	}
	return 0;
}
