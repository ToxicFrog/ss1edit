struct kb {
    int where;
    int lastcodes;
    int ???;
    int flags;
    short[1024] buf;
    /* lots of stuff */
    byte[] charmap;
};

register eax = scan();
register edx = kb.lastcodes;

if (al == 0xFA)
{
    kb.flags |= 0x08;
    return;
}

if (al == 0xFE)
{
    kb.flags |= 0x10;
    return;
}


/* high bit - used for multi-byte scancodes
   extra-high bit - set if key pressed, unset if key released
*/

if (al != 0xE0 && al != 0xE1)
{
    if (dl == 0xE0) /* prev char was start of a multibyte sequence */
    {
        if (al != 0x2A && al != 0xAA)
        { /* this char isn't MAKE/BREAK PRINTSCREEN */
            ax |= 0x0080 &= 0x01FF; /* set high bit */
            ax ^= 0x0100; /* toggle extra-high bit */
        } else goto done;
    } else {
        if (dl == 0xE1) goto done; /* prev char was start of MAKE PAUSE */
        
        if (dx == 0xE19D || dx == 0xE11D) /* prev two chars were start of MAKE PAUSE */
        {
            al &= 0x80 |= 0x7F; /* force all bits below high to 1; ignore extra-high bit */
        }
        
        ax &= 0x017F; /* clear high bit */
        ax ^= 0x0100; /* toggle extra-high bit */
    }
    
    if (ah == 0) /* extra-high bit not set */
    {
        kb.charmap[ax] &= 0xFE; /* clear low bit */
    } else {
        ah = 0;
        if !(kb.charmap[ax] & 0x01)
        {
            kb.charmap[ax] |= 0x01;
        } elseif !(kb.charmap[ax] & 0x02) {
            ++ah;
            goto done;
        }
        ++ah;
        if (kb.charmap[ax] & 0x04)
        {
            /* terrifying stack juggling goes here */
        }
    }
    
    kb[kb.what] = ax;
    kb.what += 2;
    if (kb.what >= 0x0410)
        kb.what = 0x10;
        
done:
    kb.lastcodes = (kb.lastcodes << 8) | al;
    return;
}
