#include <stdio.h>
#include "testAnonStruct.h"

void printIt(Thing t) {
  printf("value=%d Location=%s:%d\n",
         t.value, t.Location.filename, t.Location.line);
}
