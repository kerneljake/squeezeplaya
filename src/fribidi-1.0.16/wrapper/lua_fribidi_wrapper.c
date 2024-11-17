#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <fribidi.h>
#include <string.h>

#define MAX_STR_LEN 1024

// wrapper function to reorder bidirectional text using fribidi
static int lua_fribidi_log2vis(lua_State *L) {
    const char *input_text = luaL_checkstring(L, 1);
    char input_buf[MAX_STR_LEN];
    FriBidiChar logical[MAX_STR_LEN];
    FriBidiChar visual[MAX_STR_LEN];
    char output_string[MAX_STR_LEN];
    const int charset_utf8 = fribidi_parse_charset("UTF-8");
    FriBidiParType base_direction = FRIBIDI_PAR_ON; // let the library figure it out

    (void) strncpy(input_buf, input_text, MAX_STR_LEN-1);
    input_buf[MAX_STR_LEN-1] = '\0';
    const int input_length = strlen(input_buf);

    // get logical representation
    const int len = fribidi_charset_to_unicode(charset_utf8, input_text, input_length, logical);

    // get visual representation
    if(!fribidi_log2vis(/*input*/  logical, len, &base_direction,
                        /*output*/ visual, NULL, NULL, NULL))
    {
        lua_pushnil(L);
        lua_pushstring(L, "Error processing text");
        return 2;
    }

    // return reordered text
    fribidi_unicode_to_charset(charset_utf8, visual, len, output_string);
    lua_pushstring(L, output_string);
    return 1;
}

luaL_Reg fribidi_funcs[] = {
    {"log2vis", lua_fribidi_log2vis},
    {NULL, NULL}
};

LUALIB_API int luaopen_fribidi(lua_State *L)
{
    luaL_register(L, "fribidi", fribidi_funcs);
    return 1;
}
