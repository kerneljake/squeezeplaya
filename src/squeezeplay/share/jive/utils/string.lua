-----------------------------------------------------------------------------
-- strings.lua
-----------------------------------------------------------------------------

--[[
=head1 NAME

jive.util.string - string utilities

=head1 DESCRIPTION

Assorted utility functions for strings

Builds on Lua's built-in string.* class 

=head1 SYNOPSIS

 -- trim a string at the first 0x00
 local trimmed = jive.util.strings.trim(some_string)

=head1 FUNCTIONS

=cut
--]]


local tonumber, setmetatable = tonumber, setmetatable
local table  = require('jive.utils.table')
local ltable = require("string")
local utf8   = require("lua-utf8")

module(...)

-- this is the bit that does the extension.
setmetatable(_M, { __index = ltable })

--[[

=head2 str2hex(s)

Returns a string where each char of s is replaced by its ASCII hex value.

=cut
--]]
function str2hex(s)
	local s_hex = ""
	ltable.gsub(
			s,
			"(.)",
			function (c)
				s_hex = s_hex .. ltable.format("%02X ",ltable.byte(c)) 
			end)
	return s_hex
end


--[[

=head2 trim(s)

Returns s trimmed down at the first 0x00 found.

=cut
--]]
function trim(s)
	local b, e = ltable.find(s, "%z")
	if b then
		return s:sub(1, b-1)
	else
		return s
	end
end

--[[

=head2 split(inSplitPattern, myString, returnTable)

Takes a string pattern and string as arguments, and an optional third argument of a returnTable

Splits myString on inSplitPattern and returns elements in returnTable (appending to returnTable if returnTable is given)

=cut
--]]

function split(inSplitPattern, myString, returnTable)
	if not returnTable then
		returnTable = {}
	end
	local theStart = 1

	if inSplitPattern == '' then
		local length = ltable.len(myString)
		for i=1,length do
			table.insert(returnTable, ltable.sub(myString, i, i) )
		end
	else
		local theSplitStart, theSplitEnd = ltable.find(myString, inSplitPattern, theStart)
		while theSplitStart do
			table.insert(returnTable, ltable.sub(myString, theStart, theSplitStart-1))
			theStart = theSplitEnd + 1
			theSplitStart, theSplitEnd = ltable.find(myString, inSplitPattern, theStart)
		end
		table.insert(returnTable, ltable.sub(myString, theStart))
	end
	return returnTable
end

--[[

=head2 matchLiteral(s, pattern [, init])

Identical to Lua's string.match() method, but escapes all special characters in the substring first

Looks for the first match of pattern in the string s. 

If it finds one, then matchLiteral returns the captures from the pattern; otherwise it returns nil. 

If pattern specifies no captures, then the whole match is returned. 

A third, optional numerical argument init specifies where to start the search; its default value is 1 and can be negative. 

=cut
--]]

function matchLiteral(s, pattern, init)
	-- first escape all special characters in pattern
	local escapedPattern = ltable.gsub(pattern, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
	return ltable.match(s, escapedPattern, init)
 
end

--[[

=head2 urlDecode(s)

Decodes a URL-encoded string

=cut
==]]

function urlDecode (str)
	str = ltable.gsub(str, "+", " ")
	str = ltable.gsub(str, "%%(%x%x)", 
		function(h) 
			return ltable.char(tonumber(h,16)) 
		end
	)
	str = ltable.gsub (str, "\r\n", "\n")
	return str
end


--[[

=head2 urlEncode(s)

Takes a string as an arg and returns an encoded URL-encoded string

=cut
==]]

function urlEncode (str)
	str = ltable.gsub(str, "\n", "\r\n")
	str = ltable.gsub(str, "([^0-9a-zA-Z ])",
		function(c) 
			return ltable.format("%%%02X", ltable.byte(c)) 
		end
	)
	str = ltable.gsub(str, " ", "+")
	return str
end

--[[

=head2 flip_rtl(s)

flips a string to RTL if UTF-8 Right To Left codepoints detected
otherwise, returns original LTR string
also handles simple bidirectional cases

When called, the string will have an in-memory representation like this:
ABC (DEF) GH (1234)
Reversing the string naïvely would result in:
)4321( HG )FED( CBA
The algorithm attempts to reverse the string in a manner that makes sense to a native speaker:
(1234) HG (FED) CBA

Note: consecutive whitespace characters are normalized into a single space.

=cut
--]]

function flip_rtl(s)

    local utf8len = utf8.len(s)
    if not utf8len then
        return s -- bogus input
    end

    local MIN_RTL_CODEPOINT = 0x0590
    local function is_rtl_codepoint(codepoint)
        return (codepoint >= 0x0590 and codepoint <= 0x05FF) or   -- Hebrew
            (codepoint >= 0xFB1D and codepoint <= 0xFB4F) or      -- Hebrew Presentation Forms
            (codepoint >= 0x0600 and codepoint <= 0x06FF) or      -- Arabic
            (codepoint >= 0x0750 and codepoint <= 0x077F) or      -- Arabic Supplement
            (codepoint >= 0x0870 and codepoint <= 0x089F) or      -- Arabic Extended-B
            (codepoint >= 0x08A0 and codepoint <= 0x08FF) or      -- Arabic Extended-A
            (codepoint >= 0xFB50 and codepoint <= 0xFDFF) or      -- Arabic Presentation Forms-A
            (codepoint >= 0xFE70 and codepoint <= 0xFEFF)         -- Arabic Presentation Forms-B
    end

    -- return unchanged if no RTL codepoints found
    local found = false
    for i=1,utf8len do
        local codepoint = utf8.codepoint(s, utf8.offset(s, i))
        if (codepoint < MIN_RTL_CODEPOINT) then
            -- do nothing, fast DQ
        elseif (is_rtl_codepoint(codepoint)) then
            found = true
            break
        end
    end
    if not found then
        return s
    end

    rtlBuf = ''
    ltrBuf = ''
    mirrorBuf = '' -- mirror-able symbols only
    mirror = {     -- symbols having mirror images
        ["("] = ")",
        [")"] = "(",
        ["["] = "]",
        ["]"] = "[",
        ["<"] = ">",
        [">"] = "<",
        ["{"] = "}",
        ["}"] = "{"
    }

    local function reflect(s)
        -- reflect mirror-able symbols in the string
        -- loop is really for corner cases of multiple adjacent symbols ((likethis))
        local reflection = ''
        for i=1,#s do
            local char = s:sub(i, i) -- get the character at position i
            reflection = reflection .. mirror[char]
        end
        mirrorBuf = '' -- side effect
        return reflection
    end

    local function flush_buffers()
        if (rtlBuf ~= '') then
            -- RTL
            if (mirrorBuf ~= '') then
                rtlBuf = reflect(mirrorBuf) .. rtlBuf -- reflect
            end
            if (ltrBuf ~= '') then
                rtlBuf = ltrBuf .. rtlBuf
                ltrBuf = ''
            end
            table.insert(tokens, rtlBuf)
            rtlBuf = ''
        elseif (ltrBuf ~= '') then
            -- LTR
            if (mirrorBuf ~= '') then
                ltrBuf = ltrBuf .. mirrorBuf -- don't reflect
                mirrorBuf = ''
            end
            table.insert(tokens, ltrBuf)
            ltrBuf = ''
        elseif (mirrorBuf ~= '') then
            -- it's a mirror character after whitespace
            -- this is a corner case where we don't know the associativity,
            -- so assume the base direction of RTL, and mirror it
            table.insert(tokens, reflect(mirrorBuf))
        end
    end

    -- build the tokens table with lexemes that are stored in visual order
    tokens = {}
    for i=1,utf8len do
        codepoint = utf8.codepoint(s, utf8.offset(s, i))
        character = utf8.char(codepoint)

        if (mirror[character]) then
            -- collect symbols that might need to be reflected
            mirrorBuf = mirrorBuf .. character
        elseif ('\n' == character) then
            flush_buffers()
            table.insert(tokens, '\n')
        elseif (' ' == character or '\t' == character) then
            flush_buffers()
        elseif (is_rtl_codepoint(codepoint)) then
            -- RTL
            if (mirrorBuf ~= '') then
                rtlBuf = reflect(mirrorBuf) .. rtlBuf
            elseif (ltrBuf ~= '') then
                -- handle case of association without whitespace
                rtlBuf = ltrBuf .. rtlBuf
                ltrBuf = ''
            end
            rtlBuf = character .. rtlBuf
        else
            -- LTR, buffer for later
            if (mirrorBuf ~= '') then
                ltrBuf = mirrorBuf .. ltrBuf
                mirrorBuf = ''
            end
            ltrBuf = ltrBuf .. character
        end
    end
    flush_buffers()

    local function flush_ltrTok_buffer()
        -- insert accumulated LTR tokens into the lineTokBuf
        if #ltrTokBuf then
            for i=#ltrTokBuf,1,-1 do
                table.insert(lineTokBuf, ltrTokBuf[i])
            end
            ltrTokBuf = {}
        end
    end

    -- work backwards through the tokens table and construct output string
    output = ''
    ltrTokBuf = {}
    lineTokBuf = {}
    for i=#tokens,1,-1 do
        local token = tokens[i]
        local is_rtl_token = false

        for j=1,utf8.len(token) do
            local codepoint = utf8.codepoint(token, utf8.offset(token, j))
            if is_rtl_codepoint(codepoint) then
                is_rtl_token = true
                break
            end
        end
        if (is_rtl_token) then
            flush_ltrTok_buffer()
            table.insert(lineTokBuf, token)
        elseif ('\n' == token) then
            flush_ltrTok_buffer()
            output = '\n' .. table.concat(lineTokBuf, ' ') .. output
            lineTokBuf = {}
        else
            -- it’s LTR, buffer it in the opposite order
            -- the goal is to get the spacing around LTR tokens correct
            table.insert(ltrTokBuf, token)
        end
    end
    flush_ltrTok_buffer()
    output = table.concat(lineTokBuf, ' ') .. output -- space normalization happens here
    return(output)
end

--[[


=head1 LICENSE

Copyright 2010 Logitech. All Rights Reserved.

This file is licensed under BSD. Please see the LICENSE file for details.

=cut
--]]

