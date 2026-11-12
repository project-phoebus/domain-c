/*
 * c_data.asm - the C compiler's read-only tables: the reserved words'
 * and tokens' spellings, the diagnostics' numbers for the code
 * generator's codes, each diagnostic's text offset and severity, and
 * the diagnostics' texts.  Module c_data (its .blocks record, version
 * 2: the path, then the module name; one block of 0x47D0 bytes, no
 * routines).
 *
 * Image addresses (DOMAIN C 6.9; the unit is the same in both
 * binaries, byte for byte): .text, cc.m68k 0x0409E4..0x0451B3, cc.a88k
 * 0x040C64..0x044433 (18384 bytes; no data, no A5):
 *   cc.m68k   cc.a88k
 *   0x0409E4  0x040C64  c_rword_table   (750 bytes)
 *   0x040CD2  0x040F52  cerr_code_map   (172)
 *   0x040D7E  0x040FFE  cerr_messages   (1320)
 *   0x0412A6  0x041526  cerr_texts      (16142)
 * The tables are read absolutely: c_main's rword_init (the spellings,
 * entered with idntk(k, ...) as token classes; c_globals.ins.pas's
 * 76th entry is cerr_code_map's first 10 bytes), c_error's errorlst
 * and cgerr, attributes.pas and c_lex_pp.pas (single entries of
 * cerr_code_map).  The names are c_globals.ins.pas's (chosen by
 * c_error's translator, docs/questions.md 6), kept.
 *
 * Written for GNU as (m68k-elf-as), as the source repository's
 * lib/libc .s files are; the original was Apollo's ASM, whose syntax
 * is not known here.  Generated from the image's bytes and checked:
 * assembled with `m68k-elf-as' and `m68k-elf-objcopy -O binary -j
 * .text', the 18384 bytes are the image's (both binaries).
 *
 * Not known from the original: the labels' names (the image keeps
 * none: the tables are reached absolutely); whether the 75 spellings
 * were one table or a label each; how the texts were laid out in the
 * source (here one line per text, preceded by the numbers of the
 * diagnostics that use it, at most 60 characters a line; diagnostics
 * sharing a text: several numbers).
 */

        .text

/* cc.m68k 0x0409E4, cc.a88k 0x040C64: the reserved words and token
 * spellings, token classes 0..74, 10 characters each, blank-padded
 * (c_main's rword_init; c_globals.ins.pas c_rword_table). */
        .globl  c_rword_table
c_rword_table:
        .ascii  "}         "      /*  0 */
        .ascii  "if        "      /*  1 */
        .ascii  "switch    "      /*  2 */
        .ascii  "{         "      /*  3 */
        .ascii  "else      "      /*  4 */
        .ascii  "do        "      /*  5 */
        .ascii  "enum      "      /*  6 */
        .ascii  "          "      /*  7 */
        .ascii  "void      "      /*  8 */
        .ascii  "while     "      /*  9 */
        .ascii  "case      "      /* 10 */
        .ascii  "int       "      /* 11 */
        .ascii  "char      "      /* 12 */
        .ascii  "float     "      /* 13 */
        .ascii  "double    "      /* 14 */
        .ascii  "for       "      /* 15 */
        .ascii  "union     "      /* 16 */
        .ascii  "struct    "      /* 17 */
        .ascii  "__va_type "      /* 18 */
        .ascii  "++        "      /* 19 */
        .ascii  "--        "      /* 20 */
        .ascii  "%         "      /* 21 */
        .ascii  "||        "      /* 22 */
        .ascii  "&&        "      /* 23 */
        .ascii  "!         "      /* 24 */
        .ascii  "auto      "      /* 25 */
        .ascii  "register  "      /* 26 */
        .ascii  "typedef   "      /* 27 */
        .ascii  "          "      /* 28 */
        .ascii  "std_$call "      /* 29 */
        .ascii  "          "      /* 30 */
        .ascii  "...       "      /* 31 */
        .ascii  "goto      "      /* 32 */
        .ascii  "->        "      /* 33 */
        .ascii  "~         "      /* 34 */
        .ascii  "static    "      /* 35 */
        .ascii  "extern    "      /* 36 */
        .ascii  "long      "      /* 37 */
        .ascii  "short     "      /* 38 */
        .ascii  "unsigned  "      /* 39 */
        .ascii  "break     "      /* 40 */
        .ascii  "continue  "      /* 41 */
        .ascii  "sizeof    "      /* 42 */
        .ascii  "return    "      /* 43 */
        .ascii  "default   "      /* 44 */
        .ascii  "          "      /* 45 */
        .ascii  "<<        "      /* 46 */
        .ascii  ">>        "      /* 47 */
        .ascii  "?         "      /* 48 */
        .ascii  "..        "      /* 49 */
        .ascii  "]         "      /* 50 */
        .ascii  ".         "      /* 51 */
        .ascii  "=         "      /* 52 */
        .ascii  ":         "      /* 53 */
        .ascii  "<=        "      /* 54 */
        .ascii  "!=        "      /* 55 */
        .ascii  "<         "      /* 56 */
        .ascii  "==        "      /* 57 */
        .ascii  ">=        "      /* 58 */
        .ascii  ">         "      /* 59 */
        .ascii  "[         "      /* 60 */
        .ascii  "(         "      /* 61 */
        .ascii  ")         "      /* 62 */
        .ascii  ",         "      /* 63 */
        .ascii  ";         "      /* 64 */
        .ascii  "*         "      /* 65 */
        .ascii  "/         "      /* 66 */
        .ascii  "+         "      /* 67 */
        .ascii  "-         "      /* 68 */
        .ascii  "&         "      /* 69 */
        .ascii  "|         "      /* 70 */
        .ascii  "^         "      /* 71 */
        .ascii  "/EOF/     "      /* 72 */
        .ascii  "----      "      /* 73 */
        .ascii  "<-BAD_CHAR"      /* 74 */

/* cc.m68k 0x040CD2, cc.a88k 0x040F52: the diagnostic number of each
 * of the code generator's codes 0..85 (cgerr; c_globals.ins.pas
 * cerr_code_map). */
        .globl  cerr_code_map
cerr_code_map:
        .word   140, 141, 142, 143, 144, 145, 146, 147   /*  0.. */
        .word   148, 149, 150, 151, 153, 136, 137, 138   /*  8.. */
        .word   139, 154, 134, 135, 133, 159, 170, 171   /* 16.. */
        .word   180, 190, 191, 192, 201, 202, 246, 247   /* 24.. */
        .word   248, 252, 263, 264, 265, 266, 267, 268   /* 32.. */
        .word   269, 270, 271, 272, 273, 274, 275, 278   /* 40.. */
        .word   280, 281, 282, 306, 296, 299, 300, 301   /* 48.. */
        .word   302, 303, 304, 305, 328, 329, 330,   0   /* 56.. */
        .word   223, 224, 225, 226, 227, 228, 229, 230   /* 64.. */
        .word   231, 232, 233, 243, 244, 245, 255, 256   /* 72.. */
        .word   257, 260, 318, 319, 320, 321   /* 80.. */

/* cc.m68k 0x040D7E, cc.a88k 0x040FFE: each diagnostic 1..330, the
 * offset of its text in cerr_texts and its severity (0 a warning, 1
 * fatal, 2 an error, 3..6 information of level 1..4;
 * c_globals.ins.pas cerr_messages). */
        .globl  cerr_messages
cerr_messages:
        .word       0, 1   /*   1 */
        .word      21, 1   /*   2 */
        .word      47, 1   /*   3 */
        .word      77, 1   /*   4 */
        .word      93, 1   /*   5 */
        .word     118, 1   /*   6 */
        .word     177, 2   /*   7 */
        .word     211, 0   /*   8 */
        .word     260, 2   /*   9 */
        .word     303, 2   /*  10 */
        .word     349, 1   /*  11 */
        .word     390, 1   /*  12 */
        .word     453, 0   /*  13 */
        .word     495, 1   /*  14 */
        .word     549, 0   /*  15 */
        .word     587, 1   /*  16 */
        .word     628, 1   /*  17 */
        .word     666, 2   /*  18 */
        .word     714, 0   /*  19 */
        .word     762, 1   /*  20 */
        .word     812, 0   /*  21 */
        .word     873, 0   /*  22 */
        .word     927, 2   /*  23 */
        .word     954, 2   /*  24 */
        .word    1020, 2   /*  25 */
        .word    1069, 2   /*  26 */
        .word    1115, 0   /*  27 */
        .word    1178, 0   /*  28 */
        .word    1215, 0   /*  29 */
        .word    1257, 1   /*  30 */
        .word    1315, 2   /*  31 */
        .word    1369, 2   /*  32 */
        .word    1405, 2   /*  33 */
        .word    1440, 2   /*  34 */
        .word    1479, 3   /*  35 */
        .word    1564, 2   /*  36 */
        .word    1611, 1   /*  37 */
        .word    1642, 1   /*  38 */
        .word    1700, 1   /*  39 */
        .word    1736, 2   /*  40 */
        .word    1817, 1   /*  41 */
        .word    1859, 1   /*  42 */
        .word    1920, 2   /*  43 */
        .word    1969, 2   /*  44 */
        .word    2029, 0   /*  45 */
        .word    2097, 2   /*  46 */
        .word    2155, 1   /*  47 */
        .word    2192, 1   /*  48 */
        .word    2238, 2   /*  49 */
        .word    2274, 1   /*  50 */
        .word    2340, 2   /*  51 */
        .word    2373, 2   /*  52 */
        .word    2441, 2   /*  53 */
        .word    2494, 2   /*  54 */
        .word    2530, 1   /*  55 */
        .word    2576, 2   /*  56 */
        .word    2640, 2   /*  57 */
        .word    2696, 1   /*  58 */
        .word    2764, 2   /*  59 */
        .word    2816, 2   /*  60 */
        .word    2880, 2   /*  61 */
        .word    2901, 2   /*  62 */
        .word    2932, 2   /*  63 */
        .word    2965, 2   /*  64 */
        .word    2994, 2   /*  65 */
        .word    3022, 1   /*  66 */
        .word    3064, 2   /*  67 */
        .word    3126, 2   /*  68 */
        .word    3196, 2   /*  69 */
        .word    3254, 2   /*  70 */
        .word    3306, 2   /*  71 */
        .word    3362, 0   /*  72 */
        .word    3388, 1   /*  73 */
        .word    3417, 1   /*  74 */
        .word    3504, 0   /*  75 */
        .word    3524, 2   /*  76 */
        .word    3551, 2   /*  77 */
        .word    3592, 0   /*  78 */
        .word    3664, 2   /*  79 */
        .word    3712, 0   /*  80 */
        .word    3770, 1   /*  81 */
        .word    3797, 1   /*  82 */
        .word    3823, 1   /*  83 */
        .word    3893, 1   /*  84 */
        .word    3938, 2   /*  85 */
        .word    3985, 1   /*  86 */
        .word    4013, 1   /*  87 */
        .word    4047, 2   /*  88 */
        .word    4095, 0   /*  89 */
        .word    4154, 0   /*  90 */
        .word    4207, 2   /*  91 */
        .word    4238, 1   /*  92 */
        .word    4285, 1   /*  93 */
        .word    4328, 0   /*  94 */
        .word    4384, 2   /*  95 */
        .word    4407, 2   /*  96 */
        .word    4463, 2   /*  97 */
        .word    4491, 1   /*  98 */
        .word    4542, 1   /*  99 */
        .word    4578, 1   /* 100 */
        .word    4615, 1   /* 101 */
        .word    4657, 1   /* 102 */
        .word    4692, 1   /* 103 */
        .word    4734, 1   /* 104 */
        .word    4774, 1   /* 105 */
        .word    4828, 1   /* 106 */
        .word    4881, 1   /* 107 */
        .word    4931, 1   /* 108 */
        .word    4994, 2   /* 109 */
        .word    5028, 1   /* 110 */
        .word    5075, 1   /* 111 */
        .word    5119, 0   /* 112 */
        .word    5174, 0   /* 113 */
        .word    5222, 2   /* 114 */
        .word    5258, 0   /* 115 */
        .word    5320, 1   /* 116 */
        .word    5352, 1   /* 117 */
        .word    5384, 1   /* 118 */
        .word    5417, 1   /* 119 */
        .word    5441, 2   /* 120 */
        .word    5487, 2   /* 121 */
        .word    5529, 0   /* 122 */
        .word    5620, 0   /* 123 */
        .word    5708, 2   /* 124 */
        .word    5745, 2   /* 125 */
        .word    5792, 2   /* 126 */
        .word    5852, 2   /* 127 */
        .word    5918, 2   /* 128 */
        .word    5990, 0   /* 129 */
        .word    6054, 0   /* 130 */
        .word    6122, 0   /* 131 */
        .word    6170, 0   /* 132 */
        .word    6261, 1   /* 133 */
        .word    6314, 1   /* 134 */
        .word    6355, 2   /* 135 */
        .word    6403, 1   /* 136 */
        .word    6442, 1   /* 137 */
        .word    6476, 1   /* 138 */
        .word    6525, 1   /* 139 */
        .word    6565, 1   /* 140 */
        .word    6601, 1   /* 141 */
        .word    6636, 1   /* 142 */
        .word    6668, 1   /* 143 */
        .word    6705, 1   /* 144 */
        .word    6740, 1   /* 145 */
        .word    6771, 1   /* 146 */
        .word    6809, 1   /* 147 */
        .word    6847, 1   /* 148 */
        .word    6886, 1   /* 149 */
        .word    6918, 1   /* 150 */
        .word    6962, 1   /* 151 */
        .word    7000, 2   /* 152 */
        .word    7080, 2   /* 153 */
        .word    7107, 1   /* 154 */
        .word    7140, 0   /* 155 */
        .word    7194, 0   /* 156 */
        .word    7236, 2   /* 157 */
        .word    7278, 2   /* 158 */
        .word    7344, 0   /* 159 */
        .word    7394, 1   /* 160 */
        .word    7446, 1   /* 161 */
        .word    7494, 1   /* 162 */
        .word    7526, 1   /* 163 */
        .word    7564, 1   /* 164 */
        .word    7603, 1   /* 165 */
        .word    7645, 1   /* 166 */
        .word    7688, 1   /* 167 */
        .word    7716, 0   /* 168 */
        .word    7780, 1   /* 169 */
        .word    7808, 0   /* 170 */
        .word    7862, 1   /* 171 */
        .word    7906, 1   /* 172 */
        .word    7950, 0   /* 173 */
        .word    7997, 1   /* 174 */
        .word    8033, 1   /* 175 */
        .word    8063, 2   /* 176 */
        .word    8115, 0   /* 177 */
        .word    8147, 1   /* 178 */
        .word    8189, 2   /* 179 */
        .word    8208, 1   /* 180 */
        .word    8245, 1   /* 181 */
        .word    8320, 2   /* 182 */
        .word    8356, 2   /* 183 */
        .word    8405, 2   /* 184 */
        .word    8432, 2   /* 185 */
        .word    8477, 0   /* 186 */
        .word    8537, 2   /* 187 */
        .word    8628, 2   /* 188 */
        .word    8719, 0   /* 189 */
        .word    8767, 1   /* 190 */
        .word    8849, 1   /* 191 */
        .word    8888, 1   /* 192 */
        .word    8978, 1   /* 193 */
        .word    9012, 1   /* 194 */
        .word    9084, 1   /* 195 */
        .word    9155, 1   /* 196 */
        .word    9222, 0   /* 197 */
        .word    9280, 0   /* 198 */
        .word    9320, 1   /* 199 */
        .word    9389, 1   /* 200 */
        .word    9475, 1   /* 201 */
        .word    9495, 0   /* 202 */
        .word    9566, 1   /* 203 */
        .word    9629, 0   /* 204 */
        .word    9682, 0   /* 205 */
        .word    9733, 0   /* 206 */
        .word    9803, 1   /* 207 */
        .word    9839, 1   /* 208 */
        .word    9923, 1   /* 209 */
        .word    9983, 1   /* 210 */
        .word   10039, 0   /* 211 */
        .word   10077, 0   /* 212 */
        .word   10109, 3   /* 213 */
        .word   10140, 0   /* 214 */
        .word   10178, 1   /* 215 */
        .word   10227, 5   /* 216 */
        .word   10328, 1   /* 217 */
        .word   10376, 2   /* 218 */
        .word   10437, 2   /* 219 */
        .word   10475, 2   /* 220 */
        .word   10533, 0   /* 221 */
        .word   10588, 2   /* 222 */
        .word   10607, 5   /* 223 */
        .word   10667, 2   /* 224 */
        .word   10709, 2   /* 225 */
        .word   10789, 2   /* 226 */
        .word   10827, 2   /* 227 */
        .word   10875, 2   /* 228 */
        .word   10913, 0   /* 229 */
        .word   10977, 2   /* 230 */
        .word   11033, 2   /* 231 */
        .word   11084, 2   /* 232 */
        .word   11132, 0   /* 233 */
        .word   11170, 3   /* 234 */
        .word   11236, 3   /* 235 */
        .word   11282, 0   /* 236 */
        .word   11333, 1   /* 237 */
        .word   11403, 2   /* 238 */
        .word   11437, 3   /* 239 */
        .word   11513, 6   /* 240 */
        .word   11599, 3   /* 241 */
        .word   11651, 0   /* 242 */
        .word   11745, 2   /* 243 */
        .word   11826, 2   /* 244 */
        .word   11877, 2   /* 245 */
        .word   11936, 0   /* 246 */
        .word   11939, 2   /* 247 */
        .word   11942, 1   /* 248 */
        .word   11945, 5   /* 249 */
        .word   12039, 2   /* 250 */
        .word   12074, 2   /* 251 */
        .word   12112, 0   /* 252 */
        .word   12145, 0   /* 253 */
        .word   12165, 0   /* 254 */
        .word   12209, 2   /* 255 */
        .word   12234, 2   /* 256 */
        .word   12260, 0   /* 257 */
        .word   12292, 2   /* 258 */
        .word   12321, 0   /* 259 */
        .word   12371, 6   /* 260 */
        .word   12440, 0   /* 261 */
        .word   12529, 0   /* 262 */
        .word   12606, 2   /* 263 */
        .word   12680, 0   /* 264 */
        .word   12746, 0   /* 265 */
        .word   12799, 6   /* 266 */
        .word   12842, 0   /* 267 */
        .word   12901, 0   /* 268 */
        .word   12976, 0   /* 269 */
        .word   13062, 0   /* 270 */
        .word   13129, 0   /* 271 */
        .word   13181, 0   /* 272 */
        .word   13245, 0   /* 273 */
        .word   13295, 0   /* 274 */
        .word   13347, 0   /* 275 */
        .word   13390, 0   /* 276 */
        .word   13419, 2   /* 277 */
        .word   13452, 0   /* 278 */
        .word   13497, 0   /* 279 */
        .word   13534, 4   /* 280 */
        .word   13578, 2   /* 281 */
        .word   13637, 2   /* 282 */
        .word   13706, 2   /* 283 */
        .word   13731, 2   /* 284 */
        .word   13774, 2   /* 285 */
        .word   13824, 2   /* 286 */
        .word   13847, 2   /* 287 */
        .word   13899, 0   /* 288 */
        .word   13943, 1   /* 289 */
        .word   13971, 2   /* 290 */
        .word   14021, 2   /* 291 */
        .word   14047, 2   /* 292 */
        .word   14113, 2   /* 293 */
        .word   14193, 2   /* 294 */
        .word   14235, 2   /* 295 */
        .word   14271, 6   /* 296 */
        .word   14291, 0   /* 297 */
        .word   14331, 2   /* 298 */
        .word   14375, 0   /* 299 */
        .word   14398, 0   /* 300 */
        .word   14449, 0   /* 301 */
        .word   14521, 0   /* 302 */
        .word   14581, 0   /* 303 */
        .word   14642, 0   /* 304 */
        .word   14708, 0   /* 305 */
        .word   14741, 2   /* 306 */
        .word   14804, 0   /* 307 */
        .word   14875, 0   /* 308 */
        .word   14947, 1   /* 309 */
        .word   14998, 0   /* 310 */
        .word   15041, 2   /* 311 */
        .word   15088, 2   /* 312 */
        .word   15118, 2   /* 313 */
        .word   15165, 2   /* 314 */
        .word   15219, 2   /* 315 */
        .word   15266, 2   /* 316 */
        .word   15316, 0   /* 317 */
        .word   15350, 2   /* 318 */
        .word   15381, 2   /* 319 */
        .word   15461, 2   /* 320 */
        .word   15546, 2   /* 321 */
        .word   15626, 2   /* 322 */
        .word   15677, 2   /* 323 */
        .word   15723, 2   /* 324 */
        .word   15796, 2   /* 325 */
        .word   15874, 2   /* 326 */
        .word   15923, 2   /* 327 */
        .word   15957, 0   /* 328 */
        .word   16024, 4   /* 329 */
        .word   16084, 4   /* 330 */

/* cc.m68k 0x0412A6, cc.a88k 0x041526: the texts, each ended by '.'
 * (errorlst: '_' a blank, '@n' the n-th argument, '@L' '[', '@R' ']',
 * '&n' the n-th argument's line), in the order of their offsets, each
 * after the numbers of the diagnostics that use it; a NUL after the
 * last (c_globals.ins.pas cerr_texts). */
        .globl  cerr_texts
cerr_texts:
/* 1 */
        .ascii  "Unterminated comment."
/* 2 */
        .ascii  "Improper numeric constant."
/* 3 */
        .ascii  "Unterminated character string."
/* 4 */
        .ascii  "Bad syntax \"@1\"."
/* 5 */
        .ascii  "Illegal module name \"@1\"."
/* 6 */
        .ascii  "Quoted string is too long; maximum size is 4095 characters."
/* 7 */
        .ascii  "-DEF option has no name to define."
/* 8 */
        .ascii  "Old-fashioned assignment operator; taken_as_\"@1\"."
/* 9 */
        .ascii  "\"void\" is illegal for \"@1\" in this context."
/* 10 */
        .ascii  "Cannot define name \"@1\", given as -DEF option."
/* 11 */
        .ascii  "Missing right parenthesis on declaration."
/* 12 */
        .ascii  "Storage class \"@1\" is illegal in this context; default assum"
        .ascii  "ed."
/* 13 */
        .ascii  "Old-fashioned initialization; missing \"=\"."
/* 14 */
        .ascii  "Unrecognizable item \"@1\"; syntax error in declaration."
/* 15 */
        .ascii  "When allocated, size of \"@1\" was zero."
/* 16 */
        .ascii  "Improper enumerated constant syntax_\"@1\"."
/* 17 */
        .ascii  "OF expected in SET specification \"@1\"."
/* 18 */
        .ascii  "Array dimension \"@1\" is not an integer constant."
/* 19 */
        .ascii  "Array dimension \"@1\" is either zero or negative."
/* 20 */
        .ascii  "Too many enumerators for \"enum\" type; max is 1024."
/* 21 */
        .ascii  "\"long\" or \"short\" in this context is meaningless and ignored"
        .ascii  "."
/* 22 */
        .ascii  "\"unsigned\" in this context is meaningless and ignored."
/* 23 */
        .ascii  "\"@1\" has not been declared."
/* 24 */
        .ascii  "Multiple declaration of \"@1\", previous declaration was on li"
        .ascii  "ne_&2."
/* 25 */
        .ascii  "Type specifier list is invalid starting at: \"@1\"."
/* 26 */
        .ascii  "Illegal type of constant \"@1\" for \"enum\" type."
/* 27 */
        .ascii  "Improper use of \"void\" type for function; (\"int\" type assume"
        .ascii  "d)."
/* 28 */
        .ascii  "\"enum\" constant \"@1\" exceeds 16 bits."
/* 29 */
        .ascii  "Parameters are illegal (and ignored) here."
/* 30 */
        .ascii  "Parameter \"@1\" was not listed in the function declaration."
/* 31 */
        .ascii  "Dynamic aggregate variable \"@1\" cannot be initialized."
/* 32 */
        .ascii  "Base type \"@1\" of set is not scalar."
/* 33 */
        .ascii  "Set elements must be positive \"@1\"."
/* 34 */
        .ascii  "Set exceeds limit of 512 elements \"@1\"."
/* 35 */
        .ascii  "In function \"@1\", parameter \"@2\" was listed but never declar"
        .ascii  "ed; (\"int\" type assumed)."
/* 36 */
        .ascii  "Multiple declaration of \"@1\" in parameter_list."
/* 37 */
        .ascii  "Cannot assign \"void\" from \"@1\"."
/* 38 */
        .ascii  "Label \"@1\" on line_&2 is outside of the scope of the goto."
/* 39 */
        .ascii  "Improper parameter declaration_\"@1\"."
/* 40 */
        .ascii  "\"@1\" et cetera is not an 'lvalue' and therefore is illegal f"
        .ascii  "or the \"@2\" operator."
/* 41 */
        .ascii  "Unknown type \"@1\" in a structure or union."
/* 42 */
        .ascii  "Function declaration \"@1\" is illegal in a structure or union"
        .ascii  "."
/* 43 */
        .ascii  "\"switch\" expression type is not an integral type."
/* 44 */
        .ascii  "\"@1\" is not of the correct type for the \"switch\" on line_&2."
/* 45 */
        .ascii  "\"switch\" expression type is unsigned, but constant \"@1\" is n"
        .ascii  "egative."
/* 46 */
        .ascii  "\"@1\" has already occurred as a \"case\" constant on line_&2."
/* 47 */
        .ascii  "\"@1\" is not a valid option specifier."
/* 48 */
        .ascii  "Include file name is not a string; found \"@1\"."
/* 49 */
        .ascii  "Nested includes are too deep (> 16)."
/* 50 */
        .ascii  "\"@1\" is not a recognized option, or it does not begin in col"
        .ascii  "umn 1."
/* 51 */
        .ascii  "Include file @1 is not available."
/* 52 */
        .ascii  "\"@1\" is declared as a constant name, and cannot be assigned "
        .ascii  "a value."
/* 53 */
        .ascii  "Multiple declaration of \"@1\" in a structure or union."
/* 54 */
        .ascii  "Array bound type is not scalar \"@1\"."
/* 55 */
        .ascii  "Bad syntax in a struct/union/enum; \"@1\" found."
/* 56 */
        .ascii  "Multiple definition of \"@1\", previous definition was on line"
        .ascii  "_&2."
/* 57 */
        .ascii  "Improper usage of \"@1\", only a label name is valid here."
/* 58 */
        .ascii  "Bad syntax in a struct/union/enum; \"@1\" found; assuming end "
        .ascii  "of list."
/* 59 */
        .ascii  "Improper use of \"@1\", only a variable is valid here."
/* 60 */
        .ascii  "Improper use of \"@1\", only a variable or constant is valid h"
        .ascii  "ere."
/* 61 */
        .ascii  "\"@1\" is not an array."
/* 62 */
        .ascii  "\"@1\" is not a pointer variable."
/* 63 */
        .ascii  "\"@1\" is not a structure or union."
/* 64 */
        .ascii  "\"@1\" is not a member of \"@2\"."
/* 65 */
        .ascii  "Too many subscripts to \"@1\"."
/* 66 */
        .ascii  "Bit field constant \"@1\" is not an integer."
/* 67 */
        .ascii  "Improper use of \"@1\", only a function reference is valid her"
        .ascii  "e."
/* 68 */
        .ascii  "The types of [@1] and [@2] are not compatible with  the \"@3\""
        .ascii  "_operator."
/* 69 */
        .ascii  "The type of [@1] is not compatible with the \"@2\"_operator."
/* 70 */
        .ascii  "Incompatible operands [@1, @2] to the \"@3\" operator."
/* 71 */
        .ascii  "Subscript [@1] to array \"@2\" is not of the correct type."
/* 72 */
        .ascii  "No path to statement \"@1\"."
/* 73 */
        .ascii  "No declaration for type \"@1\"."
/* 74 */
        .ascii  "Function \"@1\" may not be defined inside another function; (\""
        .ascii  "@2\" begins the definition)."
/* 75 */
        .ascii  "sizeof \"@1\" is zero."
/* 76 */
        .ascii  "Illegal cast type for \"@1\"."
/* 77 */
        .ascii  "Cannot initialize external variable \"@1\"."
/* 78 */
        .ascii  "Incompatible pointer and integer operands [@1, @2] to the \"@"
        .ascii  "3\" operator."
/* 79 */
        .ascii  "Illegal type of constant \"@1\" for variable \"@2\"."
/* 80 */
        .ascii  "Illegal pointer combination with \"@1\": incompatible types."
/* 81 */
        .ascii  "Too many arguments to \"@1\"."
/* 82 */
        .ascii  "Too few arguments to \"@1\"."
/* 83 */
        .ascii  "Argument @1 to \"@2\" is not compatible with the declared argu"
        .ascii  "ment type."
/* 84 */
        .ascii  "Named bit field \"@1\" cannot have a size of 0."
/* 85 */
        .ascii  "Constant value \"@1\" is illegal for a bit field."
/* 86 */
        .ascii  "Unrecognized statement \"@1\"."
/* 87 */
        .ascii  "\"goto\" label expected; \"@1\" found."
/* 88 */
        .ascii  "\"@1\" statement is not within an iterative group."
/* 89 */
        .ascii  "Non-standard usage: partial member reference \"@1\" resolved."
/* 90 */
        .ascii  "Ambiguous reference; more than one member named \"@1\"."
/* 91 */
        .ascii  "Illegal type for bit field \"X\"."
/* 92 */
        .ascii  "Address operator is illegal for bit field \"@1\"."
/* 93 */
        .ascii  "Input line too long; it has been truncated."
/* 94 */
        .ascii  "Negative shift constant \"@1\" may give undefined results."
/* 95 */
        .ascii  "Too many include files."
/* 96 */
        .ascii  "Constant value \"@1\" cannot be evaluated at compile time."
/* 97 */
        .ascii  "Label \"@1\" is never defined."
/* 98 */
        .ascii  "Line exceeds maximum length of @1 by @2 characters."
/* 99 */
        .ascii  "Left brace ({) expected; \"@1\" found."
/* 100 */
        .ascii  "Right brace (}) expected; \"@1\" found."
/* 101 */
        .ascii  "Statement terminator expected; \"@1\" found."
/* 102 */
        .ascii  "Improper argument list; \"@1\" found."
/* 103 */
        .ascii  "\"@1\" expr must begin with \"(\"; \"@2\" found."
/* 104 */
        .ascii  "\"@1\" expr must end with \")\"; \"@2\" found."
/* 105 */
        .ascii  "Colon (:) expected in \"case\" or \"default\"; \"@1\" found."
/* 106 */
        .ascii  "\"case\" or \"default\" expected in \"switch\"; \"@1\" found."
/* 107 */
        .ascii  "More than one \"default\" case given for a \"switch\"."
/* 108 */
        .ascii  "Illegal return expression (\"@1\" et cetera) for \"void\" functi"
        .ascii  "on."
/* 109 */
        .ascii  "Cannot initialize null array \"@1\"."
/* 110 */
        .ascii  "\"while\" expected in \"do\" statement; \"@1\" found."
/* 111 */
        .ascii  "\";\" expected in \"for\" statement; \"@1\" found."
/* 112 */
        .ascii  "String initializer too long for \"@1\"; truncated to fit."
/* 113 */
        .ascii  "Structure or union member \"@1\" has size of zero."
/* 114 */
        .ascii  "<temp_alloc> size too big for stack."
/* 115 */
        .ascii  "Attempting to access object \"@1\" outside of its address rang"
        .ascii  "e."
/* 116 */
        .ascii  "Improper expression; \"@1\" found."
/* 117 */
        .ascii  "Identifier expected; \"@1\" found."
/* 118 */
        .ascii  "Member name expected; \"@1\" found."
/* 119 */
        .ascii  "Improper subscript_[@1]."
/* 120 */
        .ascii  "Illegal operation on pointer to function \"@1\"."
/* 121 */
        .ascii  "Function \"@1\" returns more than 32K bytes."
/* 122 */
        .ascii  "Function \"@1\" needs @2 bytes of stack, which approaches the "
        .ascii  "maximum stack size of @3 bytes."
/* 123 */
        .ascii  "Function \"@1\" needs @2 bytes of stack, which exceeds the max"
        .ascii  "imum stack size of @3 bytes."
/* 124 */
        .ascii  "Cannot add two pointers: \"@1\" + \"@2\"."
/* 125 */
        .ascii  "Illegal type of \"@1\" for addition to a pointer."
/* 126 */
        .ascii  "Cannot subtract two pointers of different type: \"@1\" - \"@2\"."
/* 127 */
        .ascii  "Either \"@1\" is not a pointer type, or \"@2\" is not an integer"
        .ascii  " type."
/* 128 */
        .ascii  "\"main\" function cannot return a type whose size is greater t"
        .ascii  "han 4 bytes."
/* 129 */
        .ascii  "Ignoring data initialization for \"switch\" variable declarati"
        .ascii  "ons."
/* 130 */
        .ascii  "Skipping useless statement(s) \"@1\" before first \"case\" or \"d"
        .ascii  "efault\"."
/* 131 */
        .ascii  "Address of register variable \"@1\" was requested."
/* 132 */
        .ascii  "Multiple declaration of \"@1\" with data initialization, previ"
        .ascii  "ous declaration was on line_&2."
/* 133 */
        .ascii  "Compiler failure, unexpected data init construct: @1."
/* 134 */
        .ascii  "Compiler failure, Pascal-only error code."
/* 135 */
        .ascii  "Floating point constant \"@1\" conversion problem."
/* 136 */
        .ascii  "Compiler failure, register consistency."
/* 137 */
        .ascii  "Compiler failure, no temp created."
/* 138 */
        .ascii  "Compiler failure, improper forward label at \"@1\"."
/* 139 */
        .ascii  "Compiler failure, pseudo pc consistency."
/* 140 */
        .ascii  "Compiler failure, unknown tree node."
/* 141 */
        .ascii  "Compiler failure, unknown top node."
/* 142 */
        .ascii  "Compiler failure, no temp space."
/* 143 */
        .ascii  "Compiler failure, lost value of node."
/* 144 */
        .ascii  "Compiler failure, registers locked."
/* 145 */
        .ascii  "Compiler failure, no emit inst."
/* 146 */
        .ascii  "Compiler failure, procedure too large."
/* 147 */
        .ascii  "Compiler failure, inst disp too large."
/* 148 */
        .ascii  "Compiler failure, obj module too large."
/* 149 */
        .ascii  "Compiler failure, no free space."
/* 150 */
        .ascii  "Compiler failure, short branch optimization."
/* 151 */
        .ascii  "Compiler failure, data frame overflow."
/* 152 */
        .ascii  "External variable definition \"@1\" conflicts with procedure o"
        .ascii  "r data section name."
/* 153 */
        .ascii  "Duplicate global name \"@1\"."
/* 154 */
        .ascii  "Compiler failure, too many nodes."
/* 155 */
        .ascii  "Constant subscript \"@1\" to array_\"@2\" is out of range."
/* 156 */
        .ascii  "Directive must be contained in a function."
/* 157 */
        .ascii  "Dividing by zero in a constant expression."
/* 158 */
        .ascii  "Size of a function is undeterminable (but usually, it's too "
        .ascii  "big!)."
/* 159 */
        .ascii  "Variable \"@1\" was not initialized before this use."
/* 160 */
        .ascii  "Illegal bit field constant \"@1\"; cannot be negative."
/* 161 */
        .ascii  "Unknown or incomplete structure/union type \"@1\"."
/* 162 */
        .ascii  "Illegal option \"@1\" for typedef."
/* 163 */
        .ascii  "Left bracket ([) expected; \"@1\" found."
/* 164 */
        .ascii  "Right bracket (]) expected; \"@1\" found."
/* 165 */
        .ascii  "Left parenthesis \"(\" expected; \"@1\" found."
/* 166 */
        .ascii  "Right parenthesis \")\" expected; \"@1\" found."
/* 167 */
        .ascii  "Number expected; \"@1\" found."
/* 168 */
        .ascii  "New line number @1 ignored; it cannot be lower than the curr"
        .ascii  "ent."
/* 169 */
        .ascii  "String expected; \"@1\" found."
/* 170 */
        .ascii  "Dividing by zero in a compiletime constant expression."
/* 171 */
        .ascii  "Compiler failure, store elimination failure."
/* 172 */
        .ascii  "No static address for dynamic variable \"@1\"."
/* 173 */
        .ascii  "Comma expected but not found in data init list."
/* 174 */
        .ascii  "Empty or 0-sized structure or union."
/* 175 */
        .ascii  "Unknown type name in \"sizeof\"."
/* 176 */
        .ascii  "Too many nested pointer references for debug tables."
/* 177 */
        .ascii  "8 or 9 found in an octal number."
/* 178 */
        .ascii  "Null dimension in a sub-array declaration."
/* 179 */
        .ascii  "Invalid systype @1."
/* 180 */
        .ascii  "Compiler failure, limit exceeded; @1."
/* 181 */
        .ascii  "Cannot take the address of \"@1\" by dereferencing a pointer a"
        .ascii  "t compile time."
/* 182 */
        .ascii  "Cannot give more than one \"systype\"."
/* 183 */
        .ascii  "Cannot take \"systype\" once other tokens are seen."
/* 184 */
        .ascii  "Comma expected, \"@1\" found."
/* 185 */
        .ascii  "Found \"end-of-line\" before end of definition."
/* 186 */
        .ascii  "Redundant #module or HP@_MODULE control line found; ignored."
/* 187 */
        .ascii  "Procedure section name conflicts with a previously defined d"
        .ascii  "ata section name or identifier."
/* 188 */
        .ascii  "Data section name conflicts with a previously defined proced"
        .ascii  "ure section name or identifier."
/* 189 */
        .ascii  "Extraneous data at end of control line; ignored."
/* 190 */
        .ascii  "Compiler failure, invalid use of multiple sections and non-l"
        .ascii  "ocal goto to label @1."
/* 191 */
        .ascii  "Compiler failure, bad address constant."
/* 192 */
        .ascii  "Compiler failure, invalid use of multiple sections and up-le"
        .ascii  "vel referencing in routine @1."
/* 193 */
        .ascii  "Illegal option \"@1\" for parameter."
/* 194 */
        .ascii  "Data section name conflicts with a previously defined extern"
        .ascii  "al variable."
/* 195 */
        .ascii  "Cannot take #module or HP@_MODULE directive once other token"
        .ascii  "s are seen."
/* 196 */
        .ascii  "#section or HP@_SECTION directive may not appear within a fu"
        .ascii  "nction."
/* 197 */
        .ascii  "Identifier exceeds 32 characters, only \"@1\" is recognized."
/* 198 */
        .ascii  "Type of \"@1\" is illegal for member \"@2\"."
/* 199 */
        .ascii  "Non-unique member \"@1\" requires struct/union or struct/union"
        .ascii  " pointer."
/* 200 */
        .ascii  "Illegal return type for function \"@1\"; functions must return"
        .ascii  " either an lvalue or void."
/* 201 */
        .ascii  "Internal error - @1."
/* 202 */
        .ascii  "Value assigned to @1 is never used; assignment eliminated by"
        .ascii  " optimizer."
/* 203 */
        .ascii  "Illegal declaration of \"@1\"; cannot have an array of functio"
        .ascii  "ns."
/* 204 */
        .ascii  "Wrong size for enum \"@1\"; original size \"@2\" assumed."
/* 205 */
        .ascii  "Enumeration type clash [@1, @2] to the @3 operator."
/* 206 */
        .ascii  "Address of array or function in this context is redundant an"
        .ascii  "d ignored."
/* 207 */
        .ascii  "Illegal type \"void\" for argument @1."
/* 208 */
        .ascii  "Illegal use of \"void\" in a function prototype; void must be "
        .ascii  "the only type specified."
/* 209 */
        .ascii  "No parameters may follow \"ellipsis\" in a function prototype."
/* 210 */
        .ascii  "Exceeded maximum number of allowable parameters ( > 64)."
/* 211 */
        .ascii  "Parameter @1 mismatch - \"@2\" and \"@3\"."
/* 212 */
        .ascii  "Different numbers of parameters."
/* 213 */
        .ascii  "No prototype for function \"@1\"."
/* 214 */
        .ascii  "Cannot dereference \"pointer to void\" ."
/* 215 */
        .ascii  "Missing parameter name for argument \"@1\" of \"@2\"."
/* 216 */
        .ascii  "Although argument @1 to \"@2\" is assignment compatible, it do"
        .ascii  "es not match the declared argument type. "
/* 217 */
        .ascii  "Invalid #options or @_@_options specifier, \"@1\"."
/* 218 */
        .ascii  "Illegal declaration of \"@1\"; array of references not allowed"
        .ascii  "."
/* 219 */
        .ascii  "Uninitialized reference variable \"@1\"."
/* 220 */
        .ascii  "Global or static reference variable \"@1\"; not implemented."
/* 221 */
        .ascii  "Argument @1 - incompatible integer/pointer combination."
/* 222 */
        .ascii  "Invalid runtype @1."
/* 223 */
        .ascii  "Unnaturally aligned load/store \"@1\" diminishes code quality."
/* 224 */
        .ascii  "Compiler failure, no case for object type."
/* 225 */
        .ascii  "Argument to \"@1\" attribute conflicts with value already spec"
        .ascii  "ified for this type."
/* 226 */
        .ascii  "Maximum specifiable alignment is \"@1\"."
/* 227 */
        .ascii  "Size of \"@1\" bits is invalid for specified type."
/* 228 */
        .ascii  "Structured types may not be UNALIGNED."
/* 229 */
        .ascii  "Specified \"@1\" attribute conflicts with attributes of base t"
        .ascii  "ype."
/* 230 */
        .ascii  "\"@1\" attribute is inappropriate for target machine type."
/* 231 */
        .ascii  "\"@1\" and \"@2\" attributes may not both be specified."
/* 232 */
        .ascii  "PHYSICAL attribute specified without an ADDRESS."
/* 233 */
        .ascii  "\"@1\" is inappropriate in this context."
/* 234 */
        .ascii  "Actual alignment of \"@1\" (@2) is less than natural alignment"
        .ascii  " (@3)."
/* 235 */
        .ascii  "Large bit field \"@1\" not on longword boundary."
/* 236 */
        .ascii  "Invalid section attribute for static var - ignored."
/* 237 */
        .ascii  "This section name conflicts with a previously defined global"
        .ascii  " variable."
/* 238 */
        .ascii  "Bit field constant \"@1\" too large."
/* 239 */
        .ascii  "Actual alignment of array elements (@1) is less than natural"
        .ascii  " alignment (@2)."
/* 240 */
        .ascii  "Alignment of array elements is dependent on the current defa"
        .ascii  "ult alignment environment."
/* 241 */
        .ascii  "Size of array element rounded up from @1 to @2 bits."
/* 242 */
        .ascii  "Conversion of \"@1\" to pointer of stricter alignment can caus"
        .ascii  "e serious performance degradation."
/* 243 */
        .ascii  "All NO_MODIFY registers of enclosing block must also be NO_M"
        .ascii  "ODIFY in inner block."
/* 244 */
        .ascii  "Illegal @1 register number (@2) for parameter (@3)."
/* 245 */
        .ascii  "Size of parameter (@1) is too large for specified register."
/* 246 */
        .ascii  "@1."
/* 247 */
        .ascii  "@1."
/* 248 */
        .ascii  "@1."
/* 249 */
        .ascii  "Conversion of \"@1\" to pointer of stricter alignment can caus"
        .ascii  "e serious performance degradation."
/* 250 */
        .ascii  "Illegal operation for void *  \"@1\"."
/* 251 */
        .ascii  "Illegal use of a void type expression."
/* 252 */
        .ascii  "No path exists to this statement."
/* 253 */
        .ascii  "Unrecognized pragma."
/* 254 */
        .ascii  "Invalid token. Continuing by inserting \"@1\"."
/* 255 */
        .ascii  "Alignment stack overflow."
/* 256 */
        .ascii  "Alignment stack underflow."
/* 257 */
        .ascii  "Unmatched push_alignment pragma."
/* 258 */
        .ascii  "Multiple declaration of \"@1\"."
/* 259 */
        .ascii  "\"@1\" is a predefined macro - redefinition ignored."
/* 260 */
        .ascii  "Size of record is @1 in word and @2 in natural alignment env"
        .ascii  "ironment."
/* 261 */
        .ascii  "Span between elements of array (@1 bytes) does not match siz"
        .ascii  "e of base type @2 (@3 bytes)."
/* 262 */
        .ascii  "Sizeof of *pointer (@1 bytes) not equal to sizeof type point"
        .ascii  "ed to (@2 bytes)."
/* 263 */
        .ascii  "Reference outside of bounds of array @1 also falls outside o"
        .ascii  "f stack frame."
/* 264 */
        .ascii  "Routine not expanded INLINE at call site (indefinite cause):"
        .ascii  " \"@1\"."
/* 265 */
        .ascii  "Routine not expanded INLINE (indefinite cause): \"@1\"."
/* 266 */
        .ascii  "Routine expanded INLINE at call site: \"@1\"."
/* 267 */
        .ascii  "Routine not expanded INLINE at call site (recursion): \"@1\"."
/* 268 */
        .ascii  "Routine not expanded INLINE at call site (caller + callee to"
        .ascii  "o large): \"@1\"."
/* 269 */
        .ascii  "Routine not expanded INLINE at call site (callee contains un"
        .ascii  "expanded procedure): \"@1\"."
/* 270 */
        .ascii  "Routine not expanded INLINE at call site (parameter is proc)"
        .ascii  ": \"@1\"."
/* 271 */
        .ascii  "Routine not expanded INLINE (alternate entry): \"@1\"."
/* 272 */
        .ascii  "Routine not expanded INLINE at call site (psect mismatch): \""
        .ascii  "@1\"."
/* 273 */
        .ascii  "Routine not expanded INLINE (file variable): \"@1\"."
/* 274 */
        .ascii  "Routine not expanded INLINE (record variable): \"@1\"."
/* 275 */
        .ascii  "Routine not referenced, code deleted: \"@1\"."
/* 276 */
        .ascii  "Illegal use of inline pragma."
/* 277 */
        .ascii  "Illegal assignment to const \"@1\"."
/* 278 */
        .ascii  "Routine not expanded INLINE (namelist): \"@1\"."
/* 279 */
        .ascii  "Illegal conversion from const * \"@1\"."
/* 280 */
        .ascii  "Giving variable static data semantics: \"@1\"."
/* 281 */
        .ascii  "Unable to convert floating point constant to integer: \"@1\"."
/* 282 */
        .ascii  "Call passes argument block of @1 bytes (implementation limit"
        .ascii  " is 2K )."
/* 283 */
        .ascii  "Illegal use of std_$call."
/* 284 */
        .ascii  "Internal error - unknown kind in type tree."
/* 285 */
        .ascii  "Internal error - bad type in incomplete type list."
/* 286 */
        .ascii  "0 or unknown size - @1."
/* 287 */
        .ascii  "Internal error - bad token for string concatenation."
/* 288 */
        .ascii  "Value (@1) too large for character constant."
/* 289 */
        .ascii  "Invalid multibyte character."
/* 290 */
        .ascii  "Internal error - var_name to remove not in lnktbl."
/* 291 */
        .ascii  "Invalid compilesystype @1."
/* 292 */
        .ascii  "Argument to -cpp option, @1, does not exist or cannot be acc"
        .ascii  "essed."
/* 293 */
        .ascii  "Dereferencing of a pointer to the undefined struct or union "
        .ascii  "\"@1\" is not allowed."
/* 294 */
        .ascii  "Internal Error - wrong kind for attribute."
/* 295 */
        .ascii  "Internal Error - expecting addr_con."
/* 296 */
        .ascii  "Loop was vectorized."
/* 297 */
        .ascii  "Illegal conversion from volatile * \"@1\"."
/* 298 */
        .ascii  "Internal error - bad type ptr for promotion."
/* 299 */
        .ascii  "Loop structure deleted."
/* 300 */
        .ascii  "Expression will fault at runtime -- divide by zero."
/* 301 */
        .ascii  "Expression will fault at runtime -- argument is outside func"
        .ascii  "tion domain."
/* 302 */
        .ascii  "Expression will fault at runtime -- floating-point overflow."
/* 303 */
        .ascii  "Expression will fault at runtime -- floating-point underflow"
        .ascii  "."
/* 304 */
        .ascii  "Expression will fault at runtime -- negative to non-integer "
        .ascii  "power."
/* 305 */
        .ascii  "Can't call BLOCK DATA subprogram."
/* 306 */
        .ascii  "References to atomic/volatile objects must be properly align"
        .ascii  "ed."
/* 307 */
        .ascii  "std@_$call is obsolete -- it may go away at the next compile"
        .ascii  "r release. "
/* 308 */
        .ascii  "/usr/apollo/lib/cpp not found;  defaulting to old non-ANSI p"
        .ascii  "reprocessor."
/* 309 */
        .ascii  "Preprocessor found errors;  compilation terminated."
/* 310 */
        .ascii  "HP_STANDARD pragma expects an integer 0-31."
/* 311 */
        .ascii  "Internal error - unknown result of add_pn \"@1\"."
/* 312 */
        .ascii  "Illegal option to pragma (@1)."
/* 313 */
        .ascii  "Wrong number of arguments for builtin function."
/* 314 */
        .ascii  "FORCED ALIGNMENT argument must be a struct/union type."
/* 315 */
        .ascii  "FORCED ALIGNMENT argument must be a power of 2."
/* 316 */
        .ascii  "FORCED ALIGNMENT argument must increase alignment."
/* 317 */
        .ascii  "Enum doesn't fit in this bitfield."
/* 318 */
        .ascii  "\"@1\" is an illegal @2 register."
/* 319 */
        .ascii  "Target restriction -- @1 is restricted to objects that are m"
        .ascii  "ultiples of @2 bits."
/* 320 */
        .ascii  "Target restriction -- @1 when applied to arrays must have an"
        .ascii  " element size of @2 bits."
/* 321 */
        .ascii  "Target restriction -- @1 is restricted to objects that are a"
        .ascii  "t least aligned(@2)."
/* 322 */
        .ascii  "'options' and 'attribute' are not supported at OSF."
/* 323 */
        .ascii  "Reference parameters are not supported at OSF."
/* 324 */
        .ascii  "Network license system has problems -- contact your system a"
        .ascii  "dministrator."
/* 325 */
        .ascii  "Could not get a license for this compile -- contact your sys"
        .ascii  "tem administrator."
/* 326 */
        .ascii  "Comma followed by a closing paren was unexpected."
/* 327 */
        .ascii  "std@_$call is no longer supported."
/* 328 */
        .ascii  "Expression result undefined at runtime -- shift by negative "
        .ascii  "amount."
/* 329 */
        .ascii  "Variable \"@1\" may not have been initialized before this use."
/* 330 */
        .ascii  "Routine expects an array, is passed scalar variable \"@1\"."
        .byte   0
