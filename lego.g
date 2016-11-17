#header
<<
#include <string>
#include <utility>
#include <complex>
#include <tuple>
#include <iostream>
#include <vector>
#include <set>
#include <map>
using namespace std;
const bool grammar = false;
const bool analysis = true;
const bool debug = false;
typedef struct {
	string kind;
	string text;
} Attrib;
void zzcr_attr(Attrib * attr, int type, char *text);
#define AST_FIELDS string kind; string text;
#include "ast.h"
#define zzcr_ast(as,attr,ttype,textt) as=createASTnode(attr,ttype,textt)
AST *createASTnode(Attrib * attr, int ttype, char *textt);
>><<
#include <cstdlib>
#include <cmath>
AST * root;
void zzcr_attr(Attrib * attr, int type, char *text){
	if (!grammar && type == ID) {
		attr->kind = "id";
		attr->text = text;
	} else {
		attr->kind = text;
		attr->text = "";
	}
}
AST *createASTnode(Attrib * attr, int type, char *text){
	AST *as = new AST;
	as->kind = attr->kind;
	as->text = attr->text;
	as->right = NULL;
	as->down = NULL;
	return as;
}
AST *createASTlist(AST * child){
	AST *as = new AST;
	as->kind = "list";
	as->right = NULL;
	as->down = child;
	return as;
}
AST *child(AST * a, int n){
	AST *c = a->down;
	for (int i = 0; c != NULL && i < n; i++) { c = c->right; }
	return c;
}
void ASTPrintIndent(AST * a, string s){
	if (a == NULL) {return;}
	cout << a->kind;
	if (a->text != ""){cout << "(" << a->text << ")";}
	cout << endl;
	AST *i = a->down;
	while (i != NULL && i->right != NULL) {
		cout << s + "  \\__";
		ASTPrintIndent(i, s + "  |" + string(i->kind.size() + i->text.size(), ' '));
		i = i->right;
	}
	if (i != NULL) {
		cout << s + "  \\__";
		ASTPrintIndent(i, s + "   " + string(i->kind.size() + i->text.size(), ' '));
		i = i->right;
	}
}
void ASTPrint(AST * a){
	while (a != NULL) {
		cout << " ";
		ASTPrintIndent(a, "");
		a = a->right;
	}
}
typedef struct tblock {
	int x, y;
	int h, w;
	set < tblock * >upper;
	tblock *lower;
} tblock;
map < string, tblock * >namedblocks;
map < tblock *, string > reverseNamedblocks;
set < tblock * >allblocks;
map < string, AST * >mapDef = map < string, AST * >();
tblock g;
void initGrid(int n, int m){
	g.x = 1;
	g.y = 1;
	g.w = n, g.h = m;
	namedblocks = map < string, tblock * >();
	reverseNamedblocks = map < tblock *, string > ();
	allblocks = set < tblock * >();
	allblocks.insert(&g);
	g.upper = set < tblock * >();
}
int getHeightTotal(tblock * s){
	if (s == NULL) { return 0; }
	if (s->upper.size() == 0) {	return 1;}
	int c_max = 0;
	for (const auto v : s->upper) {
		if (v == s and debug) { cout << "getHeightTotal panic, tblock* " << s << " is below itself\n"; return 0; }  
		if (v != s) {
			c_max = max(c_max, getHeightTotal(v));
		}
	}
	return 1 + c_max;
}
bool is_named(tblock * j){ return reverseNamedblocks.find(j) != reverseNamedblocks.end();}
void printTblockAddresOrId(tblock* j){ if (is_named(j)) {cout << reverseNamedblocks.at(j);} else {cout << j;} } 
void printTblock(tblock * j){
	if (is_named(j)) { cout << reverseNamedblocks.at(j) << " with address ";}
	cout << j << " on ";
	printTblockAddresOrId(j->lower);
	cout << " below";
	for (auto v:j->upper) { cout << " "; printTblockAddresOrId(v); }
	cout << endl;
}
void printAllBlocks(){
	if (!is_named(&g)) {
		namedblocks["GRID"] = &g;
		reverseNamedblocks[&g] = "GRID";
	}
	for (auto & v:allblocks) { printTblock(v);}
}
void printDefs(void){
	cout << "functions ";
	for (auto & a:mapDef) { cout << a.first; }
	cout << endl;
}
void loadDEFS(AST * a){
	AST *b = a->down;
	while (b != NULL) {
		mapDef[b->down->text] = b->down->right->down;
		b = b->right;
	}
}
void executeOps(AST * a);
bool fits(tblock * a, tblock * b);
tblock getBlock(AST * a, AST * b)
{
	tblock s;
	s.x = atoi(b->down->kind.c_str());
	s.y = atoi(b->down->right->kind.c_str());
	s.w = atoi(a->down->kind.c_str());
	s.h = atoi(a->down->right->kind.c_str());
	return s;
}
bool canMove(string id, string dir, int n)
{
	tblock *f = namedblocks.at(id);
	if (dir == "EAST") {
		namedblocks.at(id)->x += n;
	}
	if (dir == "WEST") {
		namedblocks.at(id)->x -= n;
	}
	if (dir == "NORTH") {
		namedblocks.at(id)->y -= n;
	}
	if (dir == "SOUTH") {
		namedblocks.at(id)->y += n;
	}
	g.upper.erase(f);
	bool t = fits(&g, f);
	g.upper.insert(f);
	if (!t and debug){cout << "move " << id << " cannot be done\n"; }
	return t;
}

void doMove(string id, string dir, int n)
{
	if (namedblocks.find(id) == namedblocks.end() and debug) {
		cout << "trying doing move with id " << id <<
		    " which isn't in namedblocks" << endl;
		return;
	}
	if (namedblocks.at(id) == NULL and debug) {
		cout << "trying doing move with id " << id << " NULL" <<
		    endl;
		return;
	}
	if (dir == "EAST") {
		namedblocks.at(id)->x += n;
		return;
	}
	if (dir == "WEST") {
		namedblocks.at(id)->x -= n;
		return;
	}
	if (dir == "NORTH") {
		namedblocks.at(id)->y -= n;
		return;
	}
	if (dir == "SOUTH") {
		namedblocks.at(id)->y += n;
		return;
	}
	cout << "panic\n";
}
bool fits(tblock * a, tblock * b){
	bool inside_borders = b->x >= 1 && a->w >= b->w + b->x -1 && b->y >= 1 && a->h >= b->h + b->y -1; 	
	if (!inside_borders) {return false;}
	bool intersects_other_tblocks = false;
	for (const auto v : a->upper){
		/// http://stackoverflow.com/questions/306316/determine-if-two-rectangles-overlap-each-other/306379#306379
		auto intersect = [](int Ax1, int Ax2, int Bx1, int Bx2, int Ay1, int Ay2, int By1, int By2) -> bool {
			auto valueInRange = [](int value, int min, int max) -> bool { return (value >= min) && (value <= max); };
			bool xOverlap = valueInRange(Ax1, Bx1, Bx2) ||
							valueInRange(Bx1, Ax1, Ax2);
			bool yOverlap = valueInRange(Ay1, By1, By2) ||
							valueInRange(By1, Ay1, Ay2);
			return xOverlap && yOverlap;
			};
		if (intersect(b->x, b->x + b->w - 1, v->x, v->x + v->w - 1, b->y, b->y + b->h - 1, v->y, v->y + v->h - 1)){
			intersects_other_tblocks = true;
			break;
			}
		}
	return !intersects_other_tblocks;
}
typedef pair<tblock*, tblock*> ptt;
ptt fitsPush(tblock* a, int dimx, int dimy){
	{
	tblock* b = new tblock;  b->w = dimx; b->h = dimy;
	ptt ret = ptt (a, b);
	for (int i = 1; i <= a->w; i += 1){
		for (int j = 1; j <= a->h; j += 1){
			b->x = i; b->y = j;
			if (fits(a,b)){
				return ret;
			}
		}
	}
	delete b;
	}
	for (auto v : a->upper){
		ptt resp = fitsPush(v, dimx, dimy);
		if (resp.second != NULL){
			return resp;
		}
	}
	return ptt(a,NULL);	
}
bool boolFits3(tblock * a, int dimx, int dimy, const int high){
	if (debug) {
		cout << "boolFits3 tblock* int int int called with parameters " <<
	    a << " " << dimx << " " << dimy << " " << high << endl;
		cout << "\tgetHeightTotal of tblock* is " << getHeightTotal(a) <<
	    endl;
	}    
	if (high < 2){return false;}
	if (high == 2){
		ptt resp = fitsPush(a, dimx, dimy);
		if (debug) {cout << "\tboolFits3 returns " << bool(resp.first == a && resp.second != NULL) << "\n";}
		return resp.first == a && resp.second != NULL;
	}
	if (high > 2){
		for (auto v : a->upper){
			if (boolFits3(a, dimx, dimy, high - 1)){
				if (debug){cout << "\tboolFits3 returns true\n";}
				return true;
				}
			}
		if (debug){cout << "\tboolFits3 returns false\n";	}
		return false;	
	}
	if (debug) {cout << "\tboolFits3 panic\n";	}
	return false;
}
bool executeGetBool(AST * a){
	if (a->kind == "FITS") {
		tblock *t = namedblocks.at(a->down->text);
		int dimx = atoi(a->down->right->down->kind.c_str());
		int dimy = atoi(a->down->right->down->right->kind.c_str());
		int altura = atoi(a->down->right->right->kind.c_str());
		if (debug) {
			cout <<
			    "FITS function calling boolFits3 with params "
			    << t << " " << dimx << " " << dimy << " " <<
			    altura << endl;
			    }
		return boolFits3(t, dimx, dimy, altura);
	}
	if (a->kind == "AND") {
		return executeGetBool(a->down)
		    && executeGetBool(a->down->right);
	}
	if (a->kind == ">" || a->kind == "<") {
		int A = 0, B = 0;
		if (a->down->kind == "HEIGHT") {
			A = getHeightTotal(namedblocks[a->down->down->text]);
		} else {
			A = atoi(a->down->kind.c_str());
		}
		if (a->down->right->kind == "HEIGHT") {
			B = getHeightTotal(namedblocks
					   [a->down->right->down->text]);
		} else {
			B = atoi(a->down->right->kind.c_str());
		}
		if (debug) {cout << "executeGetBool A op B " << A << " " << a->kind << " " << B << endl;}
		return (a->kind == ">") ? A > B : A < B;
	}

	cout << "panic" << endl;
	return false;
}
void executePush(tblock* c, tblock* b){
	if (b->lower != NULL) {b->lower->upper.erase(b);}
	b->lower = c;
	c->upper.insert(b);
}
tblock *executePushPop(AST * a){
	if (debug) {cout << "called execute push pop with ast* " << a << endl;}
	tblock *b = new tblock;
	if (a == NULL || a->kind == "list" || a->down == NULL
	    || a->down->kind == "list") {
		if (a == NULL) {
			return NULL;
		}
		if (a->kind == "id") {
			return namedblocks.at(a->text);
		}
		if (a->down->kind == "list") {
			b = new tblock;
			allblocks.insert(b);
			b->w = atoi(a->down->down->kind.c_str());
			b->h = atoi(a->down->down->right->kind.c_str());
			if (debug) {
				cout << "\t" << b->w << " " << b->
				    h << " with address " << b << endl;
			}
		} else {
			cout << a << " " << endl;
			ASTPrint(a);
			cout << "still undefined push\n";
			return NULL;
		}
	} else {
		b = namedblocks.at(a->down->text);
	}
	tblock *c = executePushPop(a->down->right);
	if (c == NULL) {
		return NULL;
	}
	if (a->kind == "POP") {
		if (b->lower != NULL) {
			if (b->lower != c) {return NULL;}
			c->upper.erase(b);
			b->lower = NULL;
		}
		return c;
	} else {
		ptt resp = fitsPush(c, b->w, b->h);
		if (resp.second != NULL) { 
			b->x = resp.second->x;
			b->y = resp.second->y;
			executePush(resp.first, b);
		}
	}
	return c;
}
void executeOp(AST * a){
	if (a->kind == "id") {
		if (a->down == NULL) {
			executeOps(mapDef[a->text]);
		}
		return;
	}
	if (a->kind == "HEIGHT") {
		string id = a->down->text;
		cout << "HEIGHT(" << id << ") is " <<
		    getHeightTotal(namedblocks[id]) << endl;
		return;
	}
	if (a->kind == "=") {
		string id_sink = a->down->text;
		if (a->down == NULL) {
			cout << "panic a->down null" << endl;
			return;
		}
		if (a->down->right == NULL) {
			cout << "panic a->down->right null, a->down is " <<
			    a->down << endl;
			ASTPrint(a);
			return;
		}
		if (a->down->right->kind == "PLACE") {
			AST *base = a->down->right->down;
			tblock *myblock = new tblock;
			*myblock = getBlock(base, base->right);
			bool t = fits(&g, myblock);
			if (t) {
				namedblocks[id_sink] = myblock;
				reverseNamedblocks[myblock] = id_sink;
				allblocks.insert(myblock);
				g.upper.insert(myblock);
				myblock->lower = &g;
			} else {
				if (debug) { cout << "operation place failed\n";}
			}
			return;
		}
		if (a->down->right->kind == "PUSH"
		    || a->down->right->kind == "POP") {
			tblock *pikachu = executePushPop(a->down->right);
			if (pikachu != NULL) {
				namedblocks[id_sink] = pikachu;
				reverseNamedblocks[pikachu] = id_sink;
				allblocks.insert(pikachu);
			} else {
				if (debug) {cout << "ignorando " << ( bool(a->down->right->kind == "PUSH") ? "push" : "pop" )<< endl;}
			}
			return;
		}
	}
	if (a->kind == "MOVE") {
		string id = a->down->text;
		string dir = a->down->right->kind;
		int steps = atoi(a->down->right->right->kind.c_str());
		if (canMove(id, dir, steps)) {
			doMove(id, dir, steps);
		}
		return;
	}
	if (a->kind == "WHILE") {
		while (executeGetBool(a->down)) {
			executeOps(a->down->right->down);
		}
		return;
	}
	cout << "still undefined " << a->kind << " " << a->text << endl;
}
void executeOps(AST * a){
	AST *b = a;
	while (b != NULL) {
		try {
			executeOp(b);
		}
		catch(exception e) {
			cout << "exception caught " << e.what();
			if (debug) {
				cout << " doing operation " << b->
				    kind << endl;
				ASTPrint(b->down);
			} else {
				cout << endl;
			}
		}
		b = b->right;
	}
}
void executeInit(AST * a){
	int A = atoi(a->down->down->kind.c_str());
	int B = atoi(a->down->down->right->kind.c_str());
	initGrid(A, B);
	AST *ops = a->down->right->down;
	AST *defs = a->down->right->right;
	loadDEFS(defs);
	executeOps(ops);
}
int main(){
	root = NULL;
	ANTLR(lego(&root), stdin);
	if (grammar) {
		ASTPrint(root);
	} else {
		executeInit(root);
		if (analysis) { printAllBlocks(); printDefs(); }
	}
}
>>
#lexclass START
#token NUM "[0-9]+"
#token GRID "Grid"
#token DEF "DEF"
#token ENDEF "ENDEF"
#token ASSIG "="
#token POP "POP"
#token PUSH "PUSH"
#token PLACE "PLACE"
#token WHILE "WHILE"
#token AT "AT"
#token MOVE "MOVE"
#token DIRECTION "NORTH|EAST|WEST|SOUTH"
#token LPAREN "\("
#token RPAREN "\)"
#token LCLAU "\["
#token RCLAU "\]"
#token COMMA "\,"
#token AND "AND"
#token OR "OR"
#token LT "\<"
#token GT "\>"
#token FITS "FITS"
#token HEIGHT "HEIGHT"
#token SPACE "[\ \n]" << zzskip();>>
#token TAB "[\t]" << zzskip();>>
#token ID "[a-zA-Z]+[0-9]*"
lego:grid ops defs <<#0=createASTlist(_sibling);>>;
grid:GRID ^ NUM NUM;
ops:(op_height | op_while | op_move | op_assig) * <<#0=createASTlist(_sibling);>>;
defs:(def) * <<#0=createASTlist(_sibling);>>;
def:DEF ^ ID ops ENDEF !;
ublock:LPAREN ! NUM COMMA ! NUM RPAREN ! <<#0=createASTlist(_sibling);>>;
op_place:PLACE ^ ublock AT ! ublock;
op_assig:ID(ASSIG ^ (op_place | op_primer_push) |);
op_primer_push:(ID | ublock) (PUSH ^ |POP ^) op_segon_push;
op_segon_push:ID((PUSH ^ |POP ^) op_segon_push |);
op_move:MOVE ^ ID DIRECTION NUM;
op_while:WHILE ^ LPAREN ! op_bool RPAREN ! LCLAU ! ops RCLAU !;
op_bool:op_bool_atomic(AND ^ op_bool |);
op_bool_atomic:fits | op_lt_gt;
op_lt_gt:(op_height | NUM) (LT ^ |GT ^) NUM;
pos:NUM COMMA ! NUM << #0=createASTlist(_sibling);>>;
fits:FITS ^ LPAREN ! ID COMMA ! pos COMMA ! NUM RPAREN !;
op_height:HEIGHT ^ LPAREN ! ID RPAREN !;
