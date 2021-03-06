#ifndef _VM_H
#define _VM_H

#include "const.h"



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
  char* word_name;
} Vm_Exception_t;




typedef int (*Vm_Exception_handler_t)(Vm_Exception_t*);
//extern Vm_Exception_handler_t Vm_Exception_handler;

extern void Vm_reset(void);
extern Vm_Exception_handler_t Vm_Exception_handler;
extern void Vm_eval(char *);
extern char Vm_image_start;
extern char Vm_image_end;

#endif
