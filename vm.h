#ifndef _VM_H
#define _VM_H

#include "const.S"



typedef struct 
{
  unsigned int reg[CNT_REG_SIZE/4];
  void* stack;
  void* ret_stack;
} Vm_Context_t;




typedef struct 
{
  Vm_Context_t context;
  int id;
} Vm_Exception_t;




typedef int (*Vm_Exception_handler_t)(Vm_Exception_t*);
extern Vm_Exception_handler_t Vm_Exception_handler;

#endif
