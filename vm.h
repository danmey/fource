#ifndef _VM_H
#define _VM_H

#include "const.S"



typedef struct 
{
  unsigned int reg[CNT_REG_SIZE];
  void* stack;
  void* ret_stack;
} Vm_Context_t;




typedef struct 
{
  Vm_Context_t context;
  int id;
} Vm_Exception_t;




typedef int (*Vm_Exception_handler)(Vm_Exception_t*);


#endif
