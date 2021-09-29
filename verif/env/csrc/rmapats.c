// file = 0; split type = patterns; threshold = 100000; total count = 0.
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

void  hsG_0__0 (struct dummyq_struct * I1289, EBLK  * I1283, U  I685);
void  hsG_0__0 (struct dummyq_struct * I1289, EBLK  * I1283, U  I685)
{
    U  I1547;
    U  I1548;
    U  I1549;
    struct futq * I1550;
    struct dummyq_struct * pQ = I1289;
    I1547 = ((U )vcs_clocks) + I685;
    I1549 = I1547 & ((1 << fHashTableSize) - 1);
    I1283->I727 = (EBLK  *)(-1);
    I1283->I731 = I1547;
    if (I1547 < (U )vcs_clocks) {
        I1548 = ((U  *)&vcs_clocks)[1];
        sched_millenium(pQ, I1283, I1548 + 1, I1547);
    }
    else if ((peblkFutQ1Head != ((void *)0)) && (I685 == 1)) {
        I1283->I733 = (struct eblk *)peblkFutQ1Tail;
        peblkFutQ1Tail->I727 = I1283;
        peblkFutQ1Tail = I1283;
    }
    else if ((I1550 = pQ->I1190[I1549].I745)) {
        I1283->I733 = (struct eblk *)I1550->I744;
        I1550->I744->I727 = (RP )I1283;
        I1550->I744 = (RmaEblk  *)I1283;
    }
    else {
        sched_hsopt(pQ, I1283, I1547);
    }
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
