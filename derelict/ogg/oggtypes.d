/*

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/
module derelict.ogg.oggtypes;

private
{
    import derelict.util.compat;
}

alias long      ogg_int64_t;
alias ulong     ogg_uint64_t;
alias int       ogg_int32_t;
alias uint      ogg_uint32_t;
alias short     ogg_int16_t;
alias ushort    ogg_uint16_t;

struct ogg_iovec_t
{
    void* iov_base;
    size_t iov_len;
}

struct oggpack_buffer
{
    c_long endbyte;
    int endbit;
    ubyte* buffer;
    ubyte* ptr;
    c_long storage;
}

struct ogg_page
{
    ubyte *header;
    c_long  header_len;
    ubyte *_body;       // originally named "body", but that's a keyword in D.
    c_long  body_len;
}

struct ogg_stream_state
{
    ubyte  *body_data;
    c_long     body_storage;
    c_long     body_fill;
    c_long     body_returned;
    int     *lacing_vals;
    ogg_int64_t *granule_vals;
    c_long     lacing_storage;
    c_long     lacing_fill;
    c_long     lacing_packet;
    c_long     lacing_returned;
    ubyte   header[282];
    int     header_fill;
    int     e_o_s;
    int     b_o_s;
    c_long     serialno;
    c_long     pageno;
    ogg_int64_t  packetno;
    ogg_int64_t   granulepos;
}

struct ogg_packet
{
    ubyte *packet;
    c_long   bytes;
    c_long   b_o_s;
    c_long   e_o_s;
    ogg_int64_t  granulepos;
    ogg_int64_t  packetno;
}

struct ogg_sync_state
{
    ubyte *data;
    int storage;
    int fill;
    int returned;

    int unsynced;
    int headerbytes;
    int bodybytes;
}